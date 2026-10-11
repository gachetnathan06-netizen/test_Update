# BOB 2.0 : version iPhone (SwiftUI), compatible iOS 14+

Tout le Compagnon de bureau, sans l'errance sur les autres apps (BOB vit uniquement dans l'appli).

## Installer
1. Mets ce dossier sur un dépôt GitHub (push).
2. Onglet Actions > "Build IPA" > télécharge l'artefact `BOB-ipa` (BOB.ipa non signé).
3. Signe/installe avec Sideloadly ou AltStore.

## Fonctions
- BOB vectoriel animé (clignement, respiration, gélatine), 10 humeurs, bouche qui parle.
- Touche = poke, doigt maintenu = câlin (silhouette cœur), glisser/lancer = gravité, rebonds, traînée de slime.
- 15 packs / ~66 skins (Doré, Halloween, Noël, Laine, Moyen Âge, Télétravailleur, Pirate, Sakura, Océan, Miel, Espace, Ninja, Gardien, 12 Premium x3). Activation par pack, Tout activer/désactiver, saisonniers.
- 19 accessoires portables (tête, yeux, oreilles, cou) + signatures de skins.
- Silhouettes : cœur (câlin), carré (focus), flaque (triste / batterie faible), camouflage Ninja, surchauffe (chaleur ou mémoire faible).
- Réagit à la musique (rebondit), aux écouteurs, à la batterie.
- Pomodoro (notification de fin), rappels (ponctuels/quotidiens), bulles de dialogue.
- Nouveau : jauges faim/énergie/joie avec nourriture, pièces, niveaux, 13 succès, série quotidienne, mini-jeu Panier (lancer de boulette, difficulté progressive), photo à partager, mode chevet, ciel et décor selon l'heure, ambiance saisonnière, sommeil auto 23h-7h, notification de faim.

- Niveaux simples : 1 action = 1 point, 10 points = 1 niveau.
- Fluidité réglable (30 / 60 / 120 images/s) dans Plus > Appareil.

## Décors de saison
Quand tu portes un skin d'un pack saisonnier, BOB vit dans un décor à thème (Sources/SeasonScene.swift) :
- Noël : maison, cheminée qui fume, guirlandes et sapin qui clignotent, cadeaux, neige.
- Halloween : manoir hanté, arbre mort, citrouilles qui vacillent, chauves-souris, grande lune.
- Sakura (printemps) : cerisier en fleurs, torii, lanternes, mont Fuji, papillons.
- Océan (été) : mer, voilier, parasol, palmier, mouettes.
Le décor suit le skin, pas la date. Les skins non saisonniers gardent le décor normal.

## Sons (v5)
41 sons synthétisés (Sources/Sounds/*.wav, régénérables avec `tools/synth.py`) : poke (4 variantes), câlin, repas, boing, niveau, succès, pièces, skin/accessoire, dodo/réveil, fanfare Pomodoro, atterrissages (doux/dur selon l'impact), lancer, rebonds, panier (swish/cercle/raté/série), faim, batterie, chaleur, musique, écouteurs, photo, rappel, voix « blip » dont la hauteur suit l'humeur.
Un jingle par saison quand on choisit un skin de pack saisonnier : Noël (grelots), Halloween (grave et étrange), Sakura (koto), Été (vague + steel drum).
Réglages : Plus > Appareil > Sons + volume. Les sons se mélangent avec ta musique (jamais de coupure).


## Boutique & icône
- Nourriture consommable (stock), achat de repas et de packs (DLC) avec les pièces, cadeau quotidien : voir `Sources/ShopView.swift`.
- Au départ, seul le pack Bob est débloqué.
- L'icône est générée par `tools/make_icon.py` (Pillow) → `Sources/Assets.xcassets/AppIcon.appiconset/icon.png`.

## Nouveautés v6 : Outils (DLC utilitaires) & boutique
- **Onglet Boutique** (plus visible) + bouton Boutique dans le dock, pastille pièces ambre, bandeau « Cadeau du jour » sur l'accueil, bannière « À la une ».
- **Onglet Outils** : Focus et Panier, plus 6 DLC utilitaires à débloquer (Sources/Extras.swift) : Tâches, Hydratation (rappel 2 h), Habitudes (séries), Zen (respiration guidée), Bilan d'humeur (14 jours), Pauses santé (20-20-20, posture, étirements). Pack « Bureau Pro » = les 6 à prix réduit.
- **6 nouveaux packs de skins** (18 skins) : Vacances, Gentleman, Cosy, Rockstar, Bonbon, Cyber.
