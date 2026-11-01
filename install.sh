#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_PATH="${0:-}"
SCRIPT_DIR=""
POLICY_SOURCE=""

# When run through stdin (curl | bash), $0 is normally "bash", not a script path.
# Use a local policy file only when this script is executed from a local checkout.
if [[ -f "$SCRIPT_PATH" ]]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd)"
  POLICY_SOURCE="$SCRIPT_DIR/brave-policy.json"
fi
POLICY_REF="${BRAVE_POLICY_REF:-main}"
POLICY_URL="https://raw.githubusercontent.com/slvinnm/brave-hardening-for-linux/${POLICY_REF}/brave-policy.json"
TEMP_POLICY=""
POLICY_DIR="/etc/brave/policies/managed"
POLICY_FILE="$POLICY_DIR/brave-hardening-policy.json"
STATE_DIR="/var/lib/brave-hardening"
STATE_MARKER="$STATE_DIR/installed"
ORIGINAL_EXISTS_MARKER="$STATE_DIR/original-policy-existed"
ORIGINAL_BACKUP="$STATE_DIR/original-policy.json"

# Previous locations are checked during upgrade to avoid leaving an old
# managed policy active or losing a pre-existing policy during rollback.
LEGACY_POLICY_FILE="$POLICY_DIR/omarchy-brave-policy.json"
LEGACY_STATE_DIR="/var/lib/omarchy-brave-policy"
LEGACY_STATE_MARKER="$LEGACY_STATE_DIR/installed"
LEGACY_ORIGINAL_EXISTS_MARKER="$LEGACY_STATE_DIR/original-policy-existed"
LEGACY_ORIGINAL_BACKUP="$LEGACY_STATE_DIR/original-policy.json"

log()  { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die()  { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || die "python3 is required to validate the policy JSON."

# Use the adjacent policy file for a local checkout. When this script is
# piped from curl, download the policy from the selected repository ref.
if [[ ! -f "$POLICY_SOURCE" ]]; then
  command -v curl >/dev/null 2>&1 || die "curl is required when install.sh is run without a local policy file."
  TEMP_POLICY="$(mktemp)"
  trap '[[ -z "$TEMP_POLICY" ]] || rm -f -- "$TEMP_POLICY"' EXIT
  curl -fsSL "$POLICY_URL" -o "$TEMP_POLICY" || die "Failed to download policy from $POLICY_URL"
  POLICY_SOURCE="$TEMP_POLICY"
fi

python3 -m json.tool "$POLICY_SOURCE" >/dev/null || die "The policy JSON is invalid."

# Detect native Brave packages on Arch-based systems and common executable
# names on other distributions. Flatpak-only installations are unsupported.
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
    die "Only Brave Flatpak was detected. Policies under /etc/brave/policies/managed are not guaranteed to apply to Flatpak. Install native Brave or manage Flatpak policies separately."
  fi
  die "A native Brave installation was not detected. Make sure Brave is installed and its executable is available in PATH."
fi

SUDO=()
if (( EUID != 0 )); then
  command -v sudo >/dev/null 2>&1 || die "sudo was not found."
  sudo -v || die "Failed to obtain sudo privileges."
  SUDO=(sudo)
fi

if pgrep -x brave >/dev/null 2>&1 || pgrep -x brave-browser >/dev/null 2>&1; then
  warn "Brave is running. Close and reopen Brave after installation to apply the policies."
fi

"${SUDO[@]}" install -d -m 0755 "$STATE_DIR"

# Migrate the previous installation's rollback state, if present.
if ! "${SUDO[@]}" test -f "$STATE_MARKER" && "${SUDO[@]}" test -f "$LEGACY_STATE_MARKER"; then
  if "${SUDO[@]}" test -f "$LEGACY_ORIGINAL_EXISTS_MARKER"; then
    "${SUDO[@]}" test -f "$LEGACY_ORIGINAL_BACKUP" || die "The previous installation's backup is missing. Cannot safely migrate its rollback state."
    "${SUDO[@]}" install -m 0644 "$LEGACY_ORIGINAL_BACKUP" "$ORIGINAL_BACKUP"
    "${SUDO[@]}" touch "$ORIGINAL_EXISTS_MARKER"
  fi
  log "Previous installation state detected and migrated."
fi

# If no prior state exists, preserve any policy already at the new target.
if ! "${SUDO[@]}" test -f "$STATE_MARKER"; then
  if "${SUDO[@]}" test -e "$POLICY_FILE"; then
    if ! "${SUDO[@]}" test -e "$ORIGINAL_BACKUP"; then
      "${SUDO[@]}" install -m 0644 "$POLICY_FILE" "$ORIGINAL_BACKUP"
    fi
    "${SUDO[@]}" touch "$ORIGINAL_EXISTS_MARKER"
    log "An existing policy file was found. Its original copy was saved to $ORIGINAL_BACKUP"
  fi
  "${SUDO[@]}" touch "$STATE_MARKER"
fi

"${SUDO[@]}" install -d -m 0755 "$POLICY_DIR"
"${SUDO[@]}" install -m 0644 "$POLICY_SOURCE" "$POLICY_FILE"

# Remove the old project policy after the new policy is safely installed.
if "${SUDO[@]}" test -e "$LEGACY_POLICY_FILE"; then
  "${SUDO[@]}" rm -f -- "$LEGACY_POLICY_FILE"
  log "Removed the previous policy file."
fi

# The migrated state now lives in the new state directory.
"${SUDO[@]}" rm -f -- "$LEGACY_STATE_MARKER" "$LEGACY_ORIGINAL_EXISTS_MARKER" "$LEGACY_ORIGINAL_BACKUP"
"${SUDO[@]}" rmdir "$LEGACY_STATE_DIR" 2>/dev/null || true

log "Policies installed successfully: $POLICY_FILE"
log "Open brave://policy and click Reload policies to verify them."
log "Restart Brave to ensure all changes take effect."
