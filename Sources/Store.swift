import SwiftUI
import Combine
import UIKit
import AVFoundation
import UserNotifications
import os

struct Settings: Codable {
    var gravity = true
    var trail = true
    var morph = true
    var haptics = true
    var music = true
    var autoSleep = true
    var keepAwake = false
    var overheat = true
    var camo = true
    var notifHunger = false
    var chatter = 1
    var focusMin = 25
    var shortMin = 5
    var longMin = 15
    var sounds = true
    var volume = 0.8

    init() {}
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: K.self)
        func v<T: Decodable>(_ k: K, _ def: T) -> T { (try? c.decodeIfPresent(T.self, forKey: k)) ?? def }
        gravity = v(.gravity, true); trail = v(.trail, true); morph = v(.morph, true)
        haptics = v(.haptics, true); music = v(.music, true); autoSleep = v(.autoSleep, true)
        keepAwake = v(.keepAwake, false); overheat = v(.overheat, true); camo = v(.camo, true)
        notifHunger = v(.notifHunger, false); chatter = v(.chatter, 1)
        focusMin = v(.focusMin, 25); shortMin = v(.shortMin, 5); longMin = v(.longMin, 15)
        sounds = v(.sounds, true); volume = v(.volume, 0.8)
    }
    enum K: String, CodingKey {
        case gravity, trail, morph, haptics, music, autoSleep, keepAwake, overheat, camo, notifHunger
        case chatter, focusMin, shortMin, longMin, sounds, volume
    }
}

struct Reminder: Codable, Identifiable {
    var id = UUID()
    var title: String
    var time: Date
    var daily: Bool
    var enabled = true
}

struct Saved: Codable {
    var faim = 80.0
    var energie = 85.0
    var joie = 70.0
    var coins = 20
    var xp = 0
    var skinID = "bob_menthe"
    var disabled: [String] = []
    var head: String? = nil
    var eyes: String? = nil
    var ears: String? = nil
    var neck: String? = nil
    var sleeping = false
    var forced: String? = nil
    var reminders: [Reminder] = []
    var fed = 0
    var pats = 0
    var plays = 0
    var pomos = 0
    var baskets = 0
    var hoopBest = 0
    var streak = 0
    var lastDay = ""
    var tried: [String] = []
    var worn: [String] = []
    var unlocked: [String] = []
    // Optionnels : les anciennes sauvegardes (sans ces clés) restent lisibles.
    var pantry: [String: Int]? = nil   // stock de nourriture
    var owned: [String]? = nil          // packs (DLC) achetés
    var lastGift: String? = nil         // dernier cadeau quotidien réclamé
    var pomoToday = 0
    var pomoDay = ""
    var lastSeen = Date()
    var settings = Settings()
}

enum StageEvent {
    case eat(String), hug, play, confetti, changedSkin, sleep, wake, levelUp
}

enum PomoPhase: String {
    case focus, short, long
    var title: String {
        switch self {
        case .focus: return "Focus"
        case .short: return "Pause"
        case .long: return "Longue pause"
        }
    }
}

final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()
    func setup() { UNUserNotificationCenter.current().delegate = self }
    func request() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    func schedule(_ r: Reminder) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [r.id.uuidString])
        guard r.enabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "BOB"
        content.body = r.title
        content.sound = .default
        let comps: DateComponents
        if r.daily {
            comps = Calendar.current.dateComponents([.hour, .minute], from: r.time)
        } else {
            guard r.time > Date() else { return }
            comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: r.time)
        }
        let trig = UNCalendarNotificationTrigger(dateMatching: comps, repeats: r.daily)
        center.add(UNNotificationRequest(identifier: r.id.uuidString, content: content, trigger: trig))
    }
    func cancel(_ ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
    func once(id: String, title: String, body: String, in seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let trig = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trig))
    }
}

enum Dialogue {
    enum Key { case morning, day, evening, night, eat, hug, poke, play, wake, sleep, hungry, sad, bored, happy, idle, focusStart, focusDone, breakStart, music, headphones, battery, hot, hoop, level, skin, tired }

    static let lines: [Key: [String]] = [
        .morning: ["Bonjour ! Bien dormi ?", "Un nouveau jour, un nouveau blob.", "Debout là-dedans !"],
        .day: ["Coucou toi.", "Content de te revoir !", "On fait quoi aujourd'hui ?"],
        .evening: ["Bonsoir ! Ça a été ta journée ?", "Le soir, c'est mon moment préféré.", "Tu as bien mangé ?"],
        .night: ["Tu ne dors pas ? Moi si, presque.", "Il est tard… mais je suis là.", "Chhht, tout est calme."],
        .eat: ["Miam !", "Délicieux !", "Encore, encore !", "Merci, c'était bon."],
        .hug: ["Oh… c'est trop doux.", "Je fonds. Littéralement.", "Câlin accepté.", "Ça fait du bien."],
        .poke: ["Hé !", "Boing !", "Ça chatouille !", "Oh !"],
        .play: ["On joue !", "Wiiiii !", "Encore une fois !"],
        .wake: ["Hmm… déjà ?", "Bâââille. Bonjour.", "Je suis réveillé. Presque."],
        .sleep: ["Bonne nuit…", "Zzz…", "Je ferme les yeux un instant."],
        .hungry: ["J'ai faim…", "Mon ventre fait blop.", "Un petit quelque chose ?"],
        .sad: ["Je me sens un peu seul.", "Tu m'as oublié ?", "Un câlin ?"],
        .bored: ["Je m'ennuie…", "Il se passe quoi ?", "Amuse-moi !"],
        .happy: ["Je suis au top !", "Tout va bien dans mon petit monde.", "La vie est belle."],
        .idle: ["Blop.", "Tu as vu mes joues ?", "Je réfléchis. Ou pas.", "Il fait bon ici.", "Tu es doué, tu sais."],
        .focusStart: ["Concentration. Je veille.", "Allez, on se met dans la zone.", "Je reste sage pendant que tu bosses."],
        .focusDone: ["Session terminée, bravo !", "Tu l'as fait ! Pause méritée.", "Excellent boulot."],
        .breakStart: ["Pause ! Étire-toi.", "Respire un coup.", "Bois un peu d'eau."],
        .music: ["Oh, de la musique !", "Ça groove par ici.", "Monte le son !"],
        .headphones: ["Des écouteurs ? Moi aussi !", "Tu t'isoles ? Je comprends."],
        .battery: ["Je suis à plat… recharge-moi.", "Batterie faible. Je me liquéfie."],
        .hot: ["Il fait chaud ! Je transpire.", "Ton téléphone chauffe, là."],
        .hoop: ["Swish !", "Dans le panier !", "Quel tir !"],
        .level: ["Niveau supérieur !", "On grandit ensemble."],
        .skin: ["Un nouveau look ?", "Ça me va bien, non ?", "Stylé."],
        .tired: ["Je suis crevé…", "J'ai besoin d'un café. Ou d'un lit."]
    ]

    static func pick(_ k: Key, pack: Pack?) -> String {
        if k == .idle || k == .poke || k == .skin, let q = pack?.quips.randomElement(), Int.random(in: 0..<3) == 0 { return q }
        return lines[k]?.randomElement() ?? "…"
    }
}

final class AppState: ObservableObject {
    @Published var s: Saved { didSet { Haptics.enabled = s.settings.haptics; syncSound() } }
    @Published var bubble = ""
    @Published var talking = false
    @Published var toast: String? = nil
    @Published var batteryLow = false
    @Published var overheating = false
    @Published var music = false
    @Published var headphones = false
    @Published var now = Date()
    @Published var pomoPhase: PomoPhase = .focus
    @Published var pomoRunning = false
    @Published var pomoEnd: Date? = nil
    @Published var pomoPaused: Int? = nil
    @Published var pomoCycle = 0

    let events = PassthroughSubject<StageEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    private var lastTick = Date()
    private var sayTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?
    private var autoSlept = false
    private var snooze = Date.distantPast
    private var lastFired = ""
    private var tickCount = 0
    private var patTicks = 0
    private var wasMusic = false
    private var wasHeadphones = false
    private var wasBattery = false
    private var wasHot = false
    private static let key = "bob.saved.v2"

    init() {
        if let d = UserDefaults.standard.data(forKey: Self.key),
           let v = try? JSONDecoder().decode(Saved.self, from: d) {
            s = v
        } else {
            s = Saved()
        }
        seedDefaults()
        Haptics.enabled = s.settings.haptics
        syncSound()
        Sound.shared.preload()
        UIDevice.current.isBatteryMonitoringEnabled = true
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        let away = min(Date().timeIntervalSince(s.lastSeen), 8 * 3600)
        if away > 60 { decay(minutes: away / 60 * 0.5) }
        objectWillChange
            .debounce(for: .seconds(1.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.persist() }
            .store(in: &cancellables)
        let tm = Timer(timeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        RunLoop.main.add(tm, forMode: .common)
        timer = tm
        applyKeepAwake()
    }

    func syncSound() {
        Sound.enabled = s.settings.sounds
        Sound.volume = Float(s.settings.volume)
    }

    func persist() {
        var c = s
        c.lastSeen = Date()
        if let d = try? JSONEncoder().encode(c) { UserDefaults.standard.set(d, forKey: Self.key) }
    }

    // MARK: Accesseurs
    var skin: Skin { Catalog.skin(s.skinID) }
    var pack: Pack? { Catalog.pack(skin.packID) }
    var head: Prop? { s.head.flatMap { Prop(rawValue: $0) } }
    var eyes: Prop? { s.eyes.flatMap { Prop(rawValue: $0) } }
    var ears: Prop? { s.ears.flatMap { Prop(rawValue: $0) } }
    var neck: Prop? { s.neck.flatMap { Prop(rawValue: $0) } }
    // Niveaux : 1 action = 1 point, 10 points = 1 niveau.
    static let pointsPerLevel = 10
    var level: Int { 1 + s.xp / Self.pointsPerLevel }
    var levelProgress: Double { Double(s.xp % Self.pointsPerLevel) / Double(Self.pointsPerLevel) }
    var pointsToNext: Int { Self.pointsPerLevel - s.xp % Self.pointsPerLevel }
    var enabledPacks: [Pack] { Catalog.packs.filter { $0.id == "bob" || (owns($0.id) && !s.disabled.contains($0.id)) } }

    // MARK: Boutique (nourriture + DLC)
    func owns(_ packID: String) -> Bool { packID == "bob" || (s.owned ?? []).contains(packID) }
    func stock(_ foodID: String) -> Int { s.pantry?[foodID] ?? 0 }

    /// Stock de départ (nouvelle partie ou ancienne sauvegarde) : quelques repas, un seul pack.
    func seedDefaults() {
        if s.pantry == nil { s.pantry = ["pomme": 3, "cookie": 1] }
        if s.owned == nil { s.owned = ["bob"] }
        if !owns(skin.packID) { s.skinID = "bob_menthe" }
    }

    // MARK: Cadeau du jour
    var giftReady: Bool { s.lastGift != Self.day(Date()) }

    @discardableResult
    func claimGift() -> Bool {
        guard giftReady, let f = Catalog.foods.randomElement() else { return false }
        s.lastGift = Self.day(Date())
        s.coins += 5
        var p = s.pantry ?? [:]
        p[f.id, default: 0] += 1
        s.pantry = p
        Sound.shared.play(.coin)
        Haptics.success()
        showToast("Cadeau du jour : +5 pièces et 1 \(f.name) \(f.emoji)")
        return true
    }

    @discardableResult
    func buyFood(_ f: Food, qty: Int = 1) -> Bool {
        let total = f.cost * qty
        guard s.coins >= total else { Sound.shared.play(.deny); showToast("Pas assez de pièces"); return false }
        s.coins -= total
        var p = s.pantry ?? [:]
        p[f.id, default: 0] += qty
        s.pantry = p
        Sound.shared.play(.coin)
        Haptics.impact(.light)
        return true
    }

    @discardableResult
    func buyPack(_ p: Pack) -> Bool {
        guard !owns(p.id) else { return false }
        let price = Catalog.price(p)
        guard s.coins >= price else { Sound.shared.play(.deny); showToast("Pas assez de pièces"); return false }
        s.coins -= price
        var o = s.owned ?? ["bob"]
        o.append(p.id)
        s.owned = o
        s.disabled.removeAll { $0 == p.id }
        Sound.shared.play(.achievement)
        Haptics.success()
        showToast("Pack \(p.name) débloqué")
        return true
    }

    func prop(for cat: PropCategory) -> Prop? {
        switch cat {
        case .tete: return head
        case .yeux: return eyes
        case .oreilles: return ears
        case .cou: return neck
        }
    }

    func mood(temp: Mood?) -> Mood {
        if let f = s.forced.flatMap({ Mood(rawValue: $0) }) { return f }
        if s.sleeping { return .endormi }
        if s.settings.overheat && overheating { return .surchauffe }
        if pomoRunning && pomoPhase == .focus { return .concentre }
        if let t = temp { return t }
        if s.faim < 18 { return .affame }
        if s.joie < 20 { return .triste }
        if s.energie < 20 || batteryLow { return .ennuye }
        if s.joie < 38 { return .ennuye }
        if s.joie > 82 { return .heureux }
        return .content
    }

    // MARK: Actions
    func gain() {
        let before = level
        s.xp += 1
        if level > before {
            s.coins += 10
            events.send(.levelUp)
            Sound.shared.play(.levelup)
            Haptics.success()
            say(Dialogue.pick(.level, pack: pack))
            showToast("Niveau \(level) · +10 pièces")
        }
    }

    @discardableResult
    func feed(_ f: Food) -> Bool {
        guard stock(f.id) > 0 else { Sound.shared.play(.deny); showToast("Plus de \(f.name) · passe par la boutique"); return false }
        if s.sleeping { setSleeping(false, manual: true) }
        var p = s.pantry ?? [:]
        p[f.id] = max(0, (p[f.id] ?? 0) - 1)
        s.pantry = p
        s.faim = min(100, s.faim + f.faim)
        s.joie = min(100, s.joie + f.joie)
        s.energie = min(100, s.energie + f.energie)
        s.fed += 1
        events.send(.eat(f.emoji))
        Sound.shared.play(.eat)
        say(Dialogue.pick(.eat, pack: pack))
        Haptics.impact(.soft)
        gain()
        checkAchievements()
        return true
    }

    func hug() {
        if s.sleeping { setSleeping(false, manual: true) }
        s.joie = min(100, s.joie + 14)
        s.pats += 1
        events.send(.hug)
        Sound.shared.play(.hug)
        say(Dialogue.pick(.hug, pack: pack))
        gain()
        checkAchievements()
    }

    func patTick() {
        s.joie = min(100, s.joie + 0.9)
        patTicks += 1
        if patTicks % 6 == 0 { s.pats += 1; gain(); checkAchievements() }
    }

    func poke() {
        if s.sleeping { setSleeping(false, manual: true); return }
        if !talking && Int.random(in: 0..<3) == 0 { say(Dialogue.pick(.poke, pack: pack)) }
    }

    func play() {
        if s.sleeping { setSleeping(false, manual: true) }
        guard s.energie > 8 else { say(Dialogue.pick(.tired, pack: pack)); return }
        s.energie = max(0, s.energie - 6)
        s.joie = min(100, s.joie + 12)
        s.plays += 1
        s.coins += 2
        events.send(.play)
        Sound.shared.play(.boing)
        say(Dialogue.pick(.play, pack: pack))
        gain()
        checkAchievements()
    }

    func toggleSleep() { setSleeping(!s.sleeping, manual: true) }

    func setSleeping(_ v: Bool, manual: Bool) {
        guard s.sleeping != v else { return }
        s.sleeping = v
        if manual { snooze = Date().addingTimeInterval(3600); autoSlept = false }
        events.send(v ? .sleep : .wake)
        Sound.shared.play(v ? .sleep : .wake)
        say(Dialogue.pick(v ? .sleep : .wake, pack: pack))
    }

    func chooseSkin(_ sk: Skin) {
        s.skinID = sk.id
        if !s.tried.contains(sk.id) { s.tried.append(sk.id) }
        events.send(.changedSkin)
        Haptics.select()
        Sound.shared.season(Catalog.pack(sk.packID)?.season)
        say(Dialogue.pick(.skin, pack: Catalog.pack(sk.packID)))
        checkAchievements()
    }

    func equip(_ cat: PropCategory, _ p: Prop?) {
        switch cat {
        case .tete: s.head = p?.rawValue
        case .yeux: s.eyes = p?.rawValue
        case .oreilles: s.ears = p?.rawValue
        case .cou: s.neck = p?.rawValue
        }
        if let p = p, !s.worn.contains(p.rawValue) { s.worn.append(p.rawValue) }
        Haptics.select()
        Sound.shared.play(p == nil ? .tick : .equip)
        events.send(.changedSkin)
        checkAchievements()
    }

    func setPack(_ id: String, enabled: Bool) {
        guard id != "bob", owns(id) else { return }
        if enabled { s.disabled.removeAll { $0 == id } } else if !s.disabled.contains(id) { s.disabled.append(id) }
        if !enabledPacks.flatMap({ $0.skins }).contains(where: { $0.id == s.skinID }) { s.skinID = "bob_menthe" }
    }
    func enableAllPacks() { s.disabled = [] }
    func disableAllPacks() {
        s.disabled = Catalog.packs.map { $0.id }.filter { $0 != "bob" }
        if skin.packID != "bob" { s.skinID = "bob_menthe" }
    }
    var seasonalPacks: [Pack] { Catalog.packs.filter { $0.season != nil } }
    func enableSeasonal() { s.disabled.removeAll { id in seasonalPacks.contains { $0.id == id } } }

    func resetAll() {
        Notifier.shared.cancel(s.reminders.map { $0.id.uuidString })
        s = Saved()
        seedDefaults()
        showToast("BOB est reparti de zéro")
    }

    // MARK: Succès
    func checkAchievements() {
        for a in Catalog.achievements where !s.unlocked.contains(a.id) && a.value(s) >= a.goal {
            s.unlocked.append(a.id)
            s.coins += 25
            Sound.shared.play(.achievement)
            Haptics.success()
            showToast("Succès : \(a.title) · +25")
        }
    }

    func welcome() {
        Notifier.shared.setup()
        Notifier.shared.cancel(["hunger"])
        let today = Self.day(Date())
        if s.lastDay != today {
            let y = Self.day(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
            s.streak = (s.lastDay == y) ? s.streak + 1 : 1
            s.lastDay = today
            let bonus = 5 * min(s.streak, 7)
            s.coins += bonus
            Sound.shared.play(.coin)
            showToast("Jour \(s.streak) d'affilée · +\(bonus) pièces")
            checkAchievements()
        }
        let h = Calendar.current.component(.hour, from: Date())
        let k: Dialogue.Key = h < 5 ? .night : h < 12 ? .morning : h < 18 ? .day : h < 22 ? .evening : .night
        if !s.sleeping { say(Dialogue.pick(k, pack: pack)) }
    }

    func background() {
        persist()
        if s.settings.notifHunger && s.faim > 20 {
            let mins = (s.faim - 20) / 0.167
            Notifier.shared.once(id: "hunger", title: "BOB", body: "J'ai faim… tu viens me voir ?", in: min(max(mins * 60, 600), 12 * 3600))
        }
    }

    static func day(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    // MARK: Bulles & toasts
    func say(_ text: String, hold: Double? = nil) {
        sayTask?.cancel()
        bubble = ""
        talking = true
        let chars = Array(text)
        sayTask = Task { @MainActor [weak self] in
            var n = 0
            for ch in chars {
                guard let self = self, !Task.isCancelled else { return }
                self.bubble.append(ch)
                n += 1
                if n % 2 == 1, ch != " ", !self.s.sleeping { Sound.shared.talk(mood: self.mood(temp: nil)) }
                try? await Task.sleep(nanoseconds: 28_000_000)
            }
            self?.talking = false
            let h = hold ?? max(2.2, Double(chars.count) * 0.055 + 1.6)
            try? await Task.sleep(nanoseconds: UInt64(h * 1_000_000_000))
            if Task.isCancelled { return }
            self?.bubble = ""
        }
    }

    func showToast(_ t: String) {
        toastTask?.cancel()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { toast = t }
        toastTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            if Task.isCancelled { return }
            withAnimation(.easeOut(duration: 0.3)) { self?.toast = nil }
        }
    }

    // MARK: Tick
    func decay(minutes m: Double) {
        if s.sleeping {
            s.energie = min(100, s.energie + 0.6 * m)
            s.faim = max(0, s.faim - 0.05 * m)
            s.joie = max(0, s.joie - 0.02 * m)
        } else {
            s.faim = max(0, s.faim - 0.167 * m)
            s.energie = max(0, s.energie - 0.07 * m)
            s.joie = max(0, s.joie - 0.10 * m + (music ? 0.14 * m : 0))
        }
    }

    func applyKeepAwake() { UIApplication.shared.isIdleTimerDisabled = s.settings.keepAwake }

    private func tick() {
        let n = Date()
        let dt = n.timeIntervalSince(lastTick)
        lastTick = n
        now = n
        tickCount += 1
        decay(minutes: min(dt, 5) / 60)

        let h = Calendar.current.component(.hour, from: n)
        let night = h >= 23 || h < 7
        if s.settings.autoSleep && n > snooze {
            if night && !s.sleeping { autoSlept = true; setSleeping(true, manual: false) }
            if !night && s.sleeping && autoSlept { autoSlept = false; setSleeping(false, manual: false) }
        }

        if tickCount % 2 == 0 { poll() }
        pomoCheck(n)
        checkReminders(n)

        if !talking && !s.sleeping && bubble.isEmpty {
            let p: Double = s.settings.chatter == 0 ? 1.0 / 150 : s.settings.chatter == 1 ? 1.0 / 70 : 1.0 / 35
            if Double.random(in: 0..<1) < p { say(idleLine()) }
        }
    }

    private func idleLine() -> String {
        let m = mood(temp: nil)
        switch m {
        case .affame: Sound.shared.play(.growl); return Dialogue.pick(.hungry, pack: pack)
        case .triste: return Dialogue.pick(.sad, pack: pack)
        case .ennuye: return Dialogue.pick(.bored, pack: pack)
        case .heureux: return Dialogue.pick(.happy, pack: pack)
        default: return Dialogue.pick(.idle, pack: pack)
        }
    }

    private func poll() {
        let level = UIDevice.current.batteryLevel
        let st = UIDevice.current.batteryState
        let low = level >= 0 && level < 0.15 && st != .charging && st != .full
        if low != batteryLow { batteryLow = low }
        if low && !wasBattery { Sound.shared.play(.battery); say(Dialogue.pick(.battery, pack: pack)) }
        wasBattery = low

        let th = ProcessInfo.processInfo.thermalState
        let mem = os_proc_available_memory()
        let hot = th == .serious || th == .critical || (mem > 0 && mem < 150_000_000)
        if hot != overheating { overheating = hot }
        if hot && !wasHot && s.settings.overheat { Sound.shared.play(.hot); say(Dialogue.pick(.hot, pack: pack)) }
        wasHot = hot

        let ses = AVAudioSession.sharedInstance()
        let playing = s.settings.music && ses.isOtherAudioPlaying
        if playing != music { music = playing }
        if playing && !wasMusic && !s.sleeping { Sound.shared.play(.music, gain: 0.6); say(Dialogue.pick(.music, pack: pack)) }
        wasMusic = playing
        let hp = ses.currentRoute.outputs.contains { [.headphones, .bluetoothA2DP, .bluetoothLE, .bluetoothHFP].contains($0.portType) }
        if hp != headphones { headphones = hp }
        if hp && !wasHeadphones && s.settings.music && !s.sleeping { Sound.shared.play(.headphones); say(Dialogue.pick(.headphones, pack: pack)) }
        wasHeadphones = hp
    }

    // MARK: Pomodoro
    func pomoDuration(_ p: PomoPhase) -> Int {
        switch p {
        case .focus: return s.settings.focusMin * 60
        case .short: return s.settings.shortMin * 60
        case .long: return s.settings.longMin * 60
        }
    }
    var pomoRemaining: Int {
        if pomoRunning, let e = pomoEnd { return max(0, Int(ceil(e.timeIntervalSince(now)))) }
        return pomoPaused ?? pomoDuration(pomoPhase)
    }
    var pomoProgress: Double {
        let d = Double(pomoDuration(pomoPhase))
        return d > 0 ? 1 - Double(pomoRemaining) / d : 0
    }
    func pomoStart() {
        let left = pomoPaused ?? pomoDuration(pomoPhase)
        pomoEnd = Date().addingTimeInterval(Double(left))
        pomoPaused = nil
        pomoRunning = true
        Notifier.shared.request()
        Notifier.shared.once(id: "pomo", title: "BOB · \(pomoPhase.title)", body: pomoPhase == .focus ? "Session terminée, bien joué !" : "Pause terminée, on y retourne ?", in: Double(left))
        if s.sleeping { setSleeping(false, manual: true) }
        say(Dialogue.pick(pomoPhase == .focus ? .focusStart : .breakStart, pack: pack))
        Sound.shared.play(pomoPhase == .focus ? .focus_start : .break_start)
        Haptics.impact(.medium)
    }
    func pomoPause() {
        pomoPaused = pomoRemaining
        pomoRunning = false
        pomoEnd = nil
        Notifier.shared.cancel(["pomo"])
    }
    func pomoReset() {
        pomoRunning = false
        pomoEnd = nil
        pomoPaused = nil
        Notifier.shared.cancel(["pomo"])
    }
    func pomoSet(_ p: PomoPhase) { pomoReset(); pomoPhase = p }
    func pomoSkip() { pomoReset(); pomoNext() }
    private func pomoNext() {
        if pomoPhase == .focus {
            pomoCycle += 1
            pomoPhase = pomoCycle % 4 == 0 ? .long : .short
        } else {
            pomoPhase = .focus
        }
    }
    private func pomoCheck(_ n: Date) {
        guard pomoRunning, let e = pomoEnd, n >= e else { return }
        let was = pomoPhase
        pomoRunning = false
        pomoEnd = nil
        pomoPaused = nil
        if was == .focus {
            let today = Self.day(n)
            if s.pomoDay != today { s.pomoDay = today; s.pomoToday = 0 }
            s.pomoToday += 1
            s.pomos += 1
            s.coins += 10
            gain()
            events.send(.confetti)
            Sound.shared.play(.fanfare)
            say(Dialogue.pick(.focusDone, pack: pack))
            checkAchievements()
        }
        if was != .focus { Sound.shared.play(.reminder) }
        Haptics.success()
        pomoNext()
    }

    // MARK: Rappels
    func addReminder(_ r: Reminder) {
        s.reminders.append(r)
        Notifier.shared.request()
        Notifier.shared.schedule(r)
    }
    func updateReminder(_ r: Reminder) {
        if let i = s.reminders.firstIndex(where: { $0.id == r.id }) { s.reminders[i] = r }
        Notifier.shared.schedule(r)
    }
    func deleteReminders(at offsets: IndexSet) {
        Notifier.shared.cancel(offsets.map { s.reminders[$0].id.uuidString })
        s.reminders.remove(atOffsets: offsets)
    }
    private func checkReminders(_ n: Date) {
        let cal = Calendar.current
        let key = Self.day(n) + "-\(cal.component(.hour, from: n)):\(cal.component(.minute, from: n))"
        guard cal.component(.second, from: n) < 2, key != lastFired else { return }
        for r in s.reminders where r.enabled {
            let a = cal.dateComponents([.hour, .minute], from: r.time)
            let b = cal.dateComponents([.hour, .minute], from: n)
            let sameDay = r.daily || cal.isDate(r.time, inSameDayAs: n)
            if sameDay && a.hour == b.hour && a.minute == b.minute {
                lastFired = key
                if s.sleeping { setSleeping(false, manual: true) }
                say("Rappel : \(r.title)", hold: 6)
                Sound.shared.play(.reminder)
                events.send(.confetti)
                Haptics.success()
            }
        }
    }
}
