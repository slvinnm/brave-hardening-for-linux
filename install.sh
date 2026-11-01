#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
POLICY_SOURCE="$SCRIPT_DIR/brave-policy.json"
POLICY_REF="${OMARCHY_BRAVE_POLICY_REF:-main}"
POLICY_URL="https://raw.githubusercontent.com/slvinnm/brave-hardening-for-linux/${POLICY_REF}/brave-policy.json"
TEMP_POLICY=""
POLICY_DIR="/etc/brave/policies/managed"
POLICY_FILE="$POLICY_DIR/omarchy-brave-policy.json"
STATE_DIR="/var/lib/omarchy-brave-policy"
STATE_MARKER="$STATE_DIR/installed"
ORIGINAL_EXISTS_MARKER="$STATE_DIR/original-policy-existed"
ORIGINAL_BACKUP="$STATE_DIR/original-policy.json"

log()  { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die()  { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || die "python3 diperlukan untuk validasi JSON."

# When invoked from a local checkout, use its adjacent JSON. When piped from
# curl, fetch the policy from this repository (pin with OMARCHY_BRAVE_POLICY_REF).
if [[ ! -f "$POLICY_SOURCE" ]]; then
  command -v curl >/dev/null 2>&1 || die "curl diperlukan saat install.sh dijalankan tanpa file lokal."
  TEMP_POLICY="$(mktemp)"
  trap '[[ -z "$TEMP_POLICY" ]] || rm -f -- "$TEMP_POLICY"' EXIT
  curl -fsSL "$POLICY_URL" -o "$TEMP_POLICY" || die "Gagal mengunduh policy dari $POLICY_URL"
  POLICY_SOURCE="$TEMP_POLICY"
fi

python3 -m json.tool "$POLICY_SOURCE" >/dev/null || die "JSON policy tidak valid."

# This project targets a native Brave installation. Flatpak is sandboxed and
# should not be assumed to consume the host's /etc/brave policy directory.
flatpak_installed=0
if command -v flatpak >/dev/null 2>&1 && flatpak info com.brave.Browser >/dev/null 2>&1; then
  flatpak_installed=1
fi

native_package=0
if command -v pacman >/dev/null 2>&1; then
  for pkg in brave brave-bin brave-browser brave-beta brave-nightly; do
    if pacman -Q "$pkg" >/dev/null 2>&1; then
      native_package=1
      break
    fi
  done
fi

native_command=0
for bin in brave brave-browser brave-browser-stable; do
  if command -v "$bin" >/dev/null 2>&1; then
    command_path="$(command -v "$bin")"
    resolved="$(readlink -f -- "$command_path" 2>/dev/null || true)"
    case "$command_path:$resolved" in
      *flatpak*|/app/*|*/flatpak) ;;
      *) native_command=1; break ;;
    esac
  fi
done

if (( native_package == 0 && native_command == 0 )); then
  if (( flatpak_installed == 1 )); then
    die "Yang terdeteksi hanya Brave Flatpak. Policy host /etc/brave/policies/managed tidak dijamin berlaku untuk Flatpak. Install Brave native terlebih dahulu atau kelola policy Flatpak secara terpisah."
  fi
  die "Instalasi Brave native tidak terdeteksi. Pastikan Brave sudah terpasang."
fi

SUDO=()
if (( EUID != 0 )); then
  command -v sudo >/dev/null 2>&1 || die "sudo tidak ditemukan."
  sudo -v || die "Gagal mendapatkan izin sudo."
  SUDO=(sudo)
fi

if pgrep -x brave >/dev/null 2>&1 || pgrep -x brave-browser >/dev/null 2>&1; then
  warn "Brave sedang berjalan. Tutup dan buka kembali Brave setelah instalasi agar policy diterapkan."
fi

# Record the pre-existing target only once. The state marker prevents a later
# reinstall from accidentally backing up this project's own policy file.
if ! "${SUDO[@]}" test -f "$STATE_MARKER"; then
  "${SUDO[@]}" install -d -m 0755 "$STATE_DIR"

  if "${SUDO[@]}" test -e "$POLICY_FILE"; then
    if ! "${SUDO[@]}" test -e "$ORIGINAL_BACKUP"; then
      "${SUDO[@]}" install -m 0644 "$POLICY_FILE" "$ORIGINAL_BACKUP"
    fi
    "${SUDO[@]}" touch "$ORIGINAL_EXISTS_MARKER"
    log "Policy dengan nama tujuan sudah ada; salinan aslinya disimpan di $ORIGINAL_BACKUP"
  fi

  "${SUDO[@]}" touch "$STATE_MARKER"
fi

"${SUDO[@]}" install -d -m 0755 "$POLICY_DIR"
"${SUDO[@]}" install -m 0644 "$POLICY_SOURCE" "$POLICY_FILE"

log "Policy berhasil dipasang: $POLICY_FILE"
log "Buka brave://policy lalu klik Reload policies untuk memeriksa policy."
log "Restart Brave agar seluruh perubahan diterapkan."
