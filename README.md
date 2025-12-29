# Closet Buddy 👗🧥

**Closet Buddy** est une application Flutter qui vous aide à cataloguer et gérer votre garde-robe : ajouter des vêtements avec photo, modifier des éléments, filtrer par catégorie et couleur, et gérer l'authentification via Firebase.

---

## ✨ Fonctionnalités principales

- **Authentification** via Firebase Auth (redirige vers l'écran d'authentification quand l'utilisateur est déconnecté)
- **Ajouter / Modifier / Supprimer** des vêtements (photo, catégorie principale/sous-catégorie, couleur)
- **Upload d'images** dans Firebase Storage avec gestion des erreurs et tentatives
- **Filtrage** par catégorie principale, sous-catégorie et couleur (option "Tout" + réinitialiser)
- **Sécurité** : support de Firebase App Check

---

## 🚀 Prérequis

- Flutter SDK (stable) installé
- Un projet Firebase configuré (Auth, Firestore, Storage)
- `google-services.json` (Android) et/ou `GoogleService-Info.plist` (iOS) **ou** fichier `firebase_options.dart` généré via `flutterfire`

---

## 🛠️ Installation & Configuration

1. Clonez le dépôt et placez-vous dans le dossier du projet :

```bash
cd closet_buddy
```

2. Installez les dépendances :

```bash
flutter pub get
```

3. (Optionnel) Si vous n'avez pas `firebase_options.dart` configuré :

- Installez et configurez `flutterfire` :

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

4. Ajoutez les fichiers de configuration Firebase (Android/iOS) si nécessaire :

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

5. Lancez l'application :

```bash
flutter run
```

> 💡 Si `flutter pub outdated` signale des packages obsolètes, vous pouvez mettre à jour les dépendances en évaluant d'abord la compatibilité puis en modifiant `pubspec.yaml`.

---

## ⚙️ Configuration Firebase & App Check

- Le projet active **Firebase App Check** (voir `main.dart`). En mode debug, un provider de debug est utilisé — en production, configurez le provider approprié (Play Integrity / DeviceCheck).
- Vérifiez que le bucket Storage utilisé est correctement configuré et accessible par vos règles Firebase.

---

## 📱 Utilisation

- **Connexion** : l'app redirige vers `AuthScreen` si l'utilisateur n'est pas connecté.
- **Ajouter un vêtement** : `Ajouter` → sélectionnez une image, catégorie principale → sous-catégorie → couleur (sélecteur visuel), puis validez.
- **Modifier** : depuis une carte de vêtement, appuyez sur l'élément pour ouvrir l'écran d'édition.
- **Filtrer** : utilisez les dropdowns en haut pour filtrer par catégorie principale, sous-catégorie et couleur. Choisissez `Tout` pour désactiver un filtre. Le bouton `Réinitialiser` remet tous les filtres sur `Tout`.
- **Déconnexion** : icône de déconnexion dans l'AppBar pour se déconnecter (confirmation avant signOut).

---

## 🧪 Tests & Linting

- Pour exécuter les tests :

```bash
flutter test
```

- Vous pouvez exécuter l'analyse statique et fixer automatiquement certains problèmes :

```bash
flutter analyze
# et pour corriger les règles Dart/Flutter automatiques :
flutter format .
```

---

## 🔧 Dépannage courant

- Erreur d'upload Storage (ex. `object-not-found`) : le code implémente des tentatives de récupération du `getDownloadURL`; vérifiez que le bucket et les règles sont corrects.
- Problème d'App Check : en debug, utilisez un provider debug ; en production, activez le provider approprié dans la console Firebase.
- `21 packages have newer versions` : exécutez `flutter pub outdated` pour voir ce qui est obsolète, puis mettez à jour prudemment `pubspec.yaml` et testez.

---

## 📁 Structure importante

- `lib/main.dart` — point d'entrée, configuration Firebase
- `lib/screens/` — écrans (auth, garde-robe, ajout, édition)
- `lib/models/` — modèles (`User`, `ClothingItem`)
- `lib/widgets/` — composants réutilisables (ex. `ClothingCard`)

---

## 🤝 Contribution

Les contributions sont les bienvenues ! Ouvrez une issue pour signaler un bug ou proposer une amélioration, puis soumettez une Pull Request.

---

## 📝 Licence

Indiquez ici la licence que vous souhaitez utiliser (MIT, Apache-2.0, etc.).

---

Si vous voulez, je peux :
- Ajouter des **captures d'écran** dans ce README
- Générer des **badges** (build / coverage)
- Rédiger une **version anglaise**

Souhaitez-vous que j'ajoute des captures d'écran et des instructions spécifiques à votre projet Firebase (règles Storage / Firestore) ?
