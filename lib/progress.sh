#!/usr/bin/env bash
# lib/progress.sh — Barres de progression et estimation du temps
# Sourced by start.sh

# Calibration points: taille_PBF_MB → minutes d'import
# Monaco ~0.7 MB → 5 min, Normandie ~235 MB → 30 min, Region ~1200 MB → 60 min
# Modèle linéaire simple avec plancher

# estimate_time PBF_SIZE_MB THREADS RAM_GB → minutes
estimate_time() {
  local size_mb=$1 threads=${2:-4} ram_gb=${3:-8}

  # Base: ~3 min plancher + 0.05 min/MB (calibré sur nos mesures)
  local base=$(( 3 + size_mb * 5 / 100 ))

  # Bonus threads : -10% par thread supplémentaire au-delà de 2 (max -40%)
  local thread_factor=100
  if (( threads > 2 )); then
    thread_factor=$(( 100 - (threads - 2) * 10 ))
    (( thread_factor < 60 )) && thread_factor=60
  fi

  # Bonus RAM : si >16GB, -15%
  local ram_factor=100
  (( ram_gb >= 16 )) && ram_factor=85

  local minutes=$(( base * thread_factor / 100 * ram_factor / 100 ))
  (( minutes < 3 )) && minutes=3
  echo "$minutes"
}

# format_duration MINUTES → "Xh Ymin" ou "Ymin"
format_duration() {
  local minutes=$1
  if (( minutes >= 60 )); then
    echo "$((minutes / 60))h $((minutes % 60))min"
  else
    echo "${minutes}min"
  fi
}

# progress_bar CURRENT TOTAL [LABEL] — affiche une barre inline
progress_bar() {
  local current=$1 total=$2 label="${3:-Progression}"
  local width=40
  local pct=0
  (( total > 0 )) && pct=$(( current * 100 / total ))
  local filled=$(( pct * width / 100 ))
  local empty=$(( width - filled ))

  printf "\r  %s [" "$label"
  printf '%0.s█' $(seq 1 $filled 2>/dev/null) || true
  printf '%0.s░' $(seq 1 $empty 2>/dev/null) || true
  printf "] %3d%%" "$pct"
}

# spinner PID [LABEL] — affiche un spinner tant que le PID tourne
spinner() {
  local pid=$1 label="${2:-En cours}"
  local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r  %s %s " "${chars:i%${#chars}:1}" "$label"
    ((i++))
    sleep 0.1
  done
  printf "\r  ✓ %s\n" "$label"
}

# monitor_docker_import CONTAINER_NAME TOTAL_ESTIMATE_MIN — suit l'import Docker
# surveille les logs pour les étapes connues et affiche la progression
monitor_docker_import() {
  local container=$1 estimate_min=$2
  local start_time=$SECONDS
  local phase="Initialisation"

  echo "  ⏱  Durée estimée : $(format_duration "$estimate_min")"
  echo

  while true; do
    # Check if container is still running
    local state
    state=$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null) || break
    [[ "$state" != "running" ]] && break

    # Check latest log lines for phase detection
    local last_log
    last_log=$(docker logs --tail 5 "$container" 2>&1 | tail -1)

    case "$last_log" in
      *"Downloading"*)        phase="Téléchargement PBF" ;;
      *"Importing"*|*"osm2pgsql"*) phase="Import OSM (le plus long)" ;;
      *"Indexing"*)           phase="Indexation" ;;
      *"warmup"*|*"Warming"*) phase="Préchauffage cache" ;;
      *"ready to accept"*)
        printf "\r  ✅ Import terminé en %s\n" "$(format_duration $(( (SECONDS - start_time) / 60 )))"
        return 0
        ;;
    esac

    local elapsed_min=$(( (SECONDS - start_time) / 60 ))
    local pct=0
    (( estimate_min > 0 )) && pct=$(( elapsed_min * 100 / estimate_min ))
    (( pct > 99 )) && pct=99
    progress_bar "$pct" 100 "$phase"

    sleep 10
  done

  local elapsed_min=$(( (SECONDS - start_time) / 60 ))
  printf "\r  ✅ Import terminé en %s\n" "$(format_duration $elapsed_min)"
}
