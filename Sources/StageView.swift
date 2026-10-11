import SwiftUI

enum Backdrop {
    static func fract(_ x: Double) -> Double { x - floor(x) }

    static func draw(_ ctx: GraphicsContext, size: CGSize, floorY: CGFloat, date: Date, time: Double, bodyW: CGFloat, scene: Season? = nil) {
        let hour = Theme.hourNow(date)
        let sky = Theme.sky(hour: hour)
        let w = size.width, h = size.height
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .linearGradient(Gradient(colors: [sky.top.color, sky.bottom.color]),
                                       startPoint: .zero, endPoint: CGPoint(x: 0, y: floorY)))

        // astre
        let isDay = hour >= 6 && hour < 19
        let u: Double = isDay ? (hour - 6) / 13 : (hour >= 19 ? (hour - 19) / 11 : (hour + 5) / 11)
        let ox = w * CGFloat(0.12 + 0.76 * u)
        let oy = floorY * 0.60 - CGFloat(sin(Double.pi * u)) * floorY * 0.44
        let orbR: CGFloat = isDay ? 30 : 24
        let glow = Color(hex: isDay ? 0xFFD27A : 0xDCE6FF, opacity: isDay ? 0.35 : 0.22)
        ctx.fill(Path(ellipseIn: CGRect(x: ox - orbR * 3, y: oy - orbR * 3, width: orbR * 6, height: orbR * 6)),
                 with: .radialGradient(Gradient(colors: [glow, glow.opacity(0)]), center: CGPoint(x: ox, y: oy), startRadius: 0, endRadius: orbR * 3))
        ctx.fill(Path(ellipseIn: CGRect(x: ox - orbR, y: oy - orbR, width: orbR * 2, height: orbR * 2)),
                 with: .color(Color(hex: isDay ? 0xFFE9A8 : 0xF3EFE2)))
        if !isDay {
            for (dx, dy, r) in [(-8.0, -6.0, 5.0), (7.0, 5.0, 4.0), (-2.0, 10.0, 3.0)] {
                ctx.fill(Path(ellipseIn: CGRect(x: ox + dx - r, y: oy + dy - r, width: r * 2, height: r * 2)), with: .color(Color(hex: 0xD6D0BE, opacity: 0.7)))
            }
        }

        // étoiles
        if sky.night > 0.02 {
            for i in 0..<70 {
                let f = Double(i)
                let x = CGFloat(fract(f * 0.7548776662)) * w
                let y = CGFloat(fract(f * 0.5698402909)) * floorY * 0.85
                let tw = 0.45 + 0.55 * sin(time * (0.8 + fract(f * 0.37)) + f)
                let r: CGFloat = 0.8 + CGFloat(fract(f * 0.61)) * 1.4
                ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                         with: .color(.white.opacity(sky.night * tw * 0.9)))
            }
        }

        ambient(ctx, size: size, floorY: floorY, time: time, night: sky.night, season: scene ?? Season.current)

        // sol
        let fy = floorY - bodyW * 0.08
        let floorRect = CGRect(x: 0, y: fy, width: w, height: h - fy)
        ctx.fill(Path(floorRect),
                 with: .linearGradient(Gradient(colors: [RGB.mix(sky.floor, RGB(0xFFFFFF), 0.10).color, sky.floor.darker(0.25).color]),
                                       startPoint: CGPoint(x: 0, y: fy), endPoint: CGPoint(x: 0, y: h)))
        ctx.fill(Path(CGRect(x: 0, y: fy, width: w, height: 3)), with: .color(.white.opacity(0.16)))
        var y = fy + 30
        var gap: CGFloat = 18
        while y < h {
            ctx.fill(Path(CGRect(x: 0, y: y, width: w, height: 1)), with: .color(.black.opacity(0.10)))
            y += gap
            gap *= 1.35
        }

        // décor de saison (skin saisonnier) posé sur la ligne du sol
        if let scene = scene {
            SeasonScene.draw(ctx, season: scene, size: size, baseY: fy + 6, time: time, night: sky.night)
        }
    }

    static func ambient(_ ctx: GraphicsContext, size: CGSize, floorY: CGFloat, time: Double, night: Double, season: Season?) {
        guard let season = season else { return }
        let w = size.width
        let count = season == .ete ? (night > 0.3 ? 24 : 0) : 34
        guard count > 0 else { return }
        for i in 0..<count {
            let f = Double(i)
            let sp = 16 + 34 * fract(f * 0.569840291)
            let ph = fract(f * 0.381966)
            let sx = CGFloat(fract(f * 0.754877666)) * w
            let sway = CGFloat(sin(time * 0.8 + f)) * 18
            switch season {
            case .noel:
                let y = CGFloat(fract(time * sp / Double(floorY) + ph)) * floorY
                let r: CGFloat = 1.5 + CGFloat(fract(f * 0.7)) * 2.5
                ctx.fill(Path(ellipseIn: CGRect(x: sx + sway - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.white.opacity(0.85)))
            case .printemps:
                let y = CGFloat(fract(time * sp / Double(floorY) + ph)) * floorY
                var g = ctx
                g.translateBy(x: sx + sway, y: y)
                g.rotate(by: .radians(time * 1.2 + f))
                g.fill(Path(ellipseIn: CGRect(x: -5, y: -3, width: 10, height: 6)), with: .color(Color(hex: 0xFFC2D9, opacity: 0.85)))
            case .halloween:
                let y = CGFloat(fract(time * sp / Double(floorY) + ph)) * floorY
                var g = ctx
                g.translateBy(x: sx + sway, y: y)
                g.rotate(by: .radians(time * 1.5 + f))
                g.fill(Path(ellipseIn: CGRect(x: -6, y: -3.5, width: 12, height: 7)), with: .color(Color(hex: i % 2 == 0 ? 0xFF9F40 : 0xC95A1A, opacity: 0.85)))
            case .ete:
                let fy = floorY * (0.45 + 0.5 * CGFloat(fract(f * 0.43))) + CGFloat(sin(time * 0.6 + f * 2)) * 14
                let a = 0.4 + 0.6 * sin(time * 1.6 + f * 3)
                let c = Color(hex: 0xFFF08A, opacity: max(0, a) * night)
                ctx.fill(Path(ellipseIn: CGRect(x: sx + sway - 6, y: fy - 6, width: 12, height: 12)), with: .color(c.opacity(0.25)))
                ctx.fill(Path(ellipseIn: CGRect(x: sx + sway - 1.8, y: fy - 1.8, width: 3.6, height: 3.6)), with: .color(c))
            }
        }
    }

    static func particle(_ ctx: GraphicsContext, _ p: Particle) {
        let k = p.age / p.life
        let a = max(0, 1 - k * k)
        let col = p.color.opacity(a)
        switch p.kind {
        case .heart:
            ctx.fill(Props.heart(p.x, p.y, p.size), with: .color(col))
        case .spark:
            ctx.fill(Props.star(p.x, p.y, p.size, p.size * 0.35, n: 4, rot: CGFloat(p.rot)), with: .color(col))
        case .crumb:
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - p.size / 2, y: p.y - p.size / 2, width: p.size, height: p.size)), with: .color(col))
        case .sweat:
            ctx.fill(Path(ellipseIn: CGRect(x: p.x - p.size * 0.4, y: p.y - p.size * 0.6, width: p.size * 0.8, height: p.size * 1.2)), with: .color(col))
        case .confetti:
            var g = ctx
            g.translateBy(x: p.x, y: p.y)
            g.rotate(by: .radians(p.rot))
            g.fill(Path(CGRect(x: -p.size / 2, y: -p.size / 4, width: p.size, height: p.size / 2)), with: .color(col))
        case .zzz:
            ctx.drawText("z", at: CGPoint(x: p.x, y: p.y), size: p.size, weight: .bold, rounded: true, color: col)
        case .emoji:
            ctx.drawText(p.text, at: CGPoint(x: p.x, y: p.y), size: p.size)
        }
    }
}

struct StageView: View {
    @EnvironmentObject var app: AppState
    @State private var sim = BobSim()
    @State private var touching = false

    var body: some View {
        AnimatedCanvas { ctx, size, date in
            render(ctx, size, date)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { v in
                    let now = Date()
                    if !touching {
                        touching = true
                        if sim.hit(v.startLocation) { sim.beginTouch(v.startLocation, now: now) }
                    }
                    if sim.touchDown { sim.moveTouch(v.location, now: now) }
                }
                .onEnded { _ in
                    if sim.touchDown { sim.endTouch(now: Date()) }
                    touching = false
                }
        )
        .onReceive(app.events) { sim.handle($0, now: Date()) }
        .onAppear {
            sim.onLand = { impact in Haptics.impact(impact > 900 ? .medium : .light, min(1, impact / 1600)); Sound.shared.land(impact) }
            sim.onThrow = { sp in Sound.shared.play(.whoosh, rate: Float(0.85 + min(0.5, Double(sp) / 4000)), gain: Float(min(1, Double(sp) / 1800 + 0.3))) }
            sim.onWall = { sp in Sound.shared.play(.bounce, rate: Float.random(in: 0.9...1.1), gain: Float(min(1, Double(sp) / 1400)), gap: 0.1) }
            sim.onPat = { Haptics.impact(.soft, 0.6); app.patTick() }
            sim.onPoke = { Haptics.impact(.light); Sound.shared.poke(); app.poke() }
        }
        .edgesIgnoringSafeArea(.all)
    }

    private func render(_ ctx: GraphicsContext, _ size: CGSize, _ date: Date) {
        sim.stage = size
        let s = app.s.settings
        let mood = app.mood(temp: sim.currentTemp(date))
        sim.gravityOn = s.gravity
        sim.trailOn = s.trail
        sim.sleeping = app.s.sleeping
        sim.bounceMusic = app.music && s.music
        sim.wantHeat = mood == .surchauffe
        sim.wantCamo = s.camo && app.skin.camo
        sim.targetSquare = s.morph && app.pomoRunning && app.pomoPhase == .focus ? 1 : 0
        let sad = app.s.joie < 30 && mood != .endormi
        sim.targetPuddle = s.morph && (app.batteryLow || sad) ? 1 : 0
        if !s.morph { sim.heart = 0 }
        sim.step(date, mood: mood)

        let sky = Theme.sky(hour: Theme.hourNow(date))
        Backdrop.draw(ctx, size: size, floorY: sim.floorY, date: date, time: sim.time, bodyW: sim.bodyW,
                      scene: SeasonScene.season(of: app.skin))

        // ombre
        let lift = max(0, sim.floorY - sim.pos.y)
        let sc = 1 / (1 + lift / 300)
        let shW = sim.bodyW * 0.82 * sc
        ctx.fill(Path(ellipseIn: CGRect(x: sim.pos.x - shW / 2, y: sim.floorY - shW * 0.06, width: shW, height: shW * 0.16)),
                 with: .color(.black.opacity(0.30 / (1 + lift / 200))))

        // traînée
        let tc = RGB(app.skin.bottom).color
        for d in sim.trail {
            let a = max(0, 1 - d.age / 1.1)
            let r = sim.bodyW * 0.12 * CGFloat(a)
            ctx.fill(Path(ellipseIn: CGRect(x: d.p.x - r, y: d.p.y - r * 0.6, width: r * 2, height: r * 1.2)), with: .color(tc.opacity(0.35 * a)))
        }

        var look = BobLook(skin: app.skin, mood: mood)
        look.head = app.head
        look.eyes = app.eyes
        look.ears = app.ears ?? ((app.headphones && s.music) ? .ecouteurs : nil)
        look.neck = app.neck
        look.blink = mood == .endormi ? 0 : sim.blinkValue
        look.look = sim.look
        look.mouth = app.talking && mood != .endormi ? CGFloat(0.5 + 0.5 * sin(sim.time * 22)) : 0
        look.heart = sim.heart
        look.square = sim.square
        look.puddle = sim.puddle
        look.sq = sim.sq
        look.heat = sim.heat
        look.camo = sim.camo
        look.camoColor = sky.bottom
        look.time = sim.time
        look.wobble = 0.012 + min(0.03, hypot(sim.vel.x, sim.vel.y) / 40000)
        BobRenderer.draw(ctx, at: sim.pos, width: sim.bodyW, look: look)

        for p in sim.particles { Backdrop.particle(ctx, p) }
    }
}
