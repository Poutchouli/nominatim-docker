# 🗺️ Guide API Nominatim

> Instance déployée le **__DATE__** couvrant : __REGIONS__
> Accessible sur : `http://__IP__:__PORT__`

---

## 🔍 Recherche (search)

```bash
curl "http://__IP__:__PORT__/search?q=__TEST_CITY__&format=jsonv2"
```

### Paramètres utiles

| Paramètre     | Description                              | Exemple                    |
|----------------|------------------------------------------|----------------------------|
| `q`            | Texte libre de recherche                | `Rouen`, `12 rue de la Paix` |
| `format`       | Format de sortie                        | `jsonv2`, `geojson`, `xml` |
| `limit`        | Nombre max de résultats (1-50)          | `5`                        |
| `addressdetails` | Inclure le détail de l'adresse       | `1`                        |
| `extratags`    | Tags OSM supplémentaires               | `1`                        |
| `countrycodes` | Restreindre aux pays                    | `fr`                       |
| `viewbox`      | Zone de recherche (lon1,lat1,lon2,lat2) | `1.0,49.0,2.0,50.0`       |

---

## 📍 Géocodage inverse (reverse)

```bash
curl "http://__IP__:__PORT__/reverse?lat=49.4432&lon=1.0999&format=jsonv2"
```

| Paramètre | Description                       |
|-----------|-----------------------------------|
| `lat`     | Latitude                          |
| `lon`     | Longitude                         |
| `zoom`    | Niveau de détail (0-18, défaut 18)|
| `format`  | `jsonv2`, `geojson`, `xml`        |

---

## 🔎 Lookup par ID OSM

```bash
curl "http://__IP__:__PORT__/lookup?osm_ids=R7444,N240109189&format=jsonv2"
```

---

## 📊 Statut du serveur

```bash
curl "http://__IP__:__PORT__/status?format=json"
```

---

## 💡 Exemples rapides

```bash
# Recherche structurée
curl "http://__IP__:__PORT__/search?street=25+rue+de+la+République&city=Rouen&format=jsonv2"

# Recherche avec bbox (Normandie approximative)
curl "http://__IP__:__PORT__/search?q=mairie&viewbox=-2.0,48.0,2.5,50.0&bounded=1&format=jsonv2&limit=10"

# Reverse avec détails d'adresse
curl "http://__IP__:__PORT__/reverse?lat=48.8566&lon=2.3522&format=jsonv2&addressdetails=1"
```

---

*Généré automatiquement par `start.sh` — [Documentation Nominatim](https://nominatim.org/release-docs/latest/api/Overview/)*
