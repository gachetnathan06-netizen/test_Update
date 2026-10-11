import SwiftUI
import UIKit

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

struct RGB {
    var r: Double
    var g: Double
    var b: Double
    init(_ hex: UInt32) {
        r = Double((hex >> 16) & 0xFF) / 255
        g = Double((hex >> 8) & 0xFF) / 255
        b = Double(hex & 0xFF) / 255
    }
    init(r: Double, g: Double, b: Double) { self.r = r; self.g = g; self.b = b }
    var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: 1) }
    static func mix(_ a: RGB, _ b: RGB, _ t: Double) -> RGB {
        let k = min(1, max(0, t))
        return RGB(r: a.r + (b.r - a.r) * k, g: a.g + (b.g - a.g) * k, b: a.b + (b.b - a.b) * k)
    }
    func darker(_ k: Double) -> RGB { RGB(r: r * (1 - k), g: g * (1 - k), b: b * (1 - k)) }
}

struct SkyPalette {
    var top: RGB
    var bottom: RGB
    var floor: RGB
    var night: Double
}

enum Theme {
    static let amber = Color(hex: 0xFFB547)
    static let ink = Color(hex: 0x14122B)
    static let rose = Color(hex: 0xFF7A90)
    static let mint = Color(hex: 0x6EE7B7)
    static let sky = Color(hex: 0x7CC4FF)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func sky(hour: Double) -> SkyPalette {
        let k: [(Double, UInt32, UInt32, UInt32)] = [
            (0, 0x0B0A1F, 0x1C1740, 0x120F2B),
            (5, 0x1B1840, 0x4A3B6B, 0x1A1634),
            (7, 0xF6A96B, 0xFFD9A8, 0x7A4E4A),
            (12, 0x7EC3F0, 0xE6F4FF, 0xA9856A),
            (17, 0x8FB8E8, 0xFFE2B8, 0x9B7860),
            (19, 0xE0785A, 0xFFB88A, 0x6E4545),
            (21, 0x2A2257, 0x5A3E78, 0x2A2040),
            (24, 0x0B0A1F, 0x1C1740, 0x120F2B)
        ]
        var i = 0
        while i < k.count - 2 && hour >= k[i + 1].0 { i += 1 }
        let a = k[i], b = k[i + 1]
        let t = (hour - a.0) / (b.0 - a.0)
        let night: Double
        if hour < 5 || hour >= 21 { night = 1 }
        else if hour < 7 { night = 1 - (hour - 5) / 2 }
        else if hour >= 19 { night = (hour - 19) / 2 }
        else { night = 0 }
        return SkyPalette(top: RGB.mix(RGB(a.1), RGB(b.1), t),
                          bottom: RGB.mix(RGB(a.2), RGB(b.2), t),
                          floor: RGB.mix(RGB(a.3), RGB(b.3), t),
                          night: night)
    }

    static func hourNow(_ d: Date = Date()) -> Double {
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        return Double(c.hour ?? 12) + Double(c.minute ?? 0) / 60
    }
}

struct Glass: ViewModifier {
    var radius: CGFloat
    func body(content: Content) -> some View {
        content
            .background(BlurView().clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous)))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5))
    }
}

extension View {
    func glass(_ r: CGFloat = 20) -> some View { modifier(Glass(radius: r)) }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

enum Haptics {
    static var enabled = true
    static func impact(_ s: UIImpactFeedbackGenerator.FeedbackStyle = .light, _ intensity: CGFloat = 1) {
        guard enabled else { return }
        let g = UIImpactFeedbackGenerator(style: s)
        g.impactOccurred(intensity: intensity)
    }
    static func success() {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func select() {
        guard enabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
