# =============================================================================
# DOFLUXO - Atualizar e publicar (comando unico)
# =============================================================================
# Uso:  .\deploy-web.ps1
#
# Faz:
#   1. git pull (branch atual)
#   2. valida que as correcoes de tema/atualizacao existem
#   3. build + deploy Firebase (rules + hosting) via deploy.ps1
#
# IMPORTANTE: as correcoes estao no PR #4 / branch cursor/cloud-agent-*.
# Se voce estiver em main sem merge, o script avisa antes de publicar codigo
# antigo.
# =============================================================================

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

function Test-DofluxoDeployReady {
    $requiredFiles = @(
        "lib/core/theme/theme_preference_store.dart",
        "lib/core/update/app_update_gate.dart",
        "deploy.ps1"
    )

    foreach ($file in $requiredFiles) {
        if (-not (Test-Path (Join-Path $PSScriptRoot $file))) {
            return $false
        }
    }

    $deployScript = Get-Content (Join-Path $PSScriptRoot "deploy.ps1") -Raw
    return $deployScript -match "APP_VERSION"
}

Write-Host ""
Write-Host "DOFLUXO - atualizar codigo e publicar" -ForegroundColor Cyan
Write-Host ""

$branch = git rev-parse --abbrev-ref HEAD
Write-Host "Branch atual: $branch" -ForegroundColor DarkGray
Write-Host ""

Write-Host ">> git pull origin $branch" -ForegroundColor Cyan
git pull origin $branch
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERRO no git pull. Resolva conflitos ou autenticacao e tente de novo." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ""
if (-not (Test-DofluxoDeployReady)) {
    Write-Host "=============================================================" -ForegroundColor Red
    Write-Host " ESTE BRANCH NAO TEM AS CORRECOES DE TEMA / ATUALIZACAO" -ForegroundColor Red
    Write-Host "=============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Voce provavelmente esta em 'main' sem o merge do PR #4." -ForegroundColor Yellow
    Write-Host "Faca uma das opcoes abaixo e rode .\deploy-web.ps1 de novo:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1) Merge do PR no GitHub:" -ForegroundColor Yellow
    Write-Host "     https://github.com/luisjuniorawr1/dofluxo/pull/4" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  2) Ou troque para o branch com as correcoes:" -ForegroundColor Yellow
    Write-Host "     git checkout cursor/cloud-agent-1784593741847-ryv0b" -ForegroundColor Yellow
    Write-Host "     git pull origin cursor/cloud-agent-1784593741847-ryv0b" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "Correcoes detectadas (tema + aviso de atualizacao)." -ForegroundColor Green
Write-Host ""

& (Join-Path $PSScriptRoot "deploy.ps1")
exit $LASTEXITCODE
