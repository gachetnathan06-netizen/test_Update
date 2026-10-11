import SwiftUI

enum Props {
    static let ink = Color(hex: 0x1B1530)

    static func oval(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }

    static func star(_ cx: CGFloat, _ cy: CGFloat, _ outer: CGFloat, _ inner: CGFloat, n: Int = 5, rot: CGFloat = -.pi / 2) -> Path {
        var p = Path()
        for i in 0..<(n * 2) {
            let rad: CGFloat = i % 2 == 0 ? outer : inner
            let a: CGFloat = rot + CGFloat(i) * .pi / CGFloat(n)
            let pt = CGPoint(x: cx + cos(a) * rad, y: cy + sin(a) * rad)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }

    static func heart(_ cx: CGFloat, _ cy: CGFloat, _ s: CGFloat) -> Path {
        var p = Path()
        let n = 48
        for i in 0...n {
            let t: CGFloat = CGFloat(i) / CGFloat(n) * 2 * .pi
            let s3: CGFloat = sin(t) * sin(t) * sin(t)
            let x: CGFloat = 16 * s3
            let y: CGFloat = 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)
            let pt = CGPoint(x: cx + x / 17 * s, y: cy - (y - 2) / 17 * s)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }

    static func fs(_ c: GraphicsContext, _ p: Path, _ f: Color, lw: CGFloat = 1.2) {
        c.fill(p, with: .color(f))
        c.stroke(p, with: .color(ink.opacity(0.32)), lineWidth: lw)
    }

    static func line(_ c: GraphicsContext, _ pts: [CGPoint], _ col: Color, _ lw: CGFloat) {
        var p = Path()
        for (i, q) in pts.enumerated() {
            if i == 0 { p.move(to: q) } else { p.addLine(to: q) }
        }
        c.stroke(p, with: .color(col), style: StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round))
    }

    static func rotated(_ c: GraphicsContext, at p: CGPoint, deg: Double, _ body: (GraphicsContext) -> Void) {
        var cc = c
        cc.translateBy(x: p.x, y: p.y)
        cc.rotate(by: .degrees(deg))
        body(cc)
    }

    static func rrect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r)
    }

    static func crown(_ c: GraphicsContext, W: CGFloat, H: CGFloat, top: CGFloat, scale s: CGFloat, velvet: Bool) {
        let w = W * 0.5 * s
        let h = H * 0.17 * s
        let base = top + H * 0.08
        if velvet { fs(c, oval(0, base - h * 0.1, w * 0.92, h * 0.35), Color(hex: 0x6B2FA0)) }
        var p = Path()
        p.move(to: CGPoint(x: -w / 2, y: base))
        p.addLine(to: CGPoint(x: -w / 2, y: base - h))
        p.addLine(to: CGPoint(x: -w / 4, y: base - h * 0.55))
        p.addLine(to: CGPoint(x: 0, y: base - h * 1.15))
        p.addLine(to: CGPoint(x: w / 4, y: base - h * 0.55))
        p.addLine(to: CGPoint(x: w / 2, y: base - h))
        p.addLine(to: CGPoint(x: w / 2, y: base))
        p.closeSubpath()
        fs(c, p, Color(hex: 0xFFC83D))
        c.fill(rrect(-w / 2, base - h * 0.22, w, h * 0.22, 2), with: .color(Color(hex: 0xE59E1B)))
        let gems: [(CGFloat, UInt32)] = [(-w / 2, 0xE5484D), (0, 0x3B82F6), (w / 2, 0x10B981)]
        for g in gems {
            let gy: CGFloat = g.0 == 0 ? base - h * 1.15 : base - h
            c.fill(oval(g.0, gy, W * 0.017, W * 0.017), with: .color(Color(hex: g.1)))
        }
    }

    static func headphones(_ c: GraphicsContext, W: CGFloat, H: CGFloat, band: Color, cup: Color, ring: Color, big: CGFloat) {
        var p = Path()
        p.move(to: CGPoint(x: -W * 0.49, y: -H * 0.55))
        p.addQuadCurve(to: CGPoint(x: W * 0.49, y: -H * 0.55), control: CGPoint(x: 0, y: -H * 1.35))
        c.stroke(p, with: .color(band), style: StrokeStyle(lineWidth: W * 0.03 * big, lineCap: .round))
        for sx in [-1.0, 1.0] {
            let x = CGFloat(sx) * W * 0.5
            fs(c, oval(x, -H * 0.52, W * 0.065 * big, W * 0.095 * big), cup)
            c.stroke(oval(x, -H * 0.52, W * 0.04 * big, W * 0.065 * big), with: .color(ring), lineWidth: 2)
        }
    }

    static func wing(_ c: GraphicsContext, W: CGFloat, H: CGFloat, side: CGFloat, flap: CGFloat, fill: Color, bat: Bool) {
        var cc = c
        cc.translateBy(x: side * W * 0.42, y: -H * 0.55)
        cc.scaleBy(x: side, y: 1)
        cc.rotate(by: .radians(Double(-flap)))
        var p = Path()
        p.move(to: .zero)
        if bat {
            p.addQuadCurve(to: CGPoint(x: W * 0.62, y: -H * 0.42), control: CGPoint(x: W * 0.25, y: -H * 0.5))
            p.addQuadCurve(to: CGPoint(x: W * 0.48, y: -H * 0.12), control: CGPoint(x: W * 0.52, y: -H * 0.25))
            p.addQuadCurve(to: CGPoint(x: W * 0.34, y: H * 0.1), control: CGPoint(x: W * 0.4, y: -H * 0.02))
            p.addQuadCurve(to: CGPoint(x: W * 0.14, y: H * 0.18), control: CGPoint(x: W * 0.2, y: H * 0.08))
            p.addQuadCurve(to: .zero, control: CGPoint(x: W * 0.05, y: H * 0.1))
        } else {
            p.addQuadCurve(to: CGPoint(x: W * 0.6, y: -H * 0.5), control: CGPoint(x: W * 0.3, y: -H * 0.65))
            p.addQuadCurve(to: CGPoint(x: W * 0.4, y: H * 0.05), control: CGPoint(x: W * 0.7, y: -H * 0.1))
            p.addQuadCurve(to: .zero, control: CGPoint(x: W * 0.15, y: H * 0.1))
        }
        p.closeSubpath()
        fs(cc, p, fill)
    }

    static func draw(_ prop: Prop, _ c: GraphicsContext, W: CGFloat, H: CGFloat, t: CGFloat, tint: Color) {
        let top = -H * 0.94
        let ex = W * 0.19
        let ey = -H * 0.50
        switch prop {
        case .bobHat:
            fs(c, oval(0, top + H * 0.07, W * 0.40, W * 0.065), Color(hex: 0x3F78A8))
            var crown = Path()
            crown.move(to: CGPoint(x: -W * 0.25, y: top + H * 0.07))
            crown.addLine(to: CGPoint(x: -W * 0.21, y: top - H * 0.15))
            crown.addQuadCurve(to: CGPoint(x: W * 0.21, y: top - H * 0.15), control: CGPoint(x: 0, y: top - H * 0.24))
            crown.addLine(to: CGPoint(x: W * 0.25, y: top + H * 0.07))
            crown.closeSubpath()
            fs(c, crown, Color(hex: 0x69A2D4))
            c.fill(rrect(-W * 0.245, top - H * 0.01, W * 0.49, H * 0.05, 3), with: .color(.white.opacity(0.55)))
        case .beret:
            rotated(c, at: CGPoint(x: W * 0.03, y: top + H * 0.02), deg: -9) { g in
                fs(g, oval(0, 0, W * 0.30, H * 0.11), Color(hex: 0xC8403A))
                fs(g, oval(0, -H * 0.10, W * 0.028, H * 0.03), Color(hex: 0x9E2D29))
            }
        case .couronne:
            crown(c, W: W, H: H, top: top, scale: 0.85, velvet: false)
        case .couronneRoi:
            crown(c, W: W, H: H, top: top, scale: 1.15, velvet: true)
        case .chapeauPaille:
            fs(c, oval(0, top + H * 0.07, W * 0.47, W * 0.075), Color(hex: 0xF1D38A))
            var d = Path()
            d.move(to: CGPoint(x: -W * 0.24, y: top + H * 0.06))
            d.addQuadCurve(to: CGPoint(x: W * 0.24, y: top + H * 0.06), control: CGPoint(x: 0, y: top - H * 0.34))
            d.closeSubpath()
            fs(c, d, Color(hex: 0xF6E0A5))
            c.fill(rrect(-W * 0.235, top - H * 0.02, W * 0.47, H * 0.055, 3), with: .color(Color(hex: 0xD64045)))
        case .bandana:
            var b = Path()
            b.move(to: CGPoint(x: -W * 0.47, y: -H * 0.74))
            b.addQuadCurve(to: CGPoint(x: W * 0.47, y: -H * 0.74), control: CGPoint(x: 0, y: -H * 0.96))
            b.addLine(to: CGPoint(x: W * 0.45, y: -H * 0.62))
            b.addQuadCurve(to: CGPoint(x: -W * 0.45, y: -H * 0.62), control: CGPoint(x: 0, y: -H * 0.80))
            b.closeSubpath()
            fs(c, b, Color(hex: 0xD64045))
            for i in -3...3 {
                let x: CGFloat = CGFloat(i) * W * 0.12
                let y: CGFloat = -H * 0.76 + abs(x) * 0.18
                c.fill(oval(x, y, W * 0.014, W * 0.014), with: .color(.white.opacity(0.8)))
            }
            var k = Path()
            k.move(to: CGPoint(x: W * 0.45, y: -H * 0.68))
            k.addLine(to: CGPoint(x: W * 0.60, y: -H * 0.60))
            k.addLine(to: CGPoint(x: W * 0.55, y: -H * 0.72))
            k.closeSubpath()
            fs(c, k, Color(hex: 0xB9333A))
        case .hautDeForme:
            fs(c, oval(0, top + H * 0.06, W * 0.30, W * 0.05), Color(hex: 0x22202B))
            fs(c, rrect(-W * 0.19, top - H * 0.28, W * 0.38, H * 0.34, 5), Color(hex: 0x2B2838))
            c.fill(oval(0, top - H * 0.28, W * 0.19, W * 0.04), with: .color(Color(hex: 0x3A3650)))
            c.fill(rrect(-W * 0.19, top - H * 0.02, W * 0.38, H * 0.06, 2), with: .color(Color(hex: 0xC0392B)))
        case .halo:
            let bob: CGFloat = sin(t * 2) * H * 0.01
            c.fill(oval(0, top - H * 0.12 + bob, W * 0.24, W * 0.07), with: .color(Color(hex: 0xFFE27A, opacity: 0.25)))
            c.stroke(oval(0, top - H * 0.12 + bob, W * 0.20, W * 0.05), with: .color(Color(hex: 0xFFD34E)), lineWidth: W * 0.025)
        case .couronneFleurs:
            let cols: [UInt32] = [0xFF8FB1, 0xFFD166, 0xFFFFFF, 0xB794F4, 0xFF8FB1, 0xFFD166, 0xFFFFFF]
            for i in 0..<7 {
                let a: CGFloat = (CGFloat(i) - 3) * 0.33
                let x: CGFloat = W * 0.42 * sin(a)
                let y: CGFloat = -H * 0.55 - H * 0.40 * cos(a)
                c.fill(oval(x + W * 0.06 * cos(a), y + 2, W * 0.03, W * 0.012), with: .color(Color(hex: 0x4CAF6A)))
                for k in 0..<5 {
                    let pa: CGFloat = CGFloat(k) * 2 * .pi / 5
                    c.fill(oval(x + cos(pa) * W * 0.03, y + sin(pa) * W * 0.03, W * 0.026, W * 0.026), with: .color(Color(hex: cols[i])))
                }
                c.fill(oval(x, y, W * 0.016, W * 0.016), with: .color(Color(hex: 0xFFB020)))
            }
        case .lunettesCarrees:
            for sx in [-1.0, 1.0] {
                let x = CGFloat(sx) * ex
                c.fill(rrect(x - W * 0.105, ey - W * 0.085, W * 0.21, W * 0.17, 8), with: .color(.white.opacity(0.12)))
                c.stroke(rrect(x - W * 0.105, ey - W * 0.085, W * 0.21, W * 0.17, 8), with: .color(Color(hex: 0x2A2540)), lineWidth: W * 0.018)
            }
            line(c, [CGPoint(x: -ex + W * 0.105, y: ey - W * 0.02), CGPoint(x: ex - W * 0.105, y: ey - W * 0.02)], Color(hex: 0x2A2540), W * 0.015)
        case .monocle:
            let r = W * 0.115
            c.fill(oval(ex, ey, r, r), with: .color(.white.opacity(0.14)))
            c.stroke(oval(ex, ey, r, r), with: .color(Color(hex: 0xE0A82E)), lineWidth: W * 0.016)
            var ch = Path()
            ch.move(to: CGPoint(x: ex + r * 0.7, y: ey + r * 0.7))
            ch.addQuadCurve(to: CGPoint(x: W * 0.42, y: -H * 0.18), control: CGPoint(x: W * 0.5, y: -H * 0.38))
            c.stroke(ch, with: .color(Color(hex: 0xE0A82E)), lineWidth: 1.6)
        case .masqueSki:
            var p = Path()
            p.addPath(rrect(-W * 0.49, ey - W * 0.14, W * 0.98, W * 0.28, W * 0.06))
            p.addPath(oval(-ex, ey, W * 0.09, W * 0.10))
            p.addPath(oval(ex, ey, W * 0.09, W * 0.10))
            c.fill(p, with: .color(Color(hex: 0x2E2E42)), style: FillStyle(eoFill: true))
            for i in 0..<5 {
                let y: CGFloat = ey - W * 0.11 + CGFloat(i) * W * 0.055
                line(c, [CGPoint(x: -W * 0.47, y: y), CGPoint(x: -W * 0.28, y: y)], .white.opacity(0.12), 1.5)
                line(c, [CGPoint(x: W * 0.28, y: y), CGPoint(x: W * 0.47, y: y)], .white.opacity(0.12), 1.5)
            }
        case .lunettesCoeur:
            for sx in [-1.0, 1.0] {
                let x = CGFloat(sx) * ex
                let h = heart(x, ey, W * 0.24)
                c.fill(h, with: .color(Color(hex: 0xFF5C8A, opacity: 0.6)))
                c.stroke(h, with: .color(Color(hex: 0xE23C6C)), lineWidth: W * 0.012)
            }
            line(c, [CGPoint(x: -ex + W * 0.08, y: ey - W * 0.02), CGPoint(x: ex - W * 0.08, y: ey - W * 0.02)], Color(hex: 0xE23C6C), W * 0.012)
        case .lunettesSoleil:
            for sx in [-1.0, 1.0] {
                let x = CGFloat(sx) * ex
                let l = rrect(x - W * 0.115, ey - W * 0.075, W * 0.23, W * 0.15, W * 0.06)
                c.fill(l, with: .color(Color(hex: 0x12101F, opacity: 0.94)))
                line(c, [CGPoint(x: x - W * 0.06, y: ey - W * 0.04), CGPoint(x: x - W * 0.02, y: ey - W * 0.055)], .white.opacity(0.6), 2)
            }
            line(c, [CGPoint(x: -ex + W * 0.115, y: ey - W * 0.04), CGPoint(x: ex - W * 0.115, y: ey - W * 0.04)], Color(hex: 0x12101F), W * 0.016)
        case .boucles:
            for sx in [-1.0, 1.0] {
                let x = CGFloat(sx) * W * 0.485
                c.stroke(oval(x, -H * 0.42, W * 0.035, W * 0.035), with: .color(Color(hex: 0xFFC83D)), lineWidth: W * 0.012)
                c.fill(oval(x, -H * 0.42 + W * 0.045, W * 0.014, W * 0.014), with: .color(Color(hex: 0xE5484D)))
            }
        case .ecouteurs:
            headphones(c, W: W, H: H, band: Color(hex: 0x2B2A3D), cup: Color(hex: 0x3A3F5C), ring: Color(hex: 0xFF7A90), big: 1)
        case .cacheOreilles:
            var p = Path()
            p.move(to: CGPoint(x: -W * 0.49, y: -H * 0.55))
            p.addQuadCurve(to: CGPoint(x: W * 0.49, y: -H * 0.55), control: CGPoint(x: 0, y: -H * 1.30))
            c.stroke(p, with: .color(Color(hex: 0x6B5B95)), style: StrokeStyle(lineWidth: W * 0.022, lineCap: .round))
            for sx in [-1.0, 1.0] {
                let x = CGFloat(sx) * W * 0.5
                for k in 0..<7 {
                    let a: CGFloat = CGFloat(k) / 7 * 2 * .pi
                    c.fill(oval(x + cos(a) * W * 0.05, -H * 0.52 + sin(a) * W * 0.06, W * 0.045, W * 0.045), with: .color(Color(hex: 0xFF9EC0)))
                }
                c.fill(oval(x, -H * 0.52, W * 0.05, W * 0.06), with: .color(Color(hex: 0xFFB8D2)))
            }
        case .echarpe:
            var b = Path()
            b.move(to: CGPoint(x: -W * 0.46, y: -H * 0.27))
            b.addQuadCurve(to: CGPoint(x: W * 0.46, y: -H * 0.27), control: CGPoint(x: 0, y: -H * 0.13))
            b.addLine(to: CGPoint(x: W * 0.44, y: -H * 0.15))
            b.addQuadCurve(to: CGPoint(x: -W * 0.44, y: -H * 0.15), control: CGPoint(x: 0, y: -H * 0.01))
            b.closeSubpath()
            fs(c, b, Color(hex: 0xD64045))
            for i in -3...3 {
                let x: CGFloat = CGFloat(i) * W * 0.13
                line(c, [CGPoint(x: x, y: -H * 0.18), CGPoint(x: x, y: -H * 0.06)], .white.opacity(0.55), 3)
            }
            rotated(c, at: CGPoint(x: W * 0.28, y: -H * 0.10), deg: -8) { g in
                fs(g, rrect(0, 0, W * 0.14, H * 0.24, 4), Color(hex: 0xC0353B))
                g.fill(rrect(0, H * 0.07, W * 0.14, H * 0.03, 0), with: .color(.white.opacity(0.55)))
            }
        case .noeudPapillon:
            let y = -H * 0.20
            for sx in [-1.0, 1.0] {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: CGFloat(sx) * W * 0.14, y: y - H * 0.06))
                p.addLine(to: CGPoint(x: CGFloat(sx) * W * 0.14, y: y + H * 0.06))
                p.closeSubpath()
                fs(c, p, Color(hex: 0x2F4FD0))
            }
            fs(c, oval(0, y, W * 0.035, W * 0.04), Color(hex: 0x233AA0))
        case .collier:
            for i in 0...9 {
                let u: CGFloat = CGFloat(i) / 9
                let x: CGFloat = -W * 0.34 + u * W * 0.68
                let y: CGFloat = -H * 0.27 + H * 0.10 * sin(u * .pi)
                c.fill(oval(x, y, W * 0.016, W * 0.016), with: .color(Color(hex: 0xFFF3E0)))
                c.stroke(oval(x, y, W * 0.016, W * 0.016), with: .color(ink.opacity(0.2)), lineWidth: 0.6)
            }
            fs(c, heart(0, -H * 0.145, W * 0.07), Color(hex: 0xFF5C8A))
        case .bonnetNoel:
            var p = Path()
            p.move(to: CGPoint(x: -W * 0.33, y: top + H * 0.10))
            p.addQuadCurve(to: CGPoint(x: W * 0.24, y: top - H * 0.24), control: CGPoint(x: -W * 0.22, y: top - H * 0.12))
            p.addQuadCurve(to: CGPoint(x: W * 0.33, y: top + H * 0.10), control: CGPoint(x: W * 0.34, y: top - H * 0.12))
            p.closeSubpath()
            fs(c, p, Color(hex: 0xD62F2F))
            fs(c, rrect(-W * 0.38, top + H * 0.04, W * 0.76, H * 0.09, H * 0.045), .white)
            fs(c, oval(W * 0.25, top - H * 0.25, W * 0.06, W * 0.06), .white)
        case .bonnetLutin:
            var p = Path()
            p.move(to: CGPoint(x: -W * 0.30, y: top + H * 0.10))
            p.addQuadCurve(to: CGPoint(x: W * 0.36, y: top - H * 0.20), control: CGPoint(x: -W * 0.10, y: top - H * 0.26))
            p.addQuadCurve(to: CGPoint(x: W * 0.30, y: top + H * 0.10), control: CGPoint(x: W * 0.22, y: top - H * 0.05))
            p.closeSubpath()
            fs(c, p, Color(hex: 0x2E9E5B))
            fs(c, rrect(-W * 0.34, top + H * 0.05, W * 0.68, H * 0.07, H * 0.035), Color(hex: 0xD62F2F))
            fs(c, oval(W * 0.36, top - H * 0.18, W * 0.035, W * 0.035), Color(hex: 0xFFC83D))
        case .etoile:
            let s: CGFloat = sin(t * 1.4) * 0.12
            c.fill(oval(0, top - H * 0.12, W * 0.24, W * 0.24), with: .color(Color(hex: 0xFFE27A, opacity: 0.18)))
            rotated(c, at: CGPoint(x: 0, y: top - H * 0.12), deg: Double(s * 57)) { g in
                fs(g, star(0, 0, W * 0.16, W * 0.07), Color(hex: 0xFFD34E))
            }
        case .casque:
            var p = Path()
            p.move(to: CGPoint(x: -W * 0.50, y: -H * 0.60))
            p.addQuadCurve(to: CGPoint(x: W * 0.50, y: -H * 0.60), control: CGPoint(x: 0, y: -H * 1.52))
            p.closeSubpath()
            fs(c, p, Color(hex: 0xAEB7C4))
            c.fill(rrect(-W * 0.50, -H * 0.64, W * 1.0, H * 0.05, 2), with: .color(Color(hex: 0x7F8A99)))
            line(c, [CGPoint(x: 0, y: -H * 0.64), CGPoint(x: 0, y: top - H * 0.02)], Color(hex: 0x7F8A99), 3)
            line(c, [CGPoint(x: -W * 0.28, y: -H * 0.80), CGPoint(x: -W * 0.18, y: -H * 0.92)], .white.opacity(0.6), 4)
            var pl = Path()
            pl.move(to: CGPoint(x: 0, y: top))
            pl.addQuadCurve(to: CGPoint(x: W * 0.22, y: top - H * 0.20), control: CGPoint(x: W * 0.18, y: top - H * 0.02))
            pl.addQuadCurve(to: CGPoint(x: 0, y: top + H * 0.02), control: CGPoint(x: W * 0.04, y: top - H * 0.16))
            fs(c, pl, Color(hex: 0xD62F2F))
        case .chapeauBouffon:
            let sway: CGFloat = sin(t * 2) * W * 0.02
            for sx in [-1.0, 1.0] {
                let s = CGFloat(sx)
                var p = Path()
                p.move(to: CGPoint(x: 0, y: top + H * 0.08))
                p.addQuadCurve(to: CGPoint(x: s * W * 0.40 + sway, y: top - H * 0.16), control: CGPoint(x: s * W * 0.12, y: top - H * 0.16))
                p.addQuadCurve(to: CGPoint(x: s * W * 0.22, y: top + H * 0.10), control: CGPoint(x: s * W * 0.34, y: top - H * 0.02))
                p.closeSubpath()
                fs(c, p, s < 0 ? Color(hex: 0xE5484D) : Color(hex: 0xF2B705))
                fs(c, oval(s * W * 0.40 + sway, top - H * 0.16, W * 0.03, W * 0.03), Color(hex: 0xFFE27A))
            }
            fs(c, rrect(-W * 0.24, top + H * 0.05, W * 0.48, H * 0.06, H * 0.03), Color(hex: 0x6B3FC0))
        case .chapeauPirate:
            var p = Path()
            p.move(to: CGPoint(x: -W * 0.50, y: top + H * 0.14))
            p.addQuadCurve(to: CGPoint(x: W * 0.50, y: top + H * 0.14), control: CGPoint(x: 0, y: top - H * 0.40))
            p.addQuadCurve(to: CGPoint(x: -W * 0.50, y: top + H * 0.14), control: CGPoint(x: 0, y: top + H * 0.26))
            p.closeSubpath()
            fs(c, p, Color(hex: 0x1F1D2B))
            c.stroke(p, with: .color(Color(hex: 0xE0A82E)), lineWidth: 2)
            c.fill(oval(0, top - H * 0.04, W * 0.045, W * 0.045), with: .color(.white))
            line(c, [CGPoint(x: -W * 0.07, y: top + H * 0.02), CGPoint(x: W * 0.07, y: top - H * 0.08)], .white, 2.2)
            line(c, [CGPoint(x: W * 0.07, y: top + H * 0.02), CGPoint(x: -W * 0.07, y: top - H * 0.08)], .white, 2.2)
        case .cacheOeil:
            line(c, [CGPoint(x: -W * 0.47, y: -H * 0.68), CGPoint(x: ex, y: ey), CGPoint(x: W * 0.47, y: -H * 0.40)], Color(hex: 0x1B1530), W * 0.012)
            c.fill(oval(ex, ey, W * 0.095, W * 0.085), with: .color(Color(hex: 0x1B1530)))
        case .fleurSakura:
            let cx = W * 0.26
            let cy = top + H * 0.10
            for k in 0..<5 {
                let a: CGFloat = CGFloat(k) * 2 * .pi / 5 - .pi / 2
                let p = oval(cx + cos(a) * W * 0.06, cy + sin(a) * W * 0.06, W * 0.055, W * 0.04)
                fs(c, p, Color(hex: 0xFFC2D9), lw: 0.8)
            }
            c.fill(oval(cx, cy, W * 0.025, W * 0.025), with: .color(Color(hex: 0xE0568C)))
        case .queueCitrouille:
            var s = Path()
            s.move(to: CGPoint(x: 0, y: -H * 0.97))
            s.addQuadCurve(to: CGPoint(x: W * 0.05, y: -H * 1.10), control: CGPoint(x: -W * 0.02, y: -H * 1.04))
            c.stroke(s, with: .color(Color(hex: 0x4B8B3B)), style: StrokeStyle(lineWidth: W * 0.045, lineCap: .round))
            fs(c, oval(W * 0.11, -H * 1.0, W * 0.06, W * 0.03), Color(hex: 0x5FA84A), lw: 0.8)
        case .colVampire:
            for sx in [-1.0, 1.0] {
                let s = CGFloat(sx)
                var p = Path()
                p.move(to: CGPoint(x: s * W * 0.10, y: -H * 0.14))
                p.addLine(to: CGPoint(x: s * W * 0.34, y: -H * 0.46))
                p.addLine(to: CGPoint(x: s * W * 0.46, y: -H * 0.16))
                p.closeSubpath()
                fs(c, p, Color(hex: 0x4A1020))
            }
        case .crocs:
            for sx in [-1.0, 1.0] {
                var p = Path()
                let x = CGFloat(sx) * W * 0.04
                p.move(to: CGPoint(x: x - W * 0.014, y: -H * 0.345))
                p.addLine(to: CGPoint(x: x + W * 0.014, y: -H * 0.345))
                p.addLine(to: CGPoint(x: x, y: -H * 0.345 + W * 0.05))
                p.closeSubpath()
                c.fill(p, with: .color(.white))
            }
        case .bandeauNinja:
            let wave: CGFloat = sin(t * 4) * H * 0.02
            var tail = Path()
            tail.move(to: CGPoint(x: W * 0.46, y: -H * 0.70))
            tail.addQuadCurve(to: CGPoint(x: W * 0.80, y: -H * 0.62 + wave), control: CGPoint(x: W * 0.62, y: -H * 0.80))
            tail.addLine(to: CGPoint(x: W * 0.74, y: -H * 0.55 + wave))
            tail.addQuadCurve(to: CGPoint(x: W * 0.44, y: -H * 0.64), control: CGPoint(x: W * 0.6, y: -H * 0.62))
            tail.closeSubpath()
            fs(c, tail, Color(hex: 0xC62828))
            var b = Path()
            b.move(to: CGPoint(x: -W * 0.48, y: -H * 0.72))
            b.addQuadCurve(to: CGPoint(x: W * 0.48, y: -H * 0.72), control: CGPoint(x: 0, y: -H * 0.82))
            b.addLine(to: CGPoint(x: W * 0.47, y: -H * 0.63))
            b.addQuadCurve(to: CGPoint(x: -W * 0.47, y: -H * 0.63), control: CGPoint(x: 0, y: -H * 0.73))
            b.closeSubpath()
            fs(c, b, Color(hex: 0xC62828))
            fs(c, rrect(-W * 0.09, -H * 0.775, W * 0.18, H * 0.085, 3), Color(hex: 0xC9D1DC))
        case .scaphandre:
            c.fill(oval(0, -H * 0.57, W * 0.56, H * 0.50), with: .color(.white.opacity(0.07)))
            c.stroke(oval(0, -H * 0.57, W * 0.56, H * 0.50), with: .color(.white.opacity(0.5)), lineWidth: W * 0.018)
            var h = Path()
            h.addArc(center: CGPoint(x: 0, y: -H * 0.57), radius: W * 0.46, startAngle: .degrees(200), endAngle: .degrees(250), clockwise: false)
            c.stroke(h, with: .color(.white.opacity(0.55)), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            fs(c, rrect(-W * 0.5, -H * 0.17, W * 1.0, H * 0.075, H * 0.03), Color(hex: 0xB8C0CC))
            line(c, [CGPoint(x: W * 0.3, y: top - H * 0.04), CGPoint(x: W * 0.34, y: top - H * 0.16)], Color(hex: 0xB8C0CC), 2)
            let on: Double = sin(Double(t) * 4) > 0 ? 1 : 0.35
            c.fill(oval(W * 0.34, top - H * 0.17, W * 0.02, W * 0.02), with: .color(Color(hex: 0xFF4D4D, opacity: on)))
        case .antennesMiel:
            for sx in [-1.0, 1.0] {
                let s = CGFloat(sx)
                let bounce: CGFloat = sin(t * 3 + s) * W * 0.015
                var p = Path()
                p.move(to: CGPoint(x: s * W * 0.10, y: top + H * 0.02))
                p.addQuadCurve(to: CGPoint(x: s * W * 0.22 + bounce, y: top - H * 0.20), control: CGPoint(x: s * W * 0.10, y: top - H * 0.14))
                c.stroke(p, with: .color(Color(hex: 0x3A2A00)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                c.fill(oval(s * W * 0.22 + bounce, top - H * 0.21, W * 0.03, W * 0.03), with: .color(Color(hex: 0xFFC83D)))
            }
        case .bonnetNuit:
            var p = Path()
            p.move(to: CGPoint(x: -W * 0.30, y: top + H * 0.10))
            p.addQuadCurve(to: CGPoint(x: W * 0.52, y: top + H * 0.02), control: CGPoint(x: -W * 0.05, y: top - H * 0.40))
            p.addQuadCurve(to: CGPoint(x: W * 0.30, y: top + H * 0.10), control: CGPoint(x: W * 0.36, y: top - H * 0.10))
            p.closeSubpath()
            fs(c, p, Color(hex: 0x4A6FD1))
            fs(c, rrect(-W * 0.34, top + H * 0.05, W * 0.68, H * 0.07, H * 0.035), .white.opacity(0.95))
            fs(c, oval(W * 0.53, top + H * 0.03, W * 0.05, W * 0.05), .white)
        case .cicatrices:
            line(c, [CGPoint(x: -W * 0.20, y: -H * 0.80), CGPoint(x: W * 0.15, y: -H * 0.73)], Color(hex: 0x4A3A5A), 2.4)
            for i in 0..<4 {
                let x: CGFloat = -W * 0.14 + CGFloat(i) * W * 0.08
                let y: CGFloat = -H * 0.79 + CGFloat(i) * H * 0.018
                line(c, [CGPoint(x: x, y: y - 5), CGPoint(x: x, y: y + 5)], Color(hex: 0x4A3A5A), 2)
            }
            for sx in [-1.0, 1.0] {
                c.fill(oval(CGFloat(sx) * ex, ey + W * 0.09, W * 0.07, W * 0.025), with: .color(Color(hex: 0x6A3F8A, opacity: 0.35)))
            }
        case .cornes:
            for sx in [-1.0, 1.0] {
                let s = CGFloat(sx)
                var p = Path()
                p.move(to: CGPoint(x: s * W * 0.14, y: top + H * 0.05))
                p.addQuadCurve(to: CGPoint(x: s * W * 0.34, y: top - H * 0.20), control: CGPoint(x: s * W * 0.14, y: top - H * 0.16))
                p.addQuadCurve(to: CGPoint(x: s * W * 0.24, y: top + H * 0.06), control: CGPoint(x: s * W * 0.28, y: top - H * 0.06))
                p.closeSubpath()
                fs(c, p, Color(hex: 0xF1E5C8))
            }
        case .ailesDragon:
            let f: CGFloat = sin(t * 3) * 0.12
            wing(c, W: W, H: H, side: -1, flap: f, fill: tint.opacity(0.85), bat: true)
            wing(c, W: W, H: H, side: 1, flap: f, fill: tint.opacity(0.85), bat: true)
        case .coquillages:
            let xs: [CGFloat] = [-W * 0.22, 0, W * 0.22]
            for (i, x) in xs.enumerated() {
                let r: CGFloat = i == 1 ? W * 0.12 : W * 0.085
                let cy: CGFloat = top + H * 0.06
                var p = Path()
                p.move(to: CGPoint(x: x, y: cy))
                p.addArc(center: CGPoint(x: x, y: cy), radius: r, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
                p.closeSubpath()
                fs(c, p, Color(hex: i == 1 ? 0xFFC2D9 : 0xFFD9B8))
                for k in 1..<4 {
                    let a: CGFloat = .pi + CGFloat(k) * .pi / 4
                    line(c, [CGPoint(x: x, y: cy), CGPoint(x: x + cos(a) * r, y: cy + sin(a) * r)], ink.opacity(0.18), 1)
                }
            }
            c.fill(oval(0, top + H * 0.075, W * 0.022, W * 0.022), with: .color(.white))
        case .masqueHeros:
            var p = Path()
            p.move(to: CGPoint(x: -W * 0.50, y: ey - W * 0.05))
            p.addLine(to: CGPoint(x: -W * 0.30, y: ey - W * 0.15))
            p.addLine(to: CGPoint(x: W * 0.30, y: ey - W * 0.15))
            p.addLine(to: CGPoint(x: W * 0.50, y: ey - W * 0.05))
            p.addLine(to: CGPoint(x: W * 0.46, y: ey + W * 0.12))
            p.addLine(to: CGPoint(x: -W * 0.46, y: ey + W * 0.12))
            p.closeSubpath()
            p.addPath(oval(-ex, ey, W * 0.085, W * 0.10))
            p.addPath(oval(ex, ey, W * 0.085, W * 0.10))
            c.fill(p, with: .color(Color(hex: 0x1F2A5C)), style: FillStyle(eoFill: true))
            c.stroke(p, with: .color(Color(hex: 0xFFC83D)), lineWidth: 1.4)
        case .cape:
            let fl: CGFloat = sin(t * 2.4) * W * 0.03
            var p = Path()
            p.move(to: CGPoint(x: -W * 0.36, y: -H * 0.30))
            p.addQuadCurve(to: CGPoint(x: -W * 0.66 - fl, y: H * 0.02), control: CGPoint(x: -W * 0.62, y: -H * 0.18))
            p.addQuadCurve(to: CGPoint(x: 0, y: H * 0.04), control: CGPoint(x: -W * 0.3, y: H * 0.10))
            p.addQuadCurve(to: CGPoint(x: W * 0.66 + fl, y: H * 0.02), control: CGPoint(x: W * 0.3, y: H * 0.10))
            p.addQuadCurve(to: CGPoint(x: W * 0.36, y: -H * 0.30), control: CGPoint(x: W * 0.62, y: -H * 0.18))
            p.closeSubpath()
            fs(c, p, Color(hex: 0xD62839))
        case .kabuto:
            var p = Path()
            p.move(to: CGPoint(x: -W * 0.50, y: -H * 0.62))
            p.addQuadCurve(to: CGPoint(x: W * 0.50, y: -H * 0.62), control: CGPoint(x: 0, y: -H * 1.50))
            p.closeSubpath()
            fs(c, p, Color(hex: 0x8E1B1B))
            c.fill(rrect(-W * 0.50, -H * 0.66, W, H * 0.05, 2), with: .color(Color(hex: 0xE0A82E)))
            for sx in [-1.0, 1.0] {
                let s = CGFloat(sx)
                fs(c, rrect(s > 0 ? W * 0.44 : -W * 0.56, -H * 0.64, W * 0.12, H * 0.28, 4), Color(hex: 0x6E1414))
                var h = Path()
                h.move(to: CGPoint(x: s * W * 0.04, y: top + H * 0.06))
                h.addQuadCurve(to: CGPoint(x: s * W * 0.34, y: top - H * 0.24), control: CGPoint(x: s * W * 0.10, y: top - H * 0.14))
                c.stroke(h, with: .color(Color(hex: 0xFFC83D)), style: StrokeStyle(lineWidth: W * 0.03, lineCap: .round))
            }
        case .casqueDJ:
            headphones(c, W: W, H: H, band: Color(hex: 0x15131F), cup: Color(hex: 0x23202F), ring: Color(hex: 0x4DF0FF), big: 1.45)
        case .antennesAlien:
            for sx in [-1.0, 1.0] {
                let s = CGFloat(sx)
                let pulse: CGFloat = 1 + sin(t * 4 + s) * 0.15
                var p = Path()
                p.move(to: CGPoint(x: s * W * 0.12, y: top + H * 0.03))
                p.addQuadCurve(to: CGPoint(x: s * W * 0.26, y: top - H * 0.24), control: CGPoint(x: s * W * 0.10, y: top - H * 0.16))
                c.stroke(p, with: .color(Color(hex: 0x2A2540)), style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
                c.fill(oval(s * W * 0.26, top - H * 0.25, W * 0.06 * pulse, W * 0.06 * pulse), with: .color(Color(hex: 0x7CFFB2, opacity: 0.3)))
                c.fill(oval(s * W * 0.26, top - H * 0.25, W * 0.035, W * 0.035), with: .color(Color(hex: 0x7CFFB2)))
            }
        case .casquetteDetective:
            var p = Path()
            p.move(to: CGPoint(x: -W * 0.30, y: top + H * 0.09))
            p.addQuadCurve(to: CGPoint(x: W * 0.30, y: top + H * 0.09), control: CGPoint(x: 0, y: top - H * 0.34))
            p.closeSubpath()
            fs(c, p, Color(hex: 0xA68A64))
            for i in -2...2 {
                let x: CGFloat = CGFloat(i) * W * 0.09
                line(c, [CGPoint(x: x, y: top + H * 0.08), CGPoint(x: x * 0.9, y: top - H * 0.12)], Color(hex: 0x7A603C, opacity: 0.6), 1.2)
            }
            for sx in [-1.0, 1.0] {
                let s = CGFloat(sx)
                var v = Path()
                v.move(to: CGPoint(x: s * W * 0.26, y: top + H * 0.09))
                v.addLine(to: CGPoint(x: s * W * 0.46, y: top + H * 0.13))
                v.addLine(to: CGPoint(x: s * W * 0.30, y: top + H * 0.04))
                v.closeSubpath()
                fs(c, v, Color(hex: 0x7A603C))
            }
            fs(c, oval(0, top - H * 0.05, W * 0.03, W * 0.025), Color(hex: 0x7A603C))
        case .perruqueClown:
            let cols: [UInt32] = [0xFF5C5C, 0xFFA23C, 0x4DA3FF, 0xFF5C5C, 0xFFA23C, 0x4DA3FF]
            let pts: [(CGFloat, CGFloat)] = [(-0.42, -0.80), (-0.52, -0.62), (-0.36, -0.93), (0.42, -0.80), (0.52, -0.62), (0.36, -0.93)]
            for (i, q) in pts.enumerated() {
                fs(c, oval(q.0 * W, q.1 * H, W * 0.11, W * 0.11), Color(hex: cols[i]), lw: 0.8)
            }
        case .nezClown:
            fs(c, oval(0, -H * 0.43, W * 0.055, W * 0.055), Color(hex: 0xE5303A))
            c.fill(oval(-W * 0.018, -H * 0.445, W * 0.014, W * 0.014), with: .color(.white.opacity(0.8)))
        case .bandeauBoxeur:
            var b = Path()
            b.move(to: CGPoint(x: -W * 0.48, y: -H * 0.72))
            b.addQuadCurve(to: CGPoint(x: W * 0.48, y: -H * 0.72), control: CGPoint(x: 0, y: -H * 0.84))
            b.addLine(to: CGPoint(x: W * 0.47, y: -H * 0.64))
            b.addQuadCurve(to: CGPoint(x: -W * 0.47, y: -H * 0.64), control: CGPoint(x: 0, y: -H * 0.76))
            b.closeSubpath()
            fs(c, b, Color(hex: 0xE5303A))
            c.fill(star(0, -H * 0.745, W * 0.04, W * 0.018), with: .color(Color(hex: 0xFFD34E)))
            for sx in [-1.0, 1.0] {
                let x = CGFloat(sx) * W * 0.53
                fs(c, oval(x, -H * 0.12, W * 0.09, W * 0.085), Color(hex: 0xE5303A))
                c.fill(rrect(x - W * 0.07, -H * 0.04, W * 0.14, H * 0.045, 3), with: .color(.white))
            }
        case .ailesCupidon:
            let f: CGFloat = sin(t * 3) * 0.10
            wing(c, W: W, H: H, side: -1, flap: f, fill: .white, bat: false)
            wing(c, W: W, H: H, side: 1, flap: f, fill: .white, bat: false)
        case .casqueGladiateur:
            var p = Path()
            p.move(to: CGPoint(x: -W * 0.50, y: -H * 0.60))
            p.addQuadCurve(to: CGPoint(x: W * 0.50, y: -H * 0.60), control: CGPoint(x: 0, y: -H * 1.50))
            p.closeSubpath()
            fs(c, p, Color(hex: 0xC9A04A))
            c.fill(rrect(-W * 0.50, -H * 0.64, W, H * 0.05, 2), with: .color(Color(hex: 0x9C7A2E)))
            for i in -5...5 {
                let x: CGFloat = CGFloat(i) * W * 0.07
                let h: CGFloat = H * (0.20 - abs(CGFloat(i)) * 0.018)
                line(c, [CGPoint(x: x * 0.9, y: top + H * 0.02), CGPoint(x: x * 1.1, y: top - h)], Color(hex: 0xD62F2F), W * 0.05)
            }
        case .corneLicorne:
            var p = Path()
            p.move(to: CGPoint(x: -W * 0.06, y: top + H * 0.06))
            p.addLine(to: CGPoint(x: 0, y: top - H * 0.28))
            p.addLine(to: CGPoint(x: W * 0.06, y: top + H * 0.06))
            p.closeSubpath()
            fs(c, p, Color(hex: 0xFFE9A8))
            for i in 0..<4 {
                let y: CGFloat = top + H * 0.02 - CGFloat(i) * H * 0.07
                let hw: CGFloat = W * 0.05 * (1 - CGFloat(i) * 0.22)
                line(c, [CGPoint(x: -hw, y: y), CGPoint(x: hw, y: y - H * 0.025)], Color(hex: 0xE0A82E, opacity: 0.8), 1.6)
            }
            for sx in [-1.0, 1.0] {
                let s = CGFloat(sx)
                var e = Path()
                e.move(to: CGPoint(x: s * W * 0.16, y: top + H * 0.06))
                e.addLine(to: CGPoint(x: s * W * 0.24, y: top - H * 0.10))
                e.addLine(to: CGPoint(x: s * W * 0.30, y: top + H * 0.08))
                e.closeSubpath()
                fs(c, e, Color(hex: 0xFFC2E0))
            }
        }
    }
}
