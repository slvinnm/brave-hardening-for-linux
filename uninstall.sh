#!/usr/bin/env bash
set -Eeuo pipefail

POLICY_DIR="/etc/brave/policies/managed"
POLICY_FILE="$POLICY_DIR/brave-hardening-policy.json"
STATE_DIR="/var/lib/brave-hardening"
STATE_MARKER="$STATE_DIR/installed"
ORIGINAL_EXISTS_MARKER="$STATE_DIR/original-policy-existed"
ORIGINAL_BACKUP="$STATE_DIR/original-policy.json"

# Previous locations are retained here only for safe cleanup of older installs.
LEGACY_POLICY_FILE="$POLICY_DIR/omarchy-brave-policy.json"
LEGACY_STATE_DIR="/var/lib/omarchy-brave-policy"
LEGACY_STATE_MARKER="$LEGACY_STATE_DIR/installed"
LEGACY_ORIGINAL_EXISTS_MARKER="$LEGACY_STATE_DIR/original-policy-existed"
LEGACY_ORIGINAL_BACKUP="$LEGACY_STATE_DIR/original-policy.json"

log()  { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die()  { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

SUDO=()
if (( EUID != 0 )); then
  command -v sudo >/dev/null 2>&1 || die "sudo was not found."
  sudo -v || die "Failed to obtain sudo privileges."
  SUDO=(sudo)
fi

# Prefer the current state, but recognize an installation made by the
# previous project version if the user runs this uninstaller before upgrading.
if "${SUDO[@]}" test -f "$STATE_MARKER"; then
  if "${SUDO[@]}" test -f "$ORIGINAL_EXISTS_MARKER"; then
    "${SUDO[@]}" test -f "$ORIGINAL_BACKUP" || die "The original policy backup was not found at $ORIGINAL_BACKUP. The target file was left untouched."
    "${SUDO[@]}" install -d -m 0755 "$POLICY_DIR"
    "${SUDO[@]}" install -m 0644 "$ORIGINAL_BACKUP" "$POLICY_FILE"
    log "The previous policy file was restored: $POLICY_FILE"
  else
    "${SUDO[@]}" rm -f -- "$POLICY_FILE"
    log "The policy file installed by this project was removed."
  fi
  "${SUDO[@]}" rm -f -- "$STATE_MARKER" "$ORIGINAL_EXISTS_MARKER" "$ORIGINAL_BACKUP"
  "${SUDO[@]}" rmdir "$STATE_DIR" 2>/dev/null || true
elif "${SUDO[@]}" test -f "$LEGACY_STATE_MARKER"; then
  if "${SUDO[@]}" test -f "$LEGACY_ORIGINAL_EXISTS_MARKER"; then
    "${SUDO[@]}" test -f "$LEGACY_ORIGINAL_BACKUP" || die "The original policy backup was not found at $LEGACY_ORIGINAL_BACKUP. The target file was left untouched."
    "${SUDO[@]}" install -d -m 0755 "$POLICY_DIR"
    "${SUDO[@]}" install -m 0644 "$LEGACY_ORIGINAL_BACKUP" "$LEGACY_POLICY_FILE"
    log "The previous policy file was restored."
  else
    "${SUDO[@]}" rm -f -- "$LEGACY_POLICY_FILE"
    log "The policy file installed by the previous version was removed."
  fi
  "${SUDO[@]}" rm -f -- "$LEGACY_STATE_MARKER" "$LEGACY_ORIGINAL_EXISTS_MARKER" "$LEGACY_ORIGINAL_BACKUP"
  "${SUDO[@]}" rmdir "$LEGACY_STATE_DIR" 2>/dev/null || true
else
  warn "No installation state for this project was found. No changes were made."
  exit 0
fi

"${SUDO[@]}" rmdir "$POLICY_DIR" 2>/dev/null || true

if pgrep -x brave >/dev/null 2>&1 || pgrep -x brave-browser >/dev/null 2>&1; then
  warn "Brave is running. Restart Brave to remove the policies from the browser session."
else
  log "Uninstallation complete. Open Brave and check brave://policy."
fi
