#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# start.sh — Wizard interactif de déploiement Nominatim
# Usage: ./start.sh [--regions "id1,id2,..."] [--port PORT] [--yes] [--help]
#        ./start.sh --reuse-existing [--compose-file PATH] [--env-file PATH]
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data"
GEOFABRIK_BASE="https://download.geofabrik.de/europe/france"

# Source libraries
source "$SCRIPT_DIR/lib/regions.sh"
source "$SCRIPT_DIR/lib/detect.sh"
source "$SCRIPT_DIR/lib/progress.sh"

# Defaults
PORT=8080
AUTO_YES=false
CLI_REGIONS=""
BIND_IP=""
THREADS=""
REUSE_EXISTING=false
COMPOSE_FILE=""
ENV_FILE=""
SERVICE_NAME="nominatim"
CONTAINER_NAME=""
RUNTIME_PORT=""
RUNTIME_BIND_IP=""
STATUS_HOST=""
DISPLAY_HOST=""
declare -a DETECTED_COMPOSE_FILES=()
declare -a DETECTED_ENV_FILES=()
declare -a DETECTED_COMPOSE_LABELS=()
declare -a DETECTED_COMPOSE_STATUS=()

SELECT_STEP_LABEL="━━ Étape 3/6 : Sélection des régions ━━"
ESTIMATE_STEP_LABEL="━━ Étape 4/6 : Estimation ━━"
DEPLOY_STEP_LABEL="━━ Étape 5/6 : Téléchargement et déploiement ━━"
GUIDE_STEP_LABEL="━━ Étape 6/6 : Guide API ━━"
REUSE_SELECT_STEP_LABEL="━━ Étape 3/4 : Reprise d'une base existante ━━"
REUSE_START_STEP_LABEL="━━ Étape 4/4 : Démarrage sécurisé ━━"

resolve_cli_path() {
  local path=$1
  if [[ "$path" = /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s\n' "$SCRIPT_DIR/$path"
  fi
}

display_path() {
  local path=$1
  if [[ "$path" == "$SCRIPT_DIR/"* ]]; then
    printf '%s\n' "${path#$SCRIPT_DIR/}"
  else
    printf '%s\n' "$path"
  fi
}

describe_compose_candidate() {
  local path display
  display=$(display_path "$1")

  case "$display" in
    docker-compose.generated.yml) printf '%s\n' "Déploiement généré par le wizard" ;;
    contrib/docker-compose.yml) printf '%s\n' "Monaco (test rapide)" ;;
    contrib/docker-compose-normandie.yml) printf '%s\n' "Normandie" ;;
    contrib/docker-compose-normandie-region.yml) printf '%s\n' "Normandie + régions voisines" ;;
    contrib/docker-compose-planet.yml) printf '%s\n' "Planète entière" ;;
    *) printf '%s\n' "$display" ;;
  esac
}

compose_config_valid() {
  local path=$1 env_file=$2
  local -a cmd=(docker compose)
  if [[ -n "$env_file" ]]; then
    cmd+=(--env-file "$env_file")
  fi
  cmd+=(-f "$path" config)
  "${cmd[@]}" >/dev/null 2>&1
}

compose_container_name() {
  local path=$1 env_file=$2
  local -a cmd=(docker compose)

  if [[ -n "$env_file" ]]; then
    cmd+=(--env-file "$env_file")
  fi
  cmd+=(-f "$path" config)
  "${cmd[@]}" 2>/dev/null | awk '/container_name:/ {print $2; exit}'
}

compose_has_existing_resources() {
  local path=$1 env_file=$2
  local container_name

  container_name=$(compose_container_name "$path" "$env_file")
  [[ -z "$container_name" ]] && return 1
  docker container inspect "$container_name" >/dev/null 2>&1
}

detect_compose_candidates() {
  DETECTED_COMPOSE_FILES=()
  DETECTED_ENV_FILES=()
  DETECTED_COMPOSE_LABELS=()
  DETECTED_COMPOSE_STATUS=()

  local -a paths=()
  local -a valid_paths=()
  local -a valid_envs=()
  local path compose_dir env_file

  [[ -f "$SCRIPT_DIR/docker-compose.generated.yml" ]] && paths+=("$SCRIPT_DIR/docker-compose.generated.yml")
  shopt -s nullglob
  for path in "$SCRIPT_DIR"/contrib/docker-compose*.yml; do
    paths+=("$path")
  done
  shopt -u nullglob

  for path in "${paths[@]}"; do
    env_file=""
    compose_dir=$(dirname "$path")
    [[ -f "$compose_dir/.env" ]] && env_file="$compose_dir/.env"

    if compose_config_valid "$path" "$env_file"; then
      valid_paths+=("$path")
      valid_envs+=("$env_file")
    fi
  done

  for path in "${!valid_paths[@]}"; do
    if compose_has_existing_resources "${valid_paths[$path]}" "${valid_envs[$path]}"; then
      DETECTED_COMPOSE_FILES+=("${valid_paths[$path]}")
      DETECTED_ENV_FILES+=("${valid_envs[$path]}")
      DETECTED_COMPOSE_LABELS+=("$(describe_compose_candidate "${valid_paths[$path]}")")
      DETECTED_COMPOSE_STATUS+=("ressources Docker détectées")
    fi
  done

  if (( ${#DETECTED_COMPOSE_FILES[@]} == 0 )); then
    for path in "${!valid_paths[@]}"; do
      if [[ "${valid_paths[$path]}" == "$SCRIPT_DIR/docker-compose.generated.yml" ]]; then
        DETECTED_COMPOSE_FILES+=("${valid_paths[$path]}")
        DETECTED_ENV_FILES+=("${valid_envs[$path]}")
        DETECTED_COMPOSE_LABELS+=("$(describe_compose_candidate "${valid_paths[$path]}")")
        DETECTED_COMPOSE_STATUS+=("configuration générée détectée")
      fi
    done
  fi
}

choose_detected_compose_candidate() {
  local selected_index=$1
  COMPOSE_FILE="${DETECTED_COMPOSE_FILES[$selected_index]}"
  ENV_FILE="${DETECTED_ENV_FILES[$selected_index]}"
}

resolve_reuse_target() {
  local compose_dir selected candidate_count candidate_path candidate_env candidate_label candidate_status

  if [[ -n "$COMPOSE_FILE" ]]; then
    COMPOSE_FILE=$(resolve_cli_path "$COMPOSE_FILE")
  else
    detect_compose_candidates
    candidate_count=${#DETECTED_COMPOSE_FILES[@]}

    if (( candidate_count == 0 )); then
      echo "  ❌ Aucun compose réutilisable détecté automatiquement."
      echo "     Fournissez --compose-file pour reprendre une base existante."
      return 1
    fi

    if (( candidate_count == 1 )); then
      choose_detected_compose_candidate 0
      echo "  ✓ Compose détecté automatiquement : $(display_path "$COMPOSE_FILE")"
    elif [[ "$AUTO_YES" == true ]]; then
      echo "  ❌ Plusieurs compose réutilisables ont été détectés :"
      for selected in "${!DETECTED_COMPOSE_FILES[@]}"; do
        echo "     $((selected + 1))) ${DETECTED_COMPOSE_LABELS[$selected]} — $(display_path "${DETECTED_COMPOSE_FILES[$selected]}")"
      done
      echo "     Relancez avec --compose-file pour lever l'ambiguïté."
      return 1
    else
      echo "  Compose détectés pouvant être repris :"
      for selected in "${!DETECTED_COMPOSE_FILES[@]}"; do
        candidate_path=$(display_path "${DETECTED_COMPOSE_FILES[$selected]}")
        candidate_label="${DETECTED_COMPOSE_LABELS[$selected]}"
        candidate_status="${DETECTED_COMPOSE_STATUS[$selected]}"
        printf '     %d) %s\n' "$((selected + 1))" "$candidate_label"
        printf '        %s (%s)\n' "$candidate_path" "$candidate_status"
      done
      echo
      read -rp "  → Compose à reprendre [1-${candidate_count}] : " selected
      if ! [[ "$selected" =~ ^[0-9]+$ ]] || (( selected < 1 || selected > candidate_count )); then
        echo "  ❌ Sélection invalide."
        return 1
      fi
      choose_detected_compose_candidate "$((selected - 1))"
    fi
  fi

  if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "  ❌ Fichier compose introuvable : $COMPOSE_FILE"
    return 1
  fi

  if [[ -z "$ENV_FILE" ]]; then
    compose_dir=$(dirname "$COMPOSE_FILE")
    if [[ -f "$compose_dir/.env" ]]; then
      ENV_FILE="$compose_dir/.env"
    fi
  else
    ENV_FILE=$(resolve_cli_path "$ENV_FILE")
  fi

  if [[ -n "$ENV_FILE" && ! -f "$ENV_FILE" ]]; then
    echo "  ❌ Fichier env introuvable : $ENV_FILE"
    return 1
  fi

  if ! run_compose config >/dev/null 2>&1; then
    echo
    echo "  ❌ Le fichier compose ne peut pas être résolu."
    echo "     Ajoutez --env-file si votre compose dépend de variables externes."
    return 1
  fi

  return 0
}

run_compose() {
  local -a cmd=(docker compose)
  if [[ -n "$ENV_FILE" ]]; then
    cmd+=(--env-file "$ENV_FILE")
  fi
  cmd+=(-f "$COMPOSE_FILE")
  "${cmd[@]}" "$@"
}

load_runtime_details() {
  local container_id
  container_id=$(run_compose ps -q "$SERVICE_NAME" 2>/dev/null || true)
  if [[ -z "$container_id" ]]; then
    return 1
  fi

  CONTAINER_NAME=$(docker inspect -f '{{.Name}}' "$container_id" 2>/dev/null | sed 's#^/##')
  RUNTIME_PORT=$(docker inspect -f '{{range $port, $bindings := .NetworkSettings.Ports}}{{if eq $port "8080/tcp"}}{{if $bindings}}{{(index $bindings 0).HostPort}}{{end}}{{end}}{{end}}' "$container_id" 2>/dev/null)
  RUNTIME_BIND_IP=$(docker inspect -f '{{range $port, $bindings := .NetworkSettings.Ports}}{{if eq $port "8080/tcp"}}{{if $bindings}}{{(index $bindings 0).HostIp}}{{end}}{{end}}{{end}}' "$container_id" 2>/dev/null)

  [[ -z "$RUNTIME_PORT" ]] && RUNTIME_PORT="$PORT"

  if [[ -z "$RUNTIME_BIND_IP" || "$RUNTIME_BIND_IP" == "0.0.0.0" ]]; then
    STATUS_HOST="127.0.0.1"
    DISPLAY_HOST="${BIND_IP:-localhost}"
    [[ -z "$DISPLAY_HOST" || "$DISPLAY_HOST" == "0.0.0.0" ]] && DISPLAY_HOST="localhost"
  else
    STATUS_HOST="$RUNTIME_BIND_IP"
    DISPLAY_HOST="$RUNTIME_BIND_IP"
  fi

  return 0
}

wait_for_api() {
  local host=$1 port=$2 max_wait=${3:-120}
  local waited=0

  while (( waited < max_wait )); do
    if curl -sf "http://${host}:${port}/status" &>/dev/null; then
      return 0
    fi
    sleep 5
    ((waited += 5))
  done

  return 1
}

# ---------------------------------------------------------------------------
# CLI parsing
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
🗺️  Nominatim Docker — Wizard de déploiement

Usage: ./start.sh [OPTIONS]

Options:
  --regions "r1,r2,..."   Régions/départements (IDs, numéros ou noms)
  --reuse-existing        Reprendre une base existante sans supprimer le volume
  --compose-file PATH     Fichier compose à réutiliser avec --reuse-existing
  --env-file PATH         Fichier d'environnement compose optionnel
  --port PORT             Port d'écoute (défaut: 8080)
  --bind IP               Adresse d'écoute (défaut: détection auto LAN)
  --threads N             Nombre de threads d'import
  --yes                   Skip les confirmations
  --list                  Afficher les régions disponibles et quitter
  --help                  Afficher cette aide

Exemples:
  ./start.sh                                    # Mode interactif
  ./start.sh --regions "normandie,bretagne"     # Normandie + Bretagne
  ./start.sh --regions "14,76" --yes            # Calvados + Seine-Maritime
  ./start.sh --regions "ile-de-france" --port 9090
  ./start.sh --reuse-existing                   # Reprendre docker-compose.generated.yml
  ./start.sh --reuse-existing --compose-file contrib/docker-compose-normandie-region.yml --env-file contrib/.env
EOF
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --regions) CLI_REGIONS="$2"; shift 2 ;;
    --reuse-existing) REUSE_EXISTING=true; shift ;;
    --compose-file) COMPOSE_FILE="$2"; shift 2 ;;
    --env-file) ENV_FILE="$2"; shift 2 ;;
    --port)    PORT="$2"; shift 2 ;;
    --bind)    BIND_IP="$2"; shift 2 ;;
    --threads) THREADS="$2"; shift 2 ;;
    --yes)     AUTO_YES=true; shift ;;
    --list)    list_regions; exit 0 ;;
    --help|-h) usage ;;
    *) echo "Option inconnue: $1"; usage ;;
  esac
done

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
echo
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║   🗺️  Nominatim Docker — Déploiement France     ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo

# ---------------------------------------------------------------------------
# Step 1: Prérequis
# ---------------------------------------------------------------------------
echo "━━ Étape 1/6 : Vérification des prérequis ━━"
echo
check_prerequisites || exit 1
detect_resources
echo "  ✓ Docker $(docker --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+')"
echo "  ✓ RAM: ${RAM_GB} GB | CPU: ${CPU_COUNT} cœurs | Disque libre: ${DISK_FREE_GB} GB"
echo

# ---------------------------------------------------------------------------
# Step 2: Détection réseau
# ---------------------------------------------------------------------------
echo "━━ Étape 2/6 : Configuration réseau ━━"
echo
if [[ -z "$BIND_IP" ]]; then
  BIND_IP=$(detect_lan_ip)
fi
if [[ -z "$BIND_IP" ]]; then
  BIND_IP="0.0.0.0"
  echo "  ⚠️  Impossible de détecter l'IP LAN, écoute sur toutes les interfaces"
else
  echo "  ✓ Adresse d'écoute : $BIND_IP:$PORT"
fi
echo

if [[ -z "$CLI_REGIONS" && "$REUSE_EXISTING" != true && "$AUTO_YES" != true ]]; then
  detect_compose_candidates

  echo "━━ Étape 3/7 : Choix du mode ━━"
  echo

  if (( ${#DETECTED_COMPOSE_FILES[@]} > 0 )); then
    echo "  ✓ Reprise possible détectée automatiquement :"
    for selected in "${!DETECTED_COMPOSE_FILES[@]}"; do
      printf '     %d) %s — %s\n' \
        "$((selected + 1))" \
        "${DETECTED_COMPOSE_LABELS[$selected]}" \
        "$(display_path "${DETECTED_COMPOSE_FILES[$selected]}")"
    done
    echo
    echo "  1) Nouveau déploiement"
    echo "  2) Reprendre une base existante"
    echo
    read -rp "  → Mode [1/2] (défaut 1) : " mode_choice
    mode_choice="${mode_choice:-1}"
    if [[ "$mode_choice" == "2" ]]; then
      REUSE_EXISTING=true
    elif [[ "$mode_choice" != "1" ]]; then
      echo "  ❌ Choix invalide."
      exit 1
    fi
  else
    echo "  • Aucun compose existant détecté automatiquement."
    echo "    Le wizard poursuit sur un nouveau déploiement."
  fi

  echo
  SELECT_STEP_LABEL="━━ Étape 4/7 : Sélection des régions ━━"
  ESTIMATE_STEP_LABEL="━━ Étape 5/7 : Estimation ━━"
  DEPLOY_STEP_LABEL="━━ Étape 6/7 : Téléchargement et déploiement ━━"
  GUIDE_STEP_LABEL="━━ Étape 7/7 : Guide API ━━"
  REUSE_SELECT_STEP_LABEL="━━ Étape 4/5 : Reprise d'une base existante ━━"
  REUSE_START_STEP_LABEL="━━ Étape 5/5 : Démarrage sécurisé ━━"
fi

# ---------------------------------------------------------------------------
# Reuse existing deployment
# ---------------------------------------------------------------------------
if [[ "$REUSE_EXISTING" == true ]]; then
  if [[ -n "$CLI_REGIONS" ]]; then
    echo "  ❌ --regions ne peut pas être combiné avec --reuse-existing"
    exit 1
  fi

  echo "$REUSE_SELECT_STEP_LABEL"
  echo
  if ! resolve_reuse_target; then
    exit 1
  fi

  echo "  ✓ Compose : $(display_path "$COMPOSE_FILE")"
  if [[ -n "$ENV_FILE" ]]; then
    echo "  ✓ Env     : $(display_path "$ENV_FILE")"
  else
    echo "  • Env     : aucun"
  fi

  echo
  echo "  Ce mode exécute uniquement docker compose up -d."
  echo "  Aucun volume PostgreSQL ne sera supprimé."

  if [[ "$AUTO_YES" != true ]]; then
    read -rp "  Reprendre la base existante ? [O/n] " confirm
    confirm="${confirm:-o}"
    if [[ "${confirm,,}" != "o" && "${confirm,,}" != "oui" && "${confirm,,}" != "y" && "${confirm,,}" != "yes" ]]; then
      echo "  Annulé."
      exit 0
    fi
  fi

  echo
  echo "$REUSE_START_STEP_LABEL"
  echo
  echo "  🚀 Reprise sans suppression de volume..."
  run_compose up -d

  if ! load_runtime_details; then
    echo "  ❌ Impossible d'identifier le conteneur démarré."
    exit 1
  fi

  if docker exec "$CONTAINER_NAME" test -f /var/lib/postgresql/16/main/import-finished 2>/dev/null; then
    echo "  ✓ Marqueur import-finished détecté : pas de réimport attendu."
  else
    echo "  ⚠️  Marqueur import-finished absent."
    echo "     Si la base a été créée via init.sh manuel, un réimport peut repartir."
  fi

  echo "  ⏳ Vérification de l'API..."
  if wait_for_api "$STATUS_HOST" "$RUNTIME_PORT" 120; then
    echo "  ✅ API opérationnelle sur http://${DISPLAY_HOST}:${RUNTIME_PORT}"
    echo "  Exemple : curl \"http://${DISPLAY_HOST}:${RUNTIME_PORT}/status?format=json\""
  else
    echo "  ⚠️  L'API ne répond pas encore."
    echo "  Surveillez avec : docker logs -f $CONTAINER_NAME"
  fi

  echo
  echo "  ╔══════════════════════════════════════════════════╗"
  echo "  ║   ✅ Reprise terminée                           ║"
  echo "  ╚══════════════════════════════════════════════════╝"
  echo
  exit 0
fi

# ---------------------------------------------------------------------------
# Step 3: Sélection des régions
# ---------------------------------------------------------------------------
echo "$SELECT_STEP_LABEL"
echo

declare -A SELECTED_REGIONS  # associative: id → 1

if [[ -n "$CLI_REGIONS" ]]; then
  # Mode CLI
  IFS=',' read -ra tokens <<< "$CLI_REGIONS"
  for token in "${tokens[@]}"; do
    token=$(echo "$token" | xargs) # trim
    resolved=$(resolve_input "$token") || { echo "  ❌ Entrée non reconnue : '$token'"; exit 1; }
    for rid in $resolved; do
      SELECTED_REGIONS[$rid]=1
    done
  done
else
  # Mode interactif
  list_regions
  echo "  Entrez les numéros, noms de régions ou départements"
  echo "  (séparés par des virgules, ex: 1,3,normandie,75)"
  echo "  Tapez 'all' pour toute la France métropolitaine."
  echo
  read -rp "  → Votre sélection : " user_input

  if [[ "${user_input,,}" == "all" ]]; then
    for id in "${REGION_ORDER[@]}"; do
      SELECTED_REGIONS[$id]=1
    done
  else
    IFS=',' read -ra tokens <<< "$user_input"
    for token in "${tokens[@]}"; do
      token=$(echo "$token" | xargs)
      [[ -z "$token" ]] && continue
      resolved=$(resolve_input "$token") || { echo "  ❌ Entrée non reconnue : '$token'"; exit 1; }
      for rid in $resolved; do
        SELECTED_REGIONS[$rid]=1
      done
    done
  fi
fi

if (( ${#SELECTED_REGIONS[@]} == 0 )); then
  echo "  ❌ Aucune région sélectionnée."
  exit 1
fi

# Deduplicate and sort
REGION_LIST=()
for id in "${REGION_ORDER[@]}"; do
  [[ -n "${SELECTED_REGIONS[$id]+x}" ]] && REGION_LIST+=("$id")
done

echo
echo "  📋 Régions sélectionnées :"
for id in "${REGION_LIST[@]}"; do
  printf "     • %-30s %4s MB\n" "$(get_region_name "$id")" "$(get_region_size "$id")"
done
echo

# ---------------------------------------------------------------------------
# Step 4: Estimation et confirmation
# ---------------------------------------------------------------------------
echo "$ESTIMATE_STEP_LABEL"
echo

TOTAL_SIZE=$(compute_total_size "${REGION_LIST[*]}")
[[ -z "$THREADS" ]] && THREADS=$(recommend_threads)

ESTIMATE_MIN=$(estimate_time "$TOTAL_SIZE" "$THREADS" "$RAM_GB")

echo "  📦 Taille totale PBF : ~${TOTAL_SIZE} MB"
echo "  🧵 Threads d'import  : $THREADS"
echo "  ⏱  Temps estimé      : $(format_duration "$ESTIMATE_MIN")"
echo "  💾 Espace disque requis : ~$(( TOTAL_SIZE * 3 / 1024 + 1 )) GB"
echo

check_disk_space "$TOTAL_SIZE" || exit 1

if [[ "$AUTO_YES" != true ]]; then
  read -rp "  Lancer le déploiement ? [O/n] " confirm
  confirm="${confirm:-o}"
  if [[ "${confirm,,}" != "o" && "${confirm,,}" != "oui" && "${confirm,,}" != "y" && "${confirm,,}" != "yes" ]]; then
    echo "  Annulé."
    exit 0
  fi
fi
echo

# ---------------------------------------------------------------------------
# Step 5: Téléchargement, fusion et lancement Docker
# ---------------------------------------------------------------------------
echo "$DEPLOY_STEP_LABEL"
echo

mkdir -p "$DATA_DIR"

# --- Download PBFs ---
echo "  📥 Téléchargement des fichiers PBF..."
DOWNLOADED_FILES=()
for id in "${REGION_LIST[@]}"; do
  local_file="$DATA_DIR/${id}.osm.pbf"
  url="${GEOFABRIK_BASE}/${id}-latest.osm.pbf"
  DOWNLOADED_FILES+=("$local_file")

  if [[ -f "$local_file" ]]; then
    echo "     ✓ ${id} (déjà présent)"
    continue
  fi

  printf "     ⬇ %-30s " "$(get_region_name "$id")..."
  if curl -sSL -o "$local_file" "$url" 2>/dev/null; then
    echo "OK ($(du -h "$local_file" | cut -f1))"
  else
    echo "ERREUR"
    rm -f "$local_file"
    echo "  ❌ Échec du téléchargement de $url"
    exit 1
  fi
done
echo

# --- Merge PBFs if needed ---
if (( ${#REGION_LIST[@]} == 1 )); then
  PBF_FILE="${REGION_LIST[0]}.osm.pbf"
  echo "  ✓ Région unique — pas de fusion nécessaire"
else
  PBF_FILE="nominatim-custom.osm.pbf"
  PBF_PATH="$DATA_DIR/$PBF_FILE"
  echo "  🔀 Fusion de ${#REGION_LIST[@]} fichiers PBF..."

  MERGE_ARGS=()
  for f in "${DOWNLOADED_FILES[@]}"; do
    MERGE_ARGS+=("/data/$(basename "$f")")
  done

  HOST_UID=$(id -u)
  HOST_GID=$(id -g)

  if command -v osmium &>/dev/null; then
    osmium cat -o "$PBF_PATH" "${DOWNLOADED_FILES[@]}" --overwrite
  else
    docker run --rm \
      -v "$DATA_DIR:/data" \
      -e HOST_UID="$HOST_UID" -e HOST_GID="$HOST_GID" \
      ubuntu:24.04 bash -c "
        apt-get update -qq && apt-get install -y -qq osmium-tool >/dev/null 2>&1 &&
        osmium cat -o /data/$PBF_FILE ${MERGE_ARGS[*]} --overwrite &&
        chown \$HOST_UID:\$HOST_GID /data/$PBF_FILE
      "
  fi

  if [[ ! -f "$PBF_PATH" ]]; then
    echo "  ❌ La fusion a échoué."
    exit 1
  fi
  echo "  ✓ Fusion terminée ($(du -h "$PBF_PATH" | cut -f1))"
fi
echo

# --- Generate docker-compose.yml ---
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.generated.yml"
CONTAINER_NAME="nominatim-custom"
PASSWORD=$(head -c 24 /dev/urandom | xxd -p)

sed \
  -e "s|__BIND_IP__|$BIND_IP|g" \
  -e "s|__PORT__|$PORT|g" \
  -e "s|__PBF_NAME__|$PBF_FILE|g" \
  -e "s|__THREADS__|$THREADS|g" \
  -e "s|__CONTAINER_NAME__|$CONTAINER_NAME|g" \
  -e "s|__PASSWORD__|$PASSWORD|g" \
  "$SCRIPT_DIR/templates/docker-compose.tpl.yml" > "$COMPOSE_FILE"

echo "  ✓ docker-compose.generated.yml créé"

# --- Stop any existing instance ---
if docker ps -q --filter "name=$CONTAINER_NAME" 2>/dev/null | grep -q .; then
  echo "  ⏹  Arrêt de l'instance existante..."
  docker compose -f "$COMPOSE_FILE" down -v 2>/dev/null || true
fi

# --- Start ---
echo "  🚀 Lancement du conteneur..."
docker compose -f "$COMPOSE_FILE" up -d

echo
monitor_docker_import "$CONTAINER_NAME" "$ESTIMATE_MIN"
echo

# ---------------------------------------------------------------------------
# Step 6: Génération du guide API
# ---------------------------------------------------------------------------
echo "$GUIDE_STEP_LABEL"
echo

# Build region list string for guide
REGION_NAMES=""
for id in "${REGION_LIST[@]}"; do
  [[ -n "$REGION_NAMES" ]] && REGION_NAMES+=", "
  REGION_NAMES+="$(get_region_name "$id")"
done

FIRST_CITY=$(get_region_city "${REGION_LIST[0]}")
TODAY=$(date +%Y-%m-%d)

API_GUIDE="$SCRIPT_DIR/API-GUIDE.md"
sed \
  -e "s|__IP__|$BIND_IP|g" \
  -e "s|__PORT__|$PORT|g" \
  -e "s|__REGIONS__|$REGION_NAMES|g" \
  -e "s|__TEST_CITY__|$FIRST_CITY|g" \
  -e "s|__DATE__|$TODAY|g" \
  "$SCRIPT_DIR/templates/API-GUIDE.tpl.md" > "$API_GUIDE"

echo "  ✓ API-GUIDE.md généré"
echo

# --- Final validation ---
echo "  ⏳ Vérification de l'API (attente que le serveur soit prêt)..."
MAX_WAIT=120
WAITED=0
while (( WAITED < MAX_WAIT )); do
  if curl -sf "http://${BIND_IP}:${PORT}/status" &>/dev/null; then
    break
  fi
  sleep 5
  ((WAITED += 5))
done

if curl -sf "http://${BIND_IP}:${PORT}/status" &>/dev/null; then
  echo "  ✅ API opérationnelle !"
  echo
  echo "  Exemple :"
  echo "    curl \"http://${BIND_IP}:${PORT}/search?q=${FIRST_CITY}&format=jsonv2\""
else
  echo "  ⚠️  L'API ne répond pas encore (l'import peut encore être en cours)"
  echo "  Surveillez avec : docker logs -f $CONTAINER_NAME"
fi

echo
echo "  📖 Guide complet : API-GUIDE.md"
echo
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║   ✅ Déploiement terminé                        ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo
