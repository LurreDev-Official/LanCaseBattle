# LanCast export (Windows PowerShell)
# Run from repo root in PowerShell (Developer / Flutter environment):
#   .\scripts\export.ps1

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root

$EnvFile = Join-Path $Root "config\lancast.env"
if (Test-Path $EnvFile) {
  Get-Content $EnvFile | ForEach-Object {
    if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
    $pair = $_.Split('=', 2)
    if ($pair.Length -eq 2) {
      [Environment]::SetEnvironmentVariable($pair[0].Trim(), $pair[1].Trim(), "Process")
    }
  }
}

function Resolve-Flutter {
  if ($env:FLUTTER_BIN -and (Test-Path (Join-Path $env:FLUTTER_BIN "flutter.bat"))) {
    $env:Path = "$($env:FLUTTER_BIN);$env:Path"
    return
  }
  if (Get-Command flutter -ErrorAction SilentlyContinue) { return }
  throw "flutter not found. Install Flutter and add to PATH, or set FLUTTER_BIN in config\lancast.env"
}

Resolve-Flutter

$VersionLine = (Get-Content "apps\viewer\pubspec.yaml" | Where-Object { $_ -match '^version:' } | Select-Object -First 1)
$Version = if ($VersionLine) { ($VersionLine -split '\s+')[1] -replace '\+.*','' } else { "0.1.0" }
$Stamp = Get-Date -Format "yyyyMMdd-HHmm"
$Out = Join-Path $Root "dist\windows\LanCast-$Version-$Stamp"
New-Item -ItemType Directory -Force -Path $Out | Out-Null

Write-Host "=== LanCast export (Windows) ==="
Write-Host "Version: $Version"
Write-Host "Output : $Out"

flutter config --enable-windows-desktop | Out-Null
dart pub get | Out-Null

Write-Host "-> Building Viewer (release)"
Push-Location apps\viewer
flutter build windows --release
Pop-Location

Write-Host "-> Building Sender (release)"
Push-Location apps\sender
flutter build windows --release
Pop-Location

$ViewerSrc = "apps\viewer\build\windows\x64\runner\Release"
$SenderSrc = "apps\sender\build\windows\x64\runner\Release"
if (-not (Test-Path $ViewerSrc)) { $ViewerSrc = "apps\viewer\build\windows\runner\Release" }
if (-not (Test-Path $SenderSrc)) { $SenderSrc = "apps\sender\build\windows\runner\Release" }

if (-not (Test-Path $ViewerSrc) -or -not (Test-Path $SenderSrc)) {
  throw "Release folders not found. Install Visual Studio with Desktop C++ workload."
}

$ArenaDir = Join-Path $Out "LanCast Arena"
$PartDir = Join-Path $Out "LanCast Participant"
New-Item -ItemType Directory -Force -Path $ArenaDir, $PartDir | Out-Null
Copy-Item -Recurse -Force "$ViewerSrc\*" $ArenaDir
Copy-Item -Recurse -Force "$SenderSrc\*" $PartDir

@"
LanCast Arena — Windows Release
===============================

1. Jalankan "LanCast Arena\lancast_viewer.exe" (Judge / Viewer).
2. Jalankan "LanCast Participant\lancast_sender.exe" (Sender).
3. Kedua PC harus di jaringan LAN/Wi-Fi yang sama.
4. Izinkan Windows Firewall (UDP 17891, TCP/WebSocket 17890).
5. Arena: Create Battle Room → Share Join Link.
6. Participant: Scan Rooms / Join via Link → Approve → Start Share.

Jangan pindahkan .exe saja — salin seluruh folder Release.
"@ | Set-Content -Encoding UTF8 (Join-Path $Out "CARA_PAKAI.txt")

$Zip = Join-Path $Root "dist\LanCast-windows-$Version-$Stamp.zip"
if (Test-Path $Zip) { Remove-Item $Zip -Force }
Compress-Archive -Path $Out -DestinationPath $Zip -Force

Write-Host ""
Write-Host "Done."
Write-Host "  Apps : $Out"
Write-Host "  Zip  : $Zip"
