# =============================================================================
# DOFLUXO - UM COMANDO: atualizar e publicar
# =============================================================================
# Uso (PowerShell):
#   powershell -ExecutionPolicy Bypass -File .\deploy.ps1
#
# Faz tudo:
#   1. git pull
#   2. (opcional) commit de mudancas locais pendentes
#   3. incrementa version no pubspec.yaml (+N -> +N+1)
#   4. flutter pub get
#   5. flutter build web (release, sem SW, APP_VERSION injetada)
#   6. firebase deploy --only hosting
#   7. commit + push da nova versao no GitHub
# =============================================================================

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Assert-LastExit([string]$step) {
    if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        Write-Host "ERRO em: $step" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host " DOFLUXO - publicar (tudo em um comando)" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# --- 1) Atualizar do GitHub --------------------------------------------------
Write-Host ">> git pull" -ForegroundColor Cyan
git pull --ff-only
Assert-LastExit "git pull"
# Se ff-only falhar, tenta pull normal
if ($LASTEXITCODE -ne 0) {
    git pull
    Assert-LastExit "git pull"
}

# --- 2) Commit automatico de mudancas locais (se houver) ---------------------
git add -A
$status = git status --porcelain
if ($status) {
    Write-Host ">> commit de mudancas locais pendentes" -ForegroundColor Cyan
    git commit -m "chore: sync antes do deploy"
    Assert-LastExit "git commit (sync)"
} else {
    Write-Host ">> sem mudancas locais pendentes" -ForegroundColor DarkGray
}

# --- 3) Ler e incrementar versao ---------------------------------------------
$pubspecPath = Join-Path $PSScriptRoot "pubspec.yaml"
$content = Get-Content $pubspecPath -Raw
$pattern = '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$'
$match = [regex]::Match($content, $pattern)

if (-not $match.Success) {
    Write-Host "ERRO: nao encontrei 'version: x.y.z+N' em pubspec.yaml." -ForegroundColor Red
    exit 1
}

$major = $match.Groups[1].Value
$minor = $match.Groups[2].Value
$patch = $match.Groups[3].Value
$build = [int]$match.Groups[4].Value
$oldVersion = "$major.$minor.$patch+$build"
$newVersion = "$major.$minor.$patch+$($build + 1)"

Write-Host ""
Write-Host "Versao atual : $oldVersion" -ForegroundColor DarkGray
Write-Host "Nova versao  : $newVersion" -ForegroundColor Cyan

$newContent = [regex]::Replace($content, $pattern, "version: $newVersion")
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($pubspecPath, $newContent, $utf8NoBom)
Write-Host ">> pubspec.yaml -> $newVersion" -ForegroundColor Green

# --- 4) flutter pub get ------------------------------------------------------
Write-Host ""
Write-Host ">> flutter pub get" -ForegroundColor Cyan
flutter pub get
Assert-LastExit "flutter pub get"

# --- 5) flutter build web ----------------------------------------------------
Write-Host ""
Write-Host ">> flutter build web (release, versao=$newVersion)" -ForegroundColor Cyan
flutter build web `
    --release `
    --pwa-strategy=none `
    --no-web-resources-cdn `
    --no-wasm-dry-run `
    --dart-define=APP_VERSION=$newVersion
Assert-LastExit "flutter build web"

# --- 6) firebase deploy ------------------------------------------------------
Write-Host ""
Write-Host ">> firebase deploy --only hosting" -ForegroundColor Cyan
if (Get-Command firebase -ErrorAction SilentlyContinue) {
    firebase deploy --only hosting
} else {
    Write-Host "   usando npx firebase-tools" -ForegroundColor DarkGray
    npx firebase-tools deploy --only hosting
}
Assert-LastExit "firebase deploy"

# --- 7) commit + push da versao ----------------------------------------------
Write-Host ""
Write-Host ">> git commit + push da versao $newVersion" -ForegroundColor Cyan
git add pubspec.yaml
$pending = git status --porcelain
if ($pending) {
    git commit -m "release: $newVersion"
    Assert-LastExit "git commit (release)"
}
git push
Assert-LastExit "git push"

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Green
Write-Host " PRONTO - versao $newVersion no ar" -ForegroundColor Green
Write-Host " https://dofluxo-organizer.web.app" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Abra o link (Ctrl+Shift+R se a tela parecer antiga)." -ForegroundColor DarkGray
