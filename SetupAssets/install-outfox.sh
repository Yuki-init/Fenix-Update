#!/bin/bash
################################################################################
##                                                                            ##
##   OUTFOX INSTALLER                                                         ##
##   Installs OutFox to ~/Applications + creates a desktop entry              ##
##                                                                            ##
################################################################################
##  Author  :  Yuki-init               ##  Tested on : Fedora 43, Arch Linux  ##
##  Version :  V0.2                    ##  Arch      : x86_64                 ##
##  License :  MIT                     ##                                     ##
################################################################################

set -e

# --- Cheeky message if anyone uses --help
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo ""
    echo "  OutFox Installer -- Help"
    echo ""
    echo "  Usage: bash install-outfox.sh"
    echo ""
    echo "  Options:"
    echo "    --help    You're looking at it. Congratulations, you found the one"
    echo "              option this script has. It doesn't even do anything useful."
    echo ""
    echo "  This script installs OutFox to ~/Applications and creates a desktop"
    echo "  entry. Just run it. There's nothing to configure."
    echo ""
    exit 0
fi


# --- Setup Variable Bullshit
DOWNLOAD_URL="https://github.com/TeamRizu/OutFox/releases/download/OF5.0.0-043/OutFox-alpha-0.5.0-pre-043-Final-24.04-amd64-current-date-20250907.tar.gz"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARCHIVE="$SCRIPT_DIR/outfox.tar.gz"
EXTRACT_DIR="/tmp/outfox-extract"
INSTALL_DIR="$HOME/Applications/OutFox"
DESKTOP_FILE="$HOME/.local/share/applications/outfox.desktop"
SONGS_URL="https://github.com/TeamRizu/OutFox-Serenity/releases/download/v2.5/OutFox.Serenity.All.In.One.v2.5.zip"
SONGS_ARCHIVE="$SCRIPT_DIR/OutFox.Serenity.All.In.One.v2.5.zip"
SONGS_EXTRACT_DIR="/tmp/outfox-serenity-extract"
SONGS_DIR="$INSTALL_DIR/Songs"

# --- Cleanup Trap - Cleans up even if it fails ---
trap 'rm -rf "$EXTRACT_DIR" "$SONGS_EXTRACT_DIR"' EXIT

echo ""
echo "================================================"
echo "  OutFox Installer"
echo "  Includes: Serenity Song Pack v2.5"
echo "================================================"
echo ""

# --- Step 1: Download / Use existing archive---
echo "[1/7] Checking for OutFox archive..."
if [ -f "$ARCHIVE" ]; then
    echo "      Found existing archive at $ARCHIVE — skipping download."
else
    echo "      Downloading OutFox..."
    curl -L --progress-bar -o "$ARCHIVE" "$DOWNLOAD_URL"
    echo "      Done."
fi

# --- Step 2: Prepare install directory ---
echo "[2/7] Preparing ~/Applications/OutFox..."
mkdir -p "$INSTALL_DIR"

# --- Step 3: Extract ---
echo "[3/7] Extracting archive..."
mkdir -p "$EXTRACT_DIR"
tar -xzf "$ARCHIVE" -C "$EXTRACT_DIR"

# Move contents into install dir — handles whether the tar has a top-level folder or not
EXTRACTED_CONTENTS=$(ls "$EXTRACT_DIR")
ENTRY_COUNT=$(ls "$EXTRACT_DIR" | wc -l)

if [ "$ENTRY_COUNT" -eq 1 ] && [ -d "$EXTRACT_DIR/$EXTRACTED_CONTENTS" ]; then
    # Archive had a single top-level folder — move its contents
    cp -r "$EXTRACT_DIR/$EXTRACTED_CONTENTS"/. "$INSTALL_DIR/"
else
    # Archive extracted flat — move everything directly
    cp -r "$EXTRACT_DIR"/. "$INSTALL_DIR/"
fi

echo "      Installed to: $INSTALL_DIR"

# --- Step 4: Make binary executable ---
echo "[4/7] Setting permissions..."

BINARY="$INSTALL_DIR/OutFox"

if [ ! -f "$BINARY" ]; then
    echo "Error: could not find OutFox binary at $BINARY"
    exit 1
fi

chmod +x "$BINARY"
echo "      Executable: $BINARY"
touch $INSTALL_DIR/portable.ini

# --- Step 5: Desktop entry ---
echo "[5/7] Creating desktop entry..."

# Use a png from the game's theme directory
ICON_PATH="$INSTALL_DIR/Appearance/Themes/default/Graphics/Common fallback jacket.png"

if [ ! -f "$ICON_PATH" ]; then
    echo "      Warning: Bundled icon not found at expected path — using system fallback."
    ICON_PATH="applications-games"
else
    echo "      Icon found: $ICON_PATH"
fi

mkdir -p "$(dirname "$DESKTOP_FILE")"

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=OutFox
Comment=OutFox — Open source rhythm game engine
Exec=$BINARY
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Game;
StartupNotify=true
EOF

echo "      Desktop entry: $DESKTOP_FILE"

# Update desktop database so it appears in the menu immediately
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

# --- Step 6: Download Serenity Song Pack ---
echo "[6/7] Checking for Serenity Song Pack archive..."
if [ -f "$SONGS_ARCHIVE" ]; then
    echo "      Found existing archive at $SONGS_ARCHIVE — skipping download."
else
    echo "      Downloading Serenity Song Pack v2.5..."
    curl -L --progress-bar -o "$SONGS_ARCHIVE" "$SONGS_URL"
    echo "      Done."
fi

# --- Step 7: Extract song pack into Songs folder ---
echo "[7/7] Installing songs to $SONGS_DIR..."
mkdir -p "$SONGS_DIR"
mkdir -p "$SONGS_EXTRACT_DIR"
unzip -q "$SONGS_ARCHIVE" -d "$SONGS_EXTRACT_DIR"

# Handle single top-level folder or flat extract
SONGS_CONTENTS=$(ls "$SONGS_EXTRACT_DIR")
SONGS_COUNT=$(ls "$SONGS_EXTRACT_DIR" | wc -l)

if [ "$SONGS_COUNT" -eq 1 ] && [ -d "$SONGS_EXTRACT_DIR/$SONGS_CONTENTS" ]; then
    cp -r "$SONGS_EXTRACT_DIR/$SONGS_CONTENTS"/. "$SONGS_DIR/"
else
    cp -r "$SONGS_EXTRACT_DIR"/. "$SONGS_DIR/"
fi

echo "      Songs installed to: $SONGS_DIR"



echo ""
echo "================================================"
echo "  OutFox installed successfully!"
echo "  Location : $INSTALL_DIR"
echo "  Songs    : $SONGS_DIR"
echo "  To launch : $BINARY"
echo "  It should now appear in your start menu."
echo ""
echo "  Get more songs & packs:"
echo "    https://stepmaniaonline.net/"
echo "    https://zenius-i-vanisher.com/v5.2/simfiles.php?category=simfiles"
echo "================================================"
echo ""
