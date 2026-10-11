import SwiftUI

enum Mood: String, CaseIterable, Codable, Identifiable {
    case content, heureux, triste, endormi, surpris, amoureux, concentre, ennuye, surchauffe, affame
    var id: String { rawValue }
    var label: String {
        switch self {
        case .content: return "Content"
        case .heureux: return "Heureux"
        case .triste: return "Triste"
        case .endormi: return "Endormi"
        case .surpris: return "Surpris"
        case .amoureux: return "Amoureux"
        case .concentre: return "Concentré"
        case .ennuye: return "Ennuyé"
        case .surchauffe: return "Surchauffe"
        case .affame: return "Affamé"
        }
    }
    var symbol: String {
        switch self {
        case .content: return "face.smiling"
        case .heureux: return "sun.max.fill"
        case .triste: return "cloud.rain.fill"
        case .endormi: return "moon.zzz.fill"
        case .surpris: return "exclamationmark.bubble.fill"
        case .amoureux: return "heart.fill"
        case .concentre: return "scope"
        case .ennuye: return "hourglass"
        case .surchauffe: return "thermometer.high"
        case .affame: return "fork.knife"
        }
    }
}

enum Texture: String { case none, knit, scale, polka, harlequin, stripes, ribs }
enum Decor: String { case none, stars, sprinkles, hood }

enum PropCategory: String, CaseIterable, Identifiable {
    case tete, yeux, oreilles, cou
    var id: String { rawValue }
    var title: String {
        switch self {
        case .tete: return "Tête"
        case .yeux: return "Yeux"
        case .oreilles: return "Oreilles"
        case .cou: return "Cou"
        }
    }
}

enum Prop: String, CaseIterable, Codable, Identifiable {
    case bobHat, beret, couronne, chapeauPaille, bandana, hautDeForme, halo, couronneFleurs
    case lunettesCarrees, monocle, masqueSki, lunettesCoeur, lunettesSoleil
    case boucles, ecouteurs, cacheOreilles
    case echarpe, noeudPapillon, collier
    case bonnetNoel, bonnetLutin, etoile, couronneRoi, casque, chapeauBouffon, chapeauPirate, cacheOeil
    case fleurSakura, queueCitrouille, colVampire, crocs, bandeauNinja, scaphandre, antennesMiel
    case bonnetNuit, cicatrices, cornes, ailesDragon, coquillages, masqueHeros, cape, kabuto
    case casqueDJ, antennesAlien, casquetteDetective, perruqueClown, nezClown, bandeauBoxeur
    case ailesCupidon, casqueGladiateur, corneLicorne

    var id: String { rawValue }

    var isWearable: Bool {
        switch self {
        case .bobHat, .beret, .couronne, .chapeauPaille, .bandana, .hautDeForme, .halo, .couronneFleurs,
             .lunettesCarrees, .monocle, .masqueSki, .lunettesCoeur, .lunettesSoleil,
             .boucles, .ecouteurs, .cacheOreilles, .echarpe, .noeudPapillon, .collier:
            return true
        default: return false
        }
    }
    var category: PropCategory {
        switch self {
        case .lunettesCarrees, .monocle, .masqueSki, .lunettesCoeur, .lunettesSoleil: return .yeux
        case .boucles, .ecouteurs, .cacheOreilles: return .oreilles
        case .echarpe, .noeudPapillon, .collier: return .cou
        default: return .tete
        }
    }
    var isBehind: Bool { self == .ailesDragon || self == .cape || self == .ailesCupidon }
    var name: String {
        switch self {
        case .bobHat: return "Bob"
        case .beret: return "Béret"
        case .couronne: return "Couronne"
        case .chapeauPaille: return "Paille"
        case .bandana: return "Bandana"
        case .hautDeForme: return "Haut-de-forme"
        case .halo: return "Auréole"
        case .couronneFleurs: return "Fleurs"
        case .lunettesCarrees: return "Carrées"
        case .monocle: return "Monocle"
        case .masqueSki: return "Masque ski"
        case .lunettesCoeur: return "Cœurs"
        case .lunettesSoleil: return "Soleil"
        case .boucles: return "Boucles"
        case .ecouteurs: return "Casque"
        case .cacheOreilles: return "Cache-oreilles"
        case .echarpe: return "Écharpe"
        case .noeudPapillon: return "Nœud pap'"
        case .collier: return "Collier"
        default: return rawValue
        }
    }
    static var wearables: [Prop] { allCases.filter { $0.isWearable } }
}

struct Skin: Identifiable, Hashable {
    let id: String
    let name: String
    let packID: String
    let top: UInt32
    let bottom: UInt32
    var cheek: UInt32 = 0xFF8FA3
    var texture: Texture = .none
    var textureColor: UInt32 = 0xFFFFFF
    var decor: Decor = .none
    var signature: [Prop] = []
    var glass = false
    var camo = false
    static func == (a: Skin, b: Skin) -> Bool { a.id == b.id }
    func hash(into h: inout Hasher) { h.combine(id) }
}

enum Season: String, CaseIterable {
    case halloween, noel, printemps, ete
    var label: String {
        switch self {
        case .halloween: return "Halloween"
        case .noel: return "Noël"
        case .printemps: return "Printemps"
        case .ete: return "Été"
        }
    }
    func isActive(_ d: Date = Date()) -> Bool {
        let c = Calendar.current.dateComponents([.month, .day], from: d)
        let m = c.month ?? 1, day = c.day ?? 1
        switch self {
        case .halloween: return m == 10 || (m == 11 && day <= 2)
        case .noel: return m == 12 || (m == 1 && day <= 6)
        case .printemps: return (m == 3 && day >= 20) || m == 4 || m == 5 || (m == 6 && day < 21)
        case .ete: return (m == 6 && day >= 21) || m == 7 || m == 8 || (m == 9 && day < 23)
        }
    }
    static var current: Season? { allCases.first { $0.isActive() } }
}

struct Pack: Identifiable {
    let id: String
    let name: String
    let icon: String
    let blurb: String
    var season: Season? = nil
    var quips: [String] = []
    var skins: [Skin]
}

struct Food: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let cost: Int
    let faim: Double
    let joie: Double
    let energie: Double
}

struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let symbol: String
    let goal: Int
    let value: (Saved) -> Int
}

enum Catalog {
    static func sk(_ id: String, _ name: String, _ pack: String, _ top: UInt32, _ bottom: UInt32,
                   cheek: UInt32 = 0xFF8FA3, tex: Texture = .none, texColor: UInt32 = 0xFFFFFF,
                   decor: Decor = .none, sig: [Prop] = [], glass: Bool = false, camo: Bool = false) -> Skin {
        Skin(id: id, name: name, packID: pack, top: top, bottom: bottom, cheek: cheek, texture: tex,
             textureColor: texColor, decor: decor, signature: sig, glass: glass, camo: camo)
    }

    static func premium(_ id: String, _ name: String, _ icon: String, _ blurb: String, sig: [Prop],
                        pal: [(String, UInt32, UInt32)], tex: Texture = .none, texColor: UInt32 = 0xFFFFFF,
                        decor: Decor = .none, quips: [String]) -> Pack {
        var list: [Skin] = []
        for (i, p) in pal.enumerated() {
            list.append(sk("\(id)_\(i)", "\(name) \(p.0)", id, p.1, p.2, tex: tex, texColor: texColor, decor: decor, sig: sig))
        }
        return Pack(id: id, name: name, icon: icon, blurb: blurb, quips: quips, skins: list)
    }

    static let packs: [Pack] = [
        Pack(id: "bob", name: "Bob", icon: "drop.fill", blurb: "Le blob d'origine.", quips: ["Blop.", "Je suis un blob, et fier de l'être."], skins: [
            sk("bob_menthe", "Menthe", "bob", 0x86E0C6, 0x3FA98F),
            sk("bob_peche", "Pêche", "bob", 0xFFC9A8, 0xF08A6B),
            sk("bob_lavande", "Lavande", "bob", 0xCDB8FF, 0x8F73E0)
        ]),
        Pack(id: "dore", name: "Doré", icon: "sparkles", blurb: "Pailleté, forcément.", quips: ["Je brille, c'est pas ma faute."], skins: [
            sk("dore", "Doré", "dore", 0xFFE08A, 0xE0A100, cheek: 0xFF9E7A, decor: .stars)
        ]),
        Pack(id: "halloween", name: "Halloween", icon: "moon.stars.fill", blurb: "Frissons garantis.", season: .halloween,
             quips: ["Bouh ! … Raté ?", "Des bonbons ou un sort."], skins: [
            sk("citrouille", "Citrouille", "halloween", 0xFFA24C, 0xD9641A, tex: .ribs, texColor: 0x7A2E00, sig: [.queueCitrouille]),
            sk("vampire", "Vampire", "halloween", 0xEDE6F2, 0xB9AEC9, cheek: 0xE5707F, sig: [.colVampire, .crocs]),
            sk("fantome", "Fantôme", "halloween", 0xFFFFFF, 0xCFD8FF, cheek: 0xC9D2FF, glass: true)
        ]),
        Pack(id: "noel", name: "Noël", icon: "snowflake", blurb: "Hou hou hou.", season: .noel,
             quips: ["Tu as été sage ?", "Il neige dans mon cœur."], skins: [
            sk("pere_noel", "Père Noël", "noel", 0xFF6B6B, 0xC62828, sig: [.bonnetNoel]),
            sk("lutin", "Lutin", "noel", 0x7BE0A0, 0x2E9E5B, sig: [.bonnetLutin]),
            sk("etoile_noel", "Étoile", "noel", 0xFFF0A0, 0xFFC83D, decor: .stars, sig: [.etoile])
        ]),
        Pack(id: "laine", name: "Laine", icon: "scribble", blurb: "Tricoté main.", quips: ["Câlin tout doux."], skins: [
            sk("laine_creme", "Crème", "laine", 0xFFF1DC, 0xE8CFA6, tex: .knit, texColor: 0x8A6A3A),
            sk("laine_rouge", "Rouge", "laine", 0xFF8A8A, 0xC94545, tex: .knit, texColor: 0x5A1010),
            sk("laine_bleue", "Bleue", "laine", 0x9CC8FF, 0x4A83D6, tex: .knit, texColor: 0x10305A)
        ]),
        Pack(id: "moyen_age", name: "Moyen Âge", icon: "star.circle.fill", blurb: "Par saint Bob !", quips: ["Oyez, oyez !", "À l'assaut !"], skins: [
            sk("roi", "Roi", "moyen_age", 0xB68CFF, 0x6B3FC0, sig: [.couronneRoi]),
            sk("chevalier", "Chevalier", "moyen_age", 0xD5DCE6, 0x8E9AAB, sig: [.casque]),
            sk("bouffon", "Bouffon", "moyen_age", 0xFF7A7A, 0xE0B000, tex: .harlequin, texColor: 0xFFFFFF, sig: [.chapeauBouffon])
        ]),
        Pack(id: "teletravail", name: "Télétravailleur", icon: "laptopcomputer", blurb: "Pousse-au-crime.", quips: ["Je suis en réunion. En pyjama.", "Ceci aurait pu être un mail."], skins: [
            sk("pyjama", "Pyjama de gala", "teletravail", 0x9CC8FF, 0x4A6FD1, tex: .stripes, texColor: 0xFFFFFF, sig: [.bonnetNuit]),
            sk("fantome_expert", "Fantôme expert", "teletravail", 0xFFFFFF, 0xD6DEFF, sig: [.lunettesCarrees], glass: true),
            sk("zombie_lundi", "Zombie du lundi", "teletravail", 0xB6D68A, 0x6E9A4B, cheek: 0xA8B070, sig: [.cicatrices])
        ]),
        Pack(id: "pirate", name: "Pirate", icon: "flag.fill", blurb: "Yo ho ho.", quips: ["Où est le trésor ?", "Hisse et ho !"], skins: [
            sk("pirate", "Pirate", "pirate", 0xFF8A7A, 0xB83A2E, sig: [.chapeauPirate, .cacheOeil])
        ]),
        Pack(id: "sakura", name: "Sakura", icon: "leaf.fill", blurb: "Cerisiers en fleurs.", season: .printemps, quips: ["Les pétales dansent."], skins: [
            sk("sakura", "Sakura", "sakura", 0xFFD3E2, 0xF58FB2, sig: [.fleurSakura])
        ]),
        Pack(id: "ocean", name: "Océan", icon: "cloud.fill", blurb: "Bulles et marées.", season: .ete, quips: ["Plouf."], skins: [
            sk("ocean", "Océan", "ocean", 0x7FE0F0, 0x2A8FC0, tex: .polka, texColor: 0xFFFFFF)
        ]),
        Pack(id: "miel", name: "Miel", icon: "hexagon.fill", blurb: "Bzzz.", quips: ["Bzzz bzzz."], skins: [
            sk("miel", "Miel", "miel", 0xFFE066, 0xF2A900, tex: .stripes, texColor: 0x3A2A00, sig: [.antennesMiel])
        ]),
        Pack(id: "espace", name: "Espace", icon: "sparkles", blurb: "Houston ?", quips: ["Houston, on a un blob."], skins: [
            sk("espace", "Espace", "espace", 0x5A5FD0, 0x1D1F58, cheek: 0xB07CFF, decor: .stars, sig: [.scaphandre])
        ]),
        Pack(id: "ninja", name: "Ninja", icon: "eye.slash.fill", blurb: "Invisible. Presque.", quips: ["…", "Tu ne m'as pas vu."], skins: [
            sk("ninja", "Ninja", "ninja", 0x4A4E63, 0x1E2030, cheek: 0x6A6E88, sig: [.bandeauNinja], camo: true)
        ]),
        Pack(id: "gardien", name: "Gardien", icon: "shield.fill", blurb: "Écailles et capuche.", quips: ["Je veille."], skins: [
            sk("gardien", "Gardien", "gardien", 0x4FA05A, 0x1F5B2E, cheek: 0xE0B84A, tex: .scale, texColor: 0xE8D27A, decor: .hood),
            sk("gardien_ocean", "Gardien océan", "gardien", 0x3FB8C8, 0x1B6A8A, cheek: 0xC8D8E0, tex: .scale, texColor: 0xE0F0F8, decor: .hood),
            sk("gardien_braise", "Gardien braise", "gardien", 0xD9573B, 0x8A2A1E, cheek: 0xE0A85A, tex: .scale, texColor: 0xFFD27A, decor: .hood)
        ]),
        premium("dragon", "Dragon", "flame.fill", "Souffle chaud.", sig: [.cornes, .ailesDragon],
                pal: [("Braise", 0xFF7A59, 0xC8341F), ("Émeraude", 0x6FE3A3, 0x1E9462), ("Obsidienne", 0x7B6BA8, 0x2C2347)],
                tex: .scale, texColor: 0xFFFFFF, quips: ["Grrr. (c'est un câlin)"]),
        premium("sirene", "Sirène", "drop.triangle.fill", "Voix d'or.", sig: [.coquillages],
                pal: [("Lagon", 0x6FE0E8, 0x2A9DB8), ("Corail", 0xFF9FB0, 0xE8607E), ("Perle", 0xE8DDFF, 0xB79CE6)],
                tex: .scale, texColor: 0xFFFFFF, quips: ["La mer m'appelle."]),
        premium("heros", "Super-héros", "bolt.fill", "Sauve le bureau.", sig: [.masqueHeros, .cape],
                pal: [("Rouge", 0xFF6B6B, 0xC62828), ("Bleu", 0x6FA8FF, 0x1F4FBF), ("Doré", 0xFFD866, 0xE0A100)],
                quips: ["Pas de panique, je gère."]),
        premium("samourai", "Samouraï", "wind", "Voie du blob.", sig: [.kabuto],
                pal: [("Écarlate", 0xE5534B, 0x8E1B1B), ("Indigo", 0x5C6FD1, 0x25308A), ("Nuit", 0x6C6F7D, 0x2A2C37)],
                quips: ["L'honneur avant tout."]),
        premium("dj", "DJ", "headphones", "Drop the blob.", sig: [.casqueDJ],
                pal: [("Néon", 0xFF6AD5, 0x7A3CFF), ("Cyan", 0x5CF2F2, 0x1F6FEB), ("Volt", 0xC8FF5C, 0x2BB673)],
                decor: .sprinkles, quips: ["Monte le son !"]),
        premium("alien", "Alien", "moon.fill", "Nous venons en paix.", sig: [.antennesAlien],
                pal: [("Vert", 0x9CFF9C, 0x2FBF4F), ("Violet", 0xD6A4FF, 0x7B3FCF), ("Rose", 0xFFA6D9, 0xE0489F)],
                tex: .polka, texColor: 0xFFFFFF, quips: ["Emmène-moi à ton leader."]),
        premium("detective", "Détective", "magnifyingglass", "Élémentaire.", sig: [.casquetteDetective],
                pal: [("Tweed", 0xC9A27A, 0x8A6A45), ("Brume", 0xB5BFCB, 0x6F7C8C), ("Bordeaux", 0xC4687A, 0x7A2438)],
                quips: ["Élémentaire, mon cher."]),
        premium("clown", "Clown", "star.fill", "Haha.", sig: [.perruqueClown, .nezClown],
                pal: [("Cirque", 0xFFE45C, 0xF2A900), ("Bonbon", 0xFF9ECF, 0xE04F9B), ("Ciel", 0x7ED6FF, 0x2F8FE0)],
                tex: .polka, texColor: 0xFFFFFF, quips: ["Pouët."]),
        premium("boxeur", "Boxeur", "hand.raised.fill", "Ding ding.", sig: [.bandeauBoxeur],
                pal: [("Rouge", 0xFF7070, 0xB81D1D), ("Bleu", 0x6FB2FF, 0x1D56B8), ("Noir", 0x777B8A, 0x23252E)],
                quips: ["Round 1 !"]),
        premium("cupidon", "Cupidon", "heart.circle.fill", "Flèche d'amour.", sig: [.ailesCupidon, .halo],
                pal: [("Rose", 0xFFB3C8, 0xFF6B93), ("Blanc", 0xFFF3F6, 0xF2B6C6), ("Or", 0xFFE08A, 0xF0A8B5)],
                quips: ["L'amour est dans le pré."]),
        premium("gladiateur", "Gladiateur", "shield.lefthalf.filled", "Au nom de Rome.", sig: [.casqueGladiateur],
                pal: [("Bronze", 0xE0B070, 0xA9742F), ("Sable", 0xEBD3A0, 0xC49B54), ("Sang", 0xE07A6A, 0x8A2F2A)],
                quips: ["Es-tu diverti ?"]),
        premium("licorne", "Licorne", "wand.and.stars", "Magique.", sig: [.corneLicorne],
                pal: [("Pastel", 0xFFD1F0, 0xC9B6FF), ("Arc-en-ciel", 0xFFB3E6, 0x8FD3FF), ("Minuit", 0xA9A0FF, 0x4B3F9E)],
                decor: .stars, quips: ["Tout est brillant."]),
        premium("vacances", "Vacances", "sun.max.fill", "Cocktail et transat.", sig: [.chapeauPaille, .lunettesSoleil],
                pal: [("Tropical", 0xFFD36B, 0xFF8F3F), ("Lagon", 0x7FE8D8, 0x2AA89A), ("Coucher", 0xFF9BB0, 0xE0507A)],
                quips: ["Out of office. Pour de vrai."]),
        premium("gentleman", "Gentleman", "eyeglasses", "Distingué, jusqu'au blop.", sig: [.hautDeForme, .monocle, .noeudPapillon],
                pal: [("Smoking", 0x6B6F85, 0x24263A), ("Bordeaux", 0xB5546B, 0x5A1830), ("Ivoire", 0xF3E8D2, 0xC9B48A)],
                quips: ["Très chic, n'est-ce pas ?"]),
        premium("cosy", "Cosy", "cup.and.saucer.fill", "Plaid, thé et tricot.", sig: [.cacheOreilles, .echarpe],
                pal: [("Cacao", 0xD9B38C, 0x8A5A3A), ("Chantilly", 0xFFF3E6, 0xE3C9A8), ("Myrtille", 0x9AA6E8, 0x4A569E)],
                tex: .knit, texColor: 0xFFFFFF, quips: ["On reste sous le plaid ?"]),
        premium("rock", "Rockstar", "music.note", "Sold out ce soir.", sig: [.bandana, .lunettesSoleil],
                pal: [("Noir", 0x5A5E70, 0x1B1C26), ("Électrique", 0x6FE0FF, 0x2A55E0), ("Magenta", 0xFF6AC0, 0x8A1F6E)],
                decor: .stars, quips: ["Un, deux, trois, quatre !"]),
        premium("bonbon", "Bonbon", "gift.fill", "Sucré à en fondre.", sig: [],
                pal: [("Fraise", 0xFF9FB8, 0xE8507A), ("Menthe choc", 0x9CF0D0, 0x4A8A74), ("Barbe à papa", 0xD6B8FF, 0x8FD0FF)],
                tex: .polka, texColor: 0xFFFFFF, decor: .sprinkles, quips: ["J'ai pris un sucre de plus."]),
        premium("cyber", "Cyber", "cpu", "Connecté. Trop, peut-être.", sig: [.lunettesCarrees, .ecouteurs],
                pal: [("Néon", 0xFF5CE1, 0x5A2BFF), ("Matrix", 0x7CFF9C, 0x0F6B3A), ("Chrome", 0xCFD8E6, 0x6F7C8C)],
                tex: .stripes, texColor: 0xFFFFFF, quips: ["Chargement… blop."])
    ]

    static let allSkins: [Skin] = packs.flatMap { $0.skins }
    static func skin(_ id: String) -> Skin { allSkins.first { $0.id == id } ?? allSkins[0] }
    static func pack(_ id: String) -> Pack? { packs.first { $0.id == id } }

    /// Prix d'un pack (DLC) en pièces. Le pack "bob" est offert.
    static func price(_ p: Pack) -> Int {
        switch p.id {
        case "bob": return 0
        case "dore": return 60
        case "dragon", "sirene", "heros", "samourai", "dj", "alien", "detective", "clown", "boxeur", "cupidon", "gladiateur", "licorne", "vacances", "gentleman", "cosy", "rock", "bonbon", "cyber": return 120
        default: return p.season != nil ? 60 : 80
        }
    }

    static let foods: [Food] = [
        Food(id: "pomme", name: "Pomme", emoji: "🍎", cost: 2, faim: 14, joie: 2, energie: 2),
        Food(id: "cookie", name: "Cookie", emoji: "🍪", cost: 4, faim: 22, joie: 10, energie: 3),
        Food(id: "cafe", name: "Café", emoji: "☕️", cost: 6, faim: 4, joie: 4, energie: 28),
        Food(id: "pizza", name: "Pizza", emoji: "🍕", cost: 10, faim: 42, joie: 12, energie: 6),
        Food(id: "gateau", name: "Gâteau", emoji: "🍰", cost: 16, faim: 28, joie: 26, energie: 6)
    ]

    static let achievements: [Achievement] = [
        Achievement(id: "feed1", title: "Premier repas", detail: "Nourris BOB", symbol: "fork.knife", goal: 1, value: { $0.fed }),
        Achievement(id: "feed25", title: "Gourmet", detail: "Nourris BOB 25 fois", symbol: "cart.fill", goal: 25, value: { $0.fed }),
        Achievement(id: "pat10", title: "Câlin facile", detail: "10 câlins", symbol: "heart.fill", goal: 10, value: { $0.pats }),
        Achievement(id: "pat100", title: "Pot de colle", detail: "100 câlins", symbol: "heart.circle.fill", goal: 100, value: { $0.pats }),
        Achievement(id: "focus1", title: "Dans la zone", detail: "Termine 1 session Focus", symbol: "scope", goal: 1, value: { $0.pomos }),
        Achievement(id: "focus10", title: "Machine", detail: "10 sessions Focus", symbol: "timer", goal: 10, value: { $0.pomos }),
        Achievement(id: "hoop5", title: "Arrosoir", detail: "5 paniers d'affilée", symbol: "circle.fill", goal: 5, value: { $0.hoopBest }),
        Achievement(id: "hoop15", title: "Stephen Blob", detail: "15 paniers d'affilée", symbol: "flame.fill", goal: 15, value: { $0.hoopBest }),
        Achievement(id: "streak3", title: "Fidèle", detail: "3 jours d'affilée", symbol: "calendar", goal: 3, value: { $0.streak }),
        Achievement(id: "streak7", title: "Inséparables", detail: "7 jours d'affilée", symbol: "calendar.badge.clock", goal: 7, value: { $0.streak }),
        Achievement(id: "style3", title: "Fashion", detail: "Porte 3 accessoires différents", symbol: "bag.fill", goal: 3, value: { $0.worn.count }),
        Achievement(id: "skins10", title: "Collectionneur", detail: "Essaie 10 skins", symbol: "square.stack.3d.up.fill", goal: 10, value: { $0.tried.count }),
        Achievement(id: "play10", title: "Joueur", detail: "Joue 10 fois", symbol: "gamecontroller.fill", goal: 10, value: { $0.plays })
    ]
}
