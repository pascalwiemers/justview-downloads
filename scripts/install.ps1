# Installer for justview
# Usage: irm https://raw.githubusercontent.com/pascalwiemers/justview-downloads/main/scripts/install.ps1 | iex

$ErrorActionPreference = 'Stop'

$Repo = 'pascalwiemers/justview-downloads'
$Asset = 'justview-windows-x86_64.zip'
$InstallDir = if ($env:INSTALL_DIR) { $env:INSTALL_DIR } else { "$env:LOCALAPPDATA\justview" }

Write-Host "Fetching latest release..."
$Release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"
$Tag = $Release.tag_name

if (-not $Tag) {
    Write-Error "Could not determine latest release."
    exit 1
}

$Url = "https://github.com/$Repo/releases/download/$Tag/$Asset"
Write-Host "Downloading justview $Tag for Windows..."

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

$TmpZip = Join-Path $env:TEMP "justview-download.zip"
try {
    Invoke-WebRequest -Uri $Url -OutFile $TmpZip -UseBasicParsing
    Expand-Archive -Path $TmpZip -DestinationPath $InstallDir -Force
} finally {
    Remove-Item $TmpZip -ErrorAction SilentlyContinue
}

$ViewerExe = Join-Path $InstallDir 'justview.exe'
if (Test-Path $ViewerExe) {
    $Version = & $ViewerExe --version 2>&1
    Write-Host "Installed: $Version -> $ViewerExe"
} else {
    Write-Warning "Download completed but justview.exe not found at $ViewerExe"
}

$UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
if ($UserPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable('Path', "$InstallDir;$UserPath", 'User')
    Write-Host ""
    Write-Host "Added $InstallDir to your user PATH."
    Write-Host "Restart your terminal for the change to take effect."
}
