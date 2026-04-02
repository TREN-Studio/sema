# SEMA Format Installer v1.0
# TREN Studio — https://trenstudio.com/sema
# Run as: Right-click → Run with PowerShell

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ─── Check Admin ───────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $result = [System.Windows.Forms.MessageBox]::Show(
        "SEMA Installer needs Administrator rights to register the file type.`n`nClick Yes to restart with admin privileges.",
        "SEMA Format — Admin Required",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Shield
    )
    if ($result -eq "Yes") {
        Start-Process PowerShell -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    }
    exit
}

# ─── Build UI ──────────────────────────────────────────────────
$form = New-Object System.Windows.Forms.Form
$form.Text = "SEMA Format Installer v1.0"
$form.Size = New-Object System.Drawing.Size(520, 400)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 25)
$form.ForeColor = [System.Drawing.Color]::White

# Header panel
$header = New-Object System.Windows.Forms.Panel
$header.Size = New-Object System.Drawing.Size(520, 80)
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 180)
$form.Controls.Add($header)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "SEMA Format"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::FromArgb(15, 15, 25)
$titleLabel.Location = New-Object System.Drawing.Point(20, 10)
$titleLabel.Size = New-Object System.Drawing.Size(300, 35)
$header.Controls.Add($titleLabel)

$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Text = "The Semantic File Format  —  by TREN Studio"
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(15, 15, 25)
$subtitleLabel.Location = New-Object System.Drawing.Point(22, 48)
$subtitleLabel.Size = New-Object System.Drawing.Size(400, 20)
$header.Controls.Add($subtitleLabel)

# Info label
$infoLabel = New-Object System.Windows.Forms.Label
$infoLabel.Text = "This will register .sema files on your system so they open automatically in your browser. No internet connection required."
$infoLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$infoLabel.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 200)
$infoLabel.Location = New-Object System.Drawing.Point(30, 105)
$infoLabel.Size = New-Object System.Drawing.Size(455, 45)
$infoLabel.TextAlign = "TopLeft"
$form.Controls.Add($infoLabel)

# Progress log box
$logBox = New-Object System.Windows.Forms.RichTextBox
$logBox.Location = New-Object System.Drawing.Point(30, 160)
$logBox.Size = New-Object System.Drawing.Size(455, 140)
$logBox.BackColor = [System.Drawing.Color]::FromArgb(8, 8, 18)
$logBox.ForeColor = [System.Drawing.Color]::FromArgb(0, 220, 180)
$logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$logBox.ReadOnly = $true
$logBox.BorderStyle = "FixedSingle"
$logBox.Text = "Ready to install SEMA Format v1.0...`r`n"
$form.Controls.Add($logBox)

# Install button
$installBtn = New-Object System.Windows.Forms.Button
$installBtn.Text = "Install SEMA Format"
$installBtn.Location = New-Object System.Drawing.Point(30, 315)
$installBtn.Size = New-Object System.Drawing.Size(200, 40)
$installBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 200, 180)
$installBtn.ForeColor = [System.Drawing.Color]::FromArgb(15, 15, 25)
$installBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$installBtn.FlatStyle = "Flat"
$installBtn.FlatAppearance.BorderSize = 0
$form.Controls.Add($installBtn)

# Cancel button
$cancelBtn = New-Object System.Windows.Forms.Button
$cancelBtn.Text = "Cancel"
$cancelBtn.Location = New-Object System.Drawing.Point(245, 315)
$cancelBtn.Size = New-Object System.Drawing.Size(100, 40)
$cancelBtn.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 55)
$cancelBtn.ForeColor = [System.Drawing.Color]::White
$cancelBtn.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$cancelBtn.FlatStyle = "Flat"
$cancelBtn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 100)
$cancelBtn.DialogResult = "Cancel"
$form.Controls.Add($cancelBtn)

# Version label
$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Text = "v1.0.0  |  trenstudio.com/sema"
$versionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$versionLabel.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 100)
$versionLabel.Location = New-Object System.Drawing.Point(355, 330)
$versionLabel.Size = New-Object System.Drawing.Size(140, 20)
$form.Controls.Add($versionLabel)

# ─── Install Logic ─────────────────────────────────────────────
function Add-Log($msg, $color = "Green") {
    $logBox.SelectionStart = $logBox.TextLength
    $logBox.SelectionLength = 0
    $logBox.AppendText($msg + "`r`n")
    $logBox.ScrollToCaret()
    $form.Refresh()
    Start-Sleep -Milliseconds 200
}

$installBtn.Add_Click({
    $installBtn.Enabled = $false
    $installBtn.Text = "Installing..."

    try {
        Add-Log "► Registering .sema file type..."
        New-Item -Path "HKCR:\.sema" -Force | Out-Null
        Set-ItemProperty -Path "HKCR:\.sema" -Name "(Default)" -Value "SEMAFile"
        Add-Log "  ✓ .sema extension registered"

        Add-Log "► Creating SEMAFile handler..."
        New-Item -Path "HKCR:\SEMAFile" -Force | Out-Null
        Set-ItemProperty -Path "HKCR:\SEMAFile" -Name "(Default)" -Value "SEMA Semantic File"
        New-Item -Path "HKCR:\SEMAFile\shell\open\command" -Force | Out-Null
        Set-ItemProperty -Path "HKCR:\SEMAFile\shell\open\command" -Name "(Default)" -Value "explorer.exe `"%1`""
        Add-Log "  ✓ File handler created"

        Add-Log "► Registering MIME type..."
        $mimePath = "HKLM:\SOFTWARE\Classes\MIME\Database\Content Type\application/vnd.sema"
        New-Item -Path $mimePath -Force | Out-Null
        Set-ItemProperty -Path $mimePath -Name "Extension" -Value ".sema"
        Add-Log "  ✓ MIME type: application/vnd.sema"

        Add-Log "► Refreshing Windows Explorer..."
        $code = @"
using System;
using System.Runtime.InteropServices;
public class NativeMethods {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(int wEventId, int uFlags, IntPtr dwItem1, IntPtr dwItem2);
}
"@
        Add-Type -TypeDefinition $code -Language CSharp -ErrorAction SilentlyContinue
        [NativeMethods]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)
        Add-Log "  ✓ Explorer refreshed"

        Add-Log ""
        Add-Log "✅ SEMA Format installed successfully!"
        Add-Log "   .sema files will now open automatically."
        Add-Log ""
        Add-Log "   Visit: trenstudio.com/sema"

        $installBtn.Text = "✓ Installed!"
        $installBtn.BackColor = [System.Drawing.Color]::FromArgb(0, 160, 100)
        $cancelBtn.Text = "Close"

        [System.Windows.Forms.MessageBox]::Show(
            "SEMA Format installed successfully!`n`n.sema files are now registered on your system.`n`nVisit trenstudio.com/sema to download the Viewer.",
            "Installation Complete",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
    catch {
        Add-Log "✗ Error: $_"
        $installBtn.Text = "Retry"
        $installBtn.Enabled = $true
    }
})

$form.ShowDialog() | Out-Null
