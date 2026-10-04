# Configuration du hub Cloud Nord

L'habillage et le contenu de la **boucle** — ce que les écrans de salle projettent entre
deux talks — pour Cloud Nord. Le hub de [conference-operator](https://github.com/Monpoke/conference-operator)
les importe depuis ce dépôt, à la demande : rien ne se synchronise tout seul.

## Contenu

Un dossier par édition :

```
2026/
  theme.json      le thème : couleurs, fond, polices, décor
  decor.svg       le décor derrière les scènes (rayures, anneaux, bulles), 1920×1080
  fonts/          Peace Sans, Luckiest Guy, Pacifico, et leurs licences
  boucle.json     le contenu : accueil, messages, annonces, pages sponsors, agenda,
                  code de conduite, feedbacks, durées des scènes…
```

Le **thème** habille les écrans de salle, l'habillage de captation (overlay OBS) et
l'intro/outro des VOD. Le **contenu** est celui que la console édite, vue Boucle.

## Brancher le hub sur ce dépôt

Console du hub → **Boucle** → panneau **Dépôt Git** :

| Champ | Valeur |
|---|---|
| Adresse du dépôt | `https://github.com/Monpoke/hub-cloudnord-configuration.git` |
| Branche | `main` |
| Sous-dossier | `2026` |
| Jeton d'accès | si le dépôt est privé : un jeton en lecture seule (GitHub : *fine-grained token*, droit *Contents: read*) |

Le jeton est chiffré sur le hub et n'est jamais réaffiché ; la console n'en montre que
les quatre derniers caractères.

## Importer

Deux boutons, indépendants :

- **Le thème** — le hub lit `theme.json` et ses fichiers, les vérifie, et **le met
  aussitôt sur les écrans**. Les salles le récupèrent à leur synchro suivante et leurs
  pages se rechargent d'elles-mêmes. Réimporter un thème inchangé ne change rien.
- **Le contenu de la boucle** — les sections présentes dans `boucle.json` **remplacent**
  celles du hub ; les autres restent telles quelles. Tout reste modifiable dans la
  console ensuite… jusqu'au prochain import, qui écrase à nouveau ce que nomme le fichier.

La console affiche le dernier import : sa date, son commit, ou la raison de son échec.

> **Une seule source de vérité.** Une correction faite dans la console est perdue au
> prochain import du contenu. Pour la garder : « Exporter le contenu (boucle.json) » dans
> le panneau Dépôt Git, remplacer `2026/boucle.json`, committer.

## Modifier

1. Éditer les fichiers, committer, pousser sur `main`.
2. Console → Dépôt Git → **Le thème** et/ou **Le contenu de la boucle**.
3. Vérifier dans l'aperçu, en haut de la vue Boucle.

Pour tester sans toucher aux écrans, pousser sur une autre branche et la régler
temporairement dans le panneau — en gardant en tête que l'import du thème le met sur
les écrans.

### `theme.json`

- `couleurs` — les jetons de couleur (`violet`, `orange`, `bulle-debut`, `carte-texte`,
  `avatar-0`… `overlay-1`…), en `#rrggbb`. Un jeton absent garde la valeur du thème par
  défaut du hub.
- `fond` — le fond de la scène, un dégradé CSS.
- `polices.roles` — les piles de polices (`titre`, `texte`, `accueil`, `script`) ;
  `polices.fichiers` — les polices du dossier à déclarer.
- `decor` — `svg` (le fichier du décor) et `bulles` (position, taille, durée, délai des
  bulles animées).
- `version` — à incrémenter à chaque changement : la console l'affiche.

### `boucle.json`

Les sections portent les noms de la console. Une section inconnue fait refuser tout le
fichier, avec la liste de ce qui ne va pas. Le thème choisi et le lien public d'aperçu
ne viennent jamais du fichier.

**Images** : un `logo` peut être un chemin du dossier (`images/sponsor.png`) — le hub
l'enregistre comme une image déposée depuis la console — ou une adresse `https://`.
Une référence `hub-image:…` (ce que contient l'export de la console pour une image
déposée à la main) ne vaut que pour le hub qui la détient : pour un contenu qui se
réimporte partout, préférer un fichier dans `images/`.

## Ce qui est refusé

Le hub vérifie tout avant d'importer et liste chaque problème :

- rien qui vienne d'ailleurs : ni `@import`, ni adresse http dans le CSS ou le SVG — les
  salles projettent hors-ligne ;
- ni script, ni gestionnaire d'événement (`onload`…) dans le SVG ;
- 8 Mo et 64 fichiers au plus par thème ; 2,5 Mo par image du contenu ; PNG, JPEG,
  WebP, GIF ou SVG.

## Nouvelle édition

Copier `2026/` en `2027/`, l'adapter, puis régler le sous-dossier `2027` dans le
panneau. L'édition précédente reste dans le dépôt, réimportable telle quelle.

## Licences des polices

Peace Sans et Pacifico : SIL Open Font License 1.1 ; Luckiest Guy : Apache 2.0. Leurs
licences sont dans `fonts/` et doivent y rester. Les polices de la maquette d'origine,
Gagalin et Bukhari Script, ne sont pas redistribuables : elles restent en tête des piles
CSS pour une machine qui les aurait installées sous sa propre licence.
