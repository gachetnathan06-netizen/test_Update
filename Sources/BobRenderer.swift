import SwiftUI

struct BobLook {
    var skin: Skin
    var mood: Mood = .content
    var head: Prop? = nil
    var eyes: Prop? = nil
    var ears: Prop? = nil
    var neck: Prop? = nil
    var blink: CGFloat = 0
    var look: CGPoint = .zero
    var mouth: CGFloat = 0
    var heart: CGFloat = 0
    var square: CGFloat = 0
    var puddle: CGFloat = 0
    var sq: CGFloat = 0
    var heat: CGFloat = 0
    var camo: CGFloat = 0
    var camoColor: RGB = RGB(0x333333)
    var time: Double = 0
    var wobble: CGFloat = 0.012
}

enum BobRenderer {
    static let ink = Color(hex: 0x1B1530)

    static func superPoint(_ th: Double, square: Double) -> CGPoint {
        let c = cos(th), s = sin(th)
        let nx = 2.3 + 3.7 * square
        let ny = s < 0 ? 2.1 + 4.0 * square : 3.2 + 2.8 * square
        let ux = (c < 0 ? -1.0 : 1.0) * pow(abs(c), 2 / nx)
        let uy = (s < 0 ? -1.0 : 1.0) * pow(abs(s), 2 / ny)
        return CGPoint(x: ux, y: uy)
    }

    static func heartPoint(_ th: Double) -> CGPoint {
        let t = th + .pi / 2
        let x = 16 * pow(sin(t), 3) / 17
        let y = 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)
        let sy = -y / 17
        return CGPoint(x: x * 1.05, y: (sy - 0.15) / 0.85)
    }

    static func bodyPath(W: CGFloat, H: CGFloat, b: BobLook) -> Path {
        let n = 96
        var pts: [CGPoint] = []
        pts.reserveCapacity(n)
        let w = Double(b.wobble)
        for i in 0..<n {
            let th = -Double.pi / 2 + Double(i) / Double(n) * 2 * Double.pi
            var u = superPoint(th, square: Double(b.square))
            if b.heart > 0.001 {
                let h = heartPoint(th)
                let k = Double(b.heart)
                u = CGPoint(x: u.x * (1 - k) + h.x * k, y: u.y * (1 - k) + h.y * k)
            }
            let m = 1 + w * sin(3 * th + b.time * 2.2) + w * 0.7 * sin(5 * th - b.time * 1.7)
            pts.append(CGPoint(x: u.x * m * Double(W) / 2, y: -Double(H) / 2 + u.y * m * Double(H) / 2))
        }
        var p = Path()
        func mid(_ a: CGPoint, _ c: CGPoint) -> CGPoint { CGPoint(x: (a.x + c.x) / 2, y: (a.y + c.y) / 2) }
        p.move(to: mid(pts[n - 1], pts[0]))
        for i in 0..<n {
            p.addQuadCurve(to: mid(pts[i], pts[(i + 1) % n]), control: pts[i])
        }
        p.closeSubpath()
        return p
    }

    static func draw(_ context: GraphicsContext, at base: CGPoint, width W: CGFloat, look b: BobLook) {
        var c = context
        let H = W * 0.92
        let t = CGFloat(b.time)
        let sqT: CGFloat = b.sq + 0.012 * sin(t * 2.3)
        let sy: CGFloat = (1 - sqT) * (1 - 0.42 * b.puddle)
        let sx: CGFloat = (1 + 0.7 * sqT) * (1 + 0.22 * b.puddle)
        c.translateBy(x: base.x, y: base.y)
        c.scaleBy(x: sx, y: sy)

        let skin = b.skin
        var topRGB = RGB(skin.top)
        var botRGB = RGB(skin.bottom)
        if b.camo > 0.01 {
            topRGB = RGB.mix(topRGB, b.camoColor, Double(b.camo))
            botRGB = RGB.mix(botRGB, b.camoColor, Double(b.camo))
        }
        let tint = botRGB.color

        let all: [Prop?] = [b.head, b.eyes, b.ears, b.neck]
        let wearing: [Prop] = skin.signature + all.compactMap { $0 }
        for p in wearing where p.isBehind {
            Props.draw(p, c, W: W, H: H, t: t, tint: tint)
        }

        let body = bodyPath(W: W, H: H, b: b)
        var fillCtx = c
        fillCtx.opacity = skin.glass ? 0.82 : 1
        fillCtx.fill(body, with: .linearGradient(Gradient(colors: [topRGB.color, botRGB.color]),
                                                   startPoint: CGPoint(x: 0, y: -H), endPoint: CGPoint(x: 0, y: 0)))

        c.drawLayer { l in
            l.clip(to: body)
            drawTexture(l, skin: skin, W: W, H: H)
            drawDecor(l, skin: skin, W: W, H: H, t: t)
            l.fill(Path(CGRect(x: -W, y: -H * 0.4, width: W * 2, height: H * 0.4)),
                   with: .linearGradient(Gradient(colors: [.black.opacity(0), .black.opacity(0.2)]),
                                         startPoint: CGPoint(x: 0, y: -H * 0.4), endPoint: CGPoint(x: 0, y: 0)))
            l.drawLayer { hl in
                hl.addFilter(.blur(radius: W * 0.03))
                hl.fill(Props.oval(-W * 0.17, -H * 0.80, W * 0.17, H * 0.085), with: .color(.white.opacity(0.34)))
            }
            if b.heat > 0.01 {
                l.fill(body, with: .color(Color(hex: 0xFF3B30, opacity: 0.38 * Double(b.heat))))
            }
        }
        c.stroke(body, with: .color(botRGB.darker(0.25).color.opacity(0.55)), lineWidth: W * 0.012)

        drawFace(c, W: W, H: H, b: b)

        for p in wearing where !p.isBehind {
            Props.draw(p, c, W: W, H: H, t: t, tint: tint)
        }
    }

    // MARK: Texture & decor
    static func drawTexture(_ l: GraphicsContext, skin: Skin, W: CGFloat, H: CGFloat) {
        let col = Color(hex: skin.textureColor)
        switch skin.texture {
        case .none: break
        case .knit:
            let s = W * 0.065
            var y = -H
            while y < 0 {
                var x = -W / 2
                while x < W / 2 {
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: y))
                    p.addLine(to: CGPoint(x: x + s / 2, y: y + s * 0.8))
                    p.addLine(to: CGPoint(x: x + s, y: y))
                    l.stroke(p, with: .color(col.opacity(0.28)), style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                    x += s
                }
                y += s * 0.8
            }
        case .scale:
            let s = W * 0.09
            var row = 0
            var y = -H
            while y < s {
                var x = -W / 2 - (row % 2 == 0 ? 0 : s / 2)
                while x < W / 2 + s {
                    var p = Path()
                    p.addArc(center: CGPoint(x: x, y: y), radius: s / 2, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                    l.stroke(p, with: .color(col.opacity(0.30)), lineWidth: 1.4)
                    x += s
                }
                y += s * 0.5
                row += 1
            }
        case .polka:
            let s = W * 0.13
            var row = 0
            var y = -H
            while y < 0 {
                var x = -W / 2 - (row % 2 == 0 ? 0 : s / 2)
                while x < W / 2 + s {
                    l.fill(Props.oval(x, y, s * 0.2, s * 0.2), with: .color(col.opacity(0.38)))
                    x += s
                }
                y += s * 0.8
                row += 1
            }
        case .harlequin:
            let s = W * 0.17
            var r = 0
            var y = -H
            while y < 0 {
                var x = -W / 2 - s
                var k = r
                while x < W / 2 + s {
                    if k % 2 == 0 {
                        var p = Path()
                        p.move(to: CGPoint(x: x + s / 2, y: y))
                        p.addLine(to: CGPoint(x: x + s, y: y + s / 2))
                        p.addLine(to: CGPoint(x: x + s / 2, y: y + s))
                        p.addLine(to: CGPoint(x: x, y: y + s / 2))
                        p.closeSubpath()
                        l.fill(p, with: .color(col.opacity(0.42)))
                    }
                    x += s
                    k += 1
                }
                y += s / 2
                r += 1
            }
        case .stripes:
            let s = W * 0.11
            var y = -H
            var i = 0
            while y < 0 {
                if i % 2 == 0 { l.fill(Path(CGRect(x: -W, y: y, width: W * 2, height: s * 0.5)), with: .color(col.opacity(0.28))) }
                y += s * 0.5
                i += 1
            }
        case .ribs:
            for k in [-0.55, -0.28, 0.0, 0.28, 0.55] {
                var p = Path()
                let x = CGFloat(k) * W
                p.move(to: CGPoint(x: x * 0.4, y: -H))
                p.addQuadCurve(to: CGPoint(x: x * 0.4, y: 0), control: CGPoint(x: x * 1.15, y: -H / 2))
                l.stroke(p, with: .color(col.opacity(0.28)), lineWidth: W * 0.016)
            }
        }
    }

    static func drawDecor(_ l: GraphicsContext, skin: Skin, W: CGFloat, H: CGFloat, t: CGFloat) {
        switch skin.decor {
        case .none: break
        case .stars:
            let pos: [(CGFloat, CGFloat, CGFloat)] = [(-0.30, -0.78, 1), (0.28, -0.70, 0.8), (-0.12, -0.25, 0.7), (0.34, -0.30, 1), (-0.38, -0.46, 0.6), (0.05, -0.92, 0.6), (0.0, -0.12, 0.5)]
            for (i, q) in pos.enumerated() {
                let tw: CGFloat = 0.55 + 0.45 * sin(t * 2 + CGFloat(i) * 1.7)
                l.fill(Props.star(q.0 * W, q.1 * H, W * 0.04 * q.2, W * 0.012 * q.2, n: 4), with: .color(Color(hex: 0xFFF3B0, opacity: Double(tw))))
            }
        case .sprinkles:
            let cols: [UInt32] = [0xFF7A90, 0x6EE7B7, 0x7CC4FF, 0xFFB547, 0xB794F4]
            for i in 0..<18 {
                let f = CGFloat(i)
                let x: CGFloat = (fract(f * 0.618) - 0.5) * W * 0.9
                let y: CGFloat = -H * (0.12 + 0.8 * fract(f * 0.382 + 0.2))
                var g = l
                g.translateBy(x: x, y: y)
                g.rotate(by: .radians(Double(f * 1.3)))
                g.fill(Props.rrect(-W * 0.02, -W * 0.006, W * 0.04, W * 0.012, W * 0.006), with: .color(Color(hex: cols[i % cols.count])))
            }
        case .hood:
            var p = Path()
            p.move(to: CGPoint(x: -W * 0.56, y: -H * 0.30))
            p.addQuadCurve(to: CGPoint(x: W * 0.56, y: -H * 0.30), control: CGPoint(x: 0, y: -H * 1.10))
            p.addLine(to: CGPoint(x: W * 0.7, y: -H * 1.2))
            p.addLine(to: CGPoint(x: -W * 0.7, y: -H * 1.2))
            p.closeSubpath()
            l.fill(p, with: .color(Color(hex: 0x1A1A24)))
            var e = Path()
            e.move(to: CGPoint(x: -W * 0.56, y: -H * 0.30))
            e.addQuadCurve(to: CGPoint(x: W * 0.56, y: -H * 0.30), control: CGPoint(x: 0, y: -H * 1.10))
            l.stroke(e, with: .color(Color(hex: skin.cheek)), lineWidth: W * 0.02)
        }
    }

    static func fract(_ x: CGFloat) -> CGFloat { x - floor(x) }

    // MARK: Face
    static func drawFace(_ c: GraphicsContext, W: CGFloat, H: CGFloat, b: BobLook) {
        let ex = W * 0.19
        let ey = -H * 0.50
        let rw = W * 0.058
        let rh = W * 0.080
        let lx = b.look.x * W * 0.018
        let ly = b.look.y * W * 0.014
        let opn: CGFloat = max(0.08, 1 - b.blink)
        let lw = W * 0.016
        let t = CGFloat(b.time)
        let sleepy = StrokeStyle(lineWidth: lw, lineCap: .round)

        func eye(_ cx: CGFloat, scale: CGFloat = 1, hl: Bool = true) {
            let r = Props.oval(cx + lx, ey + ly, rw * scale, rh * scale * opn)
            c.fill(r, with: .color(ink))
            if hl && opn > 0.4 {
                c.fill(Props.oval(cx + lx - rw * 0.28 * scale, ey + ly - rh * 0.30 * scale, rw * 0.34 * scale, rw * 0.34 * scale), with: .color(.white))
                c.fill(Props.oval(cx + lx + rw * 0.30 * scale, ey + ly + rh * 0.32 * scale, rw * 0.16 * scale, rw * 0.16 * scale), with: .color(.white.opacity(0.8)))
            }
        }
        func arc(_ cx: CGFloat, up: Bool) {
            var p = Path()
            p.move(to: CGPoint(x: cx - rw * 1.1, y: ey))
            p.addQuadCurve(to: CGPoint(x: cx + rw * 1.1, y: ey), control: CGPoint(x: cx, y: ey + (up ? -rh * 1.2 : rh * 1.1)))
            c.stroke(p, with: .color(ink), style: sleepy)
        }

        let xs: [CGFloat] = [-ex, ex]
        switch b.mood {
        case .endormi:
            for x in xs { arc(x, up: false) }
        case .heureux:
            for x in xs { arc(x, up: true) }
        case .amoureux:
            for x in xs { c.fill(Props.heart(x + lx, ey + ly, W * 0.17), with: .color(Color(hex: 0xFF4D79))) }
        case .surpris:
            for x in xs {
                c.fill(Props.oval(x, ey, rw * 1.3, rw * 1.3 * opn), with: .color(.white))
                c.stroke(Props.oval(x, ey, rw * 1.3, rw * 1.3 * opn), with: .color(ink), lineWidth: lw * 0.6)
                c.fill(Props.oval(x + lx, ey + ly, rw * 0.5, rw * 0.5), with: .color(ink))
            }
        case .concentre, .ennuye:
            let lid: CGFloat = b.mood == .concentre ? 0.0 : 0.12
            for x in xs {
                var g = c
                g.clip(to: Path(CGRect(x: x - rw * 1.4, y: ey - rh * 0.15 + rh * lid, width: rw * 2.8, height: rh * 2)))
                g.fill(Props.oval(x + lx * (b.mood == .ennuye ? 2 : 1), ey + ly, rw, rh * opn), with: .color(ink))
                let tilt: CGFloat = b.mood == .concentre ? (x < 0 ? 1 : -1) * rh * 0.12 : 0
                var br = Path()
                br.move(to: CGPoint(x: x - rw * 1.2, y: ey - rh * 0.18 + rh * lid - tilt))
                br.addLine(to: CGPoint(x: x + rw * 1.2, y: ey - rh * 0.18 + rh * lid + tilt))
                c.stroke(br, with: .color(ink), style: sleepy)
            }
        case .triste:
            for x in xs {
                eye(x, scale: 0.95)
                let s: CGFloat = x < 0 ? 1 : -1
                var br = Path()
                br.move(to: CGPoint(x: x - s * rw * 1.2, y: ey - rh * 0.85))
                br.addLine(to: CGPoint(x: x + s * rw * 1.2, y: ey - rh * 1.35))
                c.stroke(br, with: .color(ink), style: sleepy)
            }
            let drop: CGFloat = ((t * 0.5).truncatingRemainder(dividingBy: 1)) * W * 0.12
            c.fill(Props.oval(-ex - rw * 0.8, ey + rh * 1.2 + drop, W * 0.014, W * 0.022), with: .color(Color(hex: 0x7CC4FF, opacity: Double(0.9 - drop / (W * 0.12) * 0.8))))
        case .surchauffe:
            for x in xs {
                let s: CGFloat = x < 0 ? 1 : -1
                var p = Path()
                p.move(to: CGPoint(x: x - s * rw, y: ey - rh * 0.6))
                p.addLine(to: CGPoint(x: x + s * rw * 0.8, y: ey))
                p.addLine(to: CGPoint(x: x - s * rw, y: ey + rh * 0.6))
                c.stroke(p, with: .color(ink), style: sleepy)
            }
        case .affame:
            for x in xs { eye(x, scale: 1.05) }
        default:
            for x in xs { eye(x) }
        }

        // joues
        let cheekA: Double = b.mood == .amoureux ? 0.85 : 0.5
        for sx in [-1.0, 1.0] {
            c.fill(Props.oval(CGFloat(sx) * W * 0.30, -H * 0.38, W * 0.055, W * 0.036), with: .color(Color(hex: b.skin.cheek, opacity: cheekA)))
        }

        // bouche
        let my = -H * 0.34
        if b.mouth > 0.06 && b.mood != .endormi {
            let ry = W * (0.012 + 0.05 * b.mouth)
            c.fill(Props.oval(0, my + ry * 0.4, W * 0.05, ry), with: .color(ink))
            if b.mouth > 0.4 { c.fill(Props.oval(0, my + ry * 1.0, W * 0.03, ry * 0.45), with: .color(Color(hex: 0xFF7A90))) }
        } else {
            switch b.mood {
            case .content, .amoureux:
                var p = Path()
                p.move(to: CGPoint(x: -W * 0.07, y: my))
                p.addQuadCurve(to: CGPoint(x: W * 0.07, y: my), control: CGPoint(x: 0, y: my + W * 0.055))
                c.stroke(p, with: .color(ink), style: sleepy)
            case .heureux:
                var p = Path()
                p.move(to: CGPoint(x: -W * 0.09, y: my - W * 0.01))
                p.addQuadCurve(to: CGPoint(x: W * 0.09, y: my - W * 0.01), control: CGPoint(x: 0, y: my + W * 0.15))
                p.closeSubpath()
                c.fill(p, with: .color(ink))
                var g = c
                g.clip(to: p)
                g.fill(Props.oval(0, my + W * 0.065, W * 0.045, W * 0.03), with: .color(Color(hex: 0xFF7A90)))
            case .triste:
                var p = Path()
                p.move(to: CGPoint(x: -W * 0.06, y: my + W * 0.02))
                p.addQuadCurve(to: CGPoint(x: W * 0.06, y: my + W * 0.02), control: CGPoint(x: 0, y: my - W * 0.04))
                c.stroke(p, with: .color(ink), style: sleepy)
            case .endormi:
                let r = W * (0.02 + 0.006 * sin(t * 2.3))
                c.fill(Props.oval(0, my, r, r * 1.1), with: .color(ink.opacity(0.8)))
            case .surpris:
                c.fill(Props.oval(0, my + W * 0.01, W * 0.035, W * 0.05), with: .color(ink))
            case .concentre:
                var p = Path()
                p.move(to: CGPoint(x: -W * 0.045, y: my))
                p.addLine(to: CGPoint(x: W * 0.045, y: my))
                c.stroke(p, with: .color(ink), style: sleepy)
            case .ennuye:
                var p = Path()
                p.move(to: CGPoint(x: -W * 0.06, y: my))
                p.addQuadCurve(to: CGPoint(x: 0, y: my), control: CGPoint(x: -W * 0.03, y: my - W * 0.02))
                p.addQuadCurve(to: CGPoint(x: W * 0.06, y: my), control: CGPoint(x: W * 0.03, y: my + W * 0.02))
                c.stroke(p, with: .color(ink), style: sleepy)
            case .surchauffe:
                c.fill(Props.oval(0, my + W * 0.01, W * 0.08, W * 0.06), with: .color(ink))
                c.fill(Props.oval(0, my + W * 0.04, W * 0.05, W * 0.03), with: .color(Color(hex: 0xFF7A90)))
            case .affame:
                var p = Path()
                p.move(to: CGPoint(x: -W * 0.05, y: my - W * 0.01))
                p.addQuadCurve(to: CGPoint(x: W * 0.05, y: my - W * 0.01), control: CGPoint(x: 0, y: my + W * 0.11))
                p.closeSubpath()
                c.fill(p, with: .color(ink))
                let len: CGFloat = W * (0.03 + 0.02 * (0.5 + 0.5 * sin(t * 3)))
                c.fill(Props.oval(W * 0.05, my + W * 0.02 + len / 2, W * 0.012, len / 2 + W * 0.01), with: .color(Color(hex: 0x7CC4FF, opacity: 0.85)))
            }
        }
    }
}
