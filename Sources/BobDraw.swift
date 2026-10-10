import SwiftUI

typealias F = CGFloat
private let pupilC = Color(hex: 0x161A26)

private func P(_ x: F, _ y: F) -> CGPoint { CGPoint(x: x, y: y) }
private func R(_ x: F, _ y: F, _ w: F, _ h: F) -> CGRect { CGRect(x: x, y: y, width: w, height: h) }
private func oval(_ x: F, _ y: F, _ w: F, _ h: F) -> Path { Path(ellipseIn: R(x, y, w, h)) }
private func circ(_ cx: F, _ cy: F, _ r: F) -> Path { Path(ellipseIn: R(cx - r, cy - r, 2 * r, 2 * r)) }
private func rectP(_ x: F, _ y: F, _ w: F, _ h: F) -> Path { Path(R(x, y, w, h)) }
private func lineP(_ a: CGPoint, _ b: CGPoint) -> Path { var p = Path(); p.move(to: a); p.addLine(to: b); return p }

private func arcP(_ cx: F, _ cy: F, _ rx: F, _ ry: F, _ start: F, _ sweep: F) -> Path {
    var p = Path()
    let n = 28
    for i in 0...n {
        let a = (start + sweep * F(i) / F(n)) * .pi / 180
        let pt = P(cx + rx * cos(a), cy + ry * sin(a))
        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
    }
    return p
}

private func heartP(_ cx: F, _ cy: F, _ s: F) -> Path {
    var p = Path()
    p.move(to: P(cx, cy + s * 0.9))
    p.addCurve(to: P(cx, cy - s * 0.45), control1: P(cx - s * 1.5, cy - s * 0.1), control2: P(cx - s * 0.7, cy - s * 1.2))
    p.addCurve(to: P(cx, cy + s * 0.9), control1: P(cx + s * 0.7, cy - s * 1.2), control2: P(cx + s * 1.5, cy - s * 0.1))
    p.closeSubpath()
    return p
}

private func starP(_ cx: F, _ cy: F, _ r: F) -> Path {
    var p = Path()
    for i in 0..<8 {
        let a = (F(i) * 45 - 90) * .pi / 180
        let rr: F = i % 2 == 0 ? r : r * 0.38
        let pt = P(cx + cos(a) * rr, cy + sin(a) * rr)
        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
    }
    p.closeSubpath()
    return p
}

extension GraphicsContext {
    func fillC(_ p: Path, _ c: Color) { fill(p, with: .color(c)) }
    func strokeC(_ p: Path, _ c: Color, _ w: F, cap: CGLineCap = .round, join: CGLineJoin = .round) {
        stroke(p, with: .color(c), style: StrokeStyle(lineWidth: w, lineCap: cap, lineJoin: join))
    }
    func rot(_ deg: F, _ px: F, _ py: F, _ body: (inout GraphicsContext) -> Void) {
        drawLayer { l in
            l.translateBy(x: px, y: py)
            l.rotate(by: .degrees(Double(deg)))
            l.translateBy(x: -px, y: -py)
            body(&l)
        }
    }
}

func drawBob(_ ctx: inout GraphicsContext, size: CGSize, skin: Skin, accs: Set<Acc>, mood: Mood, sim: Sim) {
    let u: F = min(size.width, size.height * 0.82)
    let cx: F = size.width / 2
    let ground: F = size.height * 0.88
    let s: F = sim.squash - min(sim.jump, 0.6) * 0.18 + sin(sim.t * 2.2) * 0.012
    let w: F = u * 0.62 * (1 + s)
    let h: F = u * 0.54 * (1 - s * 0.9)
    let bottom: F = ground - sim.jump * u * 0.5
    let top: F = bottom - h
    let left: F = cx - w / 2
    let right: F = cx + w / 2

    // ombre
    let sh: F = 1 - min(sim.jump, 0.8) * 0.35
    ctx.fillC(oval(cx - w * 0.46 * sh, ground - u * 0.02, w * 0.92 * sh, u * 0.05), Color.black.opacity(Double(0.28 * sh)))

    // corps
    var body = Path()
    body.move(to: P(cx, top))
    body.addCurve(to: P(right, top + h * 0.62), control1: P(cx + w * 0.32, top), control2: P(right, top + h * 0.22))
    body.addCurve(to: P(right - w * 0.28, bottom), control1: P(right, bottom - h * 0.04), control2: P(right - w * 0.10, bottom))
    body.addQuadCurve(to: P(left + w * 0.28, bottom), control: P(cx, bottom + h * 0.025))
    body.addCurve(to: P(left, top + h * 0.62), control1: P(left + w * 0.10, bottom), control2: P(left, bottom - h * 0.04))
    body.addCurve(to: P(cx, top), control1: P(left, top + h * 0.22), control2: P(cx - w * 0.32, top))
    body.closeSubpath()
    ctx.fill(body, with: .linearGradient(Gradient(colors: [skin.light, skin.base, skin.dark]),
                                         startPoint: P(cx, top), endPoint: P(cx, bottom)))

    let pc = skin.patternColor
    ctx.drawLayer { l in
        l.clip(to: body)
        l.fill(rectP(left - 10, top - 10, w + 20, h + 20),
               with: .radialGradient(Gradient(colors: [Color.white.opacity(0.28), Color.white.opacity(0)]),
                                     center: P(cx, bottom - h * 0.32), startRadius: 0, endRadius: w * 0.55))
        switch skin.pattern {
        case .stars:
            let pts: [(F, F)] = [(0.22, 0.28), (0.78, 0.30), (0.14, 0.62), (0.86, 0.64), (0.34, 0.86), (0.68, 0.88), (0.50, 0.14)]
            for (i, pt) in pts.enumerated() {
                let r: F = u * (0.022 + 0.006 * F(i % 3))
                l.fillC(starP(left + w * pt.0, top + h * pt.1, r), pc.opacity(0.85))
            }
        case .polka:
            let pts: [(F, F)] = [(0.2, 0.3), (0.8, 0.32), (0.5, 0.16), (0.12, 0.66), (0.88, 0.66), (0.32, 0.88), (0.7, 0.9)]
            for pt in pts { l.fillC(circ(left + w * pt.0, top + h * pt.1, u * 0.024), pc.opacity(0.5)) }
        case .stripes:
            for fy: F in [0.08, 0.76, 0.90] {
                l.fillC(rectP(left - 2, top + h * fy, w + 4, h * 0.075), pc.opacity(0.9))
            }
        case .scales:
            let r: F = w * 0.1
            for row in 0...7 {
                for col in -1...5 {
                    let x: F = left + F(col) * r * 2 + F(row % 2) * r
                    let y: F = top + h * 0.06 + F(row) * r * 1.15
                    l.strokeC(arcP(x, y, r, r, 0, 180), pc.opacity(0.4), u * 0.007, cap: .butt)
                }
            }
        case .none: break
        }
        switch skin.decor {
        case .hood:
            var hood = Path()
            hood.move(to: P(left - 4, top - 4))
            hood.addLine(to: P(right + 4, top - 4))
            hood.addLine(to: P(right + 4, top + h * 0.30))
            hood.addQuadCurve(to: P(left - 4, top + h * 0.30), control: P(cx, top + h * 0.54))
            hood.closeSubpath()
            l.fillC(hood, skin.decorColor)
            var trim = Path()
            trim.move(to: P(right + 4, top + h * 0.30))
            trim.addQuadCurve(to: P(left - 4, top + h * 0.30), control: P(cx, top + h * 0.54))
            l.strokeC(trim, Color(hex: 0xFFD35A), u * 0.012)
        case .ninja:
            l.fillC(rectP(left - 4, top + h * 0.38, w + 8, h * 0.27), skin.decorColor)
            l.fillC(rectP(left - 4, top + h * 0.38, w + 8, h * 0.03), Color.white.opacity(0.12))
        case .none: break
        }
    }
    ctx.strokeC(body, Color.black.opacity(0.22), u * 0.01)
    ctx.rot(-28, left + w * 0.27, top + h * 0.2) { g in
        g.fillC(oval(left + w * 0.15, top + h * 0.13, w * 0.2, h * 0.1), Color.white.opacity(0.38))
    }
    ctx.fillC(circ(left + w * 0.36, top + h * 0.12, u * 0.01), Color.white.opacity(0.5))

    // visage
    let fdx: F = sim.lookX * w * 0.04
    let fdy: F = sim.lookY * h * 0.03
    let eyeY: F = top + h * 0.54 + fdy
    let ex: F = w * 0.17
    let ink = skin.ink
    let eyeInk: Color = skin.decor == .ninja ? Color.white : pupilC
    let happyNow = sim.happyTimer > 0
    let cheekA: Double = (happyNow || mood == .love) ? 0.85 : 0.55
    for sg: F in [-1, 1] {
        let ccx: F = cx + fdx + sg * ex * 1.62 - w * 0.055
        ctx.fillC(oval(ccx, eyeY + h * 0.11, w * 0.11, h * 0.06), skin.cheek.opacity(cheekA))
    }
    for sg: F in [-1, 1] {
        let ecx: F = cx + fdx + sg * ex
        let sw: F = u * 0.062 * (mood == .surprised ? 1.2 : 1)
        let shh: F = u * 0.085 * (mood == .surprised ? 1.15 : (mood == .focus ? 0.8 : 1))
        if happyNow && mood != .love {
            ctx.strokeC(arcP(ecx, eyeY + sw * 0.1, sw * 0.6, sw * 0.6, 200, 140), eyeInk, u * 0.018)
        } else if mood == .sleepy {
            ctx.strokeC(arcP(ecx, eyeY - sw * 0.1, sw * 0.6, sw * 0.6, 20, 140), eyeInk, u * 0.018)
        } else if mood == .love {
            let hs: F = u * 0.034 * (1 + 0.08 * sin(sim.t * 7))
            ctx.fillC(heartP(ecx, eyeY, hs), Color(hex: 0xFF4D7A))
            ctx.fillC(circ(ecx - hs * 0.55, eyeY - hs * 0.5, hs * 0.18), Color.white.opacity(0.8))
        } else {
            let oh: F = max(shh * sim.eyeOpen, u * 0.012)
            ctx.fillC(oval(ecx - sw / 2, eyeY - oh / 2, sw, oh), Color.white)
            let pr: F = sw * (mood == .surprised ? 0.24 : 0.33)
            let px: F = ecx + sim.lookX * sw * 0.2
            let py: F = eyeY + sim.lookY * shh * 0.18
            let ph: F = max(pr * 2 * sim.eyeOpen, u * 0.008)
            ctx.fillC(oval(px - pr, py - ph / 2, pr * 2, ph), pupilC)
            if sim.eyeOpen > 0.6 { ctx.fillC(circ(px - pr * 0.35, py - ph * 0.3, pr * 0.32), Color.white) }
            if mood == .focus {
                ctx.strokeC(lineP(P(ecx - sg * sw * 0.55, eyeY - shh * 0.72), P(ecx + sg * sw * 0.55, eyeY - shh * 0.98)), eyeInk, u * 0.014)
            }
        }
    }
    let mx: F = cx + fdx
    let my: F = eyeY + h * 0.2
    let mw: F = w * 0.09
    if happyNow || mood == .love {
        var mouth = Path()
        mouth.move(to: P(mx - mw * 1.15, my))
        mouth.addQuadCurve(to: P(mx + mw * 1.15, my), control: P(mx, my + h * 0.24))
        mouth.closeSubpath()
        ctx.fillC(mouth, ink)
        ctx.drawLayer { l in
            l.clip(to: mouth)
            l.fillC(oval(mx - mw * 0.5, my + h * 0.10, mw, h * 0.1), Color(hex: 0xFF7A9C))
        }
    } else if mood == .sleepy {
        ctx.fillC(oval(mx - mw * 0.4, my, mw * 0.8, h * (0.05 + 0.02 * sin(sim.t * 2))), ink)
    } else if mood == .surprised {
        ctx.fillC(oval(mx - mw * 0.4, my - h * 0.01, mw * 0.8, h * 0.12), ink)
    } else if mood == .focus {
        ctx.strokeC(lineP(P(mx - mw * 0.7, my + h * 0.02), P(mx + mw * 0.7, my + h * 0.02)), ink, u * 0.016)
    } else {
        var p = Path()
        p.move(to: P(mx - mw, my))
        p.addQuadCurve(to: P(mx + mw, my), control: P(mx, my + h * 0.14))
        ctx.strokeC(p, ink, u * 0.016)
    }

    // accessoires
    if accs.contains(.headphones) {
        let band = Color(hex: 0x2F3447)
        ctx.strokeC(arcP(cx, top + h * 0.43, w * 0.535, h * 0.5, 185, 170), band, u * 0.024)
        for sg: F in [-1, 1] {
            let ccx: F = cx + sg * w * 0.505
            ctx.fillC(Path(roundedRect: R(ccx - w * 0.055, top + h * 0.40, w * 0.11, h * 0.26), cornerRadius: w * 0.05), band)
            ctx.fillC(Path(roundedRect: R(ccx - w * 0.025, top + h * 0.44, w * 0.05, h * 0.18), cornerRadius: w * 0.025), Color(hex: 0x6C7BFF))
        }
    }
    if accs.contains(.glasses) {
        let lr: F = u * 0.058
        let rim = Color(hex: 0x1E2233)
        for sg: F in [-1, 1] {
            let ecx: F = cx + fdx + sg * ex
            ctx.fillC(circ(ecx, eyeY, lr), Color.white.opacity(0.14))
            ctx.strokeC(circ(ecx, eyeY, lr), rim, u * 0.013)
            ctx.strokeC(arcP(ecx, eyeY, lr * 0.7, lr * 0.7, 215, 40), Color.white.opacity(0.55), u * 0.008)
        }
        ctx.strokeC(lineP(P(cx + fdx - ex + lr, eyeY), P(cx + fdx + ex - lr, eyeY)), rim, u * 0.012, cap: .butt)
    }
    if accs.contains(.bobHat) {
        let hy: F = top + h * 0.13
        ctx.rot(-6, cx, hy) { g in
            var crown = Path()
            crown.move(to: P(cx - w * 0.27, hy))
            crown.addCurve(to: P(cx + w * 0.27, hy), control1: P(cx - w * 0.30, hy - h * 0.34), control2: P(cx + w * 0.30, hy - h * 0.34))
            crown.closeSubpath()
            g.fill(crown, with: .linearGradient(Gradient(colors: [Color(hex: 0x5B8FD6), Color(hex: 0x3A66AE)]),
                                                startPoint: P(cx, hy - h * 0.26), endPoint: P(cx, hy)))
            g.drawLayer { l in
                l.clip(to: crown)
                l.fillC(rectP(cx - w * 0.3, hy - h * 0.085, w * 0.6, h * 0.04), Color(hex: 0xF2F4FA))
            }
            g.fillC(oval(cx - w * 0.46, hy - h * 0.05, w * 0.92, h * 0.12), Color(hex: 0x2F5A94))
            g.fillC(oval(cx - w * 0.40, hy - h * 0.045, w * 0.8, h * 0.05), Color.white.opacity(0.18))
        }
    }
    if accs.contains(.crown) {
        let by: F = top + h * 0.11
        ctx.rot(5, cx, by) { g in
            var cp = Path()
            cp.move(to: P(cx - w * 0.24, by))
            cp.addLine(to: P(cx - w * 0.28, by - h * 0.25))
            cp.addLine(to: P(cx - w * 0.13, by - h * 0.12))
            cp.addLine(to: P(cx, by - h * 0.30))
            cp.addLine(to: P(cx + w * 0.13, by - h * 0.12))
            cp.addLine(to: P(cx + w * 0.28, by - h * 0.25))
            cp.addLine(to: P(cx + w * 0.24, by))
            cp.closeSubpath()
            g.fill(cp, with: .linearGradient(Gradient(colors: [Color(hex: 0xFFE27A), Color(hex: 0xE3A82B)]),
                                             startPoint: P(cx, by - h * 0.3), endPoint: P(cx, by)))
            g.strokeC(cp, Color(hex: 0xB7791F), u * 0.008)
            g.fillC(rectP(cx - w * 0.245, by - h * 0.045, w * 0.49, h * 0.045), Color(hex: 0xB7791F).opacity(0.35))
            let gems: [(F, F)] = [(cx - w * 0.28, by - h * 0.25), (cx, by - h * 0.30), (cx + w * 0.28, by - h * 0.25)]
            for gm in gems { g.fillC(circ(gm.0, gm.1, u * 0.013), Color(hex: 0xFF4D6D)) }
            g.fillC(circ(cx, by - h * 0.02, u * 0.011), Color(hex: 0x4DD0E1))
        }
    }
    if accs.contains(.beret) {
        ctx.rot(-12, cx, top + h * 0.08) { g in
            g.fillC(oval(cx - w * 0.34, top - h * 0.1, w * 0.68, h * 0.24), Color(hex: 0xD9423C))
            g.fillC(oval(cx - w * 0.26, top - h * 0.085, w * 0.3, h * 0.07), Color.white.opacity(0.2))
            g.fillC(circ(cx + w * 0.02, top - h * 0.1, u * 0.013), Color(hex: 0x8E2220))
        }
    }
    if accs.contains(.bowtie) {
        let y: F = bottom - h * 0.14
        for sg: F in [-1, 1] {
            var p = Path()
            p.move(to: P(cx, y))
            p.addLine(to: P(cx + sg * w * 0.17, y - h * 0.07))
            p.addLine(to: P(cx + sg * w * 0.17, y + h * 0.07))
            p.closeSubpath()
            ctx.fillC(p, Color(hex: 0xE5484D))
            ctx.strokeC(p, Color.black.opacity(0.18), u * 0.006)
        }
        ctx.fillC(Path(roundedRect: R(cx - w * 0.03, y - h * 0.045, w * 0.06, h * 0.09), cornerRadius: w * 0.02), Color(hex: 0xB8323A))
    }

    // coeurs et Zzz
    for hr in sim.hearts {
        let age: F = sim.t - hr.born
        let p: F = age / 1.5
        let a: Double = Double(min(max(1 - p, 0), 1))
        let sz: F = u * 0.05 * hr.s * (0.7 + 0.3 * min(1, age * 5))
        let hx: F = cx + hr.dx * u + sin(age * 6) * u * 0.02
        let hy: F = top - u * 0.02 - p * u * 0.28
        ctx.fillC(heartP(hx, hy, sz), Color(hex: 0xFF5C8A).opacity(a))
    }
    if mood == .sleepy {
        for k in 0..<2 {
            var ph: F = sim.t * 0.5 + F(k) * 0.5
            ph = ph - floor(ph)
            let zx: F = right - w * 0.05 + ph * u * 0.06
            let zy: F = top - ph * u * 0.22 + h * 0.1
            let zs: F = u * (0.025 + 0.02 * ph)
            var zp = Path()
            zp.move(to: P(zx - zs, zy - zs))
            zp.addLine(to: P(zx + zs, zy - zs))
            zp.addLine(to: P(zx - zs, zy + zs))
            zp.addLine(to: P(zx + zs, zy + zs))
            ctx.strokeC(zp, Color.white.opacity(Double((1 - ph) * 0.9)), u * 0.01)
        }
    }
}
