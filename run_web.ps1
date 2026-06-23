# DOFLUXO — dev Web com login Google persistente entre runs.
# Usa porta fixa (8080) + perfil Chrome dedicado (cookies/Firebase Auth).

$ErrorActionPreference = "Stop"
$projectRoot = $PSScriptRoot
$chromeProfile = Join-Path $projectRoot ".dart_tool\chrome-dev-profile"
$webPort = 8080

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

Write-Host "Perfil Chrome: $chromeProfile" -ForegroundColor DarkGray
Write-Host "URL: http://localhost:$webPort" -ForegroundColor DarkGray

flutter run -d chrome `
  --web-port=$webPort `
  "--web-browser-flag=--user-data-dir=$chromeProfile"
