# SEMA File Opener — TREN Studio
# Called automatically when user double-clicks any .sema file
# Usage: sema_open.ps1 "C:\path\to\file.sema"

param([string]$FilePath)

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Open-SemaFile($path) {

    if (-not (Test-Path $path)) {
        [System.Windows.Forms.MessageBox]::Show(
            "File not found:`n$path",
            "SEMA Viewer", 0, 16)
        exit
    }

    $tempDir = Join-Path $env:TEMP ("SEMA_" + [System.IO.Path]::GetFileNameWithoutExtension($path) + "_" + (Get-Random))
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        # Extract the .sema (ZIP) to temp folder
        [System.IO.Compression.ZipFile]::ExtractToDirectory($path, $tempDir)

        # Copy the original .sema file to temp so viewer can read it
        $semaName = [System.IO.Path]::GetFileName($path)
        Copy-Item $path (Join-Path $tempDir $semaName) -Force -ErrorAction SilentlyContinue

        # Priority: view.html > index.html > sema-viewer embedded
        $viewFile = $null
        $candidates = @("view.html", "viewer.html", "index.html", "sema-viewer.html")

        foreach ($c in $candidates) {
            $candidate = Join-Path $tempDir $c
            if (Test-Path $candidate) {
                $viewFile = $candidate
                break
            }
        }

        if ($viewFile) {
            # Found a viewer inside the .sema — open it directly
            Start-Process $viewFile
        } else {
            # No viewer inside — generate one on the fly
            $generated = Join-Path $tempDir "view.html"
            $files = Get-ChildItem $tempDir -Recurse -File | Where-Object { $_.Name -ne $semaName }

            $fileRows = ""
            foreach ($f in $files) {
                $rel = $f.FullName.Replace($tempDir + "\", "").Replace("\", "/")
                $size = if ($f.Length -gt 1MB) { "{0:N2} MB" -f ($f.Length/1MB) }
                        elseif ($f.Length -gt 1KB) { "{0:N1} KB" -f ($f.Length/1KB) }
                        else { "$($f.Length) B" }
                $ext = $f.Extension.TrimStart('.').ToUpper()
                if (-not $ext) { $ext = "FILE" }
                $fileRows += "<div class='layer'><div class='ext'>$ext</div><div class='name'>$rel</div><div class='size'>$size</div></div>`n"
            }

            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($path)
            $totalSize = if ((Get-Item $path).Length -gt 1MB) { "{0:N2} MB" -f ((Get-Item $path).Length/1MB) }
                         else { "{0:N1} KB" -f ((Get-Item $path).Length/1KB) }

            # Try to read content
            $contentPreview = ""
            $contentFile = Get-ChildItem $tempDir -Recurse -File |
                Where-Object { $_.Extension -match '\.(txt|md|json|csv|xml)$' } |
                Select-Object -First 1
            if ($contentFile) {
                try {
                    $raw = Get-Content $contentFile.FullName -Raw -Encoding UTF8 -ErrorAction Stop
                    $contentPreview = $raw.Substring(0, [Math]::Min(1200, $raw.Length))
                } catch {}
            }

            $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>$baseName.sema — SEMA Viewer</title>
<style>
@import url('https://fonts.googleapis.com/css2?family=Space+Grotesk:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');
:root{--teal:#00C8B4;--bg:#090911;--bg2:#0F0F1C;--bg3:#141422;--border:rgba(0,200,180,0.15);--border2:rgba(255,255,255,0.07);--text:#E0E0F0;--mono:'JetBrains Mono',monospace;--font:'Space Grotesk',system-ui,sans-serif}
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:var(--font);background:var(--bg);color:var(--text);min-height:100vh;overflow-x:hidden}
body::before{content:'';position:fixed;inset:0;background-image:linear-gradient(rgba(0,200,180,0.025) 1px,transparent 1px),linear-gradient(90deg,rgba(0,200,180,0.025) 1px,transparent 1px);background-size:44px 44px;pointer-events:none;z-index:0}
header{position:relative;z-index:10;display:flex;align-items:center;justify-content:space-between;padding:1.1rem 2rem;border-bottom:1px solid var(--border2);background:rgba(9,9,17,0.9);backdrop-filter:blur(12px)}
.logo{display:flex;align-items:center;gap:10px}
.mark{width:32px;height:32px;background:var(--teal);border-radius:8px;display:flex;align-items:center;justify-content:center;font-family:var(--mono);font-size:13px;font-weight:500;color:#090911}
.brand{font-size:15px;font-weight:600;letter-spacing:-0.3px}
.brand span{color:var(--teal)}
.ver{font-size:11px;font-family:var(--mono);color:rgba(224,224,240,0.25);background:var(--bg3);border:1px solid var(--border2);padding:4px 10px;border-radius:20px}
main{position:relative;z-index:1;max-width:860px;margin:0 auto;padding:2.5rem 2rem}
.file-title{font-size:2.2rem;font-weight:700;letter-spacing:-1.2px;margin-bottom:0.4rem;color:#fff}
.file-title span{color:var(--teal)}
.chips{display:flex;gap:10px;flex-wrap:wrap;margin-bottom:2rem}
.chip{display:flex;align-items:center;gap:5px;font-size:12px;color:rgba(224,224,240,0.4);font-family:var(--mono)}
.chip-dot{width:5px;height:5px;border-radius:50%;background:var(--teal)}
.stats{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-bottom:1.8rem}
.stat{background:var(--bg2);border:1px solid var(--border2);border-radius:10px;padding:1rem;text-align:center}
.stat-n{font-size:1.5rem;font-weight:700;color:var(--teal);font-family:var(--mono);letter-spacing:-1px}
.stat-l{font-size:10px;color:rgba(224,224,240,0.3);text-transform:uppercase;letter-spacing:1px;margin-top:3px;font-family:var(--mono)}
.card{background:var(--bg2);border:1px solid var(--border2);border-radius:12px;margin-bottom:1rem;overflow:hidden}
.card-header{display:flex;align-items:center;gap:8px;padding:0.9rem 1.2rem;background:var(--bg3);border-bottom:1px solid var(--border2);font-size:12px;font-family:var(--mono);color:rgba(224,224,240,0.35);letter-spacing:1px;text-transform:uppercase}
.card-header .dot{width:6px;height:6px;border-radius:50%;background:var(--teal)}
.card-body{padding:1.2rem}
.layer{display:flex;align-items:center;gap:12px;padding:9px 0;border-bottom:1px solid var(--border2)}
.layer:last-child{border-bottom:none}
.ext{font-family:var(--mono);font-size:10px;font-weight:600;padding:3px 7px;background:rgba(0,200,180,0.1);color:var(--teal);border-radius:4px;flex-shrink:0}
.name{font-size:13px;font-family:var(--mono);color:rgba(224,224,240,0.6);flex:1;word-break:break-all}
.size{font-size:11px;color:rgba(224,224,240,0.25);font-family:var(--mono);flex-shrink:0}
.content-text{font-family:var(--mono);font-size:12px;color:rgba(0,200,180,0.8);line-height:1.7;white-space:pre-wrap;word-break:break-word;max-height:300px;overflow-y:auto}
.empty{text-align:center;padding:2rem;color:rgba(224,224,240,0.25);font-size:14px}
footer{position:relative;z-index:1;text-align:center;padding:2rem;font-size:11px;color:rgba(224,224,240,0.2);font-family:var(--mono);border-top:1px solid var(--border2);margin-top:3rem}
footer a{color:var(--teal);text-decoration:none}
::-webkit-scrollbar{width:5px}::-webkit-scrollbar-track{background:var(--bg)}::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px}
</style>
</head>
<body>
<header>
  <div class="logo">
    <div class="mark">S</div>
    <div class="brand">SEMA <span>Viewer</span></div>
  </div>
  <div class="ver">v1.0 · TREN Studio</div>
</header>
<main>
  <div class="file-title">$baseName<span>.sema</span></div>
  <div class="chips">
    <span class="chip"><span class="chip-dot"></span>$totalSize</span>
    <span class="chip"><span class="chip-dot"></span>$($files.Count) layers</span>
    <span class="chip"><span class="chip-dot"></span>application/vnd.sema</span>
  </div>
  <div class="stats">
    <div class="stat"><div class="stat-n">$($files.Count)</div><div class="stat-l">Layers</div></div>
    <div class="stat"><div class="stat-n">$totalSize</div><div class="stat-l">Size</div></div>
    <div class="stat"><div class="stat-n">SEMA</div><div class="stat-l">Format</div></div>
  </div>
  <div class="card">
    <div class="card-header"><span class="dot"></span>Layers inside this file</div>
    <div class="card-body">
      $(if ($fileRows) { $fileRows } else { '<div class="empty">No layers found</div>' })
    </div>
  </div>
  $(if ($contentPreview) {
  "<div class='card'>
    <div class='card-header'><span class='dot'></span>Content preview</div>
    <div class='card-body'><div class='content-text'>$([System.Web.HttpUtility]::HtmlEncode($contentPreview))</div></div>
  </div>"
  })
</main>
<footer>SEMA Format v1.0 · <a href='https://trenstudio.com/sema'>trenstudio.com/sema</a> · Open Semantic File Standard</footer>
</body></html>
"@
            Set-Content -Path $generated -Value $html -Encoding UTF8
            Start-Process $generated
        }

    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Could not open .sema file.`n`nError: $_`n`nMake sure the file is a valid .sema archive.",
            "SEMA Viewer Error", 0, 16)
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Web

if ($FilePath -and (Test-Path $FilePath)) {
    Open-SemaFile $FilePath
} else {
    # No file passed — show open dialog
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Open .sema file — TREN Studio"
    $dialog.Filter = "SEMA Files (*.sema)|*.sema|All files (*.*)|*.*"
    $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")

    if ($dialog.ShowDialog() -eq "OK") {
        Open-SemaFile $dialog.FileName
    }
}
