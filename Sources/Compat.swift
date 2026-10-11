import SwiftUI
import UIKit

// ============================================================
//  Couche de compatibilité iOS 13
//  Remplace Canvas / GraphicsContext / TimelineView / NavigationStack
//  (iOS 15-16) par des équivalents basés sur Core Graphics.
//  Les types portent le même nom que ceux de SwiftUI : dans ce module
//  ils ont la priorité, le code de dessin existant reste donc inchangé.
// ============================================================

// MARK: - GraphicsContext

struct GraphicsContext {
    enum Shading {
        case color(Color)
        case linearGradient(Gradient, startPoint: CGPoint, endPoint: CGPoint)
        case radialGradient(Gradient, center: CGPoint, startRadius: CGFloat, endRadius: CGFloat)
    }

    struct Filter {
        let blurRadius: CGFloat
        static func blur(radius: CGFloat) -> Filter { Filter(blurRadius: radius) }
    }

    let cg: CGContext
    var opacity: Double = 1
    private(set) var transform: CGAffineTransform = .identity
    private var clips: [CGPath] = []
    private var blur: CGFloat = 0

    init(_ cg: CGContext) { self.cg = cg }

    // MARK: Transformations (sémantique valeur, comme SwiftUI)

    mutating func translateBy(x: CGFloat, y: CGFloat) {
        transform = CGAffineTransform(translationX: x, y: y).concatenating(transform)
    }

    mutating func scaleBy(x: CGFloat, y: CGFloat) {
        transform = CGAffineTransform(scaleX: x, y: y).concatenating(transform)
    }

    mutating func rotate(by angle: Angle) {
        transform = CGAffineTransform(rotationAngle: CGFloat(angle.radians)).concatenating(transform)
    }

    mutating func clip(to path: Path) {
        clips.append(path.applying(transform).cgPath)
    }

    mutating func addFilter(_ filter: Filter) {
        blur = max(blur, filter.blurRadius)
    }

    func drawLayer(content: (inout GraphicsContext) -> Void) {
        var layer = self
        content(&layer)
    }

    // MARK: Dessin

    func fill(_ path: Path, with shading: Shading, style: FillStyle = FillStyle()) {
        prepare()
        defer { cg.restoreGState() }
        let p = path.cgPath
        if blur > 0, case .color(let c) = shading {
            softFill(p, c)
            return
        }
        switch shading {
        case .color(let c):
            cg.setFillColor(GraphicsContext.cgColor(c))
            cg.addPath(p)
            if style.isEOFilled { cg.fillPath(using: .evenOdd) } else { cg.fillPath() }
        default:
            cg.addPath(p)
            if style.isEOFilled { cg.clip(using: .evenOdd) } else { cg.clip() }
            paint(shading)
        }
    }

    func stroke(_ path: Path, with shading: Shading, lineWidth: CGFloat = 1) {
        stroke(path, with: shading, style: StrokeStyle(lineWidth: lineWidth))
    }

    func stroke(_ path: Path, with shading: Shading, style: StrokeStyle) {
        prepare()
        defer { cg.restoreGState() }
        cg.setLineWidth(style.lineWidth)
        cg.setLineCap(style.lineCap)
        cg.setLineJoin(style.lineJoin)
        cg.setMiterLimit(style.miterLimit)
        if !style.dash.isEmpty { cg.setLineDash(phase: style.dashPhase, lengths: style.dash) }
        cg.addPath(path.cgPath)
        switch shading {
        case .color(let c):
            cg.setStrokeColor(GraphicsContext.cgColor(c))
            cg.strokePath()
        default:
            cg.replacePathWithStrokedPath()
            cg.clip()
            paint(shading)
        }
    }

    /// Remplace `ctx.draw(Text(...), at:)` (impossible en Core Graphics).
    func drawText(_ text: String, at point: CGPoint, size: CGFloat,
                  weight: UIFont.Weight = .regular, rounded: Bool = false, color: Color = .white) {
        prepare()
        defer { cg.restoreGState() }
        var font = UIFont.systemFont(ofSize: size, weight: weight)
        if rounded, let d = font.fontDescriptor.withDesign(.rounded) {
            font = UIFont(descriptor: d, size: size)
        }
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: ColorBridge.uiColor(color)]
        let s = text as NSString
        let sz = s.size(withAttributes: attrs)
        UIGraphicsPushContext(cg)
        s.draw(at: CGPoint(x: point.x - sz.width / 2, y: point.y - sz.height / 2), withAttributes: attrs)
        UIGraphicsPopContext()
    }

    // MARK: Interne

    private func prepare() {
        cg.saveGState()
        for c in clips {
            cg.addPath(c)
            cg.clip()
        }
        cg.concatenate(transform)
        cg.setAlpha(CGFloat(opacity))
    }

    /// Approximation d'un flou : halo de contours translucides + remplissage.
    private func softFill(_ p: CGPath, _ c: Color) {
        let col = GraphicsContext.cgColor(c)
        let a = CGFloat(opacity)
        cg.setFillColor(col)
        cg.setStrokeColor(col)
        cg.setLineJoin(.round)
        for i in 1...4 {
            cg.setAlpha(a * 0.14)
            cg.setLineWidth(blur * 0.9 * CGFloat(i))
            cg.addPath(p)
            cg.strokePath()
        }
        cg.setAlpha(a * 0.55)
        cg.addPath(p)
        cg.fillPath()
    }

    private func paint(_ shading: Shading) {
        switch shading {
        case .color(let c):
            cg.setFillColor(GraphicsContext.cgColor(c))
            cg.fill(cg.boundingBoxOfClipPath)
        case .linearGradient(let g, let a, let b):
            guard let grad = GraphicsContext.cgGradient(g) else { return }
            cg.drawLinearGradient(grad, start: a, end: b,
                                  options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        case .radialGradient(let g, let c, let r0, let r1):
            guard let grad = GraphicsContext.cgGradient(g) else { return }
            cg.drawRadialGradient(grad, startCenter: c, startRadius: r0,
                                  endCenter: c, endRadius: r1, options: [.drawsAfterEndLocation])
        }
    }

    static func cgColor(_ c: Color) -> CGColor {
        let u = ColorBridge.uiColor(c)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if u.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return CGColor(srgbRed: r, green: g, blue: b, alpha: a)
        }
        return u.cgColor
    }

    private static func cgGradient(_ g: Gradient) -> CGGradient? {
        let stops = g.stops
        let colors = stops.map { cgColor($0.color) } as CFArray
        var locs: [CGFloat] = stops.map { $0.location }
        return CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: &locs)
    }
}

// MARK: - Canvas

final class CanvasHostView: UIView {
    var renderer: ((GraphicsContext, CGSize) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        contentMode = .redraw
        clearsContextBeforeDrawing = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) non supporté") }

    override func draw(_ rect: CGRect) {
        guard let cg = UIGraphicsGetCurrentContext() else { return }
        renderer?(GraphicsContext(cg), bounds.size)
    }
}

struct Canvas: UIViewRepresentable {
    private let renderer: (GraphicsContext, CGSize) -> Void

    init(_ renderer: @escaping (GraphicsContext, CGSize) -> Void) {
        self.renderer = renderer
    }

    func makeUIView(context: Context) -> CanvasHostView { CanvasHostView() }

    func updateUIView(_ view: CanvasHostView, context: Context) {
        view.renderer = renderer
        view.setNeedsDisplay()
    }
}

// MARK: - TimelineView

struct CompatTimelineSchedule {
    fileprivate enum Kind {
        case animation
        case periodic(TimeInterval)
    }
    fileprivate let kind: Kind

    static var animation: CompatTimelineSchedule { CompatTimelineSchedule(kind: .animation) }
    static func periodic(from start: Date, by interval: TimeInterval) -> CompatTimelineSchedule {
        CompatTimelineSchedule(kind: .periodic(interval))
    }
}

struct CompatTimelineContext {
    let date: Date
}

enum CompatConfig {
    static let fpsKey = "fps"

    /// Images par seconde choisies dans Réglages (30, 60 ou 120). 60 par défaut.
    static var fps: Int {
        let v = UserDefaults.standard.integer(forKey: fpsKey)
        return [30, 60, 120].contains(v) ? v : 60
    }

    /// Règle la cadence d'un CADisplayLink. 120 n'a d'effet que sur un écran ProMotion (iPhone 13 Pro et +, iOS 15+).
    static func apply(to link: CADisplayLink, cap: Int? = nil) {
        let f = min(fps, cap ?? 120)
        if #available(iOS 15.0, *) {
            link.preferredFrameRateRange = CAFrameRateRange(minimum: Float(min(f, 30)), maximum: Float(f), preferred: Float(f))
        } else {
            link.preferredFramesPerSecond = f
        }
    }
}

// MARK: - AnimatedCanvas : dessin animé piloté directement par l'écran (sans passer par SwiftUI à chaque image)

private final class LinkProxy: NSObject {
    weak var view: AnimatedCanvasView?
    init(_ v: AnimatedCanvasView) { view = v }
    @objc func tick(_ link: CADisplayLink) {
        if let v = view { v.setNeedsDisplay() } else { link.invalidate() }
    }
}

final class AnimatedCanvasView: UIView {
    var renderer: ((GraphicsContext, CGSize, Date) -> Void)?
    var maxFPS: Int?
    private var link: CADisplayLink?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        backgroundColor = .clear
        contentMode = .redraw
        layer.drawsAsynchronously = true
        NotificationCenter.default.addObserver(self, selector: #selector(rateChanged),
                                               name: UserDefaults.didChangeNotification, object: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) non supporté") }

    deinit { link?.invalidate() }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { start() } else { stop() }
    }

    private func start() {
        guard link == nil else { return }
        let l = CADisplayLink(target: LinkProxy(self), selector: #selector(LinkProxy.tick(_:)))
        CompatConfig.apply(to: l, cap: maxFPS)
        l.add(to: .main, forMode: .common)
        link = l
        setNeedsDisplay()
    }

    private func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func rateChanged() {
        if let l = link { CompatConfig.apply(to: l, cap: maxFPS) }
    }

    override func draw(_ rect: CGRect) {
        guard let cg = UIGraphicsGetCurrentContext() else { return }
        renderer?(GraphicsContext(cg), bounds.size, Date())
    }
}

struct AnimatedCanvas: UIViewRepresentable {
    private let maxFPS: Int?
    private let renderer: (GraphicsContext, CGSize, Date) -> Void

    init(maxFPS: Int? = nil, _ renderer: @escaping (GraphicsContext, CGSize, Date) -> Void) {
        self.maxFPS = maxFPS
        self.renderer = renderer
    }

    func makeUIView(context: Context) -> AnimatedCanvasView {
        let v = AnimatedCanvasView()
        v.maxFPS = maxFPS
        return v
    }

    func updateUIView(_ view: AnimatedCanvasView, context: Context) {
        view.renderer = renderer
    }
}

final class TimelineTicker: ObservableObject {
    @Published var date = Date()
    private var link: CADisplayLink?
    private var timer: Timer?

    func start(_ schedule: CompatTimelineSchedule) {
        stop()
        switch schedule.kind {
        case .animation:
            let l = CADisplayLink(target: self, selector: #selector(tick))
            CompatConfig.apply(to: l)
            l.add(to: .main, forMode: .common)
            link = l
        case .periodic(let every):
            let t = Timer(timeInterval: every, repeats: true) { [weak self] _ in self?.tick() }
            RunLoop.main.add(t, forMode: .common)
            timer = t
        }
    }

    func stop() {
        link?.invalidate()
        link = nil
        timer?.invalidate()
        timer = nil
    }

    @objc private func tick() { date = Date() }

    deinit { stop() }
}

struct TimelineView<Content: View>: View {
    private let schedule: CompatTimelineSchedule
    private let content: (CompatTimelineContext) -> Content
    @State private var ticker = TimelineTicker()
    @State private var now = Date()

    init(_ schedule: CompatTimelineSchedule, @ViewBuilder content: @escaping (CompatTimelineContext) -> Content) {
        self.schedule = schedule
        self.content = content
    }

    var body: some View {
        content(CompatTimelineContext(date: now))
            .onAppear { ticker.start(schedule) }
            .onDisappear { ticker.stop() }
            .onReceive(ticker.$date) { now = $0 }
    }
}

// MARK: - NavigationStack (iOS 16) -> NavigationView

struct NavigationStack<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationView { content }
            .navigationViewStyle(.stack)
    }
}

// MARK: - Flou "verre" (remplace .ultraThinMaterial, iOS 15)

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemUltraThinMaterialDark

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ view: UIVisualEffectView, context: Context) {
        view.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Dates (remplace Date.formatted, iOS 15)

private enum CompatFormatters {
    static let time: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()
    static let dateTime: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}

extension Date {
    var timeStr: String { CompatFormatters.time.string(from: self) }
    var dateTimeStr: String { CompatFormatters.dateTime.string(from: self) }
}


// MARK: - Couleur SwiftUI -> UIColor (UIColor(Color) n'existe qu'à partir d'iOS 14)

enum ColorBridge {
    static func uiColor(_ c: Color) -> UIColor {
        if #available(iOS 14.0, *) { return UIColor(c) }
        var alpha: CGFloat = 1
        if let u = find(c, 0, &alpha) { return u.withAlphaComponent(u.cgColor.alpha * alpha) }
        let d = String(describing: c).lowercased()
        if d.contains("black") { return UIColor.black.withAlphaComponent(alpha) }
        if d.contains("clear") { return .clear }
        if d.contains("white") { return UIColor.white.withAlphaComponent(alpha) }
        if let h = hexFrom(d) { return h.withAlphaComponent(h.cgColor.alpha * alpha) }
        return UIColor.white.withAlphaComponent(alpha)
    }

    /// Cherche un UIColor dans la structure interne du Color (Color(UIColor) le conserve) et cumule les opacités.
    private static func find(_ v: Any, _ depth: Int, _ alpha: inout CGFloat) -> UIColor? {
        if let u = v as? UIColor { return u }
        if depth > 8 { return nil }
        var m: Mirror? = Mirror(reflecting: v)
        while let mm = m {
            for ch in mm.children where ch.label == "opacity" {
                if let d = ch.value as? Double { alpha *= CGFloat(d) }
                else if let f = ch.value as? Float { alpha *= CGFloat(f) }
                else if let f = ch.value as? CGFloat { alpha *= f }
            }
            for ch in mm.children { if let u = find(ch.value, depth + 1, &alpha) { return u } }
            m = mm.superclassMirror
        }
        return nil
    }

    private static func hexFrom(_ d: String) -> UIColor? {
        guard let i = d.firstIndex(of: "#") else { return nil }
        let h = String(d[d.index(after: i)...].prefix(8))
        guard h.count >= 6, let n = UInt64(h, radix: 16) else { return nil }
        if h.count == 8 {
            return UIColor(red: CGFloat((n >> 24) & 255) / 255, green: CGFloat((n >> 16) & 255) / 255,
                           blue: CGFloat((n >> 8) & 255) / 255, alpha: CGFloat(n & 255) / 255)
        }
        return UIColor(red: CGFloat((n >> 16) & 255) / 255, green: CGFloat((n >> 8) & 255) / 255, blue: CGFloat(n & 255) / 255, alpha: 1)
    }
}

// MARK: - Label (iOS 14) : équivalent simple

struct Label: View {
    let title: String
    let symbol: String
    init(_ title: String, systemImage: String) { self.title = title; self.symbol = systemImage }
    var body: some View {
        HStack(spacing: 8) { Image(systemName: symbol); Text(title) }
    }
}

// MARK: - Grille (LazyVGrid, iOS 14) : lignes de colonnes égales

struct FlowGrid: View {
    var columns: Int? = nil
    var minWidth: CGFloat = 98
    var hPad: CGFloat = 28
    var spacing: CGFloat = 10
    let cells: [AnyView]

    private var cols: Int {
        if let c = columns { return max(1, c) }
        return max(1, Int((UIScreen.main.bounds.width - hPad + spacing) / (minWidth + spacing)))
    }

    var body: some View {
        let n = cols
        let rows = (cells.count + n - 1) / n
        return VStack(spacing: spacing) {
            ForEach(0..<max(rows, 1), id: \.self) { r in
                HStack(alignment: .top, spacing: spacing) {
                    ForEach(0..<n, id: \.self) { c in
                        self.cell(r * n + c)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cell(_ i: Int) -> some View {
        if i < cells.count {
            cells[i].frame(maxWidth: .infinity)
        } else {
            Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
        }
    }
}

// MARK: - Barre de progression (ProgressView + tint, iOS 14)

struct BarProgress: View {
    var value: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.15))
                Capsule().fill(Theme.amber).frame(width: g.size.width * CGFloat(min(1, max(0, value))))
            }
        }
        .frame(height: 6)
    }
}
