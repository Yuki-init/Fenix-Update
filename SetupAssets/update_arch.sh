set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Detect real user (works whether run as root or with sudo) ──────────────────
if [ -n "${SUDO_USER:-}" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$USER"
fi
REAL_HOME="/home/$REAL_USER"

# ── Enable multilib (required for Steam and 32-bit libs) ──────────────────────
echo "→ Enabling multilib repository..."
sudo sed -i '/^#\[multilib\]/{N; s/^#\[multilib\]\n#Include/[multilib]\nInclude/}' /etc/pacman.conf

# ── System update ──────────────────────────────────────────────────────────────
echo "→ Updating system..."
sudo pacman -Sy --noconfirm archlinux-keyring
sudo pacman -Syu --noconfirm

# ── AUR helper (yay) ──────────────────────────────────────────────────────────
AUR_HELPER=""
command -v yay  &>/dev/null && AUR_HELPER="yay"
command -v paru &>/dev/null && AUR_HELPER="${AUR_HELPER:-paru}"

if [ -z "$AUR_HELPER" ]; then
    echo "→ Installing yay (AUR helper)..."
    sudo pacman -S --noconfirm --needed git base-devel
    YAYSRC="$(sudo -u "$REAL_USER" mktemp -d)"
    sudo -u "$REAL_USER" git clone https://aur.archlinux.org/yay.git "$YAYSRC"
    (cd "$YAYSRC" && sudo -u "$REAL_USER" makepkg -si --noconfirm)
    rm -rf "$YAYSRC"
    AUR_HELPER="yay"
fi

echo "  Using AUR helper: $AUR_HELPER"

# ── Pacman packages ────────────────────────────────────────────────────────────
PACMAN_PKGS=(
    lib32-vulkan-intel
    plasma-meta
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
    tesseract-data-eng
    kde-graphics-meta
    kde-multimedia-meta
    kde-network-meta
    dolphin-plugins
    kde-utilities-meta
    libreoffice-fresh
    qbittorrent
    krita
    vlc
    filelight
    haruna
    discord
    steam
    lutris
    handbrake
)

echo "→ Installing pacman packages..."
sudo pacman -S --noconfirm --needed "${PACMAN_PKGS[@]}"

# ── AUR packages ──────────────────────────────────────────────────────────────
AUR_PKGS=(
    visual-studio-code-bin
    google-chrome
    ares
    protonup-qt
    heroic-games-launcher-bin
)

echo "→ Installing AUR packages..."
sudo -u "$REAL_USER" "$AUR_HELPER" -S --noconfirm --needed "${AUR_PKGS[@]}"

# ── Flatpaks (apps best kept as Flatpak) ──────────────────────────────────────
# Flatseal and GearLever only make sense as Flatpaks; Bazaar has no AUR package.
FLATPAKS=(
    com.github.tchx84.Flatseal
    it.mijorus.gearlever
    io.github.kolunmi.Bazaar
)

echo "→ Installing flatpaks..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

for app in "${FLATPAKS[@]}"; do
    echo "  Installing $app..."
    flatpak install --noninteractive flathub "$app" &>/dev/null || echo "  WARNING: failed to install $app"
done

echo "→ Copying Misc Files..."
bash "$SCRIPT_DIR/install-outfox.sh"

echo "→ Setup complete!"
