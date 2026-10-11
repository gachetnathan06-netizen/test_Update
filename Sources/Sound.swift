import AVFoundation
import UIKit

/// Banque de sons de BOB : fichiers WAV (Sources/Sounds), lecture par pool de lecteurs,
/// mixés avec la musique de l'utilisateur (catégorie .ambient).
enum SFX: String, CaseIterable {
    case poke, poke2, poke3, poke4, hug, eat, boing, levelup, achievement, coin, skin, equip
    case sleep, wake, fanfare, focus_start, break_start, land_soft, land_hard, whoosh, bounce
    case swish, rim, miss, streak, launch, tick, toast, reminder, growl, battery, hot, music
    case headphones, talk, shutter, deny
    case season_noel, season_halloween, season_sakura, season_ete

    static var pokes: [SFX] { [.poke, .poke2, .poke3, .poke4] }
}

final class Sound {
    static let shared = Sound()
    static var enabled = true
    static var volume: Float = 0.8

    private var pools: [SFX: [AVAudioPlayer]] = [:]
    private var next: [SFX: Int] = [:]
    private var last: [SFX: TimeInterval] = [:]
    private let queue = DispatchQueue(label: "bob.sfx", qos: .userInitiated)

    private init() {}

    func preload() {
        queue.async { [self] in
            for fx in SFX.allCases {
                guard let url = Bundle.main.url(forResource: fx.rawValue, withExtension: "wav") else { continue }
                let n = (fx == .talk || fx == .tick) ? 4 : 2
                var list: [AVAudioPlayer] = []
                for _ in 0..<n {
                    if let p = try? AVAudioPlayer(contentsOf: url) {
                        p.enableRate = true
                        p.prepareToPlay()
                        list.append(p)
                    }
                }
                pools[fx] = list
            }
        }
    }

    /// Joue un son. `rate` change la hauteur (0.5–2), `gain` le volume relatif, `gap` évite les rafales.
    func play(_ fx: SFX, rate: Float = 1, gain: Float = 1, gap: TimeInterval = 0.03) {
        guard Sound.enabled, Sound.volume > 0.001 else { return }
        let now = CACurrentMediaTime()
        queue.async { [self] in
            if let l = last[fx], now - l < gap { return }
            last[fx] = now
            guard let list = pools[fx], !list.isEmpty else { return }
            let i = (next[fx] ?? 0) % list.count
            next[fx] = i + 1
            let p = list[i]
            p.stop()
            p.currentTime = 0
            p.rate = min(2, max(0.5, rate))
            p.volume = min(1, Sound.volume * gain)
            p.play()
        }
    }

    func poke() { play(SFX.pokes.randomElement() ?? .poke, rate: Float.random(in: 0.94...1.08), gap: 0.06) }

    /// Atterrissage : volume et grain selon la force de l'impact.
    func land(_ impact: CGFloat) {
        let k = Float(min(1, impact / 1600))
        play(impact > 900 ? .land_hard : .land_soft, rate: Float.random(in: 0.92...1.08), gain: 0.45 + 0.55 * k, gap: 0.08)
    }

    /// Petit « blip » de parole, hauteur selon l'humeur.
    func talk(mood: Mood) {
        let base: Float
        switch mood {
        case .triste, .ennuye, .affame: base = 0.82
        case .heureux, .amoureux, .surpris: base = 1.18
        case .endormi: base = 0.7
        default: base = 1.0
        }
        play(.talk, rate: base * Float.random(in: 0.9...1.12), gain: 0.55, gap: 0.045)
    }

    func season(_ s: Season?) {
        switch s {
        case .noel?: play(.season_noel)
        case .halloween?: play(.season_halloween)
        case .printemps?: play(.season_sakura)
        case .ete?: play(.season_ete)
        case nil: play(.skin)
        }
    }
}
