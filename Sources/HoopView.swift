import SwiftUI

final class HoopSim {
    var size = CGSize(width: 390, height: 700)
    var ball = CGPoint.zero
    var vel = CGPoint.zero
    var flying = false
    var scoredThis = false
    var rimHit = false
    var prevY: CGFloat = 0
    var score = 0
    var streak = 0
    var time: Double = 0
    var last: Date?
    var respawn: Double = 0
    var spawnScale: CGFloat = 1
    var aim: CGPoint? = nil
    var dragStart: CGPoint? = nil
    var grabbing = false
    var bobMood: Mood = .content
    var bobUntil: Double = 0
    var parts: [Particle] = []
    var rimWobble: CGFloat = 0
    var onScore: ((Int, Bool) -> Void)?
    var onMiss: (() -> Void)?
    let r: CGFloat = 18
    let g: CGFloat = 1750

    var home: CGPoint { CGPoint(x: size.width / 2, y: size.height * 0.80) }
    var rimY: CGFloat { size.height * 0.32 }
    var hoopX: CGFloat {
        let amp = min(size.width * 0.28, CGFloat(score) * 7)
        return size.width / 2 + CGFloat(sin(time * 0.9)) * amp
    }
    let rimHalf: CGFloat = 46

    func reset() {
        ball = home
        vel = .zero
        flying = false
        scoredThis = false
        rimHit = false
        spawnScale = 0
    }

    func step(_ date: Date) {
        let raw = last.map { date.timeIntervalSince($0) } ?? 0.016
        last = date
        let dt = CGFloat(min(max(raw, 0.001), 0.033))
        time += Double(dt)
        if ball == .zero { reset() }
        spawnScale = min(1, spawnScale + dt * 4)
        rimWobble *= max(0, 1 - 6 * dt)
        if time > bobUntil { bobMood = .content }

        if flying {
            prevY = ball.y
            vel.y += g * dt
            ball.x += vel.x * dt
            ball.y += vel.y * dt
            let hx = hoopX
            for rx in [hx - rimHalf, hx + rimHalf] {
                let d = CGPoint(x: ball.x - rx, y: ball.y - rimY)
                let dist = hypot(d.x, d.y)
                if dist < r + 4 && dist > 0.01 {
                    let n = CGPoint(x: d.x / dist, y: d.y / dist)
                    ball.x = rx + n.x * (r + 4)
                    ball.y = rimY + n.y * (r + 4)
                    let dot = vel.x * n.x + vel.y * n.y
                    if dot < 0 {
                        vel.x = (vel.x - 2 * dot * n.x) * 0.62
                        vel.y = (vel.y - 2 * dot * n.y) * 0.62
                        rimHit = true
                        rimWobble = 1
                        Haptics.impact(.light, 0.6)
                        Sound.shared.play(.rim, rate: Float.random(in: 0.92...1.1), gap: 0.08)
                    }
                }
            }
            if ball.x < r { ball.x = r; vel.x = abs(vel.x) * 0.6 }
            if ball.x > size.width - r { ball.x = size.width - r; vel.x = -abs(vel.x) * 0.6 }
            if !scoredThis && prevY < rimY && ball.y >= rimY && vel.y > 0 && abs(ball.x - hx) < rimHalf - 6 {
                scoredThis = true
                score += 1
                streak += 1
                let clean = !rimHit
                bobMood = .heureux
                bobUntil = time + 1.6
                rimWobble = 0.6
                confetti(at: CGPoint(x: hx, y: rimY + 20), n: clean ? 30 : 16)
                onScore?(streak, clean)
            }
            if ball.y > size.height + 60 {
                if !scoredThis { streak = 0; bobMood = .ennuye; bobUntil = time + 1.5; onMiss?() }
                reset()
            }
        }
        for i in parts.indices {
            parts[i].age += Double(dt)
            parts[i].x += parts[i].vx * dt
            parts[i].y += parts[i].vy * dt
            parts[i].vy += parts[i].gravity * dt
            parts[i].rot += parts[i].spin * Double(dt)
        }
        parts.removeAll { $0.age > $0.life }
    }

    func confetti(at p: CGPoint, n: Int) {
        let pal: [UInt32] = [0xFF7A90, 0x6EE7B7, 0x7CC4FF, 0xFFB547, 0xB794F4]
        for _ in 0..<n {
            let a = CGFloat.random(in: 0..<(2 * .pi))
            let sp = CGFloat.random(in: 120...380)
            var q = Particle(kind: .confetti, x: p.x, y: p.y, vx: cos(a) * sp, vy: sin(a) * sp - 200, life: Double.random(in: 1...1.8), size: CGFloat.random(in: 5...8), gravity: 600)
            q.color = Color(hex: pal.randomElement() ?? 0xFFFFFF)
            q.rot = Double.random(in: 0..<6)
            q.spin = Double.random(in: -8...8)
            parts.append(q)
        }
    }

    func trajectory(_ v: CGPoint) -> [CGPoint] {
        var pts: [CGPoint] = []
        var p = ball
        var vv = v
        for _ in 0..<26 {
            vv.y += g * 0.035
            p.x += vv.x * 0.035
            p.y += vv.y * 0.035
            pts.append(p)
        }
        return pts
    }

    func launchVelocity(_ t: CGSize) -> CGPoint {
        var v = CGPoint(x: t.width * 5.2 * 0.7, y: t.height * 5.2)
        let m = hypot(v.x, v.y)
        if m > 1750 { v = CGPoint(x: v.x / m * 1750, y: v.y / m * 1750) }
        return v
    }
}

struct HoopView: View {
    @EnvironmentObject var app: AppState
    @State private var sim = HoopSim()
    @State private var hudScore = 0
    @State private var hudStreak = 0

    var body: some View {
        ZStack {
            AnimatedCanvas { ctx, size, date in
                sim.size = size
                sim.step(date)
                draw(ctx, size, date)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        if sim.dragStart == nil {
                            sim.dragStart = v.startLocation
                            sim.grabbing = !sim.flying && hypot(v.startLocation.x - sim.ball.x, v.startLocation.y - sim.ball.y) < 70
                        }
                        if sim.grabbing {
                            let t = CGSize(width: v.location.x - v.startLocation.x, height: v.location.y - v.startLocation.y)
                            sim.aim = t.height < -20 ? sim.launchVelocity(t) : nil
                        }
                    }
                    .onEnded { v in
                        if sim.grabbing {
                            let t = CGSize(width: v.location.x - v.startLocation.x, height: v.location.y - v.startLocation.y)
                            if t.height < -40 {
                                sim.vel = sim.launchVelocity(t)
                                sim.flying = true
                                sim.scoredThis = false
                                sim.rimHit = false
                                Haptics.impact(.light)
                                Sound.shared.play(.launch)
                                Sound.shared.play(.whoosh, rate: 1.2, gain: 0.5)
                            }
                        }
                        sim.aim = nil
                        sim.dragStart = nil
                        sim.grabbing = false
                    }
            )

            VStack {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(hudScore)")
                            .font(Font.system(size: 64, weight: .bold, design: .rounded).monospacedDigit())
                        Text(hudStreak > 1 ? "Série de \(hudStreak)" : "Paniers")
                            .font(Theme.rounded(13, .medium)).foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Label("Record \(app.s.hoopBest)", systemImage: "star.fill")
                        Label("\(app.s.baskets) au total", systemImage: "circle.fill")
                    }
                    .font(Theme.rounded(12.5))
                    .padding(.horizontal, 12).padding(.vertical, 8).glass(14)
                }
                .padding(.horizontal, 18).padding(.top, 54)
                Spacer()
                Text("Glisse vers le haut pour lancer")
                    .font(Theme.rounded(13, .medium)).foregroundColor(.white.opacity(0.6))
                    .padding(.bottom, 12)
            }
            .foregroundColor(.white)
            .allowsHitTesting(false)
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            sim.onScore = { streak, clean in
                app.s.baskets += 1
                app.s.coins += 1 + min(streak / 3, 5) + (clean ? 1 : 0)
                if streak > app.s.hoopBest { app.s.hoopBest = streak }
                app.gain()
                app.checkAchievements()
                hudScore = sim.score
                hudStreak = streak
                Sound.shared.play(clean ? .swish : .rim)
                if streak >= 3 && streak % 3 == 0 { Sound.shared.play(.streak) }
                Haptics.success()
            }
            sim.onMiss = { hudStreak = 0; Sound.shared.play(.miss) }
            hudScore = sim.score
        }
    }

    private func draw(_ ctx: GraphicsContext, _ size: CGSize, _ date: Date) {
        let floorY = size.height * 0.86
        Backdrop.draw(ctx, size: size, floorY: floorY, date: date, time: sim.time, bodyW: 200)
        let hx = sim.hoopX
        let ry = sim.rimY
        let half = sim.rimHalf

        // panneau
        let board = CGRect(x: hx - 64, y: ry - 96, width: 128, height: 88)
        ctx.fill(Path(roundedRect: board, cornerRadius: 10), with: .color(.white.opacity(0.92)))
        ctx.stroke(Path(roundedRect: board, cornerRadius: 10), with: .color(Color(hex: 0xE5484D)), lineWidth: 3)
        ctx.stroke(Path(roundedRect: CGRect(x: hx - 26, y: ry - 52, width: 52, height: 40), cornerRadius: 4), with: .color(Color(hex: 0xE5484D)), lineWidth: 2.5)

        // balle devant/derrière filet
        let ballInNet = sim.ball.y > ry
        if !ballInNet { drawNet(ctx, hx, ry, half) }
        drawBall(ctx)
        if ballInNet { drawNet(ctx, hx, ry, half) }
        let wob = sim.rimWobble * 2
        ctx.stroke(Path(roundedRect: CGRect(x: hx - half - 3, y: ry - 2 + wob, width: half * 2 + 6, height: 5), cornerRadius: 2.5),
                   with: .color(Color(hex: 0xFF6A3D)), lineWidth: 4)

        // visée
        if let a = sim.aim {
            for (i, p) in sim.trajectory(a).enumerated() where i % 2 == 0 {
                let rr: CGFloat = 4 - CGFloat(i) * 0.1
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - rr, y: p.y - rr, width: rr * 2, height: rr * 2)), with: .color(.white.opacity(0.55 - Double(i) * 0.015)))
            }
        }
        for p in sim.parts { Backdrop.particle(ctx, p) }

        // BOB spectateur
        var l = BobLook(skin: app.skin, mood: sim.bobMood)
        l.head = app.head; l.eyes = app.eyes; l.ears = app.ears; l.neck = app.neck
        l.time = sim.time
        l.look = CGPoint(x: (sim.ball.x - 70) / size.width * 2, y: -0.4)
        l.sq = sim.bobMood == .heureux ? 0.08 * CGFloat(abs(sin(sim.time * 8))) : 0
        BobRenderer.draw(ctx, at: CGPoint(x: 62, y: floorY - 6), width: 84, look: l)
    }

    private func drawNet(_ ctx: GraphicsContext, _ hx: CGFloat, _ ry: CGFloat, _ half: CGFloat) {
        let sway = sim.rimWobble * 6
        for i in 0...6 {
            let u = CGFloat(i) / 6
            let x0 = hx - half + u * half * 2
            let x1 = hx - half * 0.55 + u * half * 1.1 + sway
            var p = Path()
            p.move(to: CGPoint(x: x0, y: ry + 2))
            p.addLine(to: CGPoint(x: x1, y: ry + 46))
            ctx.stroke(p, with: .color(.white.opacity(0.7)), lineWidth: 1.2)
        }
        for k in 1...3 {
            let t = CGFloat(k) / 4
            let y = ry + 2 + t * 44
            let w = half * (1 - 0.45 * t)
            var p = Path()
            p.move(to: CGPoint(x: hx - w + sway * t, y: y))
            p.addLine(to: CGPoint(x: hx + w + sway * t, y: y))
            ctx.stroke(p, with: .color(.white.opacity(0.5)), lineWidth: 1)
        }
    }

    private func drawBall(_ ctx: GraphicsContext) {
        let b = sim.ball
        let r = sim.r * sim.spawnScale
        let shadowY = sim.size.height * 0.86 + 6
        let lift = max(0, shadowY - b.y)
        let sw = r * 1.6 / (1 + lift / 400)
        ctx.fill(Path(ellipseIn: CGRect(x: b.x - sw, y: shadowY - sw * 0.18, width: sw * 2, height: sw * 0.36)), with: .color(.black.opacity(0.25 / (1 + lift / 300))))
        var g = ctx
        g.translateBy(x: b.x, y: b.y)
        g.rotate(by: .radians(sim.time * 2 * Double(sim.vel.x > 0 ? 1 : -1) * (sim.flying ? 1 : 0)))
        let c = Path(ellipseIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2))
        g.fill(c, with: .radialGradient(Gradient(colors: [Color(hex: 0xFFFDF6), Color(hex: 0xE4DFD2)]), center: CGPoint(x: -r * 0.3, y: -r * 0.3), startRadius: 0, endRadius: r * 1.3))
        g.stroke(c, with: .color(Color(hex: 0x8C8573, opacity: 0.6)), lineWidth: 1)
        let creases: [[(CGFloat, CGFloat)]] = [[(-0.7, -0.2), (-0.1, 0.1), (0.5, -0.5)], [(-0.4, 0.6), (0.1, 0.2), (0.7, 0.3)], [(0.0, -0.8), (-0.1, -0.2), (0.3, 0.1)]]
        for cr in creases {
            var p = Path()
            for (i, q) in cr.enumerated() {
                let pt = CGPoint(x: q.0 * r, y: q.1 * r)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            g.stroke(p, with: .color(Color(hex: 0x8C8573, opacity: 0.55)), lineWidth: 1)
        }
    }
}
