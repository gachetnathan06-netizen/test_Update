import SwiftUI

struct BobThumb: View {
    var skin: Skin
    var mood: Mood = .content
    var head: Prop? = nil
    var eyes: Prop? = nil
    var ears: Prop? = nil
    var neck: Prop? = nil
    var square: CGFloat = 0
    var animated = false
    var size: CGFloat = 72

    var body: some View {
        Group {
            if animated {
                AnimatedCanvas(maxFPS: 30) { ctx, sz, date in
                    paint(ctx, sz, time: date.timeIntervalSinceReferenceDate)
                }
            } else {
                Canvas { ctx, sz in paint(ctx, sz, time: 0) }
            }
        }
        .frame(width: size * 1.1, height: size * 1.1)
    }

    private func paint(_ ctx: GraphicsContext, _ sz: CGSize, time: Double) {
        var l = BobLook(skin: skin, mood: mood)
        l.head = head
        l.eyes = eyes
        l.ears = ears
        l.neck = neck
        l.square = square
        l.time = time
        l.blink = animated && sin(time * 1.3) > 0.97 ? 0.9 : 0
        BobRenderer.draw(ctx, at: CGPoint(x: sz.width / 2, y: sz.height * 0.92), width: size * 0.70, look: l)
    }
}

struct MeterBar: View {
    var symbol: String
    var value: Double
    var color: Color
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(value < 20 ? Theme.rose : color)
                .frame(width: 14)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.16))
                Capsule().fill(value < 20 ? Theme.rose : color)
                    .frame(width: max(4, 64 * value / 100))
            }
            .frame(width: 64, height: 5)
        }
        .animation(.easeOut(duration: 0.4), value: value)
    }
}

struct SpeechBubble: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let body = CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height - 10)
        p.addRoundedRect(in: body, cornerSize: CGSize(width: 18, height: 18), style: .continuous)
        p.move(to: CGPoint(x: r.midX - 9, y: body.maxY - 0.5))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.midX + 9, y: body.maxY - 0.5))
        p.closeSubpath()
        return p
    }
}

struct DockButton: View {
    var symbol: String
    var label: String
    var active = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 21, weight: .semibold))
                    .frame(height: 26)
                Text(label).font(Theme.rounded(10.5, .semibold))
            }
            .foregroundColor(active ? Theme.amber : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressStyle())
    }
}

struct HomeView: View {
    @EnvironmentObject var app: AppState
    @State private var showFood = false
    @State private var showShop = false
    @State private var shareImage: UIImage?
    @State private var showShare = false

    var body: some View {
        ZStack {
            StageView()
            LinearGradient(colors: [.black.opacity(0.35), .clear], startPoint: .top, endPoint: .init(x: 0.5, y: 0.22))
                .ignoresSafeArea().allowsHitTesting(false)

            VStack(spacing: 0) {
                topBar
                if app.giftReady { giftChip.padding(.top, 8).transition(.scale.combined(with: .opacity)) }
                Spacer()
            }

            GeometryReader { g in
                if !app.bubble.isEmpty {
                    Text(app.bubble)
                        .font(Theme.rounded(17, .semibold))
                        .foregroundColor(Color(hex: 0x1B1530))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .padding(.bottom, 10)
                        .frame(maxWidth: min(g.size.width - 64, 300))
                        .background(SpeechBubble().fill(Color(hex: 0xFFF8EC)))
                        .shadow(color: .black.opacity(0.25), radius: 14, y: 6)
                        .position(x: g.size.width / 2, y: g.size.height * 0.30)
                        .transition(.scale(scale: 0.85, anchor: .bottom).combined(with: .opacity))
                }
            }
            .allowsHitTesting(false)
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: app.bubble.isEmpty)

            VStack(spacing: 10) {
                Spacer()
                if showFood { foodTray.transition(.move(edge: .bottom).combined(with: .opacity)) }
                dock
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showShare) {
            if let img = shareImage { ShareSheet(items: [img]) }
        }
        .background(
            Color.clear.sheet(isPresented: $showShop) { ShopView().environmentObject(app) }
        )
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 7) {
                MeterBar(symbol: "fork.knife", value: app.s.faim, color: Theme.amber)
                MeterBar(symbol: "bolt.fill", value: app.s.energie, color: Theme.sky)
                MeterBar(symbol: "heart.fill", value: app.s.joie, color: Theme.rose)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .glass(16)
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 10) {
                    Button { showShop = true } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "circle.fill").font(.system(size: 10))
                            Text("\(app.s.coins)")
                            Image(systemName: "cart.fill").font(.system(size: 11))
                        }
                        .foregroundColor(Color(hex: 0x1B1530))
                        .padding(.horizontal, 10).frame(minHeight: 30)
                        .background(Capsule().fill(Theme.amber))
                    }
                    .buttonStyle(PressStyle())
                    Text("Niv. \(app.level) · \(app.s.xp % AppState.pointsPerLevel)/\(AppState.pointsPerLevel)").foregroundColor(.white.opacity(0.75))
                }
                .font(Theme.rounded(13))
                .padding(.horizontal, 12).padding(.vertical, 8)
                .glass(14)
                moodMenu
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }

    private var giftChip: some View {
        Button { showShop = true } label: {
            HStack(spacing: 8) {
                Text("🎁")
                Text("Cadeau du jour à ouvrir").font(Theme.rounded(13, .bold))
                Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(Color(hex: 0x1B1530))
            .padding(.horizontal, 14).frame(minHeight: 38)
            .background(Capsule().fill(Theme.amber))
            .shadow(color: Theme.amber.opacity(0.45), radius: 12, y: 4)
        }
        .buttonStyle(PressStyle())
    }

    private var moodMenu: some View {
        let m = app.mood(temp: nil)
        return Menu {
            Button { app.s.forced = nil } label: { Label("Automatique", systemImage: "wand.and.stars") }
            ForEach(Mood.allCases) { mo in
                Button { app.s.forced = mo.rawValue } label: { Label(mo.label, systemImage: mo.symbol) }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: m.symbol)
                Text(app.s.forced == nil ? m.label : "\(m.label) · fixé")
            }
            .font(Theme.rounded(12))
            .foregroundColor(app.s.forced == nil ? .white : Theme.amber)
            .padding(.horizontal, 12).padding(.vertical, 8)
            .glass(14)
        }
    }

    private var foodTray: some View {
        HStack(spacing: 2) {
            ForEach(Catalog.foods) { f in
                let n = app.stock(f.id)
                Button {
                    if app.feed(f) { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { showFood = false } }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Text(f.emoji).font(.system(size: 32))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .opacity(n > 0 ? 1 : 0.3)
                        Text("\(n)")
                            .font(Theme.rounded(10.5, .bold))
                            .foregroundColor(n > 0 ? Color(hex: 0x1B1530) : .white.opacity(0.7))
                            .frame(minWidth: 18, minHeight: 18)
                            .background(Capsule().fill(n > 0 ? Theme.mint : Color.white.opacity(0.16)))
                            .offset(x: -4, y: 2)
                    }
                }
                .buttonStyle(PressStyle())
                .accessibilityLabel("\(f.name), \(n) en stock")
            }
            Button { showShop = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "cart.fill").font(.system(size: 20)).foregroundColor(Theme.amber)
                        .frame(maxWidth: .infinity, minHeight: 52)
                    if app.giftReady {
                        Circle().fill(Theme.rose).frame(width: 10, height: 10).offset(x: -8, y: 10)
                    }
                }
            }
            .buttonStyle(PressStyle())
            .accessibilityLabel("Boutique")
        }
        .padding(.horizontal, 6)
        .glass(22)
    }

    private var dock: some View {
        HStack(spacing: 0) {
            DockButton(symbol: "fork.knife", label: "Nourrir", active: showFood) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { showFood.toggle() }
            }
            DockButton(symbol: "heart.fill", label: "Câlin") { app.hug() }
            DockButton(symbol: "sparkles", label: "Jouer") { app.play() }
            DockButton(symbol: app.s.sleeping ? "sun.max.fill" : "moon.zzz.fill", label: app.s.sleeping ? "Réveil" : "Dormir", active: app.s.sleeping) { app.toggleSleep() }
            DockButton(symbol: "cart.fill", label: "Boutique", active: true) { showShop = true }
            DockButton(symbol: "camera.fill", label: "Photo") { snapshot() }
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .glass(26)
    }

    @MainActor private func snapshot() {
        let v = SnapshotView(skin: app.skin, mood: app.mood(temp: nil), head: app.head, eyes: app.eyes, ears: app.ears, neck: app.neck)
        let size = CGSize(width: 360, height: 450)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 3
        let img = UIGraphicsImageRenderer(size: size, format: fmt).image { r in
            v.paint(GraphicsContext(r.cgContext), size)
        }
        shareImage = img
        showShare = true
        Sound.shared.play(.shutter)
        Haptics.success()
    }
}

struct SnapshotView: View {
    var skin: Skin
    var mood: Mood
    var head: Prop?
    var eyes: Prop?
    var ears: Prop?
    var neck: Prop?
    var body: some View {
        Canvas { ctx, size in paint(ctx, size) }
        .frame(width: 360, height: 450)
    }

    func paint(_ ctx: GraphicsContext, _ size: CGSize) {
        do {
            let date = Date()
            let floorY = size.height * 0.74
            let bw = size.width * 0.58
            Backdrop.draw(ctx, size: size, floorY: floorY, date: date, time: 1, bodyW: bw, scene: SeasonScene.season(of: skin))
            ctx.fill(Path(ellipseIn: CGRect(x: size.width / 2 - bw * 0.41, y: floorY - bw * 0.03, width: bw * 0.82, height: bw * 0.13)), with: .color(.black.opacity(0.3)))
            var l = BobLook(skin: skin, mood: mood == .endormi ? .content : mood)
            l.head = head
            l.eyes = eyes
            l.ears = ears
            l.neck = neck
            l.time = 1
            BobRenderer.draw(ctx, at: CGPoint(x: size.width / 2, y: floorY), width: bw, look: l)
            ctx.drawText("BOB", at: CGPoint(x: size.width / 2, y: size.height - 24), size: 15,
                         weight: .heavy, rounded: true, color: .white.opacity(0.7))
        }
    }
}
