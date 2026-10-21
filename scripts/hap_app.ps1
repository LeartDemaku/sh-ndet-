# =====================================================================
#  Shendet+ - Hap aplikacionin me nje klik
#  Backend (Docker/DB/API/worker) -> build web -> server statik -> browser
#  Perdorimi:  .\scripts\hap_app.ps1
# =====================================================================

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$root     = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$backend  = Join-Path $root 'backend'
$webDir   = Join-Path $root 'mobile\build\web'
$index    = Join-Path $webDir 'index.html'
$junction = 'C:\dev\shendetplus'
$url      = 'http://127.0.0.1:5000'

function Step([string]$t) { Write-Host ""; Write-Host ("== " + $t) -ForegroundColor Cyan }
function Ok([string]$t)   { Write-Host ("   OK   " + $t) -ForegroundColor Green }
function Bad([string]$t)  { Write-Host ("   GABIM " + $t) -ForegroundColor Red }

# ---------------------------------------------------------------
Step "1/3  Backend-i"
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'nis_backend.ps1')
if ($LASTEXITCODE -ne 0) {
    Bad "Backend-i nuk u nis."
    Read-Host "Shtyp ENTER per ta mbyllur"
    exit 1
}

# ---------------------------------------------------------------
Step "2/3  Aplikacioni web"
if (-not (Test-Path $junction)) {
    cmd /c mklink /J "`"$junction`"" "`"$root`"" | Out-Null
}
$mobile = Join-Path $junction 'mobile'

$needBuild = -not (Test-Path $index)
if (-not $needBuild) {
    $newest = Get-ChildItem (Join-Path $root 'mobile\lib') -Recurse -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $pubspec = Get-Item (Join-Path $root 'mobile\pubspec.yaml')
    $built = (Get-Item $index).LastWriteTime
    if (($newest -and $newest.LastWriteTime -gt $built) -or $pubspec.LastWriteTime -gt $built) {
        $needBuild = $true
    }
}

if ($needBuild) {
    Write-Host "   Po ndertohet versioni web (vetem here e pare ose kur ndryshon kodi)..."
    Push-Location $mobile
    & 'C:\dev\flutter\bin\flutter.bat' build web --release --dart-define=API_BASE_URL=http://127.0.0.1:8000
    $buildOk = ($LASTEXITCODE -eq 0)
    Pop-Location
    if (-not $buildOk) {
        Bad "Ndertimi web deshtoi."
        Read-Host "Shtyp ENTER per ta mbyllur"
        exit 1
    }
}
Ok "Build-i web gati."

# ---------------------------------------------------------------
Step "3/3  Serveri i aplikacionit"
$listening = $null
try { $listening = Get-NetTCPConnection -LocalPort 5000 -State Listen -ErrorAction Stop } catch { }
if (-not $listening) {
    $py = Join-Path $backend '.venv\Scripts\python.exe'
    Start-Process -FilePath $py -ArgumentList @(
        '-m', 'http.server', '5000', '--bind', '127.0.0.1', '--directory', $webDir
    ) -WindowStyle Hidden | Out-Null
    $up = $false
    for ($i = 1; $i -le 30; $i++) {
        try {
            $r = Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 2
            if ($r.StatusCode -eq 200) { $up = $true; break }
        } catch { Start-Sleep -Milliseconds 500 }
    }
    if (-not $up) {
        Bad "Serveri web nuk u nis."
        Read-Host "Shtyp ENTER per ta mbyllur"
        exit 1
    }
}
Ok "Aplikacioni sherbehet ne $url"

Write-Host ""
Write-Host "   Po hapet aplikacioni ne browser..." -ForegroundColor White
Start-Process $url | Out-Null
Write-Host ""
Write-Host "   Perdorimi i aplikacionit:" -ForegroundColor White
Write-Host "     1. Kalo onboarding-un dhe krijo llogari (email + fjalekalim)."
Write-Host "     2. Pas regjistrimit hapet Ballina."
Write-Host "     3. Butoni i kuq i emergjences eshte gjithmone i dukshem."
Write-Host ""
Write-Host "   Per ta mbyllur: mbyll dritaren e browserit; API/worker vazhdojne." -ForegroundColor DarkGray
Write-Host ""
