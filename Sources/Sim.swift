import SwiftUI

struct Particle {
    enum Kind { case heart, spark, crumb, zzz, sweat, confetti, emoji }
    var kind: Kind
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var life: Double
    var size: CGFloat
    var gravity: CGFloat = 0
    var color: Color = .white
    var text: String = ""
    var age: Double = 0
    var rot: Double = 0
    var spin: Double = 0
}

struct TrailDot { var p: CGPoint; var age: Double }

final class BobSim {
    var stage = CGSize(width: 390, height: 700)
    var pos = CGPoint(x: 195, y: 520)
    var vel = CGPoint.zero
    var dragging = false
    var grab = CGPoint.zero
    var sq: CGFloat = 0
    var sqv: CGFloat = 0
    var blinkT: Double = 0
    var nextBlink: Double = 2.5
    var look = CGPoint.zero
    var lookTarget = CGPoint.zero
    var nextLook: Double = 1.5
    var heart: CGFloat = 0
    var square: CGFloat = 0
    var puddle: CGFloat = 0
    var heat: CGFloat = 0
    var camo: CGFloat = 0
    var targetHeart: CGFloat = 0
    var targetSquare: CGFloat = 0
    var targetPuddle: CGFloat = 0
    var wantHeat = false
    var wantCamo = false
    var touchDown = false
    var touchStart: Date?
    var touchOrigin = CGPoint.zero
    var touchLoc = CGPoint.zero
    var patting = false
    var autoPatUntil = Date.distantPast
    var tempMood: Mood?
    var tempUntil = Date.distantPast
    var particles: [Particle] = []
    var trail: [TrailDot] = []
    var last: Date?
    var time: Double = 0
    var initialized = false
    var gravityOn = true
    var trailOn = true
    var bounceMusic = false
    var sleeping = false
    var musicBeat: Double = 0
    var hopsLeft = 0
    var lastTrail: Double = 0
    var patTimer: Double = 0
    var heartTimer: Double = 0
    var sweatTimer: Double = 0
    var zzzTimer: Double = 0
    var idle: Double = 0
    var lastSample: (p: CGPoint, t: Date)?
    var onLand: ((CGFloat) -> Void)?
    var onPoke: (() -> Void)?
    var onPat: (() -> Void)?
    var onThrow: ((CGFloat) -> Void)?
    var onWall: ((CGFloat) -> Void)?
    var tailColor: Color = .white

    var bodyW: CGFloat { min(stage.width * 0.56, 240) }
    var bodyH: CGFloat { bodyW * 0.92 }
    var floorY: CGFloat { stage.height * 0.74 }
    var topLimit: CGFloat { 110 + bodyH }

    func currentTemp(_ now: Date) -> Mood? { now < tempUntil ? tempMood : nil }
    func setTemp(_ m: Mood, _ secs: Double, now: Date) { tempMood = m; tempUntil = now.addingTimeInterval(secs) }

    func hit(_ p: CGPoint) -> Bool {
        let r = CGRect(x: pos.x - bodyW * 0.58, y: pos.y - bodyH * 1.12, width: bodyW * 1.16, height: bodyH * 1.2)
        return r.contains(p)
    }

    // MARK: Toucher
    func beginTouch(_ p: CGPoint, now: Date) {
        touchDown = true
        touchStart = now
        touchOrigin = p
        touchLoc = p
        patting = false
        grab = CGPoint(x: pos.x - p.x, y: pos.y - p.y)
        lastSample = (p, now)
        idle = 0
    }
    func moveTouch(_ p: CGPoint, now: Date) {
        touchLoc = p
        idle = 0
        if !dragging && hypot(p.x - touchOrigin.x, p.y - touchOrigin.y) > 14 {
            dragging = true
            patting = false
            vel = .zero
        }
        guard dragging else { return }
        let half = bodyW / 2
        pos.x = min(max(p.x + grab.x, half), stage.width - half)
        pos.y = min(max(p.y + grab.y, topLimit), floorY + 30)
        if let ls = lastSample {
            let dt = now.timeIntervalSince(ls.t)
            if dt > 0.016 {
                let v = CGPoint(x: (p.x - ls.p.x) / CGFloat(dt), y: (p.y - ls.p.y) / CGFloat(dt))
                vel = CGPoint(x: vel.x * 0.5 + v.x * 0.5, y: vel.y * 0.5 + v.y * 0.5)
                lastSample = (p, now)
            }
        }
    }
    func endTouch(now: Date) {
        let dur = now.timeIntervalSince(touchStart ?? now)
        if dragging {
            dragging = false
            let sp = hypot(vel.x, vel.y)
            if sp > 650 { onThrow?(sp) }
            vel.x = min(max(vel.x, -1800), 1800)
            vel.y = min(max(vel.y, -1800), 1800)
            if !gravityOn { vel.x *= 0.6; vel.y *= 0.6 }
        } else if !patting && dur < 0.35 {
            poke(now: now)
        }
        touchDown = false
        patting = false
    }

    func poke(now: Date) {
        sqv += 7
        sq = 0.12
        vel.y = -280
        setTemp(.surpris, 0.9, now: now)
        burst(.spark, 5, at: CGPoint(x: pos.x, y: pos.y - bodyH * 0.6), color: Color(hex: 0xFFE27A), speed: 160, size: 6...10, life: 0.5...0.8, gravity: 0)
        onPoke?()
    }

    // MARK: Évènements
    func handle(_ e: StageEvent, now: Date) {
        idle = 0
        let c = CGPoint(x: pos.x, y: pos.y - bodyH * 0.5)
        switch e {
        case .eat(let emoji):
            var p = Particle(kind: .emoji, x: pos.x, y: pos.y - bodyH * 1.5, vx: 0, vy: 160, life: 0.55, size: 34)
            p.text = emoji
            particles.append(p)
            setTemp(.heureux, 2.2, now: now)
            sqv += 5
            burst(.crumb, 8, at: CGPoint(x: pos.x, y: pos.y - bodyH * 0.35), color: Color(hex: 0xC99A5B), speed: 140, size: 3...5, life: 0.6...1.0, gravity: 500)
        case .hug:
            autoPatUntil = now.addingTimeInterval(3.5)
            burst(.heart, 8, at: CGPoint(x: pos.x, y: pos.y - bodyH * 1.0), color: Color(hex: 0xFF5C8A), speed: 120, size: 12...20, life: 1.0...1.6, gravity: -60)
        case .play:
            hopsLeft = 3
            setTemp(.heureux, 3, now: now)
            burst(.confetti, 26, at: c, color: .white, speed: 380, size: 5...8, life: 1.1...1.8, gravity: 520)
        case .confetti, .levelUp:
            burst(.confetti, 36, at: c, color: .white, speed: 420, size: 5...8, life: 1.2...2.0, gravity: 520)
        case .changedSkin:
            sq = 0.2
            sqv = 5
            burst(.spark, 14, at: c, color: Color(hex: 0xFFF3B0), speed: 220, size: 8...14, life: 0.5...0.9, gravity: 0)
        case .sleep:
            sq = 0.1
        case .wake:
            sqv += 6
            vel.y = -320
        }
    }

    func burst(_ kind: Particle.Kind, _ n: Int, at p: CGPoint, color: Color, speed: CGFloat,
               size: ClosedRange<CGFloat>, life: ClosedRange<Double>, gravity: CGFloat) {
        let palette: [Color] = [Color(hex: 0xFF7A90), Color(hex: 0x6EE7B7), Color(hex: 0x7CC4FF), Color(hex: 0xFFB547), Color(hex: 0xB794F4)]
        for _ in 0..<n {
            let a = CGFloat.random(in: 0..<(2 * .pi))
            let sp = speed * CGFloat.random(in: 0.4...1)
            var q = Particle(kind: kind, x: p.x, y: p.y, vx: cos(a) * sp, vy: sin(a) * sp - (kind == .confetti ? speed * 0.5 : 0),
                             life: Double.random(in: life), size: CGFloat.random(in: size), gravity: gravity, color: color)
            if kind == .confetti { q.color = palette.randomElement() ?? .white }
            q.rot = Double.random(in: 0..<6.28)
            q.spin = Double.random(in: -8...8)
            particles.append(q)
        }
    }

    // MARK: Étape
    func step(_ date: Date, mood: Mood) {
        let raw = last.map { date.timeIntervalSince($0) } ?? 0.016
        last = date
        let dt = CGFloat(min(max(raw, 0.001), 0.05))
        let dd = Double(dt)
        time += dd
        idle += dd
        if !initialized { pos = CGPoint(x: stage.width / 2, y: floorY); initialized = true }

        if touchDown, !dragging, let ts = touchStart, date.timeIntervalSince(ts) > 0.35 { patting = true }
        let isPat = patting || date < autoPatUntil
        let half = bodyW / 2

        // physique
        if dragging {
            // position pilotée par le doigt
        } else if gravityOn {
            vel.y += 2400 * dt
            pos.x += vel.x * dt
            pos.y += vel.y * dt
            if pos.x < half { if vel.x < -380 { onWall?(abs(vel.x)) }; pos.x = half; vel.x = abs(vel.x) * 0.55 }
            if pos.x > stage.width - half { if vel.x > 380 { onWall?(abs(vel.x)) }; pos.x = stage.width - half; vel.x = -abs(vel.x) * 0.55 }
            if pos.y < topLimit { pos.y = topLimit; vel.y = abs(vel.y) * 0.4 }
            if pos.y >= floorY {
                let impact = vel.y
                pos.y = floorY
                if impact > 140 {
                    sq = min(0.36, impact / 2600)
                    sqv = 0
                    onLand?(impact)
                    vel.y = impact > 380 ? -impact * 0.32 : 0
                } else {
                    vel.y = 0
                }
                vel.x *= 0.82
            }
        } else {
            pos.x += vel.x * dt
            pos.y += vel.y * dt
            vel.x *= max(0, 1 - 4 * dt)
            vel.y *= max(0, 1 - 4 * dt)
            pos.x = min(max(pos.x, half), stage.width - half)
            pos.y = min(max(pos.y, topLimit), floorY)
        }
        let onGround = pos.y >= floorY - 1 && abs(vel.y) < 8
        if bounceMusic && onGround && !dragging && !sleeping {
            musicBeat -= dd
            if musicBeat <= 0 { vel.y = -480; musicBeat = 0.55 }
        }
        if hopsLeft > 0 && onGround && !dragging {
            vel.y = -780
            hopsLeft -= 1
            sqv += 3
        }

        // ressort écrasement
        let acc = -220 * sq - 14 * sqv
        sqv += acc * dt
        sq += sqv * dt
        sq = min(max(sq, -0.3), 0.45)

        // clignement
        nextBlink -= dd
        if nextBlink <= 0 { blinkT = 0.16; nextBlink = Double.random(in: 2...5.5) }
        if blinkT > 0 { blinkT -= dd }

        // regard
        if touchDown {
            let dx = touchLoc.x - pos.x
            let dy = touchLoc.y - (pos.y - bodyH * 0.5)
            let m = max(1, hypot(dx, dy))
            lookTarget = CGPoint(x: dx / m, y: dy / m)
        } else {
            nextLook -= dd
            if nextLook <= 0 {
                lookTarget = CGPoint(x: CGFloat.random(in: -1...1), y: CGFloat.random(in: -0.5...0.6))
                nextLook = Double.random(in: 1.5...4)
            }
        }
        let k = min(1, dt * 8)
        look = CGPoint(x: look.x + (lookTarget.x - look.x) * k, y: look.y + (lookTarget.y - look.y) * k)

        // morphs
        let mk = min(1, dt * 7)
        targetHeart = isPat || mood == .amoureux ? 1 : targetHeart
        heart += ((isPat || mood == .amoureux ? 1 : 0) - heart) * mk
        square += (targetSquare - square) * mk
        puddle += (targetPuddle - puddle) * mk
        heat += ((wantHeat ? 1 : 0) - heat) * min(1, dt * 3)
        camo += ((wantCamo && idle > 6 && !dragging ? 0.6 : 0) - camo) * min(1, dt * 2)

        // câlin
        if isPat {
            patTimer -= dd
            heartTimer -= dd
            if patTimer <= 0 { patTimer = 0.5; onPat?() }
            if heartTimer <= 0 {
                heartTimer = 0.28
                var h = Particle(kind: .heart, x: pos.x + CGFloat.random(in: -bodyW * 0.3...bodyW * 0.3), y: pos.y - bodyH * 1.05,
                                 vx: CGFloat.random(in: -20...20), vy: -70, life: 1.3, size: CGFloat.random(in: 12...20), gravity: 0)
                h.color = Color(hex: 0xFF5C8A)
                particles.append(h)
            }
        }
        // sueur / zzz
        if mood == .surchauffe {
            sweatTimer -= dd
            if sweatTimer <= 0 {
                sweatTimer = 0.45
                var s = Particle(kind: .sweat, x: pos.x + CGFloat.random(in: -bodyW * 0.4...bodyW * 0.4), y: pos.y - bodyH * 0.85,
                                 vx: CGFloat.random(in: -25...25), vy: -40, life: 0.9, size: 9, gravity: 300)
                s.color = Color(hex: 0x7CC4FF)
                particles.append(s)
            }
        }
        if mood == .endormi {
            zzzTimer -= dd
            if zzzTimer <= 0 {
                zzzTimer = 1.4
                var z = Particle(kind: .zzz, x: pos.x + bodyW * 0.3, y: pos.y - bodyH * 0.95, vx: 14, vy: -34, life: 2.2, size: 20)
                z.color = .white
                particles.append(z)
            }
        }

        // traînée
        let speed = hypot(vel.x, vel.y)
        if trailOn && speed > 90 && time - lastTrail > 0.03 {
            lastTrail = time
            trail.append(TrailDot(p: CGPoint(x: pos.x, y: pos.y - 8), age: 0))
        }
        for i in trail.indices { trail[i].age += dd }
        trail.removeAll { $0.age > 1.1 }

        // particules
        for i in particles.indices {
            particles[i].age += dd
            particles[i].x += particles[i].vx * dt
            particles[i].y += particles[i].vy * dt
            particles[i].vy += particles[i].gravity * dt
            particles[i].rot += particles[i].spin * dd
        }
        particles.removeAll { $0.age > $0.life }
    }

    var blinkValue: CGFloat {
        guard blinkT > 0 else { return 0 }
        let ph = 1 - blinkT / 0.16
        return CGFloat(sin(Double.pi * ph))
    }
}
