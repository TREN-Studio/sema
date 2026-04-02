#!/bin/bash

# ╔══════════════════════════════════════════════════════╗
# ║       .sema Format Installer for macOS               ║
# ║       TREN Studio — trenstudio.com/sema              ║
# ╚══════════════════════════════════════════════════════╝

set -e

INSTALL_DIR="$HOME/.sema-format"
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BOLD}████████████████████████████████████████████████${NC}"
echo -e "${BOLD}█                                              █${NC}"
echo -e "${BOLD}█    .sema Format Installer — macOS           █${NC}"
echo -e "${BOLD}█    The File That Knows Itself               █${NC}"
echo -e "${BOLD}█    TREN Studio · trenstudio.com/sema        █${NC}"
echo -e "${BOLD}█                                              █${NC}"
echo -e "${BOLD}████████████████████████████████████████████████${NC}"
echo ""

# ── CHECK PYTHON ────────────────────────────────────────
echo -e "${CYAN}[1/4] Checking Python...${NC}"
if command -v python3 &>/dev/null; then
    PYTHON=python3
    echo -e "${GREEN}[OK] Python3 found: $(python3 --version)${NC}"
else
    echo -e "${RED}[!] Python3 not found. Install via: brew install python3${NC}"
    exit 1
fi

# ── CREATE INSTALL DIR ──────────────────────────────────
echo ""
echo -e "${CYAN}[2/4] Installing opener...${NC}"
mkdir -p "$INSTALL_DIR"

# Write opener Python script
cat > "$INSTALL_DIR/sema_open.py" << 'PYEOF'
#!/usr/bin/env python3
import sys, os, zipfile, tempfile, webbrowser

def open_sema(filepath):
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return

    tmpdir = tempfile.mkdtemp(prefix="sema_")

    try:
        with zipfile.ZipFile(filepath, 'r') as z:
            names = z.namelist()
            if 'view.html' in names:
                z.extract('view.html', tmpdir)
                html_path = os.path.join(tmpdir, 'view.html')
            else:
                z.extractall(tmpdir)
                html_files = [f for f in os.listdir(tmpdir) if f.endswith('.html')]
                if html_files:
                    html_path = os.path.join(tmpdir, html_files[0])
                else:
                    print("No viewer found in .sema file")
                    return

        webbrowser.open(f'file://{html_path}')
        print(f"Opened: {filepath}")

    except zipfile.BadZipFile:
        print("Error: Not a valid .sema file")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: sema_open.py <file.sema>")
        sys.exit(1)
    open_sema(sys.argv[1])
PYEOF

chmod +x "$INSTALL_DIR/sema_open.py"
echo -e "${GREEN}[OK] Opener installed at $INSTALL_DIR${NC}"

# ── CREATE macOS APP BUNDLE ─────────────────────────────
echo ""
echo -e "${CYAN}[3/4] Creating .app bundle...${NC}"

APP_PATH="$HOME/Applications/SemaViewer.app"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

# Info.plist — registers .sema UTI with macOS
cat > "$APP_PATH/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.trenstudio.sema</string>
    <key>CFBundleName</key>
    <string>Sema Viewer</string>
    <key>CFBundleDisplayName</key>
    <string>.sema Viewer</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>sema_launcher</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSHighResolutionCapable</key>
    <true/>

    <!-- Register .sema as a document type -->
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Semantic File</string>
            <key>CFBundleTypeExtensions</key>
            <array>
                <string>sema</string>
            </array>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
            <key>CFBundleTypeMIMETypes</key>
            <array>
                <string>application/vnd.sema</string>
            </array>
        </dict>
    </dict>

    <!-- Declare UTI -->
    <key>UTExportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>com.trenstudio.sema</string>
            <key>UTTypeDescription</key>
            <string>Semantic File (.sema)</string>
            <key>UTTypeConformsTo</key>
            <array>
                <string>public.zip-archive</string>
            </array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>sema</string>
                </array>
                <key>public.mime-type</key>
                <string>application/vnd.sema</string>
            </dict>
        </dict>
    </array>
</dict>
</plist>
PLIST

# Launcher script
cat > "$APP_PATH/Contents/MacOS/sema_launcher" << LAUNCHER
#!/bin/bash
SEMA_FILE=\$1
if [ -z "\$SEMA_FILE" ]; then
    open -n "$APP_PATH" --args "\$@"
    exit 0
fi
$PYTHON "$INSTALL_DIR/sema_open.py" "\$SEMA_FILE"
LAUNCHER

chmod +x "$APP_PATH/Contents/MacOS/sema_launcher"
echo -e "${GREEN}[OK] App bundle created: $APP_PATH${NC}"

# ── REGISTER WITH LAUNCH SERVICES ──────────────────────
echo ""
echo -e "${CYAN}[4/4] Registering with macOS Launch Services...${NC}"

/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$APP_PATH" 2>/dev/null || true

# Add to PATH
SHELL_RC="$HOME/.zshrc"
if [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if ! grep -q "sema-format" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# .sema Format CLI" >> "$SHELL_RC"
    echo "alias sema='$INSTALL_DIR/sema_open.py'" >> "$SHELL_RC"
fi

echo -e "${GREEN}[OK] Registered with Launch Services${NC}"

# ── DONE ────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}████████████████████████████████████████████████${NC}"
echo -e "${BOLD}${GREEN}█                                              █${NC}"
echo -e "${BOLD}${GREEN}█   [SUCCESS] .sema installed on macOS!       █${NC}"
echo -e "${BOLD}${GREEN}█                                              █${NC}"
echo -e "${BOLD}${GREEN}█   Double-click any .sema file to open it.   █${NC}"
echo -e "${BOLD}${GREEN}█   Or use: python3 ~/.sema-format/sema_open  █${NC}"
echo -e "${BOLD}${GREEN}█                                              █${NC}"
echo -e "${BOLD}${GREEN}█   trenstudio.com/sema                       █${NC}"
echo -e "${BOLD}${GREEN}█                                              █${NC}"
echo -e "${BOLD}${GREEN}████████████████████████████████████████████████${NC}"
echo ""
echo -e "  Restart Terminal to use: ${CYAN}sema yourfile.sema${NC}"
echo ""
