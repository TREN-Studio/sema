@echo off
title SEMA Format Installer — TREN Studio
color 0B
cls

echo.
echo  ╔════════════════════════════════════════════╗
echo  ║        SEMA Format Installer v1.0          ║
echo  ║        TREN Studio — trenstudio.com        ║
echo  ╚════════════════════════════════════════════╝
echo.

:: Check Admin
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo  [!] This installer needs Administrator rights.
    echo  [!] Right-click the file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo  [1/4] Registering .sema file extension...
reg add "HKCR\.sema" /ve /d "SEMAFile" /f >nul 2>&1
reg add "HKCR\.sema" /v "Content Type" /d "application/vnd.sema" /f >nul 2>&1
echo       OK

echo  [2/4] Creating file type handler...
reg add "HKCR\SEMAFile" /ve /d "SEMA Semantic File" /f >nul 2>&1
reg add "HKCR\SEMAFile\DefaultIcon" /ve /d "shell32.dll,13" /f >nul 2>&1
reg add "HKCR\SEMAFile\shell\open" /ve /d "Open with Browser" /f >nul 2>&1
reg add "HKCR\SEMAFile\shell\open\command" /ve /d "explorer.exe \"%%1\"" /f >nul 2>&1
echo       OK

echo  [3/4] Registering MIME type...
reg add "HKLM\SOFTWARE\Classes\MIME\Database\Content Type\application/vnd.sema" /v "Extension" /d ".sema" /f >nul 2>&1
echo       OK

echo  [4/4] Refreshing Windows Explorer...
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
start explorer.exe
echo       OK

echo.
echo  ╔════════════════════════════════════════════╗
echo  ║   ✓  SEMA Format installed successfully!   ║
echo  ║                                            ║
echo  ║   .sema files are now registered on        ║
echo  ║   your Windows system.                     ║
echo  ║                                            ║
echo  ║   Visit: trenstudio.com/sema               ║
echo  ╚════════════════════════════════════════════╝
echo.
pause
