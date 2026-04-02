@echo off
chcp 65001 >nul 2>&1
title SEMA Format Installer v1.1 - TREN Studio
color 0B
cls

echo.
echo  ==========================================
echo    SEMA Format Installer v1.1
echo    TREN Studio - trenstudio.com/sema
echo  ==========================================
echo.

net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo  [!] Administrator rights required.
    echo  [!] Right-click - Run as administrator
    echo.
    pause
    exit /b 1
)

set "INSTALL_DIR=%APPDATA%\TREN Studio\SEMA"

echo  [1/5] Creating installation folder...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
echo         OK

echo  [2/5] Installing SEMA opener script...
if exist "%~dp0sema_open.ps1" (
    copy /Y "%~dp0sema_open.ps1" "%INSTALL_DIR%\sema_open.ps1" >nul
    echo         OK - viewer installed
) else (
    echo         WARNING - Put sema_open.ps1 next to this .bat file
)

echo  [3/5] Registering .sema extension...
reg add "HKCR\.sema" /ve /d "SEMAFile" /f >nul 2>&1
reg add "HKCR\.sema" /v "Content Type" /d "application/vnd.sema" /f >nul 2>&1
echo         OK

echo  [4/5] Registering file handler...
reg add "HKCR\SEMAFile" /ve /d "SEMA Semantic File" /f >nul 2>&1
reg add "HKCR\SEMAFile\DefaultIcon" /ve /d "shell32.dll,1" /f >nul 2>&1
reg add "HKCR\SEMAFile\shell\open" /ve /d "Open with SEMA Viewer" /f >nul 2>&1
reg add "HKCR\SEMAFile\shell\open\command" /ve /d "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File \"%INSTALL_DIR%\sema_open.ps1\" \"%%1\"" /f >nul 2>&1
reg add "HKCR\SEMAFile\shell\open_zip" /ve /d "Inspect layers (open as ZIP)" /f >nul 2>&1
reg add "HKCR\SEMAFile\shell\open_zip\command" /ve /d "explorer.exe \"%%1\"" /f >nul 2>&1
reg add "HKCR\SEMAFile\shell\open_web" /ve /d "Learn about .sema format" /f >nul 2>&1
reg add "HKCR\SEMAFile\shell\open_web\command" /ve /d "rundll32 url.dll,FileProtocolHandler https://trenstudio.com/sema" /f >nul 2>&1
echo         OK

echo  [5/5] Registering MIME type and refreshing...
reg add "HKLM\SOFTWARE\Classes\MIME\Database\Content Type\application/vnd.sema" /v "Extension" /d ".sema" /f >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
start explorer.exe
echo         OK

echo.
echo  ==========================================
echo    SUCCESS! SEMA is installed.
echo.
echo    NOW: Double-click any .sema file
echo    It opens in your browser automatically!
echo.
echo    Right-click .sema for more options.
echo    Visit: trenstudio.com/sema
echo  ==========================================
echo.
pause
