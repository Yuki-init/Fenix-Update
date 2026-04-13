#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Detect OS ─────────────────────────────────────────────────────────────────
if [ ! -f /etc/os-release ]; then
    echo "ERROR: Cannot detect OS — /etc/os-release not found." >&2
    exit 1
fi

. /etc/os-release

echo "→ Detected OS: ${PRETTY_NAME:-$ID}"

case "${ID:-}" in
    arch)
        TARGET="$SCRIPT_DIR/SetupAssets/update_arch.sh"
        ;;
    linuxmint)
        TARGET="$SCRIPT_DIR/SetupAssets/update_mint.sh"
        ;;
    *)
        # Fall back to ID_LIKE for derivatives (e.g. Manjaro reports ID_LIKE=arch)
        case "${ID_LIKE:-}" in
            *arch*)
                echo "  (Arch-based distro — using Arch script)"
                TARGET="$SCRIPT_DIR/SetupAssets/update_arch.sh"
                ;;
            *debian*|*ubuntu*)
                echo "  (Debian/Ubuntu-based distro — using Mint script)"
                TARGET="$SCRIPT_DIR/SetupAssets/update_mint.sh"
                ;;
            *)
                echo "ERROR: Unsupported OS '$ID'. Supported: arch, linuxmint (and derivatives)." >&2
                exit 1
                ;;
        esac
        ;;
esac

if [ ! -f "$TARGET" ]; then
    echo "ERROR: Script not found: $TARGET" >&2
    exit 1
fi

echo "→ Running: $TARGET"
bash "$TARGET"
