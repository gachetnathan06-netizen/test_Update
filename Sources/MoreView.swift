import SwiftUI

struct MoreView: View {
    @EnvironmentObject var app: AppState
    @State private var bedside = false
    @State private var confirmReset = false
    private var fps: Int {
        get { let v = UserDefaults.standard.integer(forKey: "fps"); return v == 0 ? 60 : v }
        nonmutating set { UserDefaults.standard.set(newValue, forKey: "fps"); app.objectWillChange.send() }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        BobThumb(skin: app.skin, head: app.head, eyes: app.eyes, ears: app.ears, neck: app.neck, animated: true, size: 84)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Niveau \(app.level)").font(Theme.rounded(22, .bold))
                            BarProgress(value: app.levelProgress)
                            Text("\(app.s.xp % AppState.pointsPerLevel)/\(AppState.pointsPerLevel) · encore \(app.pointsToNext) action(s) pour le niveau \(app.level + 1)")
                                .font(Theme.rounded(12.5, .medium)).foregroundColor(.white.opacity(0.85))
                            Text("1 action = 1 point (nourrir, câlin, jouer, focus, panier). 10 points = 1 niveau.")
                                .font(Theme.rounded(11.5, .medium)).foregroundColor(.white.opacity(0.5))
                            Text("\(app.s.streak) jour(s) d'affilée · \(app.s.coins) pièces")
                                .font(Theme.rounded(12.5, .medium)).foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.05))
                }

                Section(header: Text("Outils")) {
                    Button { bedside = true } label: { Label("Mode chevet", systemImage: "bed.double.fill") }
                }

                Section(header: Text("Statistiques")) {
                    stat("Repas donnés", app.s.fed, "fork.knife")
                    stat("Câlins", app.s.pats, "heart.fill")
                    stat("Parties jouées", app.s.plays, "sparkles")
                    stat("Sessions Focus", app.s.pomos, "scope")
                    stat("Paniers marqués", app.s.baskets, "circle.fill")
                    stat("Skins essayés", app.s.tried.count, "square.stack.3d.up.fill")
                }

                Section(header: Text("Succès · \(app.s.unlocked.count)/\(Catalog.achievements.count)")) {
                    ForEach(Catalog.achievements) { a in
                        let v = min(a.value(app.s), a.goal)
                        let done = app.s.unlocked.contains(a.id)
                        HStack(spacing: 12) {
                            Image(systemName: done ? a.symbol : "lock.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(done ? Theme.amber : .white.opacity(0.3))
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(a.title).font(Theme.rounded(15))
                                Text(a.detail).font(Theme.rounded(12, .medium)).foregroundColor(.white.opacity(0.5))
                            }
                            Spacer()
                            Text("\(v)/\(a.goal)").font(Theme.rounded(12, .bold).monospacedDigit())
                                .foregroundColor(done ? Theme.amber : .white.opacity(0.4))
                        }
                    }
                }

                Section(header: Text("Comportement")) {
                    toggle("Gravité", \.gravity)
                    toggle("Traînée de slime", \.trail)
                    toggle("Silhouettes (cœur, carré, flaque)", \.morph)
                    toggle("Camouflage du Ninja", \.camo)
                    toggle("Indicateur de surchauffe", \.overheat)
                    toggle("Réagir à la musique", \.music)
                    toggle("Sommeil auto (23h–7h)", \.autoSleep)
                    Picker("Bavardage", selection: Binding(get: { app.s.settings.chatter }, set: { app.s.settings.chatter = $0 })) {
                        Text("Rare").tag(0)
                        Text("Normal").tag(1)
                        Text("Bavard").tag(2)
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Appareil")) {
                    toggle("Vibrations", \.haptics)
                    toggle("Sons", \.sounds)
                    if app.s.settings.sounds {
                        HStack(spacing: 10) {
                            Image(systemName: "speaker.fill").foregroundColor(.white.opacity(0.6))
                            Slider(value: Binding(get: { app.s.settings.volume }, set: { app.s.settings.volume = $0 }),
                                   in: 0.1...1, onEditingChanged: { editing in if !editing { Sound.shared.play(.poke) } })
                                .accentColor(Theme.amber)
                            Image(systemName: "speaker.wave.3.fill").foregroundColor(.white.opacity(0.6))
                        }
                    }
                    Toggle("Garder l'écran allumé", isOn: Binding(get: { app.s.settings.keepAwake }, set: { app.s.settings.keepAwake = $0; app.applyKeepAwake() }))
                    Toggle("Notifier quand BOB a faim", isOn: Binding(get: { app.s.settings.notifHunger }, set: { v in
                        app.s.settings.notifHunger = v
                        if v { Notifier.shared.request() }
                    }))
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Fluidité : \(fps) images/s", systemImage: "bolt.fill")
                        Picker("", selection: Binding(get: { fps }, set: { fps = $0 })) {
                            Text("30").tag(30)
                            Text("60").tag(60)
                            Text("120").tag(120)
                        }
                        .pickerStyle(.segmented)
                        Text("60 = fluide partout. 120 = écrans ProMotion seulement (iPhone 13 Pro et +, iOS 15+). 30 économise la batterie.")
                            .font(Theme.rounded(11.5, .medium)).foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Focus")) {
                    Stepper("Focus : \(app.s.settings.focusMin) min", value: Binding(get: { app.s.settings.focusMin }, set: { app.s.settings.focusMin = $0 }), in: 5...90, step: 5)
                    Stepper("Pause : \(app.s.settings.shortMin) min", value: Binding(get: { app.s.settings.shortMin }, set: { app.s.settings.shortMin = $0 }), in: 1...30)
                    Stepper("Longue : \(app.s.settings.longMin) min", value: Binding(get: { app.s.settings.longMin }, set: { app.s.settings.longMin = $0 }), in: 5...60, step: 5)
                }

                Section(footer: Text("Compagnon BOB 2.0 · version iPhone").font(Theme.rounded(12, .medium))) {
                    Button { confirmReset = true } label: { Label("Réinitialiser BOB", systemImage: "arrow.counterclockwise") }
                }
            }
            .background(Theme.ink.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Plus")
            .accentColor(Theme.amber)
            .actionSheet(isPresented: $confirmReset) {
                ActionSheet(title: Text("Tout remettre à zéro ?"),
                            buttons: [.destructive(Text("Réinitialiser")) { app.resetAll() }, .cancel(Text("Annuler"))])
            }
            .sheet(isPresented: $bedside) { BedsideView() }
        }
        .foregroundColor(.white)
    }

    private func stat(_ t: String, _ v: Int, _ icon: String) -> some View {
        HStack {
            Label(t, systemImage: icon)
            Spacer()
            Text("\(v)").font(Theme.rounded(15, .bold).monospacedDigit()).foregroundColor(Theme.amber)
        }
    }

    private func toggle(_ t: String, _ kp: WritableKeyPath<Settings, Bool>) -> some View {
        Toggle(t, isOn: Binding(get: { app.s.settings[keyPath: kp] }, set: { app.s.settings[keyPath: kp] = $0 }))
    }
}

struct BedsideView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.presentationMode) private var presentationMode
    private func dismiss() { presentationMode.wrappedValue.dismiss() }
    @State private var hint = true

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 26) {
                TimelineView(.periodic(from: Date(), by: 1)) { tl in
                    Text(tl.date.timeStr)
                        .font(Font.system(size: 92, weight: .thin, design: .rounded).monospacedDigit())
                        .foregroundColor(Theme.amber.opacity(0.85))
                }
                BobThumb(skin: app.skin, mood: .endormi, animated: true, size: 150)
                    .opacity(0.8)
                    .overlay(
                        Text("z z z").font(Theme.rounded(18, .bold)).foregroundColor(.white.opacity(0.4)).offset(x: 10, y: 10),
                        alignment: .topTrailing
                    )
                Text("Touche deux fois pour quitter")
                    .font(Theme.rounded(13, .medium)).foregroundColor(.white.opacity(hint ? 0.35 : 0))
            }
        }
        .onTapGesture(count: 2) { dismiss() }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { withAnimation(.easeOut(duration: 1.5)) { hint = false } }
        }
        .onDisappear { app.applyKeepAwake() }
        .statusBarHidden(true)
        .environment(\.colorScheme, .dark)
    }
}
