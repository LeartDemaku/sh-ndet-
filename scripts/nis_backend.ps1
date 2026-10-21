# =====================================================================
#  Shendet+ - Nisja e plote e backend-it me nje komande
#  Docker Desktop -> db + redis -> alembic -> uvicorn + arq worker
#  Perdorimi:  .\scripts\nis_backend.ps1
# =====================================================================

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$root    = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$backend = Join-Path $root 'backend'
$docker  = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe'
$desktop = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
$py      = Join-Path $backend '.venv\Scripts\python.exe'
$logs    = Join-Path $backend 'logs'

function Step([string]$t) { Write-Host ""; Write-Host ("== " + $t) -ForegroundColor Cyan }
function Ok([string]$t)   { Write-Host ("   OK   " + $t) -ForegroundColor Green }
function Bad([string]$t)  { Write-Host ("   GABIM " + $t) -ForegroundColor Red }

Set-Location $backend
New-Item -ItemType Directory -Force -Path $logs | Out-Null

# ---------------------------------------------------------------
Step "1/6  Docker Desktop"
if (-not (Test-Path $docker)) { Bad "docker.exe nuk u gjet te $docker"; exit 1 }

& $docker info *> $null
if ($LASTEXITCODE -ne 0) {
    if (-not (Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue)) {
        Write-Host "   Po hap Docker Desktop..."
        Start-Process $desktop | Out-Null
    }
    Write-Host "   Po pres Engine-in..."
    $ok = $false
    for ($i = 1; $i -le 150; $i++) {
        & $docker info *> $null
        if ($LASTEXITCODE -eq 0) { $ok = $true; break }
        Start-Sleep -Seconds 2
    }
    if (-not $ok) { Bad "Docker Engine nuk u nis brenda 5 minutash."; exit 1 }
}
Ok "Docker Engine gati."

# ---------------------------------------------------------------
Step "2/6  Kontejneret db + redis"
& $docker compose up -d db redis | Out-Null
$healthy = $false
for ($i = 1; $i -le 60; $i++) {
    $h = & $docker inspect --format '{{.State.Health.Status}}' backend-db-1 2>$null
    $r = & $docker inspect --format '{{.State.Status}}' backend-redis-1 2>$null
    if ($h -eq 'healthy' -and $r -eq 'running') { $healthy = $true; break }
    Start-Sleep -Seconds 2
}
if (-not $healthy) { Bad "db/redis nuk u be healthy."; & $docker compose ps; exit 1 }
Ok "Postgres healthy + Redis running."

# ---------------------------------------------------------------
Step "3/6  Migrimet (alembic upgrade head)"
$env:PYTHONIOENCODING = 'utf-8'
& $py -m alembic upgrade head 2>&1 | ForEach-Object { Write-Host ("   " + $_) }
if ($LASTEXITCODE -ne 0) { Bad "Migrimi deshtoi."; exit 1 }
Ok "Skema ne versionin me te fundit."

# ---------------------------------------------------------------
Step "4/6  Nisja e API dhe Worker"
Get-CimInstance Win32_Process -Filter "Name='python.exe'" |
    Where-Object { $_.CommandLine -match 'uvicorn\s+app\.main:app|arq\s+app\.worker' } |
    ForEach-Object {
        Write-Host ("   Ndaluar PID " + $_.ProcessId)
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
Start-Sleep -Seconds 1

# .env eshte burimi i vertete per OPENAI_API_KEY (mjedisi i Windows mund te kete
# nje vlere te vjetruar qe do ta mbivendoste).
$envLine = Get-Content (Join-Path $backend '.env') -ErrorAction SilentlyContinue |
    Where-Object { $_ -match '^OPENAI_API_KEY=' } | Select-Object -First 1
if ($envLine) {
    $key = $envLine.Substring('OPENAI_API_KEY='.Length).Trim()
    if ($key) { $env:OPENAI_API_KEY = $key } else { Remove-Item Env:\OPENAI_API_KEY -ErrorAction SilentlyContinue }
}

$api = Start-Process -FilePath $py -ArgumentList @('-m','uvicorn','app.main:app','--host','127.0.0.1','--port','8000') `
    -WorkingDirectory $backend -WindowStyle Hidden `
    -RedirectStandardOutput (Join-Path $logs 'api.out.log') `
    -RedirectStandardError  (Join-Path $logs 'api.err.log') -PassThru
$wrk = Start-Process -FilePath $py -ArgumentList @('-m','arq','app.worker.WorkerSettings') `
    -WorkingDirectory $backend -WindowStyle Hidden `
    -RedirectStandardOutput (Join-Path $logs 'worker.out.log') `
    -RedirectStandardError  (Join-Path $logs 'worker.err.log') -PassThru
Ok ("API PID " + $api.Id + " | Worker PID " + $wrk.Id)

# ---------------------------------------------------------------
Step "5/6  Shendeti i API-se"
$up = $false
for ($i = 1; $i -le 60; $i++) {
    try {
        $r = Invoke-RestMethod 'http://127.0.0.1:8000/health' -TimeoutSec 2
        $up = $true; break
    } catch { Start-Sleep -Milliseconds 700 }
}
if (-not $up) {
    Bad "API nuk pergjigjet. Shiko backend\logs\api.err.log"
    Get-Content (Join-Path $logs 'api.err.log') -Tail 25 -ErrorAction SilentlyContinue
    exit 1
}
Ok ('GET /health -> ' + ($r | ConvertTo-Json -Compress))

# ---------------------------------------------------------------
Step "6/6  Gati"
Write-Host ""
Write-Host "   API      : http://127.0.0.1:8000" -ForegroundColor White
Write-Host "   Swagger  : http://127.0.0.1:8000/docs" -ForegroundColor White
Write-Host "   Logjet   : backend\logs\api.err.log dhe worker.out.log" -ForegroundColor White
Write-Host ""
if (-not $key) {
    Write-Host "   KUJDES: OPENAI_API_KEY eshte bosh ne backend\.env" -ForegroundColor Yellow
    Write-Host "           Chat-i me LLM nuk punon; emergjencat (L0) punojne." -ForegroundColor Yellow
    Write-Host ""
}
Write-Host '   Ndalo:  Get-CimInstance Win32_Process -Filter "Name=''python.exe''" |' -ForegroundColor DarkGray
Write-Host '           Where-Object { $_.CommandLine -match ''uvicorn|arq'' } | Stop-Process -Force' -ForegroundColor DarkGray
Write-Host ""
