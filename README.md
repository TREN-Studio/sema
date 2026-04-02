# .sema Format — Installation Guide
## TREN Studio · trenstudio.com/sema

---

## What is .sema?

A new open file format where every file carries its own intelligence.
No API. No internet. No external application. Just open it.

---

## Install on Your System

### 🪟 Windows

**Option A — Full Installer (Recommended):**
1. Run `install_sema_windows.bat` as Administrator
2. Done. Double-click any `.sema` file to open it.

**Option B — Registry only (if Python already installed):**
1. Run `install_sema_windows.bat` first (installs the opener)
2. Double-click `register_sema.reg` to register the extension
3. Confirm the UAC prompt

---

### 🍎 macOS

```bash
chmod +x install_sema_macos.sh
./install_sema_macos.sh
```

Then double-click any `.sema` file, or use:
```bash
sema yourfile.sema
```

---

### 🐧 Linux (Ubuntu / Debian / Fedora)

```bash
chmod +x install_sema_linux.sh
./install_sema_linux.sh
```

Then double-click any `.sema` file in your file manager, or:
```bash
sema yourfile.sema
```

---

## How It Works (Zero API)

When you open a `.sema` file:

1. The opener extracts `view.html` from the archive
2. Opens it in your default browser
3. The file renders itself — no internet needed
4. Ask it questions → answers come from `brain.json` baked inside

```
yourfile.sema (ZIP archive)
├── sema.json       ← identity manifest
├── brain.json      ← semantic intelligence (pre-baked)
├── view.html       ← self-rendering interface
└── content/        ← original file preserved
```

---

## Build .sema Files

```bash
python sema_builder.py yourfile.pdf --author "Your Name" --org "Your Org"
```

Supports: PDF, DOCX, TXT, MD, JPG, PNG, XLSX, CSV

---

## Uninstall

**Windows:**
```
reg delete "HKEY_CLASSES_ROOT\.sema" /f
reg delete "HKEY_CLASSES_ROOT\SemaFormat.File" /f
rmdir /s "%LOCALAPPDATA%\SemaFormat"
```

**macOS / Linux:**
```bash
rm -rf ~/.sema-format
rm ~/.local/share/applications/sema-viewer.desktop
```

---

## The Format Philosophy

> "The file must carry its own soul. It must know what it is,
> what it means, and how to present itself — to anyone,
> anywhere, a thousand years from now."

---

**MIT License · Open Standard · Free Forever**
Built in Morocco 🇲🇦 by TREN Studio
https://trenstudio.com/sema
