#!/usr/bin/env bash
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
# Replace with your raw GitHub base URL once the repo is uploaded:
# https://raw.githubusercontent.com/USERNAME/REPO/BRANCH
BASE_URL="https://raw.githubusercontent.com/Yuki-init/Fenix-Update/main"

# ── Detect OS ─────────────────────────────────────────────────────────────────
if [ ! -f /etc/os-release ]; then
    echo "ERROR: Cannot detect OS — /etc/os-release not found." >&2
    exit 1
fi

. /etc/os-release

echo "→ Detected OS: ${PRETTY_NAME:-$ID}"

case "${ID:-}" in
    arch)
        OS_SCRIPT="SetupAssets/update_arch.sh"
        ;;
    linuxmint)
        OS_SCRIPT="SetupAssets/update_mint.sh"
        ;;
    *)
        case "${ID_LIKE:-}" in
            *arch*)
                echo "  (Arch-based distro — using Arch script)"
                OS_SCRIPT="SetupAssets/update_arch.sh"
                ;;
            *debian*|*ubuntu*)
                echo "  (Debian/Ubuntu-based distro — using Mint script)"
                OS_SCRIPT="SetupAssets/update_mint.sh"
                ;;
            *)
                echo "ERROR: Unsupported OS '$ID'. Supported: arch, linuxmint (and derivatives)." >&2
                exit 1
                ;;
        esac
        ;;
esac

# ── Download scripts to a temp directory ──────────────────────────────────────
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "→ Fetching scripts..."
curl -fsSL "$BASE_URL/$OS_SCRIPT"                       -o "$TMP_DIR/os_update.sh"
curl -fsSL "$BASE_URL/SetupAssets/install-outfox.sh"    -o "$TMP_DIR/install-outfox.sh"

chmod +x "$TMP_DIR/os_update.sh" "$TMP_DIR/install-outfox.sh"

# ── Run ───────────────────────────────────────────────────────────────────────
echo "→ Running update..."
bash "$TMP_DIR/os_update.sh"
