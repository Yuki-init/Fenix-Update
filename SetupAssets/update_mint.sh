set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Detect real user (works whether run as root or with sudo) ──────────────────
if [ -n "${SUDO_USER:-}" ]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$USER"
fi
REAL_HOME="/home/$REAL_USER"

# ── Enable 32-bit architecture (required for Steam) ───────────────────────────
echo "→ Enabling 32-bit architecture..."
sudo dpkg --add-architecture i386

# ── Add external repositories ─────────────────────────────────────────────────
echo "→ Adding external repositories..."

# Visual Studio Code
if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
    echo "  Adding VS Code repository..."
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor \
        | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
fi

# Google Chrome
if [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then
    echo "  Adding Google Chrome repository..."
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
        | gpg --dearmor \
        | sudo tee /usr/share/keyrings/google-chrome.gpg > /dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] \
http://dl.google.com/linux/chrome/deb/ stable main" \
        | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
fi

# ── System update ──────────────────────────────────────────────────────────────
echo "→ Updating system..."
sudo apt update
sudo apt upgrade -y

# ── APT packages ──────────────────────────────────────────────────────────────
APT_PKGS=(
    # Vulkan / 32-bit graphics (Steam, Proton)
    mesa-vulkan-drivers
    mesa-vulkan-drivers:i386

    # Office & productivity
    libreoffice
    tesseract-ocr
    tesseract-ocr-eng

    # Media & downloads
    vlc
    handbrake
    qbittorrent
    krita
    filelight

    # Gaming
    steam
    lutris

    # External repo packages
    code
    google-chrome-stable
)

echo "→ Installing APT packages..."
sudo apt install -y --no-install-recommends "${APT_PKGS[@]}"

# ── Flatpaks ──────────────────────────────────────────────────────────────────
FLATPAKS=(
    # Same as Arch setup
    com.github.tchx84.Flatseal
    it.mijorus.gearlever
    io.github.kolunmi.Bazaar

    # Packages not available in apt
    org.kde.haruna
    com.discordapp.Discord
    net.davidotek.pupgui2          # ProtonUp-Qt
    com.heroicgameslauncher.hgl    # Heroic Games Launcher
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
