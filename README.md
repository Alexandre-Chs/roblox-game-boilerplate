# Roblox House Starter

Starter local pour T3 + Claude/Codex, dérivé de [frrazer](https://github.com/frrazer/roblox-game-boilerplate), avec les skills de [SyphoDev](https://www.youtube.com/@SyphoDev). Code, UI et scène versionnés dans les fichiers ; Studio sert à visualiser et tester.

## Prérequis

- Roblox Studio et son plugin Rojo 7, Git, Node.js 22+ et pnpm.
- [Rokit](https://github.com/rojo-rbx/rokit/releases/tag/v1.2.0) : télécharger le binaire adapté, puis exécuter `rokit self-install`. Les commandes du projet retrouvent automatiquement `~/.rokit/bin`.
- Python 3.11+ pour les outils artistiques ; Blender et comptes de génération seulement quand nécessaires.

## Démarrer

```sh
pnpm run setup
pnpm run check
pnpm run build
pnpm run dev
```

Utiliser **`pnpm run setup`**, pas `pnpm setup` (commande interne de pnpm). Au premier setup, Rokit peut demander de faire confiance aux outils épinglés dans rokit.toml. Accepter uniquement ceux de cette liste.

Ouvrir `build/starter.rbxlx` dans Studio. Plugins → Rojo → connecter **localhost:34873**, puis accepter la synchronisation. Ce port diffère de l'obby initial (34872). Garder `pnpm run dev` actif.

Dans T3, ouvrir **ce dossier**. Activer le MCP intégré à Studio dans Assistant → paramètres MCP. Claude Code le charge depuis `.mcp.json` (binaire `StudioMCP` de l'installation macOS standard) : approuver le serveur `Roblox_Studio` au premier lancement. Codex se connecte via Quick connect. Commencer ensuite de nouvelles sessions. Vérifier que chaque agent retrouve la bonne fenêtre. Les skills sont locaux au dépôt ; aucune installation globale n'est nécessaire. Pour Claude, `.claude/skills` pointe vers `.agents/skills`. Sous Windows, Git doit préserver les liens symboliques (mode développeur).

## Commandes

- `pnpm run dev` : synchronisation Rojo locale.
- `pnpm run check` : format, types/lint Luau, tests et build.
- `pnpm run format` : formater volontairement le code.
- `pnpm run test` : assertions locales.
- `pnpm run doctor` : outils disponibles ; ne prouve pas l'accès MCP.
- `pnpm run publish test` : publie sur l'expérience de test (voir docs/release.md). La prod exige `--confirm-prod`.

Le starter contient des fonctionnalités d'exemple à copier, adapter ou supprimer (catalogue complet dans [docs/features.md](docs/features.md), suppression dans docs/architecture.md, Example features) :

- pièces à ramasser (bonus x2 avec pass, +10 % par ami présent), compteur, colonne Coins de la liste des joueurs, classement global sur un panneau près du spawn ;
- boutique illustrée (offre du jour, rareté, packs POPULAR / BEST VALUE), offres Robux inertes tant que leurs ids valent 0, inventaire avec objets équipables (effets) ;
- récompense quotidienne sur 7 jours, quêtes de démarrage récompensées en haut à gauche, écran Récompenses (codes promo côté serveur, récompense de groupe, invitations, favori), badges inertes à 0 ;
- notifications, Réglages (volumes sauvegardés), sons et musique vérifiés, écran de chargement illustré, interface adaptée du téléphone au grand écran, traduction en/fr/es/pt-br ;
- masquage automatique des offres aléatoires payantes là où la loi les interdit (PolicyService) ;
- statistiques (funnels, économie des pièces) dans le Creator Dashboard une fois le jeu publié ;
- commandes de test dans le chat, uniquement dans Studio : `/cash 100`, `/reset`, `/unlock`, `/daily`, `/pass DoubleCoins`, `/notify texte`.

## Architecture

`src/server/Services` détient les règles et données ; `src/client/Controllers` l'interface et les interactions ; `src/shared` les contrats Packet et la configuration publique. Les registries et Lifecycle démarrent les modules. ProfileStore sauvegarde et Replica transmet les données au joueur propriétaire. Trove gère le nettoyage.

Les modèles/UI locaux sont dans `assets`, les étapes de travail dans `work` (ignoré). Consulter le [catalogue des fonctionnalités](docs/features.md), [architecture](docs/architecture.md), [assets](docs/assets.md), [skills](docs/skills.md) et [tests](docs/testing.md) pour les conventions.

## Outils artistiques locaux

`pnpm run setup:art` crée `.venv` et installe les versions testées de Pillow, NumPy, SciPy, Requests et PyYAML (Python 3.14 utilisé ici). Cela permet les aperçus UI et les plans de maps. Utiliser `.venv/bin/python` pour ces scripts sur Mac. Blender, génération 3D distante et uploads restent des étapes optionnelles à configurer par skill.

## Nouveau jeu

Créer un dépôt depuis ce modèle (ou copier les fichiers sans `.git`, les dépendances générées, `.venv`, `work`, `build` et les LOCAL.md). Renommer `default.project.json`, `package.json`, `wally.toml` et `src/shared/Config/GameConfig.luau`. Installer, vérifier, puis utiliser un nouveau projet/univers Roblox. Ajuster le port si plusieurs jeux tournent simultanément. Conserver manifestes et versions d'outils dans Git.

Prompt de départ : « Lis AGENTS.md et utilise create-roblox-game pour construire [concept]. Les fichiers sont la référence. Fais un premier niveau jouable, teste via MCP et indique les vérifications réellement effectuées. »

## Limites

Aucune publication automatique, aucun secret inclus, aucun appel payant de génération au setup. Le catalogue d'assets commence vide ; les skills fournissent des workflows, pas des abonnements ni des assets déjà licenciés. Les API artistiques se configurent à la demande dans un environnement local.

La persistance, les achats et le multijoueur doivent être testés dans Studio avant publication. Un build ne capture pas les objets créés seulement dans Studio. Les imports IA ne sont pas tous audités.

Voir [THIRD_PARTY.md](THIRD_PARTY.md) : le code de base est Unlicense, mais les skills SyphoDev **ne peuvent pas être revendus**.
