import SwiftUI

/// Boutique : nourriture (consommable) et packs (DLC) à débloquer avec les pièces.
/// Mode "Operate" : on scanne, on compare, on achète. Le plaisir est dans les détails (aperçus de BOB, rebonds).
struct ShopView: View {
    @EnvironmentObject var app: AppState
    @Environment(\.presentationMode) private var presentation
    @State private var tab = 0
    @State private var bumped: String? = nil

    private let ink = Color(hex: 0x1B1530)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    balance
                    giftCard
                    Picker("", selection: $tab) {
                        Text("Nourriture").tag(0)
                        Text("Packs").tag(1)
                    }
                    .pickerStyle(.segmented)
                    if tab == 0 { foodGrid } else { packSections }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .background(Theme.ink.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Boutique", displayMode: .inline)
            .navigationBarItems(trailing: Button("Fermer") { presentation.wrappedValue.dismiss() })
        }
        .foregroundColor(.white)
    }

    // MARK: Solde

    private var balance: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "circle.fill").font(.system(size: 14)).foregroundColor(Theme.amber)
            Text("\(app.s.coins)").font(Theme.rounded(40, .bold))
            Text("pièces").font(Theme.rounded(15, .medium)).foregroundColor(.white.opacity(0.65))
            Spacer()
        }
        .padding(.top, 6)
        .accessibilityElement(children: .combine)
    }

    // MARK: Cadeau du jour

    private var giftCard: some View {
        let ready = app.giftReady
        return Button {
            if app.claimGift() { bump("gift") }
        } label: {
            HStack(spacing: 12) {
                Text("🎁").font(.system(size: 30))
                    .scaleEffect(bumped == "gift" ? 1.3 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.45))
                VStack(alignment: .leading, spacing: 2) {
                    Text(ready ? "Cadeau du jour" : "Cadeau récupéré").font(Theme.rounded(16))
                    Text(ready ? "5 pièces et un repas surprise" : "Reviens demain pour le suivant")
                        .font(Theme.rounded(12.5, .medium)).foregroundColor(.white.opacity(0.65))
                }
                Spacer()
                if ready {
                    Text("Ouvrir").font(Theme.rounded(13, .bold)).foregroundColor(ink)
                        .padding(.horizontal, 14).frame(minHeight: 36)
                        .background(Capsule().fill(Theme.amber))
                } else {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.mint).font(.system(size: 20))
                }
            }
            .padding(14)
            .glass(20)
            .opacity(ready ? 1 : 0.7)
        }
        .buttonStyle(PressStyle())
        .disabled(!ready)
        .accessibility(label: Text(ready ? "Ouvrir le cadeau du jour" : "Cadeau du jour déjà récupéré"))
    }

    // MARK: Nourriture

    private var foodGrid: some View {
        FlowGrid(columns: 2, spacing: 12, cells: Catalog.foods.map { AnyView(foodCard($0)) } + [AnyView(tipCard)])
    }

    private func foodCard(_ f: Food) -> some View {
        let n = app.stock(f.id)
        return VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(RadialGradient(colors: [Theme.amber.opacity(0.28), .clear], center: .center, startRadius: 2, endRadius: 52))
                    Text(f.emoji)
                        .font(.system(size: 46))
                        .scaleEffect(bumped == f.id ? 1.28 : 1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.45))
                }
                .frame(height: 88)
                .frame(maxWidth: .infinity)
                stockBadge(n)
            }
            VStack(spacing: 6) {
                Text(f.name).font(Theme.rounded(16))
                HStack(spacing: 10) {
                    effect("fork.knife", f.faim, Theme.amber)
                    effect("heart.fill", f.joie, Theme.rose)
                    effect("bolt.fill", f.energie, Theme.sky)
                }
            }
            VStack(spacing: 4) {
                priceButton("+1", price: f.cost) { buy(f, 1) }
                Button { buy(f, 5) } label: {
                    Text("Lot de 5 · \(f.cost * 5)")
                        .font(Theme.rounded(12, .semibold))
                        .foregroundColor(app.s.coins >= f.cost * 5 ? Theme.amber : .white.opacity(0.4))
                        .frame(maxWidth: .infinity, minHeight: 36)
                }
                .buttonStyle(PressStyle())
                .accessibility(label: Text("Acheter 5 \(f.name) pour \(f.cost * 5) pièces"))
            }
        }
        .padding(12)
        .glass(22)
    }

    private func stockBadge(_ n: Int) -> some View {
        Text("\(n)")
            .font(Theme.rounded(12, .bold))
            .foregroundColor(n > 0 ? ink : .white.opacity(0.75))
            .frame(minWidth: 24, minHeight: 24)
            .padding(.horizontal, 2)
            .background(Capsule().fill(n > 0 ? Theme.mint : Color.white.opacity(0.14)))
            .accessibility(label: Text("En stock : \(n)"))
    }

    private func effect(_ symbol: String, _ v: Double, _ color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: symbol).font(.system(size: 9, weight: .bold)).foregroundColor(color)
            Text("+\(Int(v))").font(Theme.rounded(11, .semibold)).foregroundColor(.white.opacity(0.7))
        }
    }

    private var tipCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "sparkles").font(.system(size: 20)).foregroundColor(Theme.amber)
            Text("Où trouver des pièces ?").font(Theme.rounded(14))
            Text("Monte de niveau, débloque des succès et enchaîne les sessions de focus.")
                .font(Theme.rounded(12, .medium)).foregroundColor(.white.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .strokeBorder(Color.white.opacity(0.16), style: StrokeStyle(lineWidth: 1, dash: [5, 5])))
    }

    private func buy(_ f: Food, _ qty: Int) {
        if app.buyFood(f, qty: qty) { bump(f.id) }
    }

    // MARK: Packs

    private var packSections: some View {
        let all = Catalog.packs.filter { $0.id != "bob" }
        let locked = all.filter { !app.owns($0.id) }.sorted { a, b in
            let sa = a.season?.isActive() == true, sb = b.season?.isActive() == true
            if sa != sb { return sa }
            return Catalog.price(a) < Catalog.price(b)
        }
        let owned = all.filter { app.owns($0.id) }
        return VStack(alignment: .leading, spacing: 24) {
            if locked.isEmpty {
                VStack(spacing: 8) {
                    Text("🎉").font(.system(size: 44))
                    Text("Tout est débloqué").font(Theme.rounded(18))
                    Text("BOB a toute sa garde-robe.").font(Theme.rounded(13, .medium)).foregroundColor(.white.opacity(0.65))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 28)
            } else {
                section("À débloquer", count: locked.count) {
                    ForEach(locked) { p in packCard(p, owned: false) }
                }
            }
            if !owned.isEmpty {
                section("Possédés", count: owned.count) {
                    ForEach(owned) { p in packCard(p, owned: true) }
                }
            }
        }
    }

    private func section<C: View>(_ title: String, count: Int, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(title).font(Theme.rounded(17))
                Text("\(count)").font(Theme.rounded(12, .bold)).foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8).padding(.vertical, 2).background(Capsule().fill(Color.white.opacity(0.1)))
            }
            content()
        }
    }

    private func packCard(_ p: Pack, owned: Bool) -> some View {
        let price = Catalog.price(p)
        let inSeason = p.season?.isActive() == true
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: p.icon)
                    .font(.system(size: 18)).foregroundColor(Theme.amber)
                    .frame(width: 40, height: 40)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.amber.opacity(0.14)))
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(p.name).font(Theme.rounded(17))
                        if inSeason { tag("En saison", Theme.amber) }
                    }
                    Text(p.blurb).font(Theme.rounded(13, .medium)).foregroundColor(.white.opacity(0.65))
                }
                Spacer(minLength: 0)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(p.skins) { sk in
                        BobThumb(skin: sk, size: 66)
                            .frame(width: 78, height: 78)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white.opacity(0.06)))
                    }
                }
            }
            if owned {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.mint)
                    Text("Possédé").font(Theme.rounded(14, .semibold)).foregroundColor(Theme.mint)
                    Spacer()
                }
            } else {
                priceButton("Débloquer", price: price) { if app.buyPack(p) { bump(p.id) } }
            }
        }
        .padding(14)
        .glass(22)
        .scaleEffect(bumped == p.id ? 1.02 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.55))
    }

    private func tag(_ t: String, _ c: Color) -> some View {
        Text(t).font(Theme.rounded(10, .bold)).foregroundColor(c)
            .padding(.horizontal, 7).padding(.vertical, 2)
            .background(Capsule().fill(c.opacity(0.18)))
    }

    // MARK: Bouton d'achat

    /// Abordable : bouton ambre. Sinon : on dit combien il manque (plus utile qu'un bouton grisé muet).
    private func priceButton(_ label: String, price: Int, _ action: @escaping () -> Void) -> some View {
        let ok = app.s.coins >= price
        return Button(action: action) {
            HStack(spacing: 6) {
                if ok {
                    Text(label)
                    Image(systemName: "circle.fill").font(.system(size: 9))
                    Text("\(price)")
                } else {
                    Image(systemName: "lock.fill").font(.system(size: 11))
                    Text("Il manque \(price - app.s.coins)")
                }
            }
            .font(Theme.rounded(14, .bold))
            .foregroundColor(ok ? ink : .white.opacity(0.55))
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ok ? Theme.amber : Color.white.opacity(0.08)))
        }
        .buttonStyle(PressStyle())
        .accessibility(label: Text(ok ? "\(label), \(price) pièces" : "Il te manque \(price - app.s.coins) pièces"))
    }

    private func bump(_ id: String) {
        bumped = id
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) { if bumped == id { bumped = nil } }
    }
}
