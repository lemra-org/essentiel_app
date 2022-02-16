# Essentiel

Application pour les [groupes de partage Essentiel](https://www.saintemadeleinevilleurbanne.fr/groupe-essentiel/).

Cette application est développée et maintenue bénévolement pour la paroisse Sainte Madeleine des Charpennes de Villeurbanne.

<a href='https://play.google.com/store/apps/details?id=app.essentiel&hl=fr&gl=FR&pcampaignid=pcampaignidMKT-Other-global-all-co-prtnr-py-PartBadge-Mar2515-1'><img alt='Disponible sur Google Play' src='https://play.google.com/intl/en_us/badges/static/images/badges/fr_badge_web_generic.png'/></a>

## Apercu

Cette application est basée sur le kit de développement [Flutter](https://flutter.dev/),
dans le but de faciliter le développement et d'être multi-plateforme.

Les listes de questions et de catégories affichées dans le jeu
proviennent de la feuille de calcul disponible [ici](https://docs.google.com/spreadsheets/d/1cR8lE6eCvDrgUXAVD1bmm36j6v5MtOEurSOAEfrTcCI/edit#gid=0).

TODO Add screen captures down here

## Compiler le projet

- Installer Flutter, conformément aux instructions officielles disponibles sur [cette page](https://docs.flutter.dev/get-started/install)
- Connecter un périphérique (virtuel ou physique) à l'ordinateur, puis lancer la commande `flutter run`, avec l'option `no-sound-null-safety`
(en raison d'incompatibilités de certaines dépendances avec [cette fonctionnalité](https://dart.dev/null-safety))

```bash
flutter --no-sound-null-safety run
```

## Publier l'application

### Android

Le Play Store Google recommande en général la publication d'App Bundles pour optimiser le téléchargement des apps par les utilisateurs. Pour créer un App Bundle, lancer la commande suivante:

```bash
flutter --no-sound-null-safety build appbundle
```

À la fin de cette opération qui ne dure que quelques minutes, un fichier `build/app/outputs/bundle/release/app-release.aab` devrait être créé.
Ce fichier devra ensuite être publié via l'interface Web du Google Play Store.

### iOS

Instructions à venir...

## Licence

    GNU AFFERO GENERAL PUBLIC LICENSE
    Version 3, 19 November 2007
