import SwiftUI

final class Sim {
    struct Heart { var born: CGFloat; var dx: CGFloat; var s: CGFloat }

    var t: CGFloat = 0
    var squash: CGFloat = 0
    var jump: CGFloat = 0
    var lookX: CGFloat = 0
    var lookY: CGFloat = 0
    var eyeOpen: CGFloat = 1
    var happyTimer: CGFloat = 0
    var hearts: [Heart] = []

    private var sv: CGFloat = 0
    private var jv: CGFloat = 0
    private var tx: CGFloat = 0
    private var ty: CGFloat = 0
    private var wander: CGFloat = 2
    private var nextBlink: CGFloat = 2
    private var blinkT: CGFloat = -1
    private var last: Date?

    func pat() {
        squash = 0.2; sv = 0; happyTimer = 1.4
        for _ in 0..<3 {
            hearts.append(Heart(born: t, dx: CGFloat.random(in: -0.2...0.2), s: CGFloat.random(in: 0.6...1.1)))
        }
    }

    func hop() { if jump <= 0.001 && jv <= 0 { jv = 2.3 } }

    func lookAt(_ x: CGFloat, _ y: CGFloat) {
        tx = min(max(x, -1), 1); ty = min(max(y, -1), 1); wander = 3
    }

    func tick(_ date: Date) {
        guard let l = last else { last = date; return }
        let dt = min(CGFloat(date.timeIntervalSince(l)), 0.033)
        last = date
        step(dt)
    }

    func step(_ dt: CGFloat) {
        t += dt
        sv += (-170 * squash - 11 * sv) * dt
        squash += sv * dt
        if jump > 0 || jv > 0 {
            jv -= 9.5 * dt
            jump += jv * dt
            if jump <= 0 {
                jump = 0
                if jv < -0.5 { squash = 0.24; sv = 0 }
                jv = 0
            }
        }
        wander -= dt
        if wander <= 0 {
            tx = CGFloat.random(in: -0.8...0.8)
            ty = CGFloat.random(in: -0.3...0.5)
            wander = CGFloat.random(in: 1.5...4.5)
        }
        let k = min(1, dt * 8)
        lookX += (tx - lookX) * k
        lookY += (ty - lookY) * k
        nextBlink -= dt
        if nextBlink <= 0 && blinkT < 0 { blinkT = 0 }
        if blinkT >= 0 {
            blinkT += dt
            let p = blinkT / 0.18
            if p >= 1 {
                blinkT = -1
                nextBlink = CGFloat.random(in: 1.5...5)
                eyeOpen = 1
            } else {
                eyeOpen = abs(1 - 2 * p)
            }
        }
        happyTimer = max(0, happyTimer - dt)
        hearts.removeAll { t - $0.born > 1.5 }
    }
}
