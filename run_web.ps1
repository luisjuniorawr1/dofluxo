# DOFLUXO — dev Web local (sem abrir o Chrome automaticamente).
# Usa web-server na porta fixa 8080.

param(
    [switch]$OpenBrowser
)

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
$webPort = 8080
$localUrl = "http://localhost:$webPort"

function Stop-ProcessOnPort {
    param([int]$Port)

    $connections = netstat -ano | Select-String ":$Port\s" | Select-String "LISTENING"
    if (-not $connections) { return }

    $pids = $connections | ForEach-Object {
        ($_ -split '\s+')[-1]
    } | Select-Object -Unique

    foreach ($procId in $pids) {
        if ($procId -eq "0") { continue }

        $process = Get-Process -Id $procId -ErrorAction SilentlyContinue
        $name = if ($process) { $process.ProcessName } else { "PID $procId" }

        if ($name -eq "dartvm") {
            Write-Host "Encerrando run anterior ($name, PID $procId) na porta $Port..." -ForegroundColor Yellow
            Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        } else {
            Write-Host "Porta $Port em uso por $name (PID $procId)." -ForegroundColor Red
            Write-Host "Feche esse processo ou altere a porta em run_web.ps1." -ForegroundColor Red
            exit 1
        }
    }
}

Stop-ProcessOnPort -Port $webPort

Write-Host "URL: $localUrl" -ForegroundColor Cyan
Write-Host "Servidor local sem abrir navegador. Use -OpenBrowser se quiser abrir o Chrome." -ForegroundColor DarkGray

if ($OpenBrowser) {
    $chromeProfile = Join-Path $projectRoot ".dart_tool\chrome-dev-profile"
    Write-Host "Perfil Chrome: $chromeProfile" -ForegroundColor DarkGray

    flutter run -d chrome `
        --web-port=$webPort `
        "--web-browser-flag=--user-data-dir=$chromeProfile"
} else {
    flutter run -d web-server --web-port=$webPort
}
