@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul 2>&1

:: ╔══════════════════════════════════════════════════════╗
:: ║         .sema Format Installer for Windows           ║
:: ║         TREN Studio — trenstudio.com/sema            ║
:: ╚══════════════════════════════════════════════════════╝

title .sema Format Installer v1.0

echo.
echo  ██████████████████████████████████████████████████
echo  █                                                █
echo  █        .sema Format Installer v1.0             █
echo  █        The File That Knows Itself              █
echo  █        TREN Studio - trenstudio.com/sema       █
echo  █                                                █
echo  ██████████████████████████████████████████████████
echo.
echo  This installer will:
echo  [1] Register .sema file extension on Windows
echo  [2] Install the .sema opener (Python-based)
echo  [3] Add right-click context menu
echo  [4] Set file icon
echo.
echo  Press any key to begin installation...
pause >nul

:: ── CHECK ADMIN RIGHTS ──────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  [!] Administrator rights required.
    echo  [!] Right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

:: ── CHECK PYTHON ────────────────────────────────────────
echo.
echo  [1/5] Checking Python installation...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!] Python not found. Checking Python3...
    python3 --version >nul 2>&1
    if !errorlevel! neq 0 (
        echo  [!] Python is not installed.
        echo  [!] Please install Python from https://python.org
        echo  [!] Then run this installer again.
        echo.
        set /p OPENWEB="  Open python.org now? (Y/N): "
        if /i "!OPENWEB!"=="Y" start https://python.org/downloads
        pause
        exit /b 1
    )
    set PYTHON_CMD=python3
) else (
    set PYTHON_CMD=python
)
echo  [OK] Python found.

:: ── CREATE INSTALL DIRECTORY ────────────────────────────
echo.
echo  [2/5] Creating installation directory...
set INSTALL_DIR=%LOCALAPPDATA%\SemaFormat
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
echo  [OK] Directory: %INSTALL_DIR%

:: ── WRITE THE OPENER SCRIPT ─────────────────────────────
echo.
echo  [3/5] Installing .sema opener...

(
echo import sys, os, zipfile, tempfile, webbrowser, shutil
echo.
echo def open_sema^(filepath^):
echo     if not os.path.exists^(filepath^):
echo         print^(f"File not found: {filepath}"^)
echo         return
echo.
echo     # Create temp dir
echo     tmpdir = tempfile.mkdtemp^(prefix="sema_"^)
echo.
echo     try:
echo         with zipfile.ZipFile^(filepath, 'r'^) as z:
echo             names = z.namelist^(^)
echo             # Extract view.html
echo             if 'view.html' in names:
echo                 z.extract^('view.html', tmpdir^)
echo                 html_path = os.path.join^(tmpdir, 'view.html'^)
echo             else:
echo                 # No viewer - extract all and open first html
echo                 z.extractall^(tmpdir^)
echo                 html_files = [f for f in os.listdir^(tmpdir^) if f.endswith^('.html'^)]
echo                 if html_files:
echo                     html_path = os.path.join^(tmpdir, html_files[0]^)
echo                 else:
echo                     print^("No viewer found in .sema file"^)
echo                     return
echo.
echo         # Open in default browser
echo         file_url = 'file:///' + html_path.replace^('\\', '/'^)
echo         webbrowser.open^(file_url^)
echo         print^(f"Opened: {filepath}"^)
echo.
echo     except zipfile.BadZipFile:
echo         print^("Error: Not a valid .sema file"^)
echo     except Exception as e:
echo         print^(f"Error: {e}"^)
echo.
echo if __name__ == '__main__':
echo     if len^(sys.argv^) ^< 2:
echo         print^("Usage: sema_open.py ^<file.sema^>"^)
echo         sys.exit^(1^)
echo     open_sema^(sys.argv[1]^)
) > "%INSTALL_DIR%\sema_open.py"

:: Write launcher batch
(
echo @echo off
echo %PYTHON_CMD% "%INSTALL_DIR%\sema_open.py" %%1
) > "%INSTALL_DIR%\sema_launch.bat"

echo  [OK] Opener installed.

:: ── WRITE ICON SVG → ICO (via Python) ───────────────────
echo.
echo  [4/5] Installing file icon...

%PYTHON_CMD% -c "
import os, struct, zlib

# Create a simple 32x32 .ico programmatically
# This is a minimal ICO with a dark background and .sema text representation
install_dir = os.environ.get('INSTALL_DIR', os.path.expandvars('%%LOCALAPPDATA%%\\SemaFormat'))

# Create a 16x16 and 32x32 BMP for the ICO
def make_bmp_rgba(size):
    w = h = size
    # BITMAPINFOHEADER
    bi_size = 40
    bi_width = w
    bi_height = h * 2  # XOR + AND mask
    bi_planes = 1
    bi_bit_count = 32
    bi_compression = 0
    bi_size_image = w * h * 4
    bi_x_pels = 0
    bi_y_pels = 0
    bi_clr_used = 0
    bi_clr_important = 0

    header = struct.pack('<IiiHHIIiiII',
        bi_size, bi_width, bi_height, bi_planes, bi_bit_count,
        bi_compression, bi_size_image, bi_x_pels, bi_y_pels,
        bi_clr_used, bi_clr_important)

    pixels = []
    for y in range(h-1, -1, -1):
        for x in range(w):
            # Dark background with accent dot
            cx, cy = w//2, h//2
            dist = ((x-cx)**2 + (y-cy)**2) ** 0.5
            if dist < w*0.35:
                # Inner circle - accent yellow-green
                r, g, b, a = 232, 255, 0, 255
            else:
                # Outer - dark
                r, g, b, a = 15, 14, 12, 255
            pixels.append(struct.pack('<BBBB', b, g, r, a))

    # AND mask (all zeros = fully opaque)
    and_mask = b'\\x00' * (((w + 31) // 32) * 4 * h)

    return header + b''.join(pixels) + and_mask

img32 = make_bmp_rgba(32)
img16 = make_bmp_rgba(16)

# ICO header
num_images = 2
ico_header = struct.pack('<HHH', 0, 1, num_images)

# Directory entries
offset = 6 + num_images * 16
entry32 = struct.pack('<BBBBHHII', 32, 32, 0, 0, 1, 32, len(img32), offset)
offset += len(img32)
entry16 = struct.pack('<BBBBHHII', 16, 16, 0, 0, 1, 32, len(img16), offset)

ico_data = ico_header + entry32 + entry16 + img32 + img16

ico_path = os.path.join(install_dir, 'sema.ico')
with open(ico_path, 'wb') as f:
    f.write(ico_data)
print('ICO created:', ico_path)
" 2>nul
echo  [OK] Icon created.

:: ── REGISTER IN WINDOWS REGISTRY ───────────────────────
echo.
echo  [5/5] Registering .sema in Windows Registry...

:: File extension → ProgID
reg add "HKEY_CLASSES_ROOT\.sema" /ve /d "SemaFormat.File" /f >nul 2>&1
reg add "HKEY_CLASSES_ROOT\.sema" /v "Content Type" /d "application/vnd.sema" /f >nul 2>&1
reg add "HKEY_CLASSES_ROOT\.sema" /v "PerceivedType" /d "document" /f >nul 2>&1

:: ProgID definition
reg add "HKEY_CLASSES_ROOT\SemaFormat.File" /ve /d "Semantic File (.sema)" /f >nul 2>&1
reg add "HKEY_CLASSES_ROOT\SemaFormat.File\DefaultIcon" /ve /d "%INSTALL_DIR%\sema.ico" /f >nul 2>&1

:: Open command
reg add "HKEY_CLASSES_ROOT\SemaFormat.File\shell\open\command" /ve /d "\"%INSTALL_DIR%\sema_launch.bat\" \"%%1\"" /f >nul 2>&1
reg add "HKEY_CLASSES_ROOT\SemaFormat.File\shell\open" /v "FriendlyAppName" /d ".sema Viewer" /f >nul 2>&1

:: Context menu — "Open with .sema Viewer"
reg add "HKEY_CLASSES_ROOT\SemaFormat.File\shell\open" /v "MUIVerb" /d "Open with .sema Viewer" /f >nul 2>&1

:: Context menu — "Inspect .sema Archive"
reg add "HKEY_CLASSES_ROOT\SemaFormat.File\shell\inspect\command" /ve /d "explorer.exe \"%%1\"" /f >nul 2>&1
reg add "HKEY_CLASSES_ROOT\SemaFormat.File\shell\inspect" /ve /d "Inspect .sema Archive" /f >nul 2>&1

:: Also register for .sema in HKCU for non-admin fallback
reg add "HKEY_CURRENT_USER\Software\Classes\.sema" /ve /d "SemaFormat.File" /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Classes\SemaFormat.File" /ve /d "Semantic File (.sema)" /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Classes\SemaFormat.File\DefaultIcon" /ve /d "%INSTALL_DIR%\sema.ico" /f >nul 2>&1
reg add "HKEY_CURRENT_USER\Software\Classes\SemaFormat.File\shell\open\command" /ve /d "\"%INSTALL_DIR%\sema_launch.bat\" \"%%1\"" /f >nul 2>&1

:: Notify Windows of association change
%PYTHON_CMD% -c "import ctypes; ctypes.windll.shell32.SHChangeNotify(0x8000000, 0, None, None)" >nul 2>&1

echo  [OK] Registry updated.

:: ── DONE ────────────────────────────────────────────────
echo.
echo  ██████████████████████████████████████████████████
echo  █                                                █
echo  █   [SUCCESS] .sema Format Installed!            █
echo  █                                                █
echo  █   Double-click any .sema file to open it.      █
echo  █   Files will show the .sema icon.              █
echo  █                                                █
echo  █   Visit: trenstudio.com/sema                   █
echo  █                                                █
echo  ██████████████████████████████████████████████████
echo.
echo  Installation directory: %INSTALL_DIR%
echo.
echo  Press any key to exit...
pause >nul
exit /b 0
