import SwiftUI

struct Pill: View {
    let label: String
    let selected: Bool
    let accent: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selected ? Color(hex: 0x0B0F20) : Color.white.opacity(0.85))
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Capsule().fill(selected ? accent : Color.white.opacity(0.07)))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: selected)
    }
}

struct SkinCard: View {
    let skin: Skin
    let selected: Bool
    let preview: Sim
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Canvas { ctx, size in
                    drawBob(&ctx, size: size, skin: skin, accs: [], mood: .happy, sim: preview)
                }
                .frame(width: 84, height: 84)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(selected ? skin.base : Color.clear, lineWidth: 2))
                Text(skin.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(selected ? 1 : 0.6))
                    .lineLimit(1)
            }
            .frame(width: 84)
            .scaleEffect(selected ? 1.06 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
        }
        .buttonStyle(.plain)
    }
}

struct Ambient: View {
    let color: Color
    @State private var pts: [(F, F, F)] = (0..<18).map { _ in
        (F.random(in: 0...1), F.random(in: 0...1), F.random(in: 0.4...1.4))
    }
    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 24) / 24
                for (i, p) in pts.enumerated() {
                    let k: Double = Double(1 + i % 2)
                    let a: Double = 2 * .pi * t * k
                    let xx: F = p.0 + F(sin(a + Double(p.1) * 9)) * 0.02
                    let yy: F = p.1 + F(sin(a + Double(p.0) * 7)) * 0.03
                    let tw: Double = 0.5 + 0.5 * sin(a + Double(p.0) * 10)
                    let r: F = min(size.width, size.height) * 0.006 * (1 + p.2 * 1.5)
                    let c = Path(ellipseIn: CGRect(x: xx * size.width - r, y: yy * size.height - r, width: 2 * r, height: 2 * r))
                    ctx.fill(c, with: .color(color.opacity(0.08 + 0.22 * tw)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold))
            .tracking(1.6)
            .foregroundColor(Color.white.opacity(0.5))
            .padding(.top, 24).padding(.bottom, 10)
    }
}

struct ContentView: View {
    @ObservedObject private var bob = Bob.shared
    @State private var preview = Sim()

    var body: some View {
        let glow = bob.skin.base
        ZStack {
            LinearGradient(colors: [Color(hex: 0x0B0F20), Color(hex: 0x151A38), Color(hex: 0x0B0F20)],
                           startPoint: .top, endPoint: .bottom).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Compagnon")
                        .font(.system(size: 30, weight: .heavy)).foregroundColor(.white)
                    Text("BOB · \(bob.skin.name)")
                        .font(.system(size: 14)).foregroundColor(Color.white.opacity(0.55))
                        .padding(.bottom, 16)

                    ZStack {
                        Ambient(color: glow)
                        BobStage()
                    }
                    .frame(height: 400)
                    .background(RadialGradient(colors: [glow.opacity(0.38), Color(hex: 0x11162E)],
                                               center: .center, startRadius: 0, endRadius: 350))
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    .animation(.easeInOut(duration: 0.5), value: bob.skinId)

                    SectionTitle(text: "Humeur")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Mood.allCases) { m in
                                Pill(label: "\(m.emoji) \(m.label)", selected: bob.mood == m, accent: glow) { bob.pickMood(m) }
                            }
                        }
                    }

                    SectionTitle(text: "Skins")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Skins.all) { s in
                                SkinCard(skin: s, selected: s.id == bob.skinId, preview: preview) { bob.pickSkin(s.id) }
                            }
                        }.padding(.vertical, 6)
                    }

                    SectionTitle(text: "Accessoires")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Acc.allCases) { a in
                                Pill(label: "\(a.emoji) \(a.label)", selected: bob.accs.contains(a), accent: glow) { bob.toggle(a) }
                            }
                        }
                    }

                    Text("Toucher : caresse · Double-toucher : saut · Glisser : il te suit des yeux")
                        .font(.system(size: 12)).foregroundColor(Color.white.opacity(0.4))
                        .padding(.top, 22).padding(.bottom, 28)
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
