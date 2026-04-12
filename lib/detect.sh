#!/usr/bin/env bash
# lib/detect.sh — Détection réseau, ressources, prérequis
# Sourced by start.sh

# detect_lan_ip — Première IP privée non-Docker
detect_lan_ip() {
  ip -4 -o addr show scope global 2>/dev/null \
    | awk '{print $2, $4}' \
    | while IFS=' ' read -r iface cidr; do
        local ip="${cidr%%/*}"
        # Skip Docker/veth bridges
        case "$iface" in
          docker*|br-*|veth*) continue ;;
        esac
        echo "$ip"
        return 0
      done
}

# detect_resources — sets RAM_GB, CPU_COUNT, DISK_FREE_GB
detect_resources() {
  RAM_GB=$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo 4)
  CPU_COUNT=$(nproc 2>/dev/null || echo 2)
  DISK_FREE_GB=$(df -BG --output=avail "${DATA_DIR:-.}" 2>/dev/null | tail -1 | tr -dc '0-9')
  [[ -z "$DISK_FREE_GB" ]] && DISK_FREE_GB=20
  return 0
}

# recommend_threads — based on CPU and RAM
recommend_threads() {
  local threads=$CPU_COUNT
  # Cap threads if RAM is limited (need ~1.5GB per thread during import)
  local max_by_ram=$(( RAM_GB * 2 / 3 ))
  (( max_by_ram < threads )) && threads=$max_by_ram
  (( threads < 1 )) && threads=1
  echo "$threads"
}

# check_prerequisites — verify required tools
check_prerequisites() {
  local missing=()

  if ! command -v docker &>/dev/null; then
    missing+=("docker")
  elif ! docker info &>/dev/null 2>&1; then
    missing+=("docker (démon inaccessible — ajouter l'utilisateur au groupe docker?)")
  fi

  if ! docker compose version &>/dev/null 2>&1; then
    missing+=("docker compose v2")
  fi

  for cmd in curl md5sum; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done

  if (( ${#missing[@]} > 0 )); then
    echo "❌ Prérequis manquants :"
    for m in "${missing[@]}"; do
      echo "   • $m"
    done
    return 1
  fi
  return 0
}

# check_disk_space SIZE_MB — verify enough free space (need ~3x for download+import)
check_disk_space() {
  local needed_mb=$1
  local needed_gb=$(( (needed_mb * 3 + 1023) / 1024 ))
  detect_resources
  if (( DISK_FREE_GB < needed_gb )); then
    echo "⚠️  Espace disque insuffisant : ${DISK_FREE_GB} GB disponible, ~${needed_gb} GB nécessaire"
    return 1
  fi
  return 0
}
