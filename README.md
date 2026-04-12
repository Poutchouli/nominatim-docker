# Nominatim Docker

Image Docker tout-en-un pour [Nominatim](https://github.com/openstreetmap/Nominatim), le géocodeur OpenStreetMap.

![Nominatim Version](https://img.shields.io/badge/Nominatim%20Version-5.3.0-blue?style=flat-square) ![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/mediagis/nominatim-docker/ci.yml?branch=master&style=flat-square) ![Github All Contributors](https://img.shields.io/github/all-contributors/mediagis/nominatim-docker?style=flat-square) ![Docker Pulls](https://img.shields.io/docker/pulls/mediagis/nominatim?style=flat-square) ![Docker Image Size with architecture (latest by date/latest semver)](https://img.shields.io/docker/image-size/mediagis/nominatim?style=flat-square)

---

## Table des matières

- [Démarrage rapide](#démarrage-rapide)
- [Scénarios d'utilisation](#scénarios-dutilisation)
- [Exemple concret : Normandie](#exemple-concret--normandie)
- [Configuration](#configuration)
- [Sécurité](#sécurité)
- [Développement](#développement)
- [Structure du projet](#structure-du-projet)
- [Objectifs du projet et alternatives](#objectifs-du-projet-et-alternatives)
- [Contribuer](#contribuer)
- [Contributeurs](#contributeurs)

---

## Démarrage rapide

### Prérequis

- [Docker](https://docs.docker.com/get-docker/) (avec Docker Compose)
- ~2 Go de RAM disponible (pour un petit jeu de données comme Monaco)

### 1. Lancer Nominatim

Avec Docker Compose (recommandé) :

```bash
docker compose -f contrib/docker-compose.yml up
```

Ou directement avec `docker run` :

```bash
docker run -it \
  -e PBF_URL=https://download.geofabrik.de/europe/monaco-latest.osm.pbf \
  -e REPLICATION_URL=https://download.geofabrik.de/europe/monaco-updates/ \
  -e NOMINATIM_PASSWORD=un_mot_de_passe_securise \
  -p 8080:8080 \
  --name nominatim \
  mediagis/nominatim:5.3
```

### 2. Attendre la fin de l'import

L'import initial prend quelques minutes (Monaco) à plusieurs heures (pays entier). Suivez la progression :

```bash
docker logs -f nominatim
```

Le message `Nominatim is ready to accept requests` indique que le service est prêt.

### 3. Tester l'API

```bash
curl "http://localhost:8080/search?q=Monaco&format=jsonv2"
```

> **✅ Si vous obtenez une réponse JSON avec des résultats, c'est fonctionnel !**

Exemples de requêtes :

```bash
# Recherche
curl "http://localhost:8080/search?q=avenue%20pasteur&format=jsonv2"

# Géocodage inverse (coordonnées → adresse)
curl "http://localhost:8080/reverse?lat=43.7384&lon=7.4246&format=jsonv2"
```

---

## Scénarios d'utilisation

Choisissez le fichier Docker Compose adapté à votre besoin :

| Besoin | Fichier Compose | Temps d'import | RAM min. |
|--------|----------------|----------------|----------|
| Test rapide (Monaco) | `contrib/docker-compose.yml` | ~5 min | 2 Go |
| Région Normandie | `contrib/docker-compose-normandie.yml` | ~30 min | 4 Go |
| Normandie + régions voisines | `contrib/docker-compose-normandie-region.yml` | ~1h | 8 Go |
| Planète entière | `contrib/docker-compose-planet.yml` | ~48h | 64 Go |

Lancement générique :

```bash
docker compose -f contrib/<fichier-compose>.yml up -d
```

Les images pré-construites sont disponibles sur [Docker Hub](https://hub.docker.com/r/mediagis/nominatim/tags). Pour utiliser une version spécifique :

```bash
docker pull mediagis/nominatim:5.3
```

---

## Exemple concret : Normandie

Geofabrik ne fournit pas de fichier unique `normandie-latest.osm.pbf`. Il faut fusionner les anciens extraits `haute-normandie` et `basse-normandie`. Des scripts automatisent ce processus.

### Préparation des données

**Linux / macOS / WSL :**

```bash
./scripts/prepare-normandie.sh
```

**Windows (PowerShell) :**

```powershell
./scripts/prepare-normandie.ps1
```

Le script :
1. Détecte automatiquement la date la plus récente disponible (jusqu'à J-7)
2. Télécharge Haute & Basse Normandie depuis Geofabrik
3. Vérifie les checksums MD5
4. Fusionne en `data/normandie.osm.pbf`

Options : `-Date 250906` pour une date précise, `-Force` pour re-télécharger.

### Lancer l'instance

```bash
docker compose -f contrib/docker-compose-normandie.yml up -d
docker logs -f nominatim-normandie
```

### Tester

```bash
curl "http://localhost:8080/search?q=Rouen&format=jsonv2"
curl "http://localhost:8080/search?q=Caen&format=jsonv2"
```

### Région étendue (optionnel)

Pour inclure Bretagne, Pays de la Loire et Île-de-France :

```bash
./scripts/prepare-normandie-region.sh    # ou .ps1 sous Windows
docker compose -f contrib/docker-compose-normandie-region.yml up -d
```

> Pour les détails avancés (export USB, troubleshooting, fusion manuelle), voir [Normandie-SETUP.md](Normandie-SETUP.md).

---

## Configuration

### Variables principales

| Variable | Description | Obligatoire |
|----------|-------------|:-----------:|
| `PBF_URL` | URL du fichier .osm.pbf à importer | Oui* |
| `PBF_PATH` | Chemin local du fichier .osm.pbf (dans le conteneur) | Oui* |
| `NOMINATIM_PASSWORD` | Mot de passe PostgreSQL | Non (défaut : `qaIACxO6wMR3`) |
| `REPLICATION_URL` | URL du flux de mises à jour OSM | Non |
| `UPDATE_MODE` | Mode de mise à jour : `continuous`, `once`, `catch-up` | Non |
| `IMPORT_STYLE` | Niveau de détail : `admin`, `street`, `address`, `full`, `extratags` | Non (défaut : `full`) |
| `THREADS` | Nombre de threads pour l'import | Non (défaut : `nproc`) |
| `REVERSE_ONLY` | N'importer que les données pour le géocodage inverse | Non |
| `FREEZE` | Geler la base (pas de mises à jour, économise de l'espace) | Non |

\* **Un seul** des deux (`PBF_URL` ou `PBF_PATH`) doit être défini.

### Variables optionnelles (données enrichies)

| Variable | Description |
|----------|-------------|
| `IMPORT_WIKIPEDIA` | Importer les données d'importance Wikipedia (`true` ou chemin local) |
| `IMPORT_GB_POSTCODES` | Codes postaux britanniques |
| `IMPORT_US_POSTCODES` | Codes postaux américains |
| `IMPORT_TIGER_ADDRESSES` | Données d'adresses TIGER (USA) |
| `SCP_PASSWORD` | Mot de passe pour le serveur de stockage des dumps optionnels |

### Tuning PostgreSQL

Des variables `POSTGRES_*` permettent d'ajuster les paramètres mémoire. Voir le [guide de configuration détaillé](howto.md) pour la liste complète et les recommandations par scénario.

> ⚠️ **Sécurité** : Le mot de passe par défaut (`NOMINATIM_PASSWORD`) est un placeholder. **Changez-le impérativement** en production via `-e NOMINATIM_PASSWORD=votre_mot_de_passe`.

---

## Sécurité

- **Mot de passe par défaut** : L'image utilise un mot de passe PostgreSQL par défaut. Remplacez-le systématiquement avant tout déploiement en production.
- **Politique de sécurité Nominatim** : Consultez la [politique officielle](https://github.com/osm-search/Nominatim/blob/master/SECURITY.md).

---

## Développement

### Construire l'image localement

```bash
docker build -t nominatim .
```

### Tests CI

Le pipeline CI (`.github/workflows/ci.yml`) exécute 15 scénarios de test avec le jeu de données Monaco, couvrant :
- Import via `PBF_URL` et `PBF_PATH`
- Modes de mise à jour (`once`, `continuous`)
- Styles d'import (`full`, `admin`)
- Fonctionnalités spéciales (codes postaux GB, `REVERSE_ONLY`, `FREEZE`)
- Redémarrage de conteneur et persistance des données
- Arrêt propre du conteneur

---

## Structure du projet

```
nominatim-docker/
├── Dockerfile                  # Image Docker multi-stage (Ubuntu 24.04 + Nominatim 5.3)
├── start.sh                    # Point d'entrée du conteneur
├── init.sh                     # Import initial (premier démarrage)
├── config.sh                   # Validation et application de la configuration
├── conf.d/
│   ├── env                     # Template .env Nominatim (tokenizer, réplication, import)
│   ├── postgres-import.conf    # Optimisations PostgreSQL pour l'import (fsync=off)
│   └── postgres-tuning.conf    # Tuning PostgreSQL runtime
├── contrib/
│   ├── docker-compose.yml              # Monaco (test rapide)
│   ├── docker-compose-normandie.yml    # Normandie
│   ├── docker-compose-normandie-region.yml  # Normandie + régions voisines
│   └── docker-compose-planet.yml       # Planète entière
├── scripts/
│   ├── prepare-normandie.sh / .ps1             # Préparation données Normandie
│   ├── prepare-normandie-region.sh / .ps1      # Préparation région étendue
│   └── export-normandie.sh / .ps1              # Export archive transportable
├── data/                       # Données OSM téléchargées (gitignored)
├── howto.md                    # Guide de configuration détaillé
├── Normandie-SETUP.md          # Guide avancé Normandie (troubleshooting, export USB)
└── LICENSE                     # CC0 1.0 (domaine public)
```

---

## Objectifs du projet et alternatives

Ce projet vise à fournir une image Docker facile à utiliser, exécutant tous les services dans un seul conteneur. L'inconvénient est que le Dockerfile est plus complexe et difficile à modifier.

Pour une approche séparant les services en conteneurs distincts, voir [github.com/smithmicro/n7m](https://github.com/smithmicro/n7m).

---

## Contribuer

Ce projet est sous licence [CC0 1.0 Universal](LICENSE) (domaine public). Les contributions de toute nature sont les bienvenues !

Ce projet suit la spécification [all-contributors](https://github.com/all-contributors/all-contributors).

---

## Contributeurs

Merci à toutes ces personnes formidables ([légende des emojis](https://allcontributors.org/docs/en/emoji-key)) :

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="16.66%"><a href="https://www.linkedin.com/in/winsent/"><img src="https://avatars.githubusercontent.com/u/2316328?v=4?s=100" width="100px;" alt="Andrew"/><br /><sub><b>Andrew</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=winsento" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=winsento" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/dlucia"><img src="https://avatars3.githubusercontent.com/u/1665623?v=4?s=100" width="100px;" alt="Donato Lucia"/><br /><sub><b>Donato Lucia</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=dlucia" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/geomark"><img src="https://avatars1.githubusercontent.com/u/1500692?v=4?s=100" width="100px;" alt="Georgios Markakis"/><br /><sub><b>Georgios Markakis</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=geomark" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/philipkozeny"><img src="https://avatars1.githubusercontent.com/u/16721635?v=4?s=100" width="100px;" alt="Philip Kozeny"/><br /><sub><b>Philip Kozeny</b></sub></a><br /><a href="#infra-philipkozeny" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=philipkozeny" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=philipkozeny" title="Tests">⚠️</a> <a href="https://github.com/mediagis/nominatim-docker/pulls?q=is%3Apr+reviewed-by%3Aphilipkozeny" title="Reviewed Pull Requests">👀</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=philipkozeny" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://www.therek.net/"><img src="https://avatars2.githubusercontent.com/u/89052?v=4?s=100" width="100px;" alt="Cezary Morga"/><br /><sub><b>Cezary Morga</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=therek" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/thomasnordquist"><img src="https://avatars0.githubusercontent.com/u/7721625?v=4?s=100" width="100px;" alt="Thomas Nordquist"/><br /><sub><b>Thomas Nordquist</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=thomasnordquist" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="16.66%"><a href="https://keybase.io/davkorss"><img src="https://avatars0.githubusercontent.com/u/5597595?v=4?s=100" width="100px;" alt="Andrey Ruíz"/><br /><sub><b>Andrey Ruíz</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=davkorss" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/UntitleDude"><img src="https://avatars2.githubusercontent.com/u/14983691?v=4?s=100" width="100px;" alt="UntitleDude"/><br /><sub><b>UntitleDude</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=UntitleDude" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://www.linkedin.com/in/jmcker"><img src="https://avatars3.githubusercontent.com/u/25001741?v=4?s=100" width="100px;" alt="Jack McKernan"/><br /><sub><b>Jack McKernan</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=jmcker" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://twitter.com/mtmthemovie"><img src="https://avatars1.githubusercontent.com/u/3727288?v=4?s=100" width="100px;" alt="mtmail"/><br /><sub><b>mtmail</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=mtmail" title="Documentation">📖</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=mtmail" title="Code">💻</a> <a href="#question-mtmail" title="Answering Questions">💬</a> <a href="https://github.com/mediagis/nominatim-docker/pulls?q=is%3Apr+reviewed-by%3Amtmail" title="Reviewed Pull Requests">👀</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://angel.co/eSlider"><img src="https://avatars3.githubusercontent.com/u/1188335?v=4?s=100" width="100px;" alt="Andrey Oblivantsev"/><br /><sub><b>Andrey Oblivantsev</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=eSlider" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://www.linkedin.com/in/simoneromano92/"><img src="https://avatars2.githubusercontent.com/u/6860423?v=4?s=100" width="100px;" alt="Simone"/><br /><sub><b>Simone</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=sromano1992" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/DuncanMackintosh"><img src="https://avatars0.githubusercontent.com/u/4966417?v=4?s=100" width="100px;" alt="DuncanMackintosh"/><br /><sub><b>DuncanMackintosh</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=DuncanMackintosh" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=DuncanMackintosh" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="http://iiroalhonen.com"><img src="https://avatars2.githubusercontent.com/u/18322926?v=4?s=100" width="100px;" alt="Iiro Alhonen"/><br /><sub><b>Iiro Alhonen</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=Iikeli" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://www.ufoproger.ru"><img src="https://avatars3.githubusercontent.com/u/212711?v=4?s=100" width="100px;" alt="Mikhail Snetkov"/><br /><sub><b>Mikhail Snetkov</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=ufoproger" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/FritschAuctores"><img src="https://avatars2.githubusercontent.com/u/43264099?v=4?s=100" width="100px;" alt="FritschAuctores"/><br /><sub><b>FritschAuctores</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=FritschAuctores" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/rebos"><img src="https://avatars.githubusercontent.com/u/490798?v=4?s=100" width="100px;" alt="rebos"/><br /><sub><b>rebos</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=rebos" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://leonard.io/blog/"><img src="https://avatars.githubusercontent.com/u/151346?v=4?s=100" width="100px;" alt="Leonard Ehrenfried"/><br /><sub><b>Leonard Ehrenfried</b></sub></a><br /><a href="#infra-leonardehrenfried" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=leonardehrenfried" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=leonardehrenfried" title="Tests">⚠️</a> <a href="https://github.com/mediagis/nominatim-docker/pulls?q=is%3Apr+reviewed-by%3Aleonardehrenfried" title="Reviewed Pull Requests">👀</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=leonardehrenfried" title="Documentation">📖</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="16.66%"><a href="https://roelandtn.frama.io/"><img src="https://avatars.githubusercontent.com/u/17683898?v=4?s=100" width="100px;" alt="Nicolas Roelandt"/><br /><sub><b>Nicolas Roelandt</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=Bakaniko" title="Documentation">📖</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=Bakaniko" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=Bakaniko" title="Tests">⚠️</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/Sacerdoss"><img src="https://avatars.githubusercontent.com/u/22632241?v=4?s=100" width="100px;" alt="Sacerdoss"/><br /><sub><b>Sacerdoss</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=Sacerdoss" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/sake"><img src="https://avatars.githubusercontent.com/u/154311?v=4?s=100" width="100px;" alt="Tobias Wich"/><br /><sub><b>Tobias Wich</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=sake" title="Documentation">📖</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=sake" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/aclowkey"><img src="https://avatars.githubusercontent.com/u/2061017?v=4?s=100" width="100px;" alt="Alex Chaplianka"/><br /><sub><b>Alex Chaplianka</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=aclowkey" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/gmalenko"><img src="https://avatars.githubusercontent.com/u/6521413?v=4?s=100" width="100px;" alt="Idris Hayward"/><br /><sub><b>Idris Hayward</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=gmalenko" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/karlvr"><img src="https://avatars.githubusercontent.com/u/1086005?v=4?s=100" width="100px;" alt="Karl von Randow"/><br /><sub><b>Karl von Randow</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=karlvr" title="Documentation">📖</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/mlechner"><img src="https://avatars.githubusercontent.com/u/1194826?v=4?s=100" width="100px;" alt="Marco Lechner"/><br /><sub><b>Marco Lechner</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=mlechner" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/mattegawel"><img src="https://avatars.githubusercontent.com/u/14986712?v=4?s=100" width="100px;" alt="Mateusz Gaweł"/><br /><sub><b>Mateusz Gaweł</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=mattegawel" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="http://www.forum-software.org/"><img src="https://avatars.githubusercontent.com/u/1044941?v=4?s=100" width="100px;" alt="Nicolas Ternisien"/><br /><sub><b>Nicolas Ternisien</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=lastnico" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/oschlueter"><img src="https://avatars.githubusercontent.com/u/10252511?v=4?s=100" width="100px;" alt="oschlueter"/><br /><sub><b>oschlueter</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=oschlueter" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/timnon"><img src="https://avatars.githubusercontent.com/u/5597397?v=4?s=100" width="100px;" alt="Tim Nonner"/><br /><sub><b>Tim Nonner</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=timnon" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/thlor"><img src="https://avatars.githubusercontent.com/u/6570020?v=4?s=100" width="100px;" alt="thlor"/><br /><sub><b>thlor</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=thlor" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=thlor" title="Documentation">📖</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/mogita"><img src="https://avatars.githubusercontent.com/u/1173069?v=4?s=100" width="100px;" alt="Yun Wang"/><br /><sub><b>Yun Wang</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=mogita" title="Documentation">📖</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=mogita" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/Stefanic"><img src="https://avatars.githubusercontent.com/u/4499284?v=4?s=100" width="100px;" alt="Stefanic"/><br /><sub><b>Stefanic</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=Stefanic" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=Stefanic" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/xpoinsard"><img src="https://avatars.githubusercontent.com/u/6130463?v=4?s=100" width="100px;" alt="xpoinsard"/><br /><sub><b>xpoinsard</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=xpoinsard" title="Documentation">📖</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=xpoinsard" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/Bartizan"><img src="https://avatars.githubusercontent.com/u/6322553?v=4?s=100" width="100px;" alt="Bartizan"/><br /><sub><b>Bartizan</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=Bartizan" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=Bartizan" title="Documentation">📖</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=Bartizan" title="Tests">⚠️</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/galewis2"><img src="https://avatars.githubusercontent.com/u/62433564?v=4?s=100" width="100px;" alt="galewis2"/><br /><sub><b>galewis2</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=galewis2" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/TurtIeSocks"><img src="https://avatars.githubusercontent.com/u/58572875?v=4?s=100" width="100px;" alt="Derick M."/><br /><sub><b>Derick M.</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=TurtIeSocks" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=TurtIeSocks" title="Documentation">📖</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=TurtIeSocks" title="Tests">⚠️</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/norcis"><img src="https://avatars.githubusercontent.com/u/1047487?v=4?s=100" width="100px;" alt="norcis"/><br /><sub><b>norcis</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=norcis" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="http://rapsody.com/"><img src="https://avatars.githubusercontent.com/u/7005?v=4?s=100" width="100px;" alt="SClo"/><br /><sub><b>SClo</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=sclo" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=sclo" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/poliquin"><img src="https://avatars.githubusercontent.com/u/360123?v=4?s=100" width="100px;" alt="Chris"/><br /><sub><b>Chris</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=poliquin" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=poliquin" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/iAlex97"><img src="https://avatars.githubusercontent.com/u/12383594?v=4?s=100" width="100px;" alt="iAlex97"/><br /><sub><b>iAlex97</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=iAlex97" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=iAlex97" title="Tests">⚠️</a></td>
      <td align="center" valign="top" width="16.66%"><a href="http://bugsquash.blogspot.com/"><img src="https://avatars.githubusercontent.com/u/95194?v=4?s=100" width="100px;" alt="Mauricio Scheffer"/><br /><sub><b>Mauricio Scheffer</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=mausch" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/anthropos9"><img src="https://avatars.githubusercontent.com/u/3867685?v=4?s=100" width="100px;" alt="Sean Dean"/><br /><sub><b>Sean Dean</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=anthropos9" title="Documentation">📖</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/pgassmann"><img src="https://avatars.githubusercontent.com/u/460192?v=4?s=100" width="100px;" alt="Philipp Gassmann"/><br /><sub><b>Philipp Gassmann</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=pgassmann" title="Documentation">📖</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=pgassmann" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=pgassmann" title="Tests">⚠️</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/saddfox"><img src="https://avatars.githubusercontent.com/u/48035291?v=4?s=100" width="100px;" alt="saddfox"/><br /><sub><b>saddfox</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=saddfox" title="Documentation">📖</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=saddfox" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=saddfox" title="Tests">⚠️</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/gsg-git"><img src="https://avatars.githubusercontent.com/u/92863111?v=4?s=100" width="100px;" alt="gsg-git"/><br /><sub><b>gsg-git</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=gsg-git" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/breunigs"><img src="https://avatars.githubusercontent.com/u/307954?v=4?s=100" width="100px;" alt="Stefan Breunig"/><br /><sub><b>Stefan Breunig</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=breunigs" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/carlomion"><img src="https://avatars.githubusercontent.com/u/161817799?v=4?s=100" width="100px;" alt="carlomion"/><br /><sub><b>carlomion</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=carlomion" title="Code">💻</a> <a href="#infra-carlomion" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/stouch"><img src="https://avatars.githubusercontent.com/u/17531455?v=4?s=100" width="100px;" alt="stouch"/><br /><sub><b>stouch</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=stouch" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=stouch" title="Documentation">📖</a> <a href="#infra-stouch" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/tzezar"><img src="https://avatars.githubusercontent.com/u/163430081?v=4?s=100" width="100px;" alt="Sebastian Drozd"/><br /><sub><b>Sebastian Drozd</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=tzezar" title="Code">💻</a> <a href="https://github.com/mediagis/nominatim-docker/commits?author=tzezar" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://www.linkedin.com/in/ilialaz/"><img src="https://avatars.githubusercontent.com/u/33663870?v=4?s=100" width="100px;" alt="Ilia Lazebnik"/><br /><sub><b>Ilia Lazebnik</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=DrFaust92" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/drnextgis"><img src="https://avatars.githubusercontent.com/u/866124?v=4?s=100" width="100px;" alt="Denis Rykov"/><br /><sub><b>Denis Rykov</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=drnextgis" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/EricHayter"><img src="https://avatars.githubusercontent.com/u/57542086?v=4?s=100" width="100px;" alt="Eric Hayter"/><br /><sub><b>Eric Hayter</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=EricHayter" title="Documentation">📖</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://wiki.debian.org/AnthonyFok"><img src="https://avatars.githubusercontent.com/u/1274764?v=4?s=100" width="100px;" alt="Anthony Fok"/><br /><sub><b>Anthony Fok</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=anthonyfok" title="Code">💻</a></td>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/harriteja"><img src="https://avatars.githubusercontent.com/u/37623394?v=4?s=100" width="100px;" alt="Hari Teja"/><br /><sub><b>Hari Teja</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=harriteja" title="Code">💻</a></td>
    </tr>
    <tr>
      <td align="center" valign="top" width="16.66%"><a href="https://github.com/onlygecko"><img src="https://avatars.githubusercontent.com/u/3233376?v=4?s=100" width="100px;" alt="onlygecko"/><br /><sub><b>onlygecko</b></sub></a><br /><a href="https://github.com/mediagis/nominatim-docker/commits?author=onlygecko" title="Code">💻</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

Ce projet suit la spécification [all-contributors](https://github.com/all-contributors/all-contributors). Les contributions de toute nature sont les bienvenues !
