# Publica firestore.rules no projeto dofluxo-organizer.
# Pode rodar no Firebase CLI Win ou no PowerShell (usa firebase-tools local).

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

$firebase = Join-Path $root 'node_modules\.bin\firebase.cmd'
if (-not (Test-Path $firebase)) {
  Write-Host 'firebase-tools nao encontrado. Rode: npm install' -ForegroundColor Red
  exit 1
}

Write-Host ">> Publicando firestore.rules em dofluxo-organizer..." -ForegroundColor Cyan
& $firebase deploy --only firestore:rules --project dofluxo-organizer
if ($LASTEXITCODE -ne 0) {
  Write-Host "Falhou. No Firebase CLI Win: firebase login --reauth" -ForegroundColor Yellow
  exit $LASTEXITCODE
}

Write-Host "OK — rules publicadas." -ForegroundColor Green
