#!/bin/bash

# ╔══════════════════════════════════════════════════════╗
# ║       .sema Format Installer for Linux               ║
# ║       TREN Studio — trenstudio.com/sema              ║
# ╚══════════════════════════════════════════════════════╝

BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

INSTALL_DIR="$HOME/.local/share/sema-format"
MIME_DIR="$HOME/.local/share/mime"
APP_DIR="$HOME/.local/share/applications"

echo ""
echo -e "${BOLD}████████████████████████████████████████████████${NC}"
echo -e "${BOLD}█    .sema Format Installer — Linux            █${NC}"
echo -e "${BOLD}█    TREN Studio · trenstudio.com/sema         █${NC}"
echo -e "${BOLD}████████████████████████████████████████████████${NC}"
echo ""

# ── CHECK DEPS ──────────────────────────────────────────
echo -e "${CYAN}[1/5] Checking dependencies...${NC}"

PYTHON=""
for cmd in python3 python; do
    if command -v $cmd &>/dev/null; then
        PYTHON=$cmd
        break
    fi
done

if [ -z "$PYTHON" ]; then
    echo -e "${RED}[!] Python not found. Install: sudo apt install python3${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] Python: $($PYTHON --version)${NC}"

# ── INSTALL OPENER ──────────────────────────────────────
echo ""
echo -e "${CYAN}[2/5] Installing opener...${NC}"
mkdir -p "$INSTALL_DIR"

cat > "$INSTALL_DIR/sema_open.py" << 'PYEOF'
#!/usr/bin/env python3
import sys, os, zipfile, tempfile, webbrowser, subprocess

def get_browser():
    for cmd in ['xdg-open', 'firefox', 'chromium-browser', 'google-chrome']:
        if subprocess.run(['which', cmd], capture_output=True).returncode == 0:
            return cmd
    return None

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

        url = f'file://{html_path}'
        browser = get_browser()
        if browser:
            subprocess.Popen([browser, url])
        else:
            webbrowser.open(url)
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
echo -e "${GREEN}[OK] Opener installed${NC}"

# ── REGISTER MIME TYPE ──────────────────────────────────
echo ""
echo -e "${CYAN}[3/5] Registering MIME type...${NC}"
mkdir -p "$MIME_DIR/packages"

cat > "$MIME_DIR/packages/sema.xml" << 'MIMEEOF'
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/vnd.sema">
    <comment>Semantic File</comment>
    <comment xml:lang="ar">ملف سيمانتيك</comment>
    <comment xml:lang="fr">Fichier Sémantique</comment>
    <glob pattern="*.sema"/>
    <magic priority="50">
      <match type="string" value="PK" offset="0"/>
    </magic>
    <sub-class-of type="application/zip"/>
  </mime-type>
</mime-info>
MIMEEOF

update-mime-database "$MIME_DIR" 2>/dev/null || true
echo -e "${GREEN}[OK] MIME type registered: application/vnd.sema${NC}"

# ── CREATE DESKTOP ENTRY ────────────────────────────────
echo ""
echo -e "${CYAN}[4/5] Creating desktop entry...${NC}"
mkdir -p "$APP_DIR"

cat > "$APP_DIR/sema-viewer.desktop" << DESKEOF
[Desktop Entry]
Name=Sema Viewer
GenericName=Semantic File Viewer
Comment=Open and interact with .sema semantic files
Exec=$PYTHON $INSTALL_DIR/sema_open.py %f
Terminal=false
Type=Application
MimeType=application/vnd.sema;
Categories=Viewer;Office;
Keywords=sema;semantic;file;viewer;
StartupNotify=true
DESKEOF

update-desktop-database "$APP_DIR" 2>/dev/null || true
xdg-mime default sema-viewer.desktop application/vnd.sema 2>/dev/null || true
echo -e "${GREEN}[OK] Desktop entry created${NC}"

# ── ADD CLI ALIAS ───────────────────────────────────────
echo ""
echo -e "${CYAN}[5/5] Adding CLI alias...${NC}"

for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$RC" ]; then
        if ! grep -q "sema-format" "$RC"; then
            echo "" >> "$RC"
            echo "# .sema Format CLI (TREN Studio)" >> "$RC"
            echo "alias sema='$PYTHON $INSTALL_DIR/sema_open.py'" >> "$RC"
            echo -e "${GREEN}[OK] Added alias to $RC${NC}"
        fi
    fi
done

# ── DONE ────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}████████████████████████████████████████████████${NC}"
echo -e "${BOLD}${GREEN}█                                              █${NC}"
echo -e "${BOLD}${GREEN}█   [SUCCESS] .sema installed on Linux!       █${NC}"
echo -e "${BOLD}${GREEN}█                                              █${NC}"
echo -e "${BOLD}${GREEN}█   Double-click any .sema file in Files      █${NC}"
echo -e "${BOLD}${GREEN}█   Or in terminal: sema yourfile.sema        █${NC}"
echo -e "${BOLD}${GREEN}█                                              █${NC}"
echo -e "${BOLD}${GREEN}█   trenstudio.com/sema                       █${NC}"
echo -e "${BOLD}${GREEN}█                                              █${NC}"
echo -e "${BOLD}${GREEN}████████████████████████████████████████████████${NC}"
echo ""
echo "  Restart terminal to use: sema yourfile.sema"
echo ""
