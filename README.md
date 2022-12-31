# Essentiel

Application pour les [groupes de partage Essentiel](https://www.saintemadeleinevilleurbanne.fr/groupe-essentiel/).

Cette application est développée et maintenue bénévolement pour la paroisse Sainte Madeleine des Charpennes de Villeurbanne.

<a href='https://play.google.com/store/apps/details?id=app.essentiel&hl=fr&gl=FR&pcampaignid=pcampaignidMKT-Other-global-all-co-prtnr-py-PartBadge-Mar2515-1'><img alt='Disponible sur Google Play' src='https://play.google.com/intl/en_us/badges/static/images/badges/fr_badge_web_generic.png' style="height: 97px; width:250px;"/></a>

## Apercu

<img src="deployment/google_play/screenshots/phone/screen-0.png" alt="Preview" style="height: 530px; width:212px;"/>

Cette application est basée sur le kit de développement [Flutter](https://flutter.dev/),
dans le but de faciliter le développement et d'être multi-plateforme.

Les listes de questions et de catégories affichées dans le jeu
proviennent de la feuille de calcul disponible [ici](https://docs.google.com/spreadsheets/d/1cR8lE6eCvDrgUXAVD1bmm36j6v5MtOEurSOAEfrTcCI/edit#gid=0).

## Compiler le projet

- Installer Flutter:
  - soit conformément aux instructions officielles disponibles sur [cette page](https://docs.flutter.dev/get-started/install)
  - soit, si vous utilisez le gestionnaire de versions [`asdf`](https://asdf-vm.com/), à l'aide de cette commande: `asdf install`
- Installer les outils nécessaires pour Flutter (comme le SDK Android)
- Créer un project Google Cloud ainsi qu'un compte de service (utiles pour accéder aux APIs de Google pour lire la feuille de calcul qui sert de base de données). Plus de détails dans cet article "[How to Get credentials for Google Sheets](https://medium.com/@a.marenkov/how-to-get-credentials-for-google-sheets-456b7e88c430)" (en anglais). Les identifiants de ce compte de service serviront ensuite à créer un "environnement" de build dédié, comme indiqué ci-après.
- Préparer l'environnement (ignorer pour utiliser le mode de développement par défaut - cf. fichier [`lib/environments/dev.dart`](lib/environments/dev.dart)). Pour utiliser d'autres identifiants de compte de service, il suffit de créer un "environnement" dédié dans un nouveau fichier à placer dans le dossier `lib/environments`; par exemple: `lib/environments/staging.dart`:
```dart
import 'package:essentiel/env.dart';

void main() => Staging().init();

class Staging extends Env {
  final String saEmail = "Service Account Email Address";
  final String saId = "Service Account ID";
  final String saPK = "Fill Service Account Private Key";
}
```
- Connecter un périphérique (virtuel ou physique) à l'ordinateur, puis lancer la commande `flutter run [-t lib/environments/<mon_environnement.dart>]`

```bash
flutter run [-t lib/environments/<mon_environnement.dart>]
```

## Publier l'application

### Android

Le Play Store Google recommande la publication d'App Bundles pour optimiser le téléchargement des apps par les utilisateurs.
Pour créer un App Bundle, lancer la commande ci-après:

```bash
flutter build appbundle [-t lib/environments/<mon_environnement.dart>]
```

À la fin de cette opération qui ne dure que quelques minutes, un fichier `build/app/outputs/bundle/release/app-release.aab` devrait être créé.
Ce fichier devra ensuite être publié via l'interface Web du Google Play Store.

### iOS

Instructions à venir...

## Licence

    GNU AFFERO GENERAL PUBLIC LICENSE
    Version 3, 19 November 2007
