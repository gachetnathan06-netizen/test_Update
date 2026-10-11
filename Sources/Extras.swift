import SwiftUI
import UserNotifications

// MARK: - Données persistées (indépendantes de la sauvegarde principale)

struct Todo: Codable, Identifiable { var id = UUID(); var title: String; var done = false }
struct Habit: Codable, Identifiable { var id = UUID(); var name: String; var emoji: String; var days: [String] = [] }

struct ExtraData: Codable {
    var todos: [Todo] = []
    var todoDay = ""
    var todoCount = 0
    var water = 0
    var waterDay = ""
    var waterGoal = 8
    var waterReminder = false
    var habits: [Habit] = []
    var moods: [String: Int] = [:]
    var zenSessions = 0
    var breaks: [String] = []
    var breakEvery = 30
    var rewarded: [String] = []
}

final class ExtrasStore: ObservableObject {
    static let shared = ExtrasStore()
    @Published var d: ExtraData { didSet { save() } }
    private let key = "bob.extras.v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: "bob.extras.v1"),
           let v = try? JSONDecoder().decode(ExtraData.self, from: data) { d = v } else { d = ExtraData() }
    }
    private func save() {
        if let data = try? JSONEncoder().encode(d) { UserDefaults.standard.set(data, forKey: key) }
    }
    var today: String { AppState.day(Date()) }
    var waterToday: Int { d.waterDay == today ? d.water : 0 }

    /// Vrai une seule fois par clé (anti-abus des récompenses).
    func once(_ k: String) -> Bool {
        if d.rewarded.contains(k) { return false }
        d.rewarded.append(k)
        if d.rewarded.count > 400 { d.rewarded.removeFirst(100) }
        return true
    }
}

// MARK: - Catalogue des outils (DLC utilitaires)

struct Tool: Identifiable {
    let id: String
    let name: String
    let icon: String
    let blurb: String
    let price: Int
    let perks: [String]
    let tint: Color
}

enum Tools {
    static let bundleID = "tool_bundle"

    static let all: [Tool] = [
        Tool(id: "tool_todo", name: "Tâches", icon: "checklist", blurb: "Ta to-do du jour, avec BOB qui t'applaudit.",
             price: 40, perks: ["Liste illimitée", "+2 pièces par tâche (5/jour)", "Nettoyage en un geste"], tint: Color(hex: 0x6EE7B7)),
        Tool(id: "tool_water", name: "Hydratation", icon: "drop.fill", blurb: "Bois assez, BOB veille sur ta gourde.",
             price: 40, perks: ["Objectif de verres réglable", "Rappel toutes les 2 h", "+5 pièces à l'objectif"], tint: Color(hex: 0x7CC4FF)),
        Tool(id: "tool_habits", name: "Habitudes", icon: "flame.fill", blurb: "Suis tes routines et tes séries sur 7 jours.",
             price: 60, perks: ["Habitudes illimitées", "Séries de jours", "+1 pièce par validation"], tint: Color(hex: 0xFF8F5A)),
        Tool(id: "tool_zen", name: "Zen", icon: "wind", blurb: "Respiration guidée avec BOB qui gonfle et se dégonfle.",
             price: 50, perks: ["3 techniques (5-5, carré, 4-7-8)", "Orbe animé à ton rythme", "+3 pièces par séance"], tint: Color(hex: 0xB79CFF)),
        Tool(id: "tool_mood", name: "Bilan", icon: "chart.bar.fill", blurb: "Note ton humeur chaque jour, vois la tendance.",
             price: 30, perks: ["Check-in en 1 tap", "Graphique sur 14 jours", "Moyenne de la semaine"], tint: Color(hex: 0xFFB547)),
        Tool(id: "tool_breaks", name: "Pauses santé", icon: "figure.walk", blurb: "20-20-20, posture, étirements : BOB te relance.",
             price: 50, perks: ["4 rappels intelligents", "Intervalle au choix", "Routine d'étirements"], tint: Color(hex: 0xFF7A90)),
        Tool(id: bundleID, name: "Bureau Pro", icon: "briefcase.fill", blurb: "Les 6 outils d'un coup, au meilleur prix.",
             price: 180, perks: ["Tâches, Hydratation, Habitudes", "Zen, Bilan, Pauses santé", "Économise 90 pièces"], tint: Color(hex: 0xFFD866))
    ]
    static var singles: [Tool] { all.filter { $0.id != bundleID } }
    static var bundle: Tool { all[all.count - 1] }
}

extension AppState {
    func ownsTool(_ id: String) -> Bool {
        let o = s.owned ?? []
        return o.contains(id) || o.contains(Tools.bundleID)
    }

    @discardableResult
    func buyTool(_ t: Tool) -> Bool {
        guard !ownsTool(t.id) else { return false }
        guard s.coins >= t.price else { Sound.shared.play(.deny); showToast("Pas assez de pièces"); return false }
        s.coins -= t.price
        var o = s.owned ?? ["bob"]
        o.append(t.id)
        s.owned = o
        Sound.shared.play(.achievement)
        Haptics.success()
        showToast("\(t.name) débloqué")
        return true
    }

    func reward(_ n: Int, _ msg: String) {
        s.coins += n
        Sound.shared.play(.coin)
        Haptics.success()
        showToast(msg)
    }
}

enum Remind {
    static func repeating(id: String, body: String, everyMin: Int) {
        let c = UNMutableNotificationContent()
        c.title = "BOB"
        c.body = body
        c.sound = .default
        let trig = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(1, everyMin)) * 60, repeats: true)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: c, trigger: trig))
    }
    static func cancel(_ ids: [String]) { Notifier.shared.cancel(ids) }
}

// MARK: - Cartes réutilisables (boutique + hub)

struct ToolCard: View {
    @EnvironmentObject var app: AppState
    let tool: Tool
    var onOpen: (() -> Void)? = nil
    var onBuy: () -> Void = {}

    private var owned: Bool { app.ownsTool(tool.id) }
    private var saving: Int { Tools.singles.reduce(0) { $0 + $1.price } - Tools.bundle.price }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: tool.icon)
                    .font(.system(size: 20, weight: .bold)).foregroundColor(Color(hex: 0x1B1530))
                    .frame(width: 46, height: 46)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: [tool.tint, tool.tint.opacity(0.65)], startPoint: .top, endPoint: .bottom)))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(tool.name).font(Theme.rounded(17))
                        if tool.id == Tools.bundleID && !owned {
                            Text("−\(saving) pièces").font(Theme.rounded(10, .bold)).foregroundColor(Theme.amber)
                                .padding(.horizontal, 7).padding(.vertical, 2)
                                .background(Capsule().fill(Theme.amber.opacity(0.18)))
                        }
                    }
                    Text(tool.blurb).font(Theme.rounded(13, .medium)).foregroundColor(.white.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: 5) {
                ForEach(tool.perks, id: \.self) { p in
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(tool.tint)
                        Text(p).font(Theme.rounded(12.5, .medium)).foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            action
        }
        .padding(14)
        .glass(22)
    }

    @ViewBuilder private var action: some View {
        if owned {
            if let open = onOpen {
                Button(action: open) {
                    HStack(spacing: 6) {
                        Text("Ouvrir"); Image(systemName: "arrow.right")
                    }
                    .font(Theme.rounded(14, .bold)).foregroundColor(Color(hex: 0x1B1530))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tool.tint))
                }
                .buttonStyle(PressStyle())
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.mint)
                    Text("Possédé · onglet Outils").font(Theme.rounded(14, .semibold)).foregroundColor(Theme.mint)
                    Spacer()
                }
            }
        } else {
            let ok = app.s.coins >= tool.price
            Button(action: onBuy) {
                HStack(spacing: 6) {
                    if ok {
                        Text("Débloquer"); Image(systemName: "circle.fill").font(.system(size: 9)); Text("\(tool.price)")
                    } else {
                        Image(systemName: "lock.fill").font(.system(size: 11)); Text("Il manque \(tool.price - app.s.coins)")
                    }
                }
                .font(Theme.rounded(14, .bold))
                .foregroundColor(ok ? Color(hex: 0x1B1530) : .white.opacity(0.55))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ok ? Theme.amber : Color.white.opacity(0.08)))
            }
            .buttonStyle(PressStyle())
        }
    }
}

// MARK: - Hub : onglet Outils

enum Dest: Identifiable {
    case focus, hoop, tool(Tool)
    var id: String {
        switch self {
        case .focus: return "focus"
        case .hoop: return "hoop"
        case .tool(let t): return t.id
        }
    }
}

struct CloseButton: View {
    @Environment(\.presentationMode) private var pm
    var body: some View {
        Button { pm.wrappedValue.dismiss() } label: {
            Image(systemName: "xmark").font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                .frame(width: 40, height: 40).glass(20)
        }
        .buttonStyle(PressStyle())
        .padding(.top, 10).padding(.trailing, 14)
        .accessibilityLabel("Fermer")
    }
}

struct ToolsHubView: View {
    @EnvironmentObject var app: AppState
    @State private var dest: Dest? = nil
    @State private var tab = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 12) {
                        shortcut("Focus", "timer", Theme.sky) { dest = .focus }
                        shortcut("Panier", "gamecontroller.fill", Theme.rose) { dest = .hoop }
                    }
                    let mine = Tools.singles.filter { app.ownsTool($0.id) }
                    let locked = Tools.all.filter { !app.ownsTool($0.id) }
                    if !mine.isEmpty {
                        header("Mes outils", mine.count)
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            ForEach(mine) { t in tile(t) }
                        }
                    }
                    if !locked.isEmpty {
                        header(mine.isEmpty ? "Débloque tes premiers outils" : "À débloquer", locked.count)
                        ForEach(locked) { t in
                            ToolCard(tool: t, onOpen: nil) { _ = app.buyTool(t) }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 28).padding(.top, 6)
            }
            .background(Theme.ink.ignoresSafeArea())
            .navigationTitle("Outils")
        }
        .foregroundColor(.white)
        .fullScreenCover(item: $dest) { d in
            switch d {
            case .focus:
                ZStack(alignment: .topTrailing) { FocusView().environmentObject(app); CloseButton() }
            case .hoop:
                ZStack(alignment: .topTrailing) { HoopView().environmentObject(app); CloseButton() }
            case .tool(let t):
                ToolScreen(tool: t).environmentObject(app)
            }
        }
    }

    private func header(_ t: String, _ n: Int) -> some View {
        HStack(spacing: 8) {
            Text(t).font(Theme.rounded(18))
            Text("\(n)").font(Theme.rounded(12, .bold)).foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 8).padding(.vertical, 2).background(Capsule().fill(Color.white.opacity(0.1)))
        }
    }

    private func shortcut(_ title: String, _ icon: String, _ c: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon).font(.system(size: 22, weight: .bold)).foregroundColor(c)
                Text(title).font(Theme.rounded(17))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16).glass(22)
        }
        .buttonStyle(PressStyle())
    }

    private func tile(_ t: Tool) -> some View {
        Button { dest = .tool(t) } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: t.icon).font(.system(size: 20, weight: .bold)).foregroundColor(Color(hex: 0x1B1530))
                    .frame(width: 42, height: 42)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(t.tint))
                Text(t.name).font(Theme.rounded(16))
                Text(t.blurb).font(Theme.rounded(11.5, .medium)).foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.leading).lineLimit(2).fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14).glass(22)
        }
        .buttonStyle(PressStyle())
    }
}

// MARK: - Cadre commun des outils

struct ToolFrame<C: View>: View {
    let tool: Tool
    let content: C
    @Environment(\.presentationMode) private var pm

    init(_ tool: Tool, @ViewBuilder _ content: () -> C) {
        self.tool = tool
        self.content = content()
    }

    var body: some View {
        ZStack {
            Theme.ink.ignoresSafeArea()
            RadialGradient(colors: [tool.tint.opacity(0.32), .clear], center: .top, startRadius: 0, endRadius: 380)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: tool.icon).font(.system(size: 18, weight: .bold)).foregroundColor(tool.tint)
                    Text(tool.name).font(Theme.rounded(24, .bold))
                    Spacer()
                    Button { pm.wrappedValue.dismiss() } label: {
                        Text("Fermer").font(Theme.rounded(14, .bold)).foregroundColor(.white)
                            .padding(.horizontal, 14).frame(minHeight: 36).glass(18)
                    }
                    .buttonStyle(PressStyle())
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) { content }
                        .padding(.horizontal, 16).padding(.bottom, 34)
                }
            }
        }
        .foregroundColor(.white)
    }
}

struct ToolScreen: View {
    let tool: Tool
    var body: some View {
        switch tool.id {
        case "tool_todo": TodoScreen(tool: tool)
        case "tool_water": WaterScreen(tool: tool)
        case "tool_habits": HabitsScreen(tool: tool)
        case "tool_zen": ZenScreen(tool: tool)
        case "tool_mood": MoodScreen(tool: tool)
        default: BreaksScreen(tool: tool)
        }
    }
}

private func primaryButton(_ label: String, _ icon: String, tint: Color, _ action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(label)
        }
        .font(Theme.rounded(15, .bold)).foregroundColor(Color(hex: 0x1B1530))
        .frame(maxWidth: .infinity, minHeight: 48)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tint))
    }
    .buttonStyle(PressStyle())
}

// MARK: - Tâches

struct TodoScreen: View {
    let tool: Tool
    @EnvironmentObject var app: AppState
    @ObservedObject private var x = ExtrasStore.shared
    @State private var text = ""

    var body: some View {
        ToolFrame(tool) {
            let total = x.d.todos.count
            let done = x.d.todos.filter { $0.done }.count
            HStack(spacing: 10) {
                TextField("Nouvelle tâche", text: $text)
                    .font(Theme.rounded(16, .medium))
                    .padding(.horizontal, 14).frame(minHeight: 48)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.1)))
                Button(action: add) {
                    Image(systemName: "plus").font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: 0x1B1530))
                        .frame(width: 48, height: 48)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tool.tint))
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel("Ajouter")
            }
            if total > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(done) sur \(total) faites").font(Theme.rounded(13, .semibold)).foregroundColor(.white.opacity(0.7))
                    ProgressView(value: Double(done), total: Double(max(1, total)))
                        .progressViewStyle(LinearProgressViewStyle(tint: tool.tint))
                }
            }
            if total == 0 {
                VStack(spacing: 8) {
                    Text("📝").font(.system(size: 44))
                    Text("Rien à faire… pour l'instant.").font(Theme.rounded(15, .medium)).foregroundColor(.white.opacity(0.65))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 30)
            }
            ForEach(x.d.todos) { t in
                HStack(spacing: 12) {
                    Button { toggle(t) } label: {
                        Image(systemName: t.done ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 26)).foregroundColor(t.done ? tool.tint : .white.opacity(0.45))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(PressStyle())
                    .accessibilityLabel(t.done ? "Marquer non faite" : "Marquer faite")
                    Text(t.title).font(Theme.rounded(16, .medium))
                        .strikethrough(t.done).foregroundColor(.white.opacity(t.done ? 0.45 : 1))
                    Spacer(minLength: 0)
                    Button { x.d.todos.removeAll { $0.id == t.id } } label: {
                        Image(systemName: "trash").font(.system(size: 15)).foregroundColor(.white.opacity(0.45))
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(PressStyle())
                    .accessibilityLabel("Supprimer")
                }
                .padding(.horizontal, 6).glass(18)
            }
            if done > 0 {
                Button { x.d.todos.removeAll { $0.done } } label: {
                    Text("Effacer les tâches faites").font(Theme.rounded(14, .semibold)).foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(PressStyle())
            }
        }
    }

    private func add() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        x.d.todos.insert(Todo(title: t), at: 0)
        text = ""
        Haptics.impact(.light)
    }

    private func toggle(_ t: Todo) {
        guard let i = x.d.todos.firstIndex(where: { $0.id == t.id }) else { return }
        x.d.todos[i].done.toggle()
        guard x.d.todos[i].done else { return }
        if x.d.todoDay != x.today { x.d.todoDay = x.today; x.d.todoCount = 0 }
        if x.d.todoCount < 5 && x.once("todo|\(t.id.uuidString)") {
            x.d.todoCount += 1
            app.reward(2, "Tâche faite · +2 pièces")
        } else {
            Haptics.impact(.light)
        }
    }
}

// MARK: - Hydratation

struct WaterScreen: View {
    let tool: Tool
    @EnvironmentObject var app: AppState
    @ObservedObject private var x = ExtrasStore.shared

    var body: some View {
        ToolFrame(tool) {
            let n = x.waterToday
            let goal = x.d.waterGoal
            let p = min(1, Double(n) / Double(max(1, goal)))
            ZStack {
                Circle().stroke(Color.white.opacity(0.12), lineWidth: 16)
                Circle().trim(from: 0, to: CGFloat(p))
                    .stroke(tool.tint, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: n)
                VStack(spacing: 2) {
                    Text("\(n)").font(Theme.rounded(64, .bold))
                    Text("sur \(goal) verres").font(Theme.rounded(14, .medium)).foregroundColor(.white.opacity(0.65))
                }
            }
            .frame(width: 210, height: 210)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .accessibilityElement(children: .combine)

            HStack(spacing: 10) {
                Button { add(-1) } label: {
                    Image(systemName: "minus").font(.system(size: 18, weight: .bold))
                        .frame(width: 56, height: 48).glass(14)
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel("Retirer un verre")
                primaryButton("Un verre", "plus", tint: tool.tint) { add(1) }
            }

            VStack(alignment: .leading, spacing: 12) {
                Stepper("Objectif : \(x.d.waterGoal) verres", value: $x.d.waterGoal, in: 4...14)
                    .font(Theme.rounded(15, .semibold))
                Toggle("Rappel toutes les 2 h", isOn: Binding(get: { x.d.waterReminder }, set: { v in
                    x.d.waterReminder = v
                    if v {
                        Notifier.shared.request()
                        Remind.repeating(id: "bob.water", body: "Un verre d'eau ? Ton BOB a soif pour toi.", everyMin: 120)
                    } else {
                        Remind.cancel(["bob.water"])
                    }
                }))
                .toggleStyle(SwitchToggleStyle(tint: tool.tint))
                .font(Theme.rounded(15, .semibold))
            }
            .padding(14).glass(20)
        }
    }

    private func add(_ k: Int) {
        if x.d.waterDay != x.today { x.d.waterDay = x.today; x.d.water = 0 }
        x.d.water = max(0, x.d.water + k)
        Haptics.impact(.light)
        if k > 0 && x.d.water >= x.d.waterGoal && x.once("water|\(x.today)") {
            app.reward(5, "Objectif atteint · +5 pièces")
        }
    }
}

// MARK: - Habitudes

struct HabitsScreen: View {
    let tool: Tool
    @EnvironmentObject var app: AppState
    @ObservedObject private var x = ExtrasStore.shared
    @State private var text = ""
    private let emojis = ["📚", "🏃", "🧘", "💧", "🛌", "🥗", "✍️", "🎸"]

    private var week: [Date] {
        (0..<7).reversed().map { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) ?? Date() }
    }
    private static let letter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.dateFormat = "EEEEE"
        return f
    }()

    var body: some View {
        ToolFrame(tool) {
            HStack(spacing: 10) {
                TextField("Nouvelle habitude", text: $text)
                    .font(Theme.rounded(16, .medium))
                    .padding(.horizontal, 14).frame(minHeight: 48)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(0.1)))
                Button(action: add) {
                    Image(systemName: "plus").font(.system(size: 18, weight: .bold)).foregroundColor(Color(hex: 0x1B1530))
                        .frame(width: 48, height: 48)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tool.tint))
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel("Ajouter")
            }
            if x.d.habits.isEmpty {
                VStack(spacing: 8) {
                    Text("🌱").font(.system(size: 44))
                    Text("Ajoute une habitude à suivre.").font(Theme.rounded(15, .medium)).foregroundColor(.white.opacity(0.65))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 30)
            }
            ForEach(x.d.habits) { h in card(h) }
        }
    }

    private func card(_ h: Habit) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(h.emoji).font(.system(size: 26))
                Text(h.name).font(Theme.rounded(17))
                Spacer()
                Text("🔥 \(streak(h))").font(Theme.rounded(14, .bold)).foregroundColor(tool.tint)
                Button { x.d.habits.removeAll { $0.id == h.id } } label: {
                    Image(systemName: "trash").font(.system(size: 14)).foregroundColor(.white.opacity(0.45))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel("Supprimer")
            }
            HStack(spacing: 6) {
                ForEach(week, id: \.self) { d in
                    let key = AppState.day(d)
                    let on = h.days.contains(key)
                    Button { toggle(h, key) } label: {
                        VStack(spacing: 4) {
                            Text(Self.letter.string(from: d).uppercased()).font(Theme.rounded(10, .bold)).foregroundColor(.white.opacity(0.5))
                            Image(systemName: on ? "checkmark" : "circle")
                                .font(.system(size: on ? 14 : 8, weight: .bold))
                                .foregroundColor(on ? Color(hex: 0x1B1530) : .white.opacity(0.3))
                                .frame(width: 38, height: 38)
                                .background(Circle().fill(on ? tool.tint : Color.white.opacity(0.08)))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PressStyle())
                }
            }
        }
        .padding(14).glass(22)
    }

    private func add() {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        x.d.habits.append(Habit(name: t, emoji: emojis[x.d.habits.count % emojis.count]))
        text = ""
        Haptics.impact(.light)
    }

    private func toggle(_ h: Habit, _ day: String) {
        guard let i = x.d.habits.firstIndex(where: { $0.id == h.id }) else { return }
        if let j = x.d.habits[i].days.firstIndex(of: day) {
            x.d.habits[i].days.remove(at: j)
        } else {
            x.d.habits[i].days.append(day)
            if day == x.today && x.once("habit|\(h.id.uuidString)|\(day)") { app.reward(1, "Habitude validée · +1 pièce") }
            else { Haptics.impact(.light) }
        }
    }

    private func streak(_ h: Habit) -> Int {
        var n = 0
        var d = Date()
        if !h.days.contains(AppState.day(d)) { d = Calendar.current.date(byAdding: .day, value: -1, to: d) ?? d }
        while h.days.contains(AppState.day(d)) && n < 3650 {
            n += 1
            d = Calendar.current.date(byAdding: .day, value: -1, to: d) ?? d
        }
        return n
    }
}

// MARK: - Zen (respiration)

struct ZenScreen: View {
    let tool: Tool
    @EnvironmentObject var app: AppState
    @ObservedObject private var x = ExtrasStore.shared
    @State private var pattern = 0
    @State private var running = false
    @State private var phase = 0
    @State private var ticks = 0
    @State private var cycle = 0
    @State private var scale: CGFloat = 0.55
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let cycles = 6

    private let patterns: [(String, [(String, Int)])] = [
        ("Cohérence 5-5", [("Inspire", 5), ("Expire", 5)]),
        ("Carré 4-4-4-4", [("Inspire", 4), ("Retiens", 4), ("Expire", 4), ("Retiens", 4)]),
        ("Apaisant 4-7-8", [("Inspire", 4), ("Retiens", 7), ("Expire", 8)])
    ]
    private var steps: [(String, Int)] { patterns[pattern].1 }

    var body: some View {
        ToolFrame(tool) {
            ZStack {
                Circle().fill(RadialGradient(colors: [tool.tint.opacity(0.4), .clear], center: .center, startRadius: 10, endRadius: 150))
                    .frame(width: 300, height: 300).scaleEffect(scale)
                BobThumb(skin: app.skin, mood: .content, animated: true, size: 150).scaleEffect(scale)
            }
            .frame(height: 300).frame(maxWidth: .infinity)
            .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text(running ? steps[phase].0 : "Prêt ?").font(Theme.rounded(30, .bold))
                Text(running ? "\(max(0, steps[phase].1 - ticks)) s · cycle \(cycle + 1)/\(cycles)" : "\(cycles) cycles · environ \(approxMin) min")
                    .font(Theme.rounded(14, .medium)).foregroundColor(.white.opacity(0.65))
            }
            .frame(maxWidth: .infinity)

            Picker("", selection: $pattern) {
                ForEach(0..<patterns.count, id: \.self) { i in Text(patterns[i].0.components(separatedBy: " ").last ?? "").tag(i) }
            }
            .pickerStyle(SegmentedPickerStyle())
            .disabled(running)
            Text(patterns[pattern].0).font(Theme.rounded(13, .semibold)).foregroundColor(.white.opacity(0.55)).frame(maxWidth: .infinity)

            primaryButton(running ? "Arrêter" : "Commencer", running ? "stop.fill" : "play.fill", tint: tool.tint) {
                if running { stop() } else { start() }
            }
            Text("\(x.d.zenSessions) séance(s) terminée(s)").font(Theme.rounded(12.5, .medium))
                .foregroundColor(.white.opacity(0.5)).frame(maxWidth: .infinity)
        }
        .onReceive(timer) { _ in tick() }
        .onDisappear { running = false }
    }

    private var approxMin: Int {
        let per = steps.reduce(0) { $0 + $1.1 }
        return max(1, Int((Double(per * cycles) / 60).rounded()))
    }

    private func target(_ i: Int) -> CGFloat {
        let name = steps[i].0
        if name == "Inspire" { return 1 }
        if name == "Expire" { return 0.55 }
        return steps[(i + steps.count - 1) % steps.count].0 == "Inspire" ? 1 : 0.55
    }

    private func begin(_ i: Int) {
        phase = i
        ticks = 0
        withAnimation(.easeInOut(duration: Double(steps[i].1))) { scale = target(i) }
        Haptics.impact(.light)
    }

    private func start() {
        cycle = 0
        scale = 0.55
        running = true
        begin(0)
    }

    private func stop() {
        running = false
        withAnimation(.easeInOut(duration: 0.6)) { scale = 0.55 }
    }

    private func tick() {
        guard running else { return }
        ticks += 1
        guard ticks >= steps[phase].1 else { return }
        let next = phase + 1
        if next >= steps.count {
            cycle += 1
            if cycle >= cycles { finish(); return }
            begin(0)
        } else {
            begin(next)
        }
    }

    private func finish() {
        stop()
        x.d.zenSessions += 1
        app.reward(3, "Séance terminée · +3 pièces")
    }
}

// MARK: - Bilan d'humeur

struct MoodScreen: View {
    let tool: Tool
    @EnvironmentObject var app: AppState
    @ObservedObject private var x = ExtrasStore.shared
    private let faces = ["😞", "🙁", "😐", "🙂", "😄"]
    private let labels = ["Au plus bas", "Bof", "Neutre", "Bien", "Au top"]

    private var days: [Date] {
        (0..<14).reversed().map { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) ?? Date() }
    }

    var body: some View {
        ToolFrame(tool) {
            Text("Comment te sens-tu aujourd'hui ?").font(Theme.rounded(18))
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { i in
                    let on = x.d.moods[x.today] == i + 1
                    Button { log(i + 1) } label: {
                        VStack(spacing: 4) {
                            Text(faces[i]).font(.system(size: 30))
                            Text(labels[i]).font(Theme.rounded(9.5, .semibold)).foregroundColor(.white.opacity(0.65)).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, minHeight: 68)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(on ? tool.tint.opacity(0.35) : Color.white.opacity(0.07)))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(on ? tool.tint : Color.clear, lineWidth: 2))
                    }
                    .buttonStyle(PressStyle())
                    .accessibilityLabel(labels[i])
                }
            }
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("14 derniers jours").font(Theme.rounded(16))
                    Spacer()
                    if let a = average { Text("Moyenne 7 j : \(String(format: "%.1f", a))/5").font(Theme.rounded(12.5, .semibold)).foregroundColor(tool.tint) }
                }
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(days, id: \.self) { d in
                        let v = x.d.moods[AppState.day(d)] ?? 0
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(v == 0 ? Color.white.opacity(0.08) : tool.tint.opacity(0.35 + 0.13 * Double(v)))
                                .frame(height: v == 0 ? 6 : CGFloat(v) * 20)
                            Circle().fill(Calendar.current.isDateInToday(d) ? tool.tint : Color.clear).frame(width: 5, height: 5)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 118, alignment: .bottom)
            }
            .padding(14).glass(22)
        }
    }

    private var average: Double? {
        let vals = days.suffix(7).compactMap { x.d.moods[AppState.day($0)] }
        return vals.isEmpty ? nil : Double(vals.reduce(0, +)) / Double(vals.count)
    }

    private func log(_ v: Int) {
        let first = x.d.moods[x.today] == nil
        x.d.moods[x.today] = v
        if first && x.once("mood|\(x.today)") { app.reward(1, "Bilan enregistré · +1 pièce") }
        else { Haptics.impact(.light) }
    }
}

// MARK: - Pauses santé

struct BreaksScreen: View {
    let tool: Tool
    @ObservedObject private var x = ExtrasStore.shared

    private struct Kind { let id: String; let emoji: String; let title: String; let tip: String; let mult: Int; let msg: String }
    private let kinds: [Kind] = [
        Kind(id: "eyes", emoji: "👀", title: "Règle 20-20-20", tip: "Regarde à 6 m pendant 20 s", mult: 1, msg: "Regarde au loin pendant 20 secondes."),
        Kind(id: "posture", emoji: "🧍", title: "Posture", tip: "Redresse le dos, relâche les épaules", mult: 2, msg: "Redresse-toi et relâche les épaules."),
        Kind(id: "stretch", emoji: "🤸", title: "Étirements", tip: "Nuque, poignets, épaules", mult: 3, msg: "Une minute d'étirements, ça te dit ?"),
        Kind(id: "walk", emoji: "🚶", title: "Marche", tip: "Lève-toi et bouge 2 minutes", mult: 4, msg: "Lève-toi et marche un peu.")
    ]
    private let routine: [(String, String)] = [
        ("Nuque", "Penche la tête à droite puis à gauche, 15 s chaque côté."),
        ("Épaules", "10 grands cercles vers l'arrière, bras détendus."),
        ("Poignets", "Tends le bras, tire doucement les doigts vers toi, 15 s."),
        ("Dos", "Assis, tourne le buste à droite puis à gauche, 15 s."),
        ("Jambes", "Debout, monte sur la pointe des pieds 15 fois.")
    ]

    var body: some View {
        ToolFrame(tool) {
            Text("BOB te relance à intervalle régulier.").font(Theme.rounded(14, .medium)).foregroundColor(.white.opacity(0.65))
            Picker("", selection: Binding(get: { x.d.breakEvery }, set: { v in x.d.breakEvery = v; reschedule() })) {
                Text("20 min").tag(20); Text("30 min").tag(30); Text("45 min").tag(45); Text("60 min").tag(60)
            }
            .pickerStyle(SegmentedPickerStyle())
            ForEach(kinds, id: \.id) { k in
                let on = x.d.breaks.contains(k.id)
                HStack(spacing: 12) {
                    Text(k.emoji).font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(k.title).font(Theme.rounded(16))
                        Text("\(k.tip) · toutes les \(x.d.breakEvery * k.mult) min").font(Theme.rounded(12, .medium)).foregroundColor(.white.opacity(0.6))
                    }
                    Spacer(minLength: 6)
                    Toggle("", isOn: Binding(get: { on }, set: { v in
                        if v { x.d.breaks.append(k.id); Notifier.shared.request() } else { x.d.breaks.removeAll { $0 == k.id } }
                        reschedule()
                    }))
                    .labelsHidden().toggleStyle(SwitchToggleStyle(tint: tool.tint))
                }
                .padding(14).glass(20)
            }
            Text("Routine d'étirements").font(Theme.rounded(17)).padding(.top, 6)
            VStack(spacing: 0) {
                ForEach(0..<routine.count, id: \.self) { i in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(i + 1)").font(Theme.rounded(13, .bold)).foregroundColor(Color(hex: 0x1B1530))
                            .frame(width: 26, height: 26).background(Circle().fill(tool.tint))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(routine[i].0).font(Theme.rounded(15))
                            Text(routine[i].1).font(Theme.rounded(12.5, .medium)).foregroundColor(.white.opacity(0.65))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 10).padding(.horizontal, 14)
                }
            }
            .glass(20)
        }
    }

    private func reschedule() {
        Remind.cancel(kinds.map { "bob.break.\($0.id)" })
        for k in kinds where x.d.breaks.contains(k.id) {
            Remind.repeating(id: "bob.break.\(k.id)", body: k.msg, everyMin: x.d.breakEvery * k.mult)
        }
    }
}
