#!/usr/bin/env bash
# Split the DJI Mic 3 receiver (4-channel USB mode) into 1 to 4 persistent mono
# PipeWire sources: "DJI TX1" (FL), "DJI TX2" (FR), "DJI TX3" (RL), "DJI TX4" (RR).
#
# Usage:
#   dji-mic3-split.sh                 install / update, 4 sources (auto-detects the receiver)
#   dji-mic3-split.sh -n 3            install only the first 3 sources (1 to 4)
#   dji-mic3-split.sh [-n N] <source> install using an explicit PipeWire source name
#   dji-mic3-split.sh --uninstall     remove the configuration
set -euo pipefail

CONF_DIR="$HOME/.config/pipewire/pipewire.conf.d"
CONF_FILE="$CONF_DIR/dji-mic3-split.conf"
# Channel of the receiver feeding each transmitter, in TX1..TX4 order.
ALL_CHANNELS=(FL FR RL RR)

die() { echo "Erreur : $*" >&2; exit 1; }

restart_pipewire() {
    echo "Redémarrage de PipeWire..."
    systemctl --user restart pipewire pipewire-pulse wireplumber
}

unload_temp_modules() {
    local id
    while read -r id _; do
        pactl unload-module "$id"
        echo "Module temporaire $id déchargé."
    done < <(pactl list modules short | grep -E 'module-remap-source.*source_name=dji_tx' || true)
}

ensure_deps() {
    if ! command -v pactl >/dev/null; then
        echo "Installation de pulseaudio-utils (pactl)..."
        sudo apt-get install -y pulseaudio-utils
    fi
    command -v pw-cli >/dev/null || die "PipeWire n'est pas installé."
    systemctl --user is-active --quiet pipewire || die "Le service PipeWire utilisateur n'est pas actif."
}

MICS=${#ALL_CHANNELS[@]}
SRC=""
UNINSTALL=0
while (( $# > 0 )); do
    case "$1" in
        --uninstall) UNINSTALL=1 ;;
        -n|--mics)
            [[ "${2:-}" =~ ^[1-4]$ ]] || die "-n attend un nombre de micros entre 1 et 4."
            MICS=$2
            shift ;;
        -*) die "option inconnue : $1" ;;
        *) SRC=$1 ;;
    esac
    shift
done
CHANNELS=("${ALL_CHANNELS[@]:0:MICS}")

if (( UNINSTALL )); then
    ensure_deps
    unload_temp_modules
    rm -f "$CONF_FILE"
    echo "Configuration supprimée : $CONF_FILE"
    restart_pipewire
    exit 0
fi

ensure_deps

if [[ -z "$SRC" ]]; then
    SRC=$(pactl list sources short | awk '$2 ~ /DJI.*Wireless_Mic_Rx/ && $2 !~ /\.monitor$/ {print $2; exit}')
    [[ -n "$SRC" ]] || die "récepteur DJI introuvable. Branche-le en USB (mode 4 canaux) ou passe le nom de la source en argument."
fi

CH_COUNT=$(pactl list sources short | awk -v s="$SRC" '$2 == s {for (i=1;i<=NF;i++) if ($i ~ /^[0-9]+ch$/) {sub("ch","",$i); print $i}}')
[[ -n "$CH_COUNT" ]] || die "source '$SRC' introuvable."
(( CH_COUNT >= 4 )) || die "la source '$SRC' n'a que $CH_COUNT canaux. Passe le récepteur en mode 4 canaux (profil Surround 4.0 dans pavucontrol > Configuration)."

echo "Récepteur détecté : $SRC ($CH_COUNT canaux)"

mkdir -p "$CONF_DIR"
{
    echo "# Généré par dji-mic3-split.sh - un micro DJI Mic 3 par source mono."
    echo "context.modules = ["
    for i in "${!CHANNELS[@]}"; do
        n=$((i + 1))
        cat <<EOF
  { name = libpipewire-module-loopback
    args = {
      node.description = "DJI TX$n"
      capture.props = {
        node.name = "cap.dji_tx$n"
        audio.position = [ ${CHANNELS[$i]} ]
        stream.dont-remix = true
        node.passive = true
        node.dont-fallback = true
        target.object = "$SRC"
      }
      playback.props = {
        node.name = "dji_tx$n"
        node.description = "DJI TX$n"
        media.class = "Audio/Source"
        audio.position = [ MONO ]
      }
    }
  }
EOF
    done
    echo "]"
} > "$CONF_FILE"
echo "Configuration écrite : $CONF_FILE"

unload_temp_modules
restart_pipewire

for _ in $(seq 1 20); do
    found=$(pactl list sources short 2>/dev/null | awk '$2 ~ /^dji_tx[0-9]+$/' | wc -l)
    (( found >= ${#CHANNELS[@]} )) && break
    sleep 0.5
done

pactl list sources short | awk '$2 ~ /^dji_tx[0-9]+$/ {print "  OK  " $2}'
(( found >= ${#CHANNELS[@]} )) || die "seulement $found source(s) DJI créée(s) sur ${#CHANNELS[@]}. Voir : journalctl --user -u pipewire -n 50"
echo "Terminé. Dans OBS : Capture d'entrée audio (PulseAudio) > DJI TX1 / TX2 / TX3."
