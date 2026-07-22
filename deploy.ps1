# =============================================================================
# DOFLUXO - UM COMANDO: atualizar e publicar
# =============================================================================
# Uso (PowerShell):
#   .\deploy.ps1
#
# Voce NAO precisa mexer em PR, merge ou git pull manual.
# Este script faz tudo:
#   1. atualiza o main do GitHub (fetch --prune + pull)
#   2. commit de mudancas locais pendentes (se houver)
#   3. incrementa version no pubspec.yaml (+N -> +N+1)
#   4. flutter pub get
#   5. flutter build web (release, sem SW, APP_VERSION injetada)
#   6. firebase deploy --only firestore:rules,hosting
#   7. commit + push da nova versao no GitHub
# =============================================================================

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Invoke-Firebase {
    param([string[]]$Arguments)

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"

    try {
        if (Get-Command firebase -ErrorAction SilentlyContinue) {
            $output = & firebase @Arguments 2>&1
        } else {
            Write-Host "   (firebase nao encontrado no PATH; usando npx firebase-tools)" -ForegroundColor DarkGray
            $output = & npx firebase-tools @Arguments 2>&1
        }

        return [PSCustomObject]@{
            Output   = ($output | ForEach-Object { "$_" }) -join [Environment]::NewLine
            ExitCode = $LASTEXITCODE
        }
    } finally {
        $ErrorActionPreference = $previousErrorAction
    }
}

function Assert-FirebaseLogin {
    Write-Host ""
    Write-Host ">> Verificando login Firebase..." -ForegroundColor Cyan

    $loginResult = Invoke-Firebase @("login:list")
    if ($loginResult.Output) {
        Write-Host $loginResult.Output
    }

    if ($loginResult.ExitCode -ne 0 -or $loginResult.Output -notmatch '@') {
        Write-Host ""
        Write-Host "Voce nao esta autenticado no Firebase CLI." -ForegroundColor Red
        Write-Host "Rode no PowerShell:" -ForegroundColor Yellow
        Write-Host "  firebase logout" -ForegroundColor Yellow
        Write-Host "  firebase login" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Use a conta dofluxodigital@gmail.com (projeto dofluxo-organizer)." -ForegroundColor Yellow
        exit 1
    }

    Write-Host ">> Login Firebase OK" -ForegroundColor Green
}

function Assert-LastExit([string]$step) {
    if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        Write-Host "ERRO em: $step" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

# Git escreve warnings (CRLF) no stderr; com ErrorAction Stop o PowerShell trata como erro.
function Invoke-Git {
    param([Parameter(Mandatory = $true)][string[]]$GitArgs)

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & git @GitArgs 2>&1 | ForEach-Object {
            $line = "$_"
            if ($line -match '^warning:') {
                Write-Host $line -ForegroundColor DarkGray
            } elseif ($line.Trim().Length -gt 0) {
                Write-Host $line
            }
        }
        return $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorAction
    }
}

function Ensure-GitIdentity {
    $email = git config user.email
    $name = git config user.name

    if ($email -and $name) { return }

    Write-Host ">> Configurando identidade Git deste repositorio..." -ForegroundColor Yellow

    if (-not $email) {
        git config user.email "dofluxodigital@gmail.com"
        Assert-LastExit "git config user.email"
    }

    if (-not $name) {
        git config user.name "DOFLUXO"
        Assert-LastExit "git config user.name"
    }

    Write-Host "   user.email = $(git config user.email)" -ForegroundColor DarkGray
    Write-Host "   user.name  = $(git config user.name)" -ForegroundColor DarkGray
}

function Ensure-GitEditor {
    $editor = git config core.editor
    if (-not $editor) {
        Write-Host ">> Configurando editor Git como Notepad (evita Vim travado)" -ForegroundColor Yellow
        git config core.editor "notepad"
        Assert-LastExit "git config core.editor"
    }
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host " DOFLUXO - publicar (tudo em um comando)" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

Ensure-GitIdentity
Ensure-GitEditor

# Merge incompleto bloqueia pull/deploy - limpa automatico se sobrou de tentativa anterior.
$gitDir = Join-Path $PSScriptRoot ".git"
if (Test-Path (Join-Path $gitDir "MERGE_HEAD")) {
    Write-Host ">> merge incompleto detectado - cancelando para liberar o deploy" -ForegroundColor Yellow
    git merge --abort
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: nao consegui cancelar o merge incompleto." -ForegroundColor Red
        Write-Host "Rode: git merge --abort" -ForegroundColor Yellow
        Write-Host "Depois: .\deploy.ps1" -ForegroundColor Yellow
        exit 1
    }
}

# Deploy anterior pode ter incrementado pubspec.yaml e falhado antes do commit.
$pubspecDirty = git status --porcelain -- pubspec.yaml 2>$null
if ($pubspecDirty -match '^\s*M\s+pubspec\.yaml') {
    Write-Host ">> pubspec.yaml alterado localmente - restaurando versao do Git" -ForegroundColor Yellow
    git checkout -- pubspec.yaml
    Assert-LastExit "git checkout pubspec.yaml"
}

# --- 1) Atualizar do GitHub --------------------------------------------------
# Na 1a passagem: fetch/prune + pull, depois REINICIA o script ja atualizado.
if (-not $env:DOFLUXO_DEPLOY_RELOADED) {
    Write-Host ">> git fetch --prune origin" -ForegroundColor Cyan
    git fetch --prune origin
    Assert-LastExit "git fetch --prune origin"

    $currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($currentBranch -ne "main") {
        Write-Host ">> mudando para main (estava em $currentBranch)" -ForegroundColor Yellow
        git checkout main
        Assert-LastExit "git checkout main"
    }

    Write-Host ">> git pull origin main" -ForegroundColor Cyan
    git pull --ff-only origin main
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ff-only falhou; tentando git pull --rebase..." -ForegroundColor DarkGray
        git pull --rebase origin main
        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "ERRO no git pull. Resolva o estado do Git e tente de novo:" -ForegroundColor Red
            Write-Host "  git merge --abort" -ForegroundColor Yellow
            Write-Host "  git pull --rebase origin main" -ForegroundColor Yellow
            Write-Host "  .\deploy.ps1" -ForegroundColor Yellow
            exit $LASTEXITCODE
        }
    }

    Write-Host ">> reiniciando deploy com o script atualizado..." -ForegroundColor DarkGray
    $env:DOFLUXO_DEPLOY_RELOADED = "1"
    & powershell -ExecutionPolicy Bypass -File $PSCommandPath @args
    exit $LASTEXITCODE
}

Write-Host ">> confirmando main atualizado..." -ForegroundColor Cyan
$currentBranch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($currentBranch -ne "main") {
    Write-Host ">> mudando para main (estava em $currentBranch)" -ForegroundColor Yellow
    git checkout main
    Assert-LastExit "git checkout main"
}

git pull --ff-only origin main
if ($LASTEXITCODE -ne 0) {
    git pull --rebase origin main
    Assert-LastExit "git pull origin main"
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
Write-Host ">> flutter build web release $newVersion" -ForegroundColor Cyan
flutter build web `
    --release `
    --pwa-strategy=none `
    --no-web-resources-cdn `
    --no-wasm-dry-run `
    --dart-define=APP_VERSION=$newVersion
Assert-LastExit "flutter build web"

# --- 6) firebase deploy ------------------------------------------------------
Assert-FirebaseLogin

Write-Host ""
Write-Host ">> firebase deploy --only firestore:rules,hosting" -ForegroundColor Cyan
$deployResult = Invoke-Firebase @("deploy", "--only", "firestore:rules,hosting")
if ($deployResult.Output) {
    Write-Host $deployResult.Output
}
if ($deployResult.ExitCode -ne 0) {
    Write-Host ""
    Write-Host "ERRO no firebase deploy." -ForegroundColor Red
    Write-Host "Confirme login com dofluxodigital@gmail.com:" -ForegroundColor Yellow
    Write-Host "  firebase logout" -ForegroundColor Yellow
    Write-Host "  firebase login" -ForegroundColor Yellow
    exit $deployResult.ExitCode
}

# --- 7) commit + push da versao ----------------------------------------------
Write-Host ""
Write-Host ">> git commit + push da versao $newVersion" -ForegroundColor Cyan
$code = Invoke-Git @("add", "pubspec.yaml")
if ($code -ne 0) { Assert-LastExit "git add pubspec.yaml" }

$cachePath = Join-Path $PSScriptRoot ".firebase\hosting.YnVpbGRcd2Vi.cache"
if (Test-Path $cachePath) {
    $null = Invoke-Git @("add", ".firebase/hosting.YnVpbGRcd2Vi.cache")
}

$pending = git status --porcelain
if ($pending) {
    $code = Invoke-Git @("commit", "-m", "release: $newVersion")
    if ($code -ne 0) { Assert-LastExit "git commit (release)" }
}
$code = Invoke-Git @("push", "origin", "main")
if ($code -ne 0) { Assert-LastExit "git push" }

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Green
Write-Host " PRONTO - versao $newVersion no ar" -ForegroundColor Green
Write-Host " https://dofluxo-organizer.web.app" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Abas abertas recebem aviso de atualizacao em ate 5 segundos." -ForegroundColor DarkGray
Write-Host "Novas visitas carregam a versao publicada automaticamente." -ForegroundColor DarkGray
