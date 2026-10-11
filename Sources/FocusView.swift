import SwiftUI

struct FocusView: View {
    @EnvironmentObject var app: AppState
    @State private var showAdd = false

    private func fmt(_ s: Int) -> String { String(format: "%02d:%02d", s / 60, s % 60) }

    private var remindersHeader: some View {
        HStack {
            Text("Rappels").font(Theme.rounded(17)).foregroundColor(.white)
            Spacer()
            Button { showAdd = true } label: { Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(Theme.amber) }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    timerBlock
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
                Section(header: remindersHeader) {
                    ForEach(app.s.reminders) { r in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(r.title).font(Theme.rounded(16))
                                Text(r.daily ? "Tous les jours · \(r.time.timeStr)"
                                              : r.time.dateTimeStr)
                                    .font(Theme.rounded(12, .medium)).foregroundColor(.white.opacity(0.55))
                            }
                            Spacer()
                            Toggle("", isOn: Binding(get: { r.enabled }, set: { v in var n = r; n.enabled = v; app.updateReminder(n) }))
                                .labelsHidden()
                        }
                        .listRowBackground(Color.white.opacity(0.05))
                    }
                    .onDelete { app.deleteReminders(at: $0) }
                    if app.s.reminders.isEmpty {
                        Text("Aucun rappel. BOB te préviendra à l'heure choisie.")
                            .font(Theme.rounded(13, .medium)).foregroundColor(.white.opacity(0.5))
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .background(Theme.ink.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Focus")
            .sheet(isPresented: $showAdd) { AddReminderSheet() }
        }
        .foregroundColor(.white)
    }

    private var timerBlock: some View {
        VStack(spacing: 18) {
            Picker("", selection: Binding(get: { app.pomoPhase }, set: { app.pomoSet($0) })) {
                Text("Focus").tag(PomoPhase.focus)
                Text("Pause").tag(PomoPhase.short)
                Text("Longue").tag(PomoPhase.long)
            }
            .pickerStyle(.segmented)

            ZStack {
                Circle().stroke(Color.white.opacity(0.08), lineWidth: 12)
                Circle()
                    .trim(from: 0, to: max(0.001, app.pomoProgress))
                    .stroke(Theme.amber, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1))
                VStack(spacing: 2) {
                    BobThumb(skin: app.skin, mood: app.pomoPhase == .focus ? .concentre : .heureux,
                             head: app.head, eyes: app.eyes, ears: app.ears, neck: app.neck,
                             square: app.pomoPhase == .focus && app.s.settings.morph ? 1 : 0, animated: true, size: 92)
                    Text(fmt(app.pomoRemaining))
                        .font(Font.system(size: 50, weight: .semibold, design: .rounded).monospacedDigit())
                    Text(app.pomoPhase.title).font(Theme.rounded(13, .medium)).foregroundColor(.white.opacity(0.55))
                }
            }
            .frame(width: 268, height: 268)
            .padding(.top, 4)

            HStack(spacing: 14) {
                Button { app.pomoReset() } label: {
                    Image(systemName: "arrow.counterclockwise").font(.system(size: 18, weight: .semibold))
                        .frame(width: 54, height: 54).glass(27)
                }
                Button {
                    if app.pomoRunning { app.pomoPause() } else { app.pomoStart() }
                } label: {
                    Label(app.pomoRunning ? "Pause" : (app.pomoPaused == nil ? "Démarrer" : "Reprendre"),
                          systemImage: app.pomoRunning ? "pause.fill" : "play.fill")
                        .font(Theme.rounded(18, .bold))
                        .foregroundColor(Theme.ink)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(Capsule().fill(Theme.amber))
                }
                Button { app.pomoSkip() } label: {
                    Image(systemName: "forward.end.fill").font(.system(size: 18, weight: .semibold))
                        .frame(width: 54, height: 54).glass(27)
                }
            }
            .buttonStyle(PressStyle())

            Text("Aujourd'hui : \(app.s.pomoDay == AppState.day(Date()) ? app.s.pomoToday : 0) session(s) · Total : \(app.s.pomos)")
                .font(Theme.rounded(13, .medium)).foregroundColor(.white.opacity(0.55))
        }
        .padding(.vertical, 8)
    }
}

struct AddReminderSheet: View {
    @EnvironmentObject var app: AppState
    @Environment(\.presentationMode) private var presentationMode
    private func dismiss() { presentationMode.wrappedValue.dismiss() }
    @State private var title = ""
    @State private var time = Date().addingTimeInterval(3600)
    @State private var daily = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Rappel")) {
                    TextField("Ex : boire de l'eau", text: $title)
                    Toggle("Tous les jours", isOn: $daily)
                    DatePicker("Quand", selection: $time, displayedComponents: daily ? [.hourAndMinute] : [.date, .hourAndMinute])
                }
            }
            .background(Theme.ink.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Nouveau rappel", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Annuler") { dismiss() },
                trailing: Button("Ajouter") {
                    let t = title.trimmingCharacters(in: .whitespaces)
                    app.addReminder(Reminder(title: t.isEmpty ? "Coucou de BOB" : t, time: time, daily: daily))
                    dismiss()
                }
            )
        }
        .environment(\.colorScheme, .dark)
    }
}
