#!/usr/bin/env bash
set -Eeuo pipefail

POLICY_DIR="/etc/brave/policies/managed"
POLICY_FILE="$POLICY_DIR/omarchy-brave-policy.json"
STATE_DIR="/var/lib/omarchy-brave-policy"
STATE_MARKER="$STATE_DIR/installed"
ORIGINAL_EXISTS_MARKER="$STATE_DIR/original-policy-existed"
ORIGINAL_BACKUP="$STATE_DIR/original-policy.json"

log()  { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die()  { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

SUDO=()
if (( EUID != 0 )); then
  command -v sudo >/dev/null 2>&1 || die "sudo tidak ditemukan."
  sudo -v || die "Gagal mendapatkan izin sudo."
  SUDO=(sudo)
fi

if ! "${SUDO[@]}" test -f "$STATE_MARKER"; then
  warn "Tidak menemukan status instalasi milik project ini. Tidak ada perubahan dilakukan."
  exit 0
fi

if "${SUDO[@]}" test -f "$ORIGINAL_EXISTS_MARKER"; then
  "${SUDO[@]}" test -f "$ORIGINAL_BACKUP" || die "Backup policy asli tidak ditemukan di $ORIGINAL_BACKUP. File tidak dihapus agar konfigurasi sebelumnya tidak hilang."
  "${SUDO[@]}" install -d -m 0755 "$POLICY_DIR"
  "${SUDO[@]}" install -m 0644 "$ORIGINAL_BACKUP" "$POLICY_FILE"
  log "Policy sebelumnya berhasil dipulihkan: $POLICY_FILE"
else
  "${SUDO[@]}" rm -f -- "$POLICY_FILE"
  log "Policy milik project ini berhasil dihapus."
fi

"${SUDO[@]}" rm -f -- "$STATE_MARKER" "$ORIGINAL_EXISTS_MARKER" "$ORIGINAL_BACKUP"
"${SUDO[@]}" rmdir "$STATE_DIR" 2>/dev/null || true
"${SUDO[@]}" rmdir "$POLICY_DIR" 2>/dev/null || true

if pgrep -x brave >/dev/null 2>&1 || pgrep -x brave-browser >/dev/null 2>&1; then
  warn "Brave sedang berjalan. Restart Brave untuk menghapus policy dari sesi browser."
else
  log "Uninstall selesai. Buka Brave dan periksa brave://policy."
fi
