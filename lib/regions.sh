#!/usr/bin/env bash
# lib/regions.sh — Catalogue des régions Geofabrik France + mapping départements
# Sourced by start.sh — ne pas exécuter directement.

# Format: REGIONS[id]="Nom affiché|taille_MB_approx|ville_test"
declare -A REGIONS
REGIONS[alsace]="Alsace|123|Strasbourg"
REGIONS[aquitaine]="Aquitaine|278|Bordeaux"
REGIONS[auvergne]="Auvergne|143|Clermont-Ferrand"
REGIONS[basse-normandie]="Basse-Normandie|135|Caen"
REGIONS[bourgogne]="Bourgogne|187|Dijon"
REGIONS[bretagne]="Bretagne|309|Rennes"
REGIONS[centre]="Centre|227|Orléans"
REGIONS[champagne-ardenne]="Champagne-Ardenne|99|Reims"
REGIONS[corse]="Corse|32|Ajaccio"
REGIONS[franche-comte]="Franche-Comté|116|Besançon"
REGIONS[haute-normandie]="Haute-Normandie|100|Rouen"
REGIONS[ile-de-france]="Île-de-France|316|Paris"
REGIONS[languedoc-roussillon]="Languedoc-Roussillon|251|Montpellier"
REGIONS[limousin]="Limousin|92|Limoges"
REGIONS[lorraine]="Lorraine|161|Nancy"
REGIONS[midi-pyrenees]="Midi-Pyrénées|338|Toulouse"
REGIONS[nord-pas-de-calais]="Nord-Pas-de-Calais|224|Lille"
REGIONS[pays-de-la-loire]="Pays de la Loire|350|Nantes"
REGIONS[picardie]="Picardie|125|Amiens"
REGIONS[poitou-charentes]="Poitou-Charentes|218|Poitiers"
REGIONS[provence-alpes-cote-d-azur]="Provence-Alpes-Côte d'Azur|363|Marseille"
REGIONS[rhone-alpes]="Rhône-Alpes|494|Lyon"
# DOM/TOM
REGIONS[guadeloupe]="Guadeloupe|23|Pointe-à-Pitre"
REGIONS[guyane]="Guyane|14|Cayenne"
REGIONS[martinique]="Martinique|19|Fort-de-France"
REGIONS[mayotte]="Mayotte|10|Mamoudzou"
REGIONS[reunion]="Réunion|32|Saint-Denis"

# Ordre d'affichage (numéroté dans le menu)
REGION_ORDER=(
  alsace aquitaine auvergne basse-normandie bourgogne bretagne centre
  champagne-ardenne corse franche-comte haute-normandie ile-de-france
  languedoc-roussillon limousin lorraine midi-pyrenees nord-pas-de-calais
  pays-de-la-loire picardie poitou-charentes provence-alpes-cote-d-azur
  rhone-alpes
  guadeloupe guyane martinique mayotte reunion
)

# Alias "normandie" → les deux régions Geofabrik
declare -A REGION_ALIASES
REGION_ALIASES[normandie]="basse-normandie haute-normandie"

# Mapping département (numéro ET nom) → région Geofabrik
declare -A DEPT_TO_REGION
# Alsace
DEPT_TO_REGION[67]="alsace"; DEPT_TO_REGION[bas-rhin]="alsace"
DEPT_TO_REGION[68]="alsace"; DEPT_TO_REGION[haut-rhin]="alsace"
# Aquitaine
DEPT_TO_REGION[24]="aquitaine"; DEPT_TO_REGION[dordogne]="aquitaine"
DEPT_TO_REGION[33]="aquitaine"; DEPT_TO_REGION[gironde]="aquitaine"
DEPT_TO_REGION[40]="aquitaine"; DEPT_TO_REGION[landes]="aquitaine"
DEPT_TO_REGION[47]="aquitaine"; DEPT_TO_REGION[lot-et-garonne]="aquitaine"
DEPT_TO_REGION[64]="aquitaine"; DEPT_TO_REGION[pyrenees-atlantiques]="aquitaine"
# Auvergne
DEPT_TO_REGION[03]="auvergne"; DEPT_TO_REGION[allier]="auvergne"
DEPT_TO_REGION[15]="auvergne"; DEPT_TO_REGION[cantal]="auvergne"
DEPT_TO_REGION[43]="auvergne"; DEPT_TO_REGION[haute-loire]="auvergne"
DEPT_TO_REGION[63]="auvergne"; DEPT_TO_REGION[puy-de-dome]="auvergne"
# Basse-Normandie
DEPT_TO_REGION[14]="basse-normandie"; DEPT_TO_REGION[calvados]="basse-normandie"
DEPT_TO_REGION[50]="basse-normandie"; DEPT_TO_REGION[manche]="basse-normandie"
DEPT_TO_REGION[61]="basse-normandie"; DEPT_TO_REGION[orne]="basse-normandie"
# Bourgogne
DEPT_TO_REGION[21]="bourgogne"; DEPT_TO_REGION[cote-d-or]="bourgogne"
DEPT_TO_REGION[58]="bourgogne"; DEPT_TO_REGION[nievre]="bourgogne"
DEPT_TO_REGION[71]="bourgogne"; DEPT_TO_REGION[saone-et-loire]="bourgogne"
DEPT_TO_REGION[89]="bourgogne"; DEPT_TO_REGION[yonne]="bourgogne"
# Bretagne
DEPT_TO_REGION[22]="bretagne"; DEPT_TO_REGION[cotes-d-armor]="bretagne"
DEPT_TO_REGION[29]="bretagne"; DEPT_TO_REGION[finistere]="bretagne"
DEPT_TO_REGION[35]="bretagne"; DEPT_TO_REGION[ille-et-vilaine]="bretagne"
DEPT_TO_REGION[56]="bretagne"; DEPT_TO_REGION[morbihan]="bretagne"
# Centre
DEPT_TO_REGION[18]="centre"; DEPT_TO_REGION[cher]="centre"
DEPT_TO_REGION[28]="centre"; DEPT_TO_REGION[eure-et-loir]="centre"
DEPT_TO_REGION[36]="centre"; DEPT_TO_REGION[indre]="centre"
DEPT_TO_REGION[37]="centre"; DEPT_TO_REGION[indre-et-loire]="centre"
DEPT_TO_REGION[41]="centre"; DEPT_TO_REGION[loir-et-cher]="centre"
DEPT_TO_REGION[45]="centre"; DEPT_TO_REGION[loiret]="centre"
# Champagne-Ardenne
DEPT_TO_REGION[08]="champagne-ardenne"; DEPT_TO_REGION[ardennes]="champagne-ardenne"
DEPT_TO_REGION[10]="champagne-ardenne"; DEPT_TO_REGION[aube]="champagne-ardenne"
DEPT_TO_REGION[51]="champagne-ardenne"; DEPT_TO_REGION[marne]="champagne-ardenne"
DEPT_TO_REGION[52]="champagne-ardenne"; DEPT_TO_REGION[haute-marne]="champagne-ardenne"
# Corse
DEPT_TO_REGION[2A]="corse"; DEPT_TO_REGION[2a]="corse"; DEPT_TO_REGION[corse-du-sud]="corse"
DEPT_TO_REGION[2B]="corse"; DEPT_TO_REGION[2b]="corse"; DEPT_TO_REGION[haute-corse]="corse"
# Franche-Comté
DEPT_TO_REGION[25]="franche-comte"; DEPT_TO_REGION[doubs]="franche-comte"
DEPT_TO_REGION[39]="franche-comte"; DEPT_TO_REGION[jura]="franche-comte"
DEPT_TO_REGION[70]="franche-comte"; DEPT_TO_REGION[haute-saone]="franche-comte"
DEPT_TO_REGION[90]="franche-comte"; DEPT_TO_REGION[territoire-de-belfort]="franche-comte"
# Haute-Normandie
DEPT_TO_REGION[27]="haute-normandie"; DEPT_TO_REGION[eure]="haute-normandie"
DEPT_TO_REGION[76]="haute-normandie"; DEPT_TO_REGION[seine-maritime]="haute-normandie"
# Île-de-France
DEPT_TO_REGION[75]="ile-de-france"; DEPT_TO_REGION[paris]="ile-de-france"
DEPT_TO_REGION[77]="ile-de-france"; DEPT_TO_REGION[seine-et-marne]="ile-de-france"
DEPT_TO_REGION[78]="ile-de-france"; DEPT_TO_REGION[yvelines]="ile-de-france"
DEPT_TO_REGION[91]="ile-de-france"; DEPT_TO_REGION[essonne]="ile-de-france"
DEPT_TO_REGION[92]="ile-de-france"; DEPT_TO_REGION[hauts-de-seine]="ile-de-france"
DEPT_TO_REGION[93]="ile-de-france"; DEPT_TO_REGION[seine-saint-denis]="ile-de-france"
DEPT_TO_REGION[94]="ile-de-france"; DEPT_TO_REGION[val-de-marne]="ile-de-france"
DEPT_TO_REGION[95]="ile-de-france"; DEPT_TO_REGION[val-d-oise]="ile-de-france"
# Languedoc-Roussillon
DEPT_TO_REGION[11]="languedoc-roussillon"; DEPT_TO_REGION[aude]="languedoc-roussillon"
DEPT_TO_REGION[30]="languedoc-roussillon"; DEPT_TO_REGION[gard]="languedoc-roussillon"
DEPT_TO_REGION[34]="languedoc-roussillon"; DEPT_TO_REGION[herault]="languedoc-roussillon"
DEPT_TO_REGION[48]="languedoc-roussillon"; DEPT_TO_REGION[lozere]="languedoc-roussillon"
DEPT_TO_REGION[66]="languedoc-roussillon"; DEPT_TO_REGION[pyrenees-orientales]="languedoc-roussillon"
# Limousin
DEPT_TO_REGION[19]="limousin"; DEPT_TO_REGION[correze]="limousin"
DEPT_TO_REGION[23]="limousin"; DEPT_TO_REGION[creuse]="limousin"
DEPT_TO_REGION[87]="limousin"; DEPT_TO_REGION[haute-vienne]="limousin"
# Lorraine
DEPT_TO_REGION[54]="lorraine"; DEPT_TO_REGION[meurthe-et-moselle]="lorraine"
DEPT_TO_REGION[55]="lorraine"; DEPT_TO_REGION[meuse]="lorraine"
DEPT_TO_REGION[57]="lorraine"; DEPT_TO_REGION[moselle]="lorraine"
DEPT_TO_REGION[88]="lorraine"; DEPT_TO_REGION[vosges]="lorraine"
# Midi-Pyrénées
DEPT_TO_REGION[09]="midi-pyrenees"; DEPT_TO_REGION[ariege]="midi-pyrenees"
DEPT_TO_REGION[12]="midi-pyrenees"; DEPT_TO_REGION[aveyron]="midi-pyrenees"
DEPT_TO_REGION[31]="midi-pyrenees"; DEPT_TO_REGION[haute-garonne]="midi-pyrenees"
DEPT_TO_REGION[32]="midi-pyrenees"; DEPT_TO_REGION[gers]="midi-pyrenees"
DEPT_TO_REGION[46]="midi-pyrenees"; DEPT_TO_REGION[lot]="midi-pyrenees"
DEPT_TO_REGION[65]="midi-pyrenees"; DEPT_TO_REGION[hautes-pyrenees]="midi-pyrenees"
DEPT_TO_REGION[81]="midi-pyrenees"; DEPT_TO_REGION[tarn]="midi-pyrenees"
DEPT_TO_REGION[82]="midi-pyrenees"; DEPT_TO_REGION[tarn-et-garonne]="midi-pyrenees"
# Nord-Pas-de-Calais
DEPT_TO_REGION[59]="nord-pas-de-calais"; DEPT_TO_REGION[nord]="nord-pas-de-calais"
DEPT_TO_REGION[62]="nord-pas-de-calais"; DEPT_TO_REGION[pas-de-calais]="nord-pas-de-calais"
# Pays de la Loire
DEPT_TO_REGION[44]="pays-de-la-loire"; DEPT_TO_REGION[loire-atlantique]="pays-de-la-loire"
DEPT_TO_REGION[49]="pays-de-la-loire"; DEPT_TO_REGION[maine-et-loire]="pays-de-la-loire"
DEPT_TO_REGION[53]="pays-de-la-loire"; DEPT_TO_REGION[mayenne]="pays-de-la-loire"
DEPT_TO_REGION[72]="pays-de-la-loire"; DEPT_TO_REGION[sarthe]="pays-de-la-loire"
DEPT_TO_REGION[85]="pays-de-la-loire"; DEPT_TO_REGION[vendee]="pays-de-la-loire"
# Picardie
DEPT_TO_REGION[02]="picardie"; DEPT_TO_REGION[aisne]="picardie"
DEPT_TO_REGION[60]="picardie"; DEPT_TO_REGION[oise]="picardie"
DEPT_TO_REGION[80]="picardie"; DEPT_TO_REGION[somme]="picardie"
# Poitou-Charentes
DEPT_TO_REGION[16]="poitou-charentes"; DEPT_TO_REGION[charente]="poitou-charentes"
DEPT_TO_REGION[17]="poitou-charentes"; DEPT_TO_REGION[charente-maritime]="poitou-charentes"
DEPT_TO_REGION[79]="poitou-charentes"; DEPT_TO_REGION[deux-sevres]="poitou-charentes"
DEPT_TO_REGION[86]="poitou-charentes"; DEPT_TO_REGION[vienne]="poitou-charentes"
# Provence-Alpes-Côte d'Azur
DEPT_TO_REGION[04]="provence-alpes-cote-d-azur"; DEPT_TO_REGION[alpes-de-haute-provence]="provence-alpes-cote-d-azur"
DEPT_TO_REGION[05]="provence-alpes-cote-d-azur"; DEPT_TO_REGION[hautes-alpes]="provence-alpes-cote-d-azur"
DEPT_TO_REGION[06]="provence-alpes-cote-d-azur"; DEPT_TO_REGION[alpes-maritimes]="provence-alpes-cote-d-azur"
DEPT_TO_REGION[13]="provence-alpes-cote-d-azur"; DEPT_TO_REGION[bouches-du-rhone]="provence-alpes-cote-d-azur"
DEPT_TO_REGION[83]="provence-alpes-cote-d-azur"; DEPT_TO_REGION[var]="provence-alpes-cote-d-azur"
DEPT_TO_REGION[84]="provence-alpes-cote-d-azur"; DEPT_TO_REGION[vaucluse]="provence-alpes-cote-d-azur"
# Rhône-Alpes
DEPT_TO_REGION[01]="rhone-alpes"; DEPT_TO_REGION[ain]="rhone-alpes"
DEPT_TO_REGION[07]="rhone-alpes"; DEPT_TO_REGION[ardeche]="rhone-alpes"
DEPT_TO_REGION[26]="rhone-alpes"; DEPT_TO_REGION[drome]="rhone-alpes"
DEPT_TO_REGION[38]="rhone-alpes"; DEPT_TO_REGION[isere]="rhone-alpes"
DEPT_TO_REGION[42]="rhone-alpes"; DEPT_TO_REGION[loire]="rhone-alpes"
DEPT_TO_REGION[69]="rhone-alpes"; DEPT_TO_REGION[rhone]="rhone-alpes"
DEPT_TO_REGION[73]="rhone-alpes"; DEPT_TO_REGION[savoie]="rhone-alpes"
DEPT_TO_REGION[74]="rhone-alpes"; DEPT_TO_REGION[haute-savoie]="rhone-alpes"
# DOM/TOM
DEPT_TO_REGION[971]="guadeloupe"; DEPT_TO_REGION[972]="martinique"
DEPT_TO_REGION[973]="guyane"; DEPT_TO_REGION[974]="reunion"; DEPT_TO_REGION[976]="mayotte"

# ---------------------------------------------------------------------------
# Functions
# ---------------------------------------------------------------------------

# get_region_name ID → display name
get_region_name() { IFS='|' read -r name _ _ <<< "${REGIONS[$1]}"; echo "$name"; }

# get_region_size ID → size in MB
get_region_size() { IFS='|' read -r _ size _ <<< "${REGIONS[$1]}"; echo "$size"; }

# get_region_city ID → test city name
get_region_city() { IFS='|' read -r _ _ city <<< "${REGIONS[$1]}"; echo "$city"; }

# list_regions — print numbered menu
list_regions() {
  local i=1
  printf "\n  %-4s %-35s %s\n" "#" "Région" "Taille"
  printf "  %s\n" "────────────────────────────────────────────────"
  for id in "${REGION_ORDER[@]}"; do
    local name size
    IFS='|' read -r name size _ <<< "${REGIONS[$id]}"
    if [[ $i -eq 23 ]]; then
      printf "\n  %s\n" "── DOM/TOM ─────────────────────────────────────"
    fi
    printf "  %-4s %-35s %4s MB\n" "${i})" "$name" "$size"
    ((i++))
  done
  echo
}

# resolve_input TOKEN → space-separated list of region IDs
# Accepts: region ID, department number, department name, menu number, alias
resolve_input() {
  local token="${1,,}" # lowercase
  token="${token// /-}" # spaces to dashes

  # Check alias first (e.g. "normandie")
  if [[ -n "${REGION_ALIASES[$token]+x}" ]]; then
    echo "${REGION_ALIASES[$token]}"
    return 0
  fi

  # Direct region ID
  if [[ -n "${REGIONS[$token]+x}" ]]; then
    echo "$token"
    return 0
  fi

  # Department mapping (number or name)
  if [[ -n "${DEPT_TO_REGION[$token]+x}" ]]; then
    echo "${DEPT_TO_REGION[$token]}"
    return 0
  fi

  # Zero-padded department number (e.g. "1" → "01")
  local padded
  padded=$(printf "%02s" "$token")
  if [[ -n "${DEPT_TO_REGION[$padded]+x}" ]]; then
    echo "${DEPT_TO_REGION[$padded]}"
    return 0
  fi

  # Menu number (1-27)
  if [[ "$token" =~ ^[0-9]+$ ]] && (( token >= 1 && token <= ${#REGION_ORDER[@]} )); then
    echo "${REGION_ORDER[$((token - 1))]}"
    return 0
  fi

  return 1
}

# compute_total_size "id1 id2 ..." → total MB
compute_total_size() {
  local total=0
  for id in $1; do
    local size
    size=$(get_region_size "$id")
    total=$((total + size))
  done
  echo "$total"
}
