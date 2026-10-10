import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: 1)
    }
}

enum Pattern { case none, scales, polka, stars, stripes }
enum Decor { case none, hood, ninja }
enum Slot { case head, eyes, ears, neck }

enum Acc: String, CaseIterable, Identifiable {
    case bobHat, crown, beret, glasses, headphones, bowtie
    var id: String { rawValue }
    var label: String {
        switch self {
        case .bobHat: return "Chapeau Bob"
        case .crown: return "Couronne"
        case .beret: return "Béret"
        case .glasses: return "Lunettes"
        case .headphones: return "Casque"
        case .bowtie: return "Nœud pap'"
        }
    }
    var emoji: String {
        switch self {
        case .bobHat: return "🧢"
        case .crown: return "👑"
        case .beret: return "🎨"
        case .glasses: return "🕶️"
        case .headphones: return "🎧"
        case .bowtie: return "🎀"
        }
    }
    var slot: Slot {
        switch self {
        case .bobHat, .crown, .beret: return .head
        case .glasses: return .eyes
        case .headphones: return .ears
        case .bowtie: return .neck
        }
    }
}

enum Mood: String, CaseIterable, Identifiable {
    case happy, love, sleepy, surprised, focus
    var id: String { rawValue }
    var label: String {
        switch self {
        case .happy: return "Joyeux"
        case .love: return "Amoureux"
        case .sleepy: return "Sommeil"
        case .surprised: return "Surpris"
        case .focus: return "Focus"
        }
    }
    var emoji: String {
        switch self {
        case .happy: return "😄"
        case .love: return "😍"
        case .sleepy: return "😴"
        case .surprised: return "😮"
        case .focus: return "🎯"
        }
    }
}

struct Skin: Identifiable {
    let id: String
    let name: String
    let light: Color
    let base: Color
    let dark: Color
    let cheek: Color
    var pattern: Pattern = .none
    var patternColor: Color = .white
    var decor: Decor = .none
    var decorColor: Color = Color(hex: 0x231B2E)
    var ink: Color = Color(hex: 0x1E2233)
}

enum Skins {
    static let all: [Skin] = [
        Skin(id: "classique", name: "Classique", light: Color(hex: 0x9FE3FF), base: Color(hex: 0x4FB7F5), dark: Color(hex: 0x2B7FD0), cheek: Color(hex: 0xFF8FB1)),
        Skin(id: "dore", name: "Doré", light: Color(hex: 0xFFF3B8), base: Color(hex: 0xFFCB45), dark: Color(hex: 0xD28F12), cheek: Color(hex: 0xFF9E80), pattern: .stars),
        Skin(id: "pirate", name: "Pirate", light: Color(hex: 0xFFFFFF), base: Color(hex: 0xF1EBDD), dark: Color(hex: 0xC9BFA8), cheek: Color(hex: 0xFF9A9A), pattern: .stripes, patternColor: Color(hex: 0x2A4A8C)),
        Skin(id: "sakura", name: "Sakura", light: Color(hex: 0xFFE6F0), base: Color(hex: 0xFFB3CE), dark: Color(hex: 0xE97FA6), cheek: Color(hex: 0xFF6F9C), pattern: .polka),
        Skin(id: "ocean", name: "Océan", light: Color(hex: 0x9CF3E8), base: Color(hex: 0x22C3C3), dark: Color(hex: 0x0E7C97), cheek: Color(hex: 0xFF9EB5), pattern: .scales),
        Skin(id: "miel", name: "Miel", light: Color(hex: 0xFFE394), base: Color(hex: 0xF5B82E), dark: Color(hex: 0xB9770E), cheek: Color(hex: 0xFF9A7A), pattern: .stripes, patternColor: Color(hex: 0x3B2A14)),
        Skin(id: "espace", name: "Espace", light: Color(hex: 0x9A88FF), base: Color(hex: 0x4B3AA8), dark: Color(hex: 0x241A5E), cheek: Color(hex: 0xFF7FB0), pattern: .stars),
        Skin(id: "ninja", name: "Ninja", light: Color(hex: 0x566074), base: Color(hex: 0x2C3345), dark: Color(hex: 0x14171F), cheek: Color(hex: 0xFF6B6B), decor: .ninja, decorColor: Color(hex: 0x0B0D13), ink: Color(hex: 0xE8ECF5)),
        Skin(id: "gardien", name: "Gardien", light: Color(hex: 0x8DDC8A), base: Color(hex: 0x2F9E5B), dark: Color(hex: 0x14633A), cheek: Color(hex: 0xFFB07A), pattern: .scales, patternColor: Color(hex: 0xFFD35A), decor: .hood),
        Skin(id: "gardien_ocean", name: "Gardien Océan", light: Color(hex: 0x8FE3F0), base: Color(hex: 0x2A9BC4), dark: Color(hex: 0x14587E), cheek: Color(hex: 0xFFB0B8), pattern: .scales, patternColor: Color(hex: 0xDDE8F2), decor: .hood, decorColor: Color(hex: 0x14233A)),
        Skin(id: "gardien_braise", name: "Gardien Braise", light: Color(hex: 0xFF9C7A), base: Color(hex: 0xD9432F), dark: Color(hex: 0x86201A), cheek: Color(hex: 0xFFC09A), pattern: .scales, patternColor: Color(hex: 0xE0A33A), decor: .hood, decorColor: Color(hex: 0x2A1416))
    ]
}

final class Bob: ObservableObject {
    static let shared = Bob()
    @Published private(set) var skinId: String
    @Published private(set) var mood: Mood
    @Published private(set) var accs: Set<Acc>

    private let d = UserDefaults.standard

    private init() {
        skinId = UserDefaults.standard.string(forKey: "skin") ?? "classique"
        mood = Mood(rawValue: UserDefaults.standard.string(forKey: "mood") ?? "") ?? .happy
        let names = UserDefaults.standard.stringArray(forKey: "accs") ?? []
        accs = Set(names.compactMap { Acc(rawValue: $0) })
    }

    var skin: Skin { Skins.all.first { $0.id == skinId } ?? Skins.all[0] }

    func pickSkin(_ id: String) { skinId = id; d.set(id, forKey: "skin") }
    func pickMood(_ m: Mood) { mood = m; d.set(m.rawValue, forKey: "mood") }
    func toggle(_ a: Acc) {
        if accs.contains(a) { accs.remove(a) }
        else {
            accs = accs.filter { $0.slot != a.slot }
            accs.insert(a)
        }
        d.set(accs.map { $0.rawValue }, forKey: "accs")
    }
}

enum Dialogue {
    private static func pick(_ l: [String]) -> String { l.randomElement() ?? "" }
    static func greet() -> String { pick(["Coucou ! Je suis BOB 👋", "Te revoilà ! 💙", "Prêt pour une belle journée ?"]) }
    static func pat() -> String { pick(["Hihi ! 💕", "Encore, encore !", "Ça chatouille ~", "Moi aussi je t'aime bien !", "Mmmh, c'est doux…", "Wouiii ✨"]) }
    static func hop() -> String { pick(["Hop !", "Boing !", "Wouaaah !"]) }
    static func idle(_ m: Mood) -> String {
        switch m {
        case .happy: return pick(["Tu fais du super boulot 💪", "Pense à t'hydrater 💧", "Une petite pause ?", "Je veille sur toi 👀", "Touche-moi, je ne mords pas !"])
        case .love: return pick(["Tu es mon humain préféré 💖", "Câlin ? 🥰", "Je rougis…"])
        case .sleepy: return pick(["Zzz… encore 5 minutes…", "*bâille*", "Je rêve de gelée…"])
        case .surprised: return pick(["Oh ! Quoi ?!", "Tu as vu ça ?!", "Waouh !"])
        case .focus: return pick(["Concentration… 🎯", "Un truc à la fois.", "Tu gères. Continue."])
        }
    }
}
