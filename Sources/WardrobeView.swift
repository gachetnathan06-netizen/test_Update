import SwiftUI

struct WardrobeView: View {
    @EnvironmentObject var app: AppState
    @State private var tab = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Picker("", selection: $tab) {
                        Text("Skins").tag(0)
                        Text("Accessoires").tag(1)
                        Text("Packs").tag(2)
                    }
                    .pickerStyle(.segmented)
                    if tab == 0 { skins }
                    if tab == 1 { accessories }
                    if tab == 2 { packs }
                }
                .padding(16)
            }
            .background(Theme.ink.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Garde-robe", displayMode: .large)
        }
    }

    // MARK: Skins
    private var skins: some View {
        VStack(alignment: .leading, spacing: 22) {
            if let s = Season.current, let p = app.enabledPacks.first(where: { $0.season == s }) {
                Button { if let f = p.skins.first { app.chooseSkin(f) } } label: {
                    HStack(spacing: 12) {
                        Image(systemName: p.icon).font(.system(size: 20)).foregroundColor(Theme.amber)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(s.label), c'est la saison").font(Theme.rounded(15))
                            Text("Essayer le pack \(p.name)").font(Theme.rounded(13, .medium)).foregroundColor(.white.opacity(0.65))
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.4))
                    }
                    .padding(14)
                    .glass(18)
                }
                .buttonStyle(PressStyle())
            }
            ForEach(app.enabledPacks) { p in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: p.icon).foregroundColor(Theme.amber)
                        Text(p.name).font(Theme.rounded(17))
                        Text(p.blurb).font(Theme.rounded(13, .medium)).foregroundColor(.white.opacity(0.5))
                    }
                    FlowGrid(spacing: 10, cells: p.skins.map { sk in
                        AnyView(tile(selected: app.s.skinID == sk.id, name: sk.name) {
                            app.chooseSkin(sk)
                        } thumb: {
                            BobThumb(skin: sk, head: app.head, eyes: app.eyes, ears: app.ears, neck: app.neck, size: 78)
                        })
                    })
                }
            }
        }
        .foregroundColor(.white)
    }

    // MARK: Accessoires
    private var accessories: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(PropCategory.allCases) { cat in
                VStack(alignment: .leading, spacing: 10) {
                    Text(cat.title).font(Theme.rounded(17))
                    FlowGrid(spacing: 10, cells: accessoryCells(cat))
                }
            }
        }
        .foregroundColor(.white)
    }

    private func accessoryCells(_ cat: PropCategory) -> [AnyView] {
        var cells: [AnyView] = [
            AnyView(tile(selected: app.prop(for: cat) == nil, name: "Aucun") {
                app.equip(cat, nil)
            } thumb: {
                BobThumb(skin: app.skin, size: 78)
            })
        ]
        for p in Prop.wearables.filter({ $0.category == cat }) {
            cells.append(AnyView(tile(selected: app.prop(for: cat) == p, name: p.name) {
                app.equip(cat, p)
            } thumb: {
                BobThumb(skin: app.skin, head: cat == .tete ? p : nil, eyes: cat == .yeux ? p : nil,
                         ears: cat == .oreilles ? p : nil, neck: cat == .cou ? p : nil, size: 78)
            }))
        }
        return cells
    }

    // MARK: Packs
    private var packs: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                chip("Tout activer (possédés)") { app.enableAllPacks() }
                chip("Tout désactiver") { app.disableAllPacks() }
                chip("Saisonniers (\(app.seasonalPacks.count))") { app.enableSeasonal() }
            }
            ForEach(Catalog.packs) { p in
                let owned = app.owns(p.id)
                let on = owned && (p.id == "bob" || !app.s.disabled.contains(p.id))
                HStack(spacing: 12) {
                    Image(systemName: p.icon).font(.system(size: 18)).foregroundColor(on ? Theme.amber : .white.opacity(0.3)).frame(width: 26)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(p.name).font(Theme.rounded(16))
                            if let s = p.season {
                                Text(s.label).font(Theme.rounded(10, .bold)).padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Capsule().fill(Theme.amber.opacity(0.2))).foregroundColor(Theme.amber)
                            }
                        }
                        Text("\(p.skins.count) skin\(p.skins.count > 1 ? "s" : "") · \(p.blurb)")
                            .font(Theme.rounded(12, .medium)).foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    if owned {
                        Toggle("", isOn: Binding(get: { on }, set: { app.setPack(p.id, enabled: $0) }))
                            .labelsHidden().disabled(p.id == "bob")
                    } else {
                        Button { app.buyPack(p) } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill").font(.system(size: 10))
                                Text("\(Catalog.price(p))")
                            }
                            .font(Theme.rounded(13, .bold))
                            .foregroundColor(Color(hex: 0x1B1530))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Capsule().fill(Theme.amber))
                            .opacity(app.s.coins >= Catalog.price(p) ? 1 : 0.4)
                        }
                        .buttonStyle(PressStyle())
                    }
                }
                .padding(.vertical, 6)
                Divider().overlay(Color.white.opacity(0.08))
            }
        }
        .foregroundColor(.white)
    }

    private func chip(_ t: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Text(t).font(Theme.rounded(12.5)).padding(.horizontal, 12).padding(.vertical, 8).glass(14)
        }
        .buttonStyle(PressStyle())
    }

    private func tile<T: View>(selected: Bool, name: String, action: @escaping () -> Void, @ViewBuilder thumb: () -> T) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                thumb()
                Text(name).font(Theme.rounded(12, .semibold)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8).padding(.horizontal, 4)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(selected ? Theme.amber.opacity(0.14) : Color.white.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(selected ? Theme.amber : Color.white.opacity(0.06), lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(PressStyle())
    }
}
