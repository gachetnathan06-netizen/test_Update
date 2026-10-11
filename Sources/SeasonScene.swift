import SwiftUI

// ============================================================
//  Décors de saison
//  Quand le skin porté appartient à un pack saisonnier (Noël, Halloween,
//  Sakura, Océan), BOB vit dans un décor à thème, posé sur la ligne du sol :
//  Noël  : maison, cheminée qui fume, guirlandes et sapin qui clignotent
//  Halloween : manoir hanté, arbre mort, citrouilles, chauves-souris
//  Printemps : cerisier en fleurs, torii, lanternes, Fuji, papillons
//  Été   : mer, voilier, parasol, palmier, mouettes
//  Dessiné uniquement avec l'API du GraphicsContext de Compat.swift.
// ============================================================

enum SeasonScene {
    private struct Env {
        let w: CGFloat      // largeur de l'écran
        let u: CGFloat      // unité d'échelle (1 pour un écran de 390 pt)
        let B: CGFloat      // ligne de sol sur laquelle le décor est posé
        let t: Double       // temps (animation)
        let night: Double   // 0 jour … 1 nuit
    }

    /// Saison du décor associée à un skin (nil si le skin n'est pas saisonnier).
    static func season(of skin: Skin) -> Season? { Catalog.pack(skin.packID)?.season }

    static func draw(_ ctx: GraphicsContext, season: Season, size: CGSize, baseY: CGFloat, time: Double, night: Double) {
        let e = Env(w: size.width, u: min(size.width, 520) / 390, B: baseY, t: time, night: night)
        switch season {
        case .noel: noel(ctx, e)
        case .halloween: halloween(ctx, e)
        case .printemps: printemps(ctx, e)
        case .ete: ete(ctx, e)
        }
    }

    // MARK: - Outils

    private static func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

    private static func poly(_ pts: [CGPoint]) -> Path {
        var p = Path()
        p.addLines(pts)
        p.closeSubpath()
        return p
    }

    /// Couleur du décor, assombrie la nuit.
    private static func tone(_ hex: UInt32, _ night: Double, _ amount: Double = 0.5, _ opacity: Double = 1) -> Color {
        let c = RGB.mix(RGB(hex), RGB(0x0B0A24), night * amount)
        return Color(.sRGB, red: c.r, green: c.g, blue: c.b, opacity: opacity)
    }

    private static let bulbColors: [UInt32] = [0xFF4D5E, 0xFFD34E, 0x5BE37D, 0x5BB8FF]

    /// Ampoule de guirlande qui clignote.
    private static func bulb(_ ctx: GraphicsContext, _ e: Env, _ p: CGPoint, _ idx: Int, r: CGFloat) {
        let hex = bulbColors[idx % bulbColors.count]
        let a = 0.30 + 0.70 * max(0, sin(e.t * 3.4 + Double(idx) * 1.9))
        ctx.fill(Props.oval(p.x, p.y, r * 2.6, r * 2.6), with: .color(Color(hex: hex, opacity: (0.14 + 0.30 * e.night) * a)))
        ctx.fill(Props.oval(p.x, p.y, r, r), with: .color(Color(hex: hex, opacity: 0.50 + 0.50 * a)))
    }

    /// Fil tendu entre deux points avec des ampoules.
    private static func garland(_ ctx: GraphicsContext, _ e: Env, from a: CGPoint, to b: CGPoint,
                                sag: CGFloat, count: Int, phase: Int = 0) {
        let ctrl = pt((a.x + b.x) / 2, (a.y + b.y) / 2 + sag * 2)
        var wire = Path()
        wire.move(to: a)
        wire.addQuadCurve(to: b, control: ctrl)
        ctx.stroke(wire, with: .color(tone(0x1B4D2B, e.night, 0.3)), lineWidth: 1.6 * e.u)
        for i in 0..<count {
            let t = (CGFloat(i) + 0.5) / CGFloat(count)
            let m = 1 - t
            let x = m * m * a.x + 2 * m * t * ctrl.x + t * t * b.x
            let y = m * m * a.y + 2 * m * t * ctrl.y + t * t * b.y
            bulb(ctx, e, pt(x, y + 3 * e.u), i + phase, r: 2.8 * e.u)
        }
    }

    // MARK: - Noël

    private static func noel(_ ctx: GraphicsContext, _ e: Env) {
        let u = e.u, B = e.B, w = e.w, n = e.night, t = e.t
        let snow = tone(0xF4F8FF, n, 0.35)

        // congères
        var drift = Path()
        var dx: CGFloat = -24 * u
        while dx < w + 24 * u {
            drift.addEllipse(in: CGRect(x: dx, y: B - 7 * u, width: 80 * u, height: 20 * u))
            dx += 52 * u
        }
        ctx.fill(drift, with: .color(tone(0xF4F8FF, n, 0.35, 0.95)))

        // --- maison
        let x0 = 12 * u, hw = 214 * u, wh = 118 * u, rise = 76 * u
        let top = B - wh
        let cx = x0 + hw / 2
        let x1 = x0 + hw + 14 * u
        func roofY(_ x: CGFloat) -> CGFloat { top - rise + (x - cx) / (x1 - cx) * (rise + 2 * u) }

        ctx.fill(Path(CGRect(x: x0, y: top, width: hw, height: wh)), with: .color(tone(0x8B5A3C, n)))
        var planks = Path()
        var py = top + 14 * u
        while py < B {
            planks.addRect(CGRect(x: x0, y: py, width: hw, height: 1.4 * u))
            py += 14 * u
        }
        ctx.fill(planks, with: .color(Color.black.opacity(0.14)))
        ctx.fill(Path(CGRect(x: x0 - 3 * u, y: B - 10 * u, width: hw + 6 * u, height: 12 * u)), with: .color(tone(0x6B6F7D, n)))

        // cheminée (avant le toit : le toit recouvre son pied)
        let chX = x0 + hw * 0.74
        let chTop = roofY(chX) - 38 * u
        ctx.fill(Path(CGRect(x: chX - 13 * u, y: chTop, width: 26 * u, height: 60 * u)), with: .color(tone(0x9A4F3F, n)))
        var bricks = Path()
        var by = chTop + 9 * u
        while by < chTop + 50 * u {
            bricks.addRect(CGRect(x: chX - 13 * u, y: by, width: 26 * u, height: 1.2 * u))
            by += 9 * u
        }
        ctx.fill(bricks, with: .color(Color.black.opacity(0.18)))
        ctx.fill(Path(CGRect(x: chX - 16 * u, y: chTop - 5 * u, width: 32 * u, height: 7 * u)), with: .color(tone(0x7E3F33, n)))
        ctx.fill(Path(ellipseIn: CGRect(x: chX - 15 * u, y: chTop - 10 * u, width: 30 * u, height: 9 * u)), with: .color(snow))

        // toit + neige
        ctx.fill(poly([pt(x0 - 14 * u, top + 2 * u), pt(cx, top - rise), pt(x1, top + 2 * u)]), with: .color(tone(0xA83B46, n)))
        var cap = Path()
        cap.move(to: pt(x0 - 14 * u, top + 2 * u))
        cap.addLine(to: pt(cx, top - rise))
        cap.addLine(to: pt(x1, top + 2 * u))
        ctx.stroke(cap, with: .color(snow), style: StrokeStyle(lineWidth: 9 * u, lineCap: .round, lineJoin: .round))

        // fumée
        for i in 0..<6 {
            let ph = CGFloat(Backdrop.fract(t * 0.16 + Double(i) / 6))
            let sx = chX + CGFloat(sin(t * 1.1 + Double(i))) * 7 * u + ph * 36 * u
            let sy = chTop - 12 * u - ph * 96 * u
            let r = (5 + ph * 15) * u
            ctx.fill(Props.oval(sx, sy, r, r), with: .color(tone(0xEDEBF5, n, 0.4, Double(0.5 * (1 - ph)))))
        }

        // fenêtres allumées
        for (i, wx) in [x0 + 24 * u, x0 + hw - 64 * u].enumerated() {
            let wy = top + 30 * u
            let fl = 0.9 + 0.1 * sin(t * 7 + Double(i) * 2)
            ctx.fill(Path(CGRect(x: wx - 5 * u, y: wy - 5 * u, width: 50 * u, height: 50 * u)),
                     with: .color(Color(hex: 0xFFC76A, opacity: (0.10 + 0.20 * n) * fl)))
            ctx.fill(Path(CGRect(x: wx, y: wy, width: 40 * u, height: 40 * u)),
                     with: .color(Color(hex: 0xFFD27A, opacity: (0.62 + 0.38 * n) * fl)))
            var fr = Path()
            fr.addRect(CGRect(x: wx, y: wy, width: 40 * u, height: 40 * u))
            fr.move(to: pt(wx + 20 * u, wy))
            fr.addLine(to: pt(wx + 20 * u, wy + 40 * u))
            fr.move(to: pt(wx, wy + 20 * u))
            fr.addLine(to: pt(wx + 40 * u, wy + 20 * u))
            ctx.stroke(fr, with: .color(tone(0x4B2A25, n)), lineWidth: 3 * u)
            ctx.fill(Path(ellipseIn: CGRect(x: wx - 3 * u, y: wy - 5 * u, width: 46 * u, height: 8 * u)), with: .color(snow))
        }

        // porte + couronne
        ctx.fill(Props.rrect(cx - 17 * u, B - 64 * u, 34 * u, 70 * u, 14 * u), with: .color(tone(0x4B2A25, n)))
        ctx.fill(Props.oval(cx + 9 * u, B - 28 * u, 1.8 * u, 1.8 * u), with: .color(Color(hex: 0xFFD34E)))
        ctx.stroke(Props.oval(cx, B - 42 * u, 10 * u, 10 * u), with: .color(tone(0x2E8B4A, n, 0.3)), lineWidth: 4.5 * u)
        for k in 0..<4 {
            let a = Double(k) * 1.57 + 0.6
            ctx.fill(Props.oval(cx + CGFloat(cos(a)) * 10 * u, B - 42 * u + CGFloat(sin(a)) * 10 * u, 2.2 * u, 2.2 * u),
                     with: .color(Color(hex: 0xFF4D5E)))
        }

        // guirlandes de la maison
        garland(ctx, e, from: pt(x0 - 8 * u, top + 6 * u), to: pt(x0 + hw + 8 * u, top + 6 * u), sag: 12 * u, count: 13)
        garland(ctx, e, from: pt(x0 - 12 * u, top), to: pt(cx, top - rise + 2 * u), sag: 3 * u, count: 8, phase: 3)
        garland(ctx, e, from: pt(cx, top - rise + 2 * u), to: pt(x1 - 2 * u, top), sag: 3 * u, count: 8, phase: 5)

        // --- sapin
        let tx = w - 62 * u
        let th: CGFloat = 200 * u
        let tb = B - 2 * u
        let tt = tb - th
        garland(ctx, e, from: pt(x1 + 4 * u, top + 10 * u), to: pt(tx, tt + 22 * u), sag: 30 * u, count: 11, phase: 1)
        ctx.fill(Path(CGRect(x: tx - 9 * u, y: tb - 22 * u, width: 18 * u, height: 26 * u)), with: .color(tone(0x6B4423, n)))
        let layers: [(CGFloat, CGFloat, CGFloat, UInt32)] = [
            (0.50, 0.96, 72, 0x1B5E35), (0.27, 0.72, 56, 0x216E3E), (0.03, 0.48, 40, 0x28804A)
        ]
        for l in layers {
            let ly = tt + th * l.0, lb = tt + th * l.1
            ctx.fill(poly([pt(tx, ly), pt(tx - l.2 * u, lb), pt(tx + l.2 * u, lb)]), with: .color(tone(l.3, n, 0.35)))
            var edge = Path()
            edge.move(to: pt(tx - l.2 * u, lb))
            edge.addLine(to: pt(tx + l.2 * u, lb))
            ctx.stroke(edge, with: .color(snow), style: StrokeStyle(lineWidth: 4 * u, lineCap: .round))
        }
        // boules fixes
        for i in 0..<8 {
            let f = CGFloat(Backdrop.fract(Double(i) * 0.7548776662 + 0.1))
            let g = CGFloat(Backdrop.fract(Double(i) * 0.5698402909 + 0.3))
            let y = tt + 30 * u + f * (th - 56 * u)
            let half = (y - tt) / th * 58 * u
            ctx.fill(Props.oval(tx + (g * 2 - 1) * half * 0.8, y, 3.6 * u, 3.6 * u),
                     with: .color(Color(hex: i % 2 == 0 ? 0xE23C4A : 0xFFD34E)))
        }
        // lumières qui clignotent
        for i in 0..<22 {
            let f = CGFloat(Backdrop.fract(Double(i) * 0.618034))
            let g = CGFloat(Backdrop.fract(Double(i) * 0.381966 + 0.17))
            let y = tt + 22 * u + f * (th - 40 * u)
            let half = (y - tt) / th * 62 * u
            bulb(ctx, e, pt(tx + (g * 2 - 1) * half * 0.85, y), i, r: 3.2 * u)
        }
        // étoile
        let sp = CGFloat(0.7 + 0.3 * sin(t * 3))
        ctx.fill(Props.oval(tx, tt - 2 * u, 22 * u * sp, 22 * u * sp), with: .color(Color(hex: 0xFFE27A, opacity: 0.22 + 0.20 * n)))
        ctx.fill(Props.star(tx, tt - 2 * u, 13 * u, 5.5 * u), with: .color(Color(hex: 0xFFD34E)))

        // cadeaux
        gift(ctx, e, x: tx - 74 * u, w: 26 * u, h: 18 * u, box: 0xD6303E, ribbon: 0xFFD34E)
        gift(ctx, e, x: tx + 40 * u, w: 22 * u, h: 14 * u, box: 0x3C7DD9, ribbon: 0xF4F8FF)
    }

    private static func gift(_ ctx: GraphicsContext, _ e: Env, x: CGFloat, w: CGFloat, h: CGFloat, box: UInt32, ribbon: UInt32) {
        let y = e.B - h + 2 * e.u
        ctx.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(tone(box, e.night, 0.35)))
        ctx.fill(Path(CGRect(x: x + w / 2 - 2 * e.u, y: y, width: 4 * e.u, height: h)), with: .color(tone(ribbon, e.night, 0.25)))
        ctx.fill(Path(CGRect(x: x, y: y + h / 2 - 2 * e.u, width: w, height: 4 * e.u)), with: .color(tone(ribbon, e.night, 0.25)))
    }

    // MARK: - Halloween

    private static func halloween(_ ctx: GraphicsContext, _ e: Env) {
        let u = e.u, B = e.B, w = e.w, t = e.t
        let dark = Color(hex: 0x150E26)
        let wall = Color(hex: 0x241943)

        // voile violet sur le ciel
        ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: B)),
                 with: .linearGradient(Gradient(colors: [Color(hex: 0x1B0F3B, opacity: 0.72), Color(hex: 0x3A1550, opacity: 0)]),
                                       startPoint: .zero, endPoint: CGPoint(x: 0, y: B)))
        // grande lune orange
        let mx = w * 0.70, my = B - 330 * u
        ctx.fill(Props.oval(mx, my, 92 * u, 92 * u),
                 with: .radialGradient(Gradient(colors: [Color(hex: 0xFFB347, opacity: 0.35), Color(hex: 0xFFB347, opacity: 0)]),
                                       center: pt(mx, my), startRadius: 0, endRadius: 92 * u))
        ctx.fill(Props.oval(mx, my, 48 * u, 48 * u), with: .color(Color(hex: 0xFFC869, opacity: 0.95)))
        for (dx, dy, r) in [(-14.0, -10.0, 8.0), (12.0, 8.0, 6.0), (-4.0, 18.0, 4.5)] {
            ctx.fill(Props.oval(mx + CGFloat(dx) * u, my + CGFloat(dy) * u, CGFloat(r) * u, CGFloat(r) * u),
                     with: .color(Color(hex: 0xE59A3C, opacity: 0.55)))
        }

        // brume au sol
        for k in 0..<3 {
            let mxk = w * (0.2 + 0.3 * CGFloat(k)) + CGFloat(sin(t * 0.3 + Double(k) * 2)) * 30 * u
            ctx.fill(Props.oval(mxk, B - 4 * u, 120 * u, 14 * u), with: .color(Color.white.opacity(0.07)))
        }

        // arbre mort
        let tx = w * 0.12
        var trunk = Path()
        trunk.move(to: pt(tx, B + 2 * u))
        trunk.addQuadCurve(to: pt(tx + 8 * u, B - 140 * u), control: pt(tx - 16 * u, B - 70 * u))
        ctx.stroke(trunk, with: .color(dark), style: StrokeStyle(lineWidth: 14 * u, lineCap: .round))
        var br = Path()
        br.move(to: pt(tx + 8 * u, B - 140 * u))
        br.addQuadCurve(to: pt(tx - 46 * u, B - 198 * u), control: pt(tx - 14 * u, B - 150 * u))
        br.move(to: pt(tx + 8 * u, B - 140 * u))
        br.addQuadCurve(to: pt(tx + 50 * u, B - 190 * u), control: pt(tx + 30 * u, B - 136 * u))
        br.move(to: pt(tx - 2 * u, B - 100 * u))
        br.addQuadCurve(to: pt(tx - 44 * u, B - 120 * u), control: pt(tx - 24 * u, B - 96 * u))
        br.move(to: pt(tx - 30 * u, B - 176 * u))
        br.addLine(to: pt(tx - 54 * u, B - 168 * u))
        br.move(to: pt(tx + 32 * u, B - 168 * u))
        br.addLine(to: pt(tx + 48 * u, B - 150 * u))
        ctx.stroke(br, with: .color(dark), style: StrokeStyle(lineWidth: 6 * u, lineCap: .round, lineJoin: .round))

        // manoir hanté
        let hx = w - 190 * u
        let hwid = 150 * u, hh = 104 * u
        ctx.fill(Path(CGRect(x: hx - 40 * u, y: B - 176 * u, width: 50 * u, height: 176 * u)), with: .color(wall))
        ctx.fill(poly([pt(hx - 48 * u, B - 176 * u), pt(hx - 15 * u, B - 234 * u), pt(hx + 18 * u, B - 176 * u)]), with: .color(dark))
        ctx.fill(Path(CGRect(x: hx, y: B - hh, width: hwid, height: hh)), with: .color(wall))
        ctx.fill(Path(CGRect(x: hx + hwid * 0.70, y: B - hh - 58 * u, width: 16 * u, height: 40 * u)), with: .color(dark))
        ctx.fill(poly([pt(hx - 10 * u, B - hh), pt(hx + hwid * 0.45, B - hh - 66 * u), pt(hx + hwid + 10 * u, B - hh)]), with: .color(dark))
        glowWindow(ctx, e, x: hx - 26 * u, y: B - 150 * u, w: 18 * u, h: 28 * u, i: 0)
        glowWindow(ctx, e, x: hx - 26 * u, y: B - 96 * u, w: 18 * u, h: 28 * u, i: 1)
        glowWindow(ctx, e, x: hx + 22 * u, y: B - 84 * u, w: 24 * u, h: 30 * u, i: 2)
        glowWindow(ctx, e, x: hx + hwid - 50 * u, y: B - 84 * u, w: 24 * u, h: 30 * u, i: 3)
        glowWindow(ctx, e, x: hx + hwid * 0.45 - 9 * u, y: B - hh - 38 * u, w: 18 * u, h: 18 * u, i: 4)
        ctx.fill(Props.rrect(hx + hwid * 0.45 - 12 * u, B - 44 * u, 24 * u, 46 * u, 11 * u), with: .color(dark))
        ctx.fill(Path(CGRect(x: hx + hwid * 0.45 - 1.2 * u, y: B - 40 * u, width: 2.4 * u, height: 38 * u)),
                 with: .color(Color(hex: 0xFFA032, opacity: 0.55)))

        // pierres tombales
        ctx.fill(Props.rrect(w * 0.27, B - 36 * u, 24 * u, 42 * u, 11 * u), with: .color(tone(0x5A5470, e.night, 0.3)))
        ctx.fill(Props.rrect(w * 0.27 + 30 * u, B - 26 * u, 19 * u, 32 * u, 9 * u), with: .color(tone(0x4C4662, e.night, 0.3)))

        // citrouilles
        pumpkin(ctx, e, x: w * 0.40, r: 20 * u, k: 0)
        pumpkin(ctx, e, x: w * 0.74, r: 29 * u, k: 1)
        pumpkin(ctx, e, x: w * 0.74 + 36 * u, r: 17 * u, k: 2)

        // chauves-souris
        for k in 0..<3 {
            let sp = 0.035 + Double(k) * 0.012
            let bx = CGFloat(Backdrop.fract(t * sp + Double(k) * 0.33)) * (w + 80 * u) - 40 * u
            let byy = B - (300 + CGFloat(k) * 34) * u + CGFloat(sin(t * 1.6 + Double(k) * 2)) * 16 * u
            let fl = CGFloat(sin(t * 13 + Double(k) * 1.7))
            var g = ctx
            g.translateBy(x: bx, y: byy)
            var wing = Path()
            wing.move(to: pt(0, 0))
            wing.addQuadCurve(to: pt(18 * u, -6 * u * fl - 2 * u), control: pt(9 * u, -12 * u * fl - 6 * u))
            wing.addQuadCurve(to: pt(11 * u, 3 * u), control: pt(15 * u, 2 * u))
            wing.addQuadCurve(to: pt(5 * u, 2 * u), control: pt(8 * u, 6 * u))
            wing.addQuadCurve(to: pt(0, 5 * u), control: pt(2 * u, 5 * u))
            wing.closeSubpath()
            let col = Color(hex: 0x0E0818)
            g.fill(wing, with: .color(col))
            var g2 = g
            g2.scaleBy(x: -1, y: 1)
            g2.fill(wing, with: .color(col))
            g.fill(Props.oval(0, 1 * u, 3.4 * u, 4.4 * u), with: .color(col))
        }
    }

    private static func glowWindow(_ ctx: GraphicsContext, _ e: Env, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, i: Int) {
        let fl = 0.62 + 0.38 * max(0, sin(e.t * 5.3 + Double(i) * 2.9))
        ctx.fill(Path(CGRect(x: x - 4 * e.u, y: y - 4 * e.u, width: w + 8 * e.u, height: h + 8 * e.u)),
                 with: .color(Color(hex: 0xFF8A1E, opacity: 0.13 * fl)))
        ctx.fill(Props.rrect(x, y, w, h, w * 0.4), with: .color(Color(hex: 0xFFA032, opacity: 0.55 + 0.4 * fl)))
    }

    private static func pumpkin(_ ctx: GraphicsContext, _ e: Env, x: CGFloat, r: CGFloat, k: Int) {
        let u = e.u, B = e.B
        let cy = B - r * 0.78 + 2 * u
        let rx = r, ry = r * 0.8
        let fl = 0.72 + 0.28 * sin(e.t * 9 + Double(k) * 2.3)
        ctx.fill(Props.oval(x, cy, rx * 1.6, ry * 1.6), with: .color(Color(hex: 0xFF9A2A, opacity: 0.10 * fl * (0.4 + e.night))))
        ctx.fill(Props.oval(x, cy, rx, ry), with: .color(tone(0xF08A24, e.night, 0.35)))
        var rib = Path()
        rib.move(to: pt(x - rx * 0.45, cy - ry * 0.9))
        rib.addQuadCurve(to: pt(x - rx * 0.45, cy + ry * 0.9), control: pt(x - rx * 0.85, cy))
        rib.move(to: pt(x + rx * 0.45, cy - ry * 0.9))
        rib.addQuadCurve(to: pt(x + rx * 0.45, cy + ry * 0.9), control: pt(x + rx * 0.85, cy))
        ctx.stroke(rib, with: .color(Color(hex: 0x8A3F0E, opacity: 0.45)), lineWidth: 1.6 * u)
        ctx.fill(Props.rrect(x - 3 * u, cy - ry - 7 * u, 6 * u, 10 * u, 2 * u), with: .color(tone(0x3E7A2E, e.night, 0.35)))
        let glow = Color(hex: 0xFFD54A, opacity: 0.55 + 0.45 * fl)
        ctx.fill(poly([pt(x - 0.50 * r, cy - 0.10 * r), pt(x - 0.15 * r, cy - 0.10 * r), pt(x - 0.32 * r, cy - 0.45 * r)]), with: .color(glow))
        ctx.fill(poly([pt(x + 0.15 * r, cy - 0.10 * r), pt(x + 0.50 * r, cy - 0.10 * r), pt(x + 0.32 * r, cy - 0.45 * r)]), with: .color(glow))
        ctx.fill(poly([pt(x - 0.50 * r, cy + 0.18 * r), pt(x - 0.25 * r, cy + 0.12 * r), pt(x, cy + 0.20 * r),
                       pt(x + 0.25 * r, cy + 0.12 * r), pt(x + 0.50 * r, cy + 0.18 * r), pt(x + 0.30 * r, cy + 0.50 * r),
                       pt(x, cy + 0.38 * r), pt(x - 0.30 * r, cy + 0.50 * r)]), with: .color(glow))
    }

    // MARK: - Printemps

    private static func printemps(_ ctx: GraphicsContext, _ e: Env) {
        let u = e.u, B = e.B, w = e.w, n = e.night, t = e.t

        // mont Fuji lointain
        let px = w * 0.46
        ctx.fill(poly([pt(px - 200 * u, B), pt(px, B - 170 * u), pt(px + 200 * u, B)]), with: .color(tone(0x8E9AD1, n, 0.5, 0.55)))
        ctx.fill(poly([pt(px - 54 * u, B - 120 * u), pt(px, B - 170 * u), pt(px + 54 * u, B - 120 * u),
                       pt(px + 30 * u, B - 129 * u), pt(px + 10 * u, B - 116 * u), pt(px - 12 * u, B - 129 * u)]),
                 with: .color(tone(0xFFFFFF, n, 0.3, 0.92)))

        // tapis de pétales
        for k in 0..<5 {
            ctx.fill(Props.oval(w * (0.08 + 0.2 * CGFloat(k)), B + 2 * u, 46 * u, 6 * u), with: .color(Color(hex: 0xFFB7D0, opacity: 0.45)))
        }

        // torii
        let gx = w - 70 * u
        let red = tone(0xD0382F, n, 0.4)
        ctx.fill(Path(CGRect(x: gx - 48 * u, y: B - 118 * u, width: 11 * u, height: 120 * u)), with: .color(red))
        ctx.fill(Path(CGRect(x: gx + 37 * u, y: B - 118 * u, width: 11 * u, height: 120 * u)), with: .color(red))
        ctx.fill(Path(CGRect(x: gx - 51 * u, y: B - 8 * u, width: 17 * u, height: 10 * u)), with: .color(tone(0x2B2433, n, 0.3)))
        ctx.fill(Path(CGRect(x: gx + 34 * u, y: B - 8 * u, width: 17 * u, height: 10 * u)), with: .color(tone(0x2B2433, n, 0.3)))
        ctx.fill(Path(CGRect(x: gx - 50 * u, y: B - 100 * u, width: 100 * u, height: 8 * u)), with: .color(red))
        ctx.fill(Path(CGRect(x: gx - 4 * u, y: B - 128 * u, width: 8 * u, height: 30 * u)), with: .color(red))
        ctx.fill(poly([pt(gx - 74 * u, B - 124 * u), pt(gx - 62 * u, B - 140 * u), pt(gx + 62 * u, B - 140 * u),
                       pt(gx + 74 * u, B - 124 * u), pt(gx + 60 * u, B - 129 * u), pt(gx - 60 * u, B - 129 * u)]),
                 with: .color(tone(0x2B2433, n, 0.3)))
        ctx.fill(Path(CGRect(x: gx - 60 * u, y: B - 130 * u, width: 120 * u, height: 4 * u)), with: .color(red))

        // cerisier
        let tx = w * 0.11
        var trunk = Path()
        trunk.move(to: pt(tx, B + 2 * u))
        trunk.addQuadCurve(to: pt(tx + 14 * u, B - 150 * u), control: pt(tx - 22 * u, B - 80 * u))
        ctx.stroke(trunk, with: .color(tone(0x4A2F2A, n, 0.4)), style: StrokeStyle(lineWidth: 17 * u, lineCap: .round))
        var br = Path()
        br.move(to: pt(tx + 14 * u, B - 150 * u))
        br.addQuadCurve(to: pt(tx + 72 * u, B - 196 * u), control: pt(tx + 36 * u, B - 150 * u))
        br.move(to: pt(tx + 6 * u, B - 118 * u))
        br.addQuadCurve(to: pt(tx - 40 * u, B - 168 * u), control: pt(tx - 18 * u, B - 128 * u))
        ctx.stroke(br, with: .color(tone(0x4A2F2A, n, 0.4)), style: StrokeStyle(lineWidth: 8 * u, lineCap: .round))
        let crown = pt(tx + 18 * u, B - 200 * u)
        let pinks: [UInt32] = [0xFFB7D0, 0xFF9EC0, 0xFFD3E2]
        for i in 0..<18 {
            let a = Double(i) * 2.399963
            let rr = (26 + CGFloat(i % 4) * 14) * u
            let sway = CGFloat(sin(t * 0.6 + Double(i))) * 1.6 * u
            let cxp = crown.x + CGFloat(cos(a)) * rr * 1.7 + sway
            let cyp = crown.y + CGFloat(sin(a)) * rr * 0.85
            let r = (24 + CGFloat(i % 3) * 8) * u
            ctx.fill(Props.oval(cxp, cyp, r, r), with: .color(tone(pinks[i % 3], n, 0.35, 0.92)))
        }

        // lanternes entre le cerisier et le torii
        let la = pt(tx + 72 * u, B - 190 * u)
        let lb = pt(gx - 74 * u, B - 128 * u)
        let ctrl = pt((la.x + lb.x) / 2, (la.y + lb.y) / 2 + 70 * u)
        var wire = Path()
        wire.move(to: la)
        wire.addQuadCurve(to: lb, control: ctrl)
        ctx.stroke(wire, with: .color(tone(0x3A2A2A, n, 0.3)), lineWidth: 1.4 * u)
        for i in 0..<7 {
            let s = (CGFloat(i) + 0.5) / 7
            let m = 1 - s
            let lx = m * m * la.x + 2 * m * s * ctrl.x + s * s * lb.x
            let ly = m * m * la.y + 2 * m * s * ctrl.y + s * s * lb.y + 4 * u
            let fl = 0.8 + 0.2 * sin(t * 2.2 + Double(i) * 1.3)
            ctx.fill(Props.oval(lx, ly + 8 * u, 16 * u, 16 * u), with: .color(Color(hex: 0xFF9DBB, opacity: (0.10 + 0.28 * n) * fl)))
            ctx.fill(Props.oval(lx, ly + 8 * u, 6.5 * u, 8.5 * u), with: .color(Color(hex: 0xFF9DBB, opacity: 0.70 + 0.30 * n)))
            ctx.fill(Path(CGRect(x: lx - 4 * u, y: ly - 1 * u, width: 8 * u, height: 2.4 * u)), with: .color(tone(0x3A2A2A, n, 0.3)))
        }

        // papillons
        for k in 0..<2 {
            let ph = Double(k) * 2.4
            let bx = w * (0.38 + 0.3 * CGFloat(k)) + CGFloat(sin(t * 0.7 + ph)) * 60 * u
            let byy = B - (120 + CGFloat(k) * 50) * u + CGFloat(sin(t * 1.3 + ph * 2)) * 24 * u
            let flap = abs(sin(t * 11 + ph))
            let ww = CGFloat(0.25 + 0.75 * flap) * 7 * u
            ctx.fill(Props.oval(bx - ww, byy - 2 * u, ww, 5 * u), with: .color(Color(hex: k == 0 ? 0xFFD05E : 0xFF8FB1)))
            ctx.fill(Props.oval(bx + ww, byy - 2 * u, ww, 5 * u), with: .color(Color(hex: k == 0 ? 0xFFD05E : 0xFF8FB1)))
            ctx.fill(Props.oval(bx, byy, 1.1 * u, 4 * u), with: .color(Color(hex: 0x3A2A2A)))
        }
    }

    // MARK: - Été

    private static func ete(_ ctx: GraphicsContext, _ e: Env) {
        let u = e.u, B = e.B, w = e.w, n = e.night, t = e.t

        // mer à l'horizon
        let seaTop = B - 54 * u
        ctx.fill(Path(CGRect(x: 0, y: seaTop, width: w, height: 56 * u)),
                 with: .linearGradient(Gradient(colors: [tone(0x58D0EE, n, 0.55), tone(0x1D8FC8, n, 0.55)]),
                                       startPoint: pt(0, seaTop), endPoint: pt(0, B + 2 * u)))
        for j in 0..<3 {
            var wv = Path()
            let ry = seaTop + CGFloat(j) * 14 * u + 10 * u
            var x: CGFloat = -10 * u
            wv.move(to: pt(x, ry))
            while x < w + 10 * u {
                x += 8 * u
                wv.addLine(to: pt(x, ry + CGFloat(sin(Double(x) * 0.06 + t * (1.0 + Double(j) * 0.35))) * 3 * u))
            }
            ctx.stroke(wv, with: .color(Color.white.opacity(0.32 - Double(j) * 0.07)), lineWidth: 1.8 * u)
        }

        // voilier
        let bx = CGFloat(Backdrop.fract(t * 0.014 + 0.25)) * (w + 120 * u) - 60 * u
        let by = seaTop + 24 * u + CGFloat(sin(t * 1.4)) * 2 * u
        ctx.fill(poly([pt(bx - 18 * u, by), pt(bx + 18 * u, by), pt(bx + 12 * u, by + 8 * u), pt(bx - 12 * u, by + 8 * u)]),
                 with: .color(tone(0x8B4B2A, n, 0.4)))
        ctx.fill(Path(CGRect(x: bx - 0.8 * u, y: by - 36 * u, width: 1.6 * u, height: 36 * u)), with: .color(tone(0x6B4423, n, 0.4)))
        ctx.fill(poly([pt(bx - 2 * u, by - 34 * u), pt(bx - 2 * u, by - 3 * u), pt(bx - 17 * u, by - 3 * u)]), with: .color(tone(0xFFFFFF, n, 0.35)))
        ctx.fill(poly([pt(bx + 2 * u, by - 28 * u), pt(bx + 2 * u, by - 3 * u), pt(bx + 15 * u, by - 3 * u)]), with: .color(tone(0xFF5A5F, n, 0.35)))

        // parasol
        let ux = w * 0.14, uy = B - 92 * u, R = 56 * u
        var pole = Path()
        pole.move(to: pt(ux, uy))
        pole.addLine(to: pt(ux + 4 * u, B + 2 * u))
        ctx.stroke(pole, with: .color(tone(0xE8E2D0, n, 0.4)), lineWidth: 3 * u)
        for i in 0..<6 {
            var wd = Path()
            wd.move(to: pt(ux, uy))
            wd.addArc(center: pt(ux, uy), radius: R,
                      startAngle: .radians(Double.pi + Double(i) * Double.pi / 6),
                      endAngle: .radians(Double.pi + Double(i + 1) * Double.pi / 6), clockwise: false)
            wd.closeSubpath()
            ctx.fill(wd, with: .color(i % 2 == 0 ? tone(0xFF5A5F, n, 0.35) : tone(0xFFFFFF, n, 0.35)))
        }
        // serviette
        ctx.fill(Props.rrect(ux + 14 * u, B - 4 * u, 70 * u, 10 * u, 3 * u), with: .color(tone(0xFFD34E, n, 0.35)))
        ctx.fill(Path(CGRect(x: ux + 34 * u, y: B - 4 * u, width: 8 * u, height: 10 * u)), with: .color(tone(0xFF7A90, n, 0.35)))
        ctx.fill(Path(CGRect(x: ux + 58 * u, y: B - 4 * u, width: 8 * u, height: 10 * u)), with: .color(tone(0xFF7A90, n, 0.35)))

        // palmier
        let px = w - 58 * u
        let topP = pt(px - 10 * u, B - 178 * u)
        var trunk = Path()
        trunk.move(to: pt(px + 6 * u, B + 2 * u))
        trunk.addQuadCurve(to: topP, control: pt(px + 30 * u, B - 90 * u))
        ctx.stroke(trunk, with: .color(tone(0x8A6240, n, 0.4)), style: StrokeStyle(lineWidth: 13 * u, lineCap: .round))
        for k in 0..<7 {
            let ang = -3.0 + Double(k) * 0.5
            let sway = sin(t * 1.2 + Double(k)) * 0.06
            let len = 64 * u
            let ex = topP.x + CGFloat(cos(ang + sway)) * len
            let ey = topP.y + CGFloat(sin(ang + sway)) * len * 0.55 + 26 * u * CGFloat(abs(cos(ang)))
            let c1 = pt(topP.x + CGFloat(cos(ang)) * len * 0.55, topP.y + CGFloat(sin(ang)) * len * 0.75 - 8 * u)
            var leaf = Path()
            leaf.move(to: topP)
            leaf.addQuadCurve(to: pt(ex, ey), control: c1)
            leaf.addQuadCurve(to: topP, control: pt(c1.x, c1.y + 12 * u))
            ctx.fill(leaf, with: .color(k % 2 == 0 ? tone(0x2E9E4F, n, 0.4) : tone(0x3AB35E, n, 0.4)))
        }
        ctx.fill(Props.oval(topP.x - 4 * u, topP.y + 6 * u, 4.5 * u, 4.5 * u), with: .color(tone(0x6B4423, n, 0.4)))
        ctx.fill(Props.oval(topP.x + 4 * u, topP.y + 7 * u, 4.5 * u, 4.5 * u), with: .color(tone(0x6B4423, n, 0.4)))

        // mouettes
        for k in 0..<2 {
            let gx = CGFloat(Backdrop.fract(t * 0.03 * (1 + Double(k) * 0.4) + Double(k) * 0.4)) * (w + 80 * u) - 40 * u
            let gy = B - (250 + CGFloat(k) * 30) * u + CGFloat(sin(t * 2 + Double(k))) * 6 * u
            let fl = CGFloat(sin(t * 6 + Double(k)))
            var g = Path()
            g.move(to: pt(gx - 11 * u, gy - 3 * u * fl))
            g.addQuadCurve(to: pt(gx, gy), control: pt(gx - 5 * u, gy - 7 * u * fl - 3 * u))
            g.addQuadCurve(to: pt(gx + 11 * u, gy - 3 * u * fl), control: pt(gx + 5 * u, gy - 7 * u * fl - 3 * u))
            ctx.stroke(g, with: .color(Color.white.opacity(0.9)), style: StrokeStyle(lineWidth: 2 * u, lineCap: .round, lineJoin: .round))
        }
    }
}
