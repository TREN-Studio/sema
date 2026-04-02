param([string]$FilePath)

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Open-SemaFile($path) {

    if (-not (Test-Path $path)) {
        [System.Windows.Forms.MessageBox]::Show("File not found:`n$path", "SEMA Viewer", 0, 16)
        exit
    }

    $tempDir = Join-Path $env:TEMP ("SEMA_" + [System.IO.Path]::GetFileNameWithoutExtension($path) + "_" + (Get-Random))
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($path, $tempDir)
        $semaName = [System.IO.Path]::GetFileName($path)
        Copy-Item $path (Join-Path $tempDir $semaName) -Force -ErrorAction SilentlyContinue

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
            Start-Process $viewFile
        } else {
            [System.Windows.Forms.MessageBox]::Show("No view.html found inside the SEMA file.", "SEMA Viewer Error", 0, 16)
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
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Open .sema file - TREN Studio"
    $dialog.Filter = "SEMA Files (*.sema)|*.sema|All files (*.*)|*.*"
    $dialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")

    if ($dialog.ShowDialog() -eq "OK") {
        Open-SemaFile $dialog.FileName
    }
}
