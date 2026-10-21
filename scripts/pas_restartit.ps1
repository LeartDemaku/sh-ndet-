# =====================================================================
#  Shendet+ - Kontroll pas restartit + nisja e Docker (db/redis)
#  Ekzekutohet automatikisht nga "Pas Restartit (kontrollo Docker).bat"
# =====================================================================

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

function Write-Title([string]$t) {
    Write-Host ""
    Write-Host ("=" * 58)
    Write-Host "  $t"
    Write-Host ("=" * 58)
    Write-Host ""
}

function Write-Step([string]$n, [string]$text) {
    Write-Host ("[$n] $text")
}

function Write-OK([string]$t)   { Write-Host ("     OK   : $t") -ForegroundColor Green }
function Write-Warn([string]$t) { Write-Host ("     WARN : $t") -ForegroundColor Yellow }
function Write-Err([string]$t)  { Write-Host ("     GABIM: $t") -ForegroundColor Red }

$allOk     = $true
$hvOk      = $false
$vmOk      = $false
$dockerOk  = $false

Write-Title "SHENDET+ - Kontroll pas restartit"

# ---------------------------------------------------------------
Write-Step "1/5" "Hypervisor / virtualizimi"
$cs = Get-CimInstance Win32_ComputerSystem
Write-Host ("     HypervisorPresent = " + $cs.HypervisorPresent)
if ($cs.HypervisorPresent) {
    Write-OK "Hypervisor aktiv."
    $hvOk = $true
} else {
    Write-Err "Hypervisor NUK eshte aktiv."
    Write-Host "     Shkaqet e mundshme:"
    Write-Host "       - Kompjuteri nuk u ri-nis pas aktivizimit te komponenteve"
    Write-Host "       - Virtualizimi i CPU eshte i caktivizuar ne BIOS/UEFI (VT-x / AMD-V)"
    $allOk = $false
}

# ---------------------------------------------------------------
Write-Host ""
Write-Step "2/5" "Sherbimi vmcompute (WSL2 / Docker backend)"
$svc = Get-Service vmcompute -ErrorAction SilentlyContinue
if ($null -eq $svc) {
    Write-Err "Sherbimi vmcompute nuk ekziston ende."
    Write-Host "     => Komponentet jane aktivizuar, por Windows nuk ka perfunduar instalimin."
    Write-Host "     => RI-NIS kompjuterin perseri dhe ekzekuto kete skript."
    $allOk = $false
} else {
    Write-Host ("     Statusi fillestar = " + $svc.Status)
    if ($svc.Status -ne 'Running') {
        Start-Service vmcompute -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        $svc.Refresh()
    }
    Write-Host ("     Statusi tani      = " + $svc.Status)
    if ($svc.Status -eq 'Running') {
        Write-OK "vmcompute punon."
        $vmOk = $true
    } else {
        Write-Err "vmcompute nuk niset."
        $allOk = $false
    }
}

# ---------------------------------------------------------------
Write-Host ""
Write-Step "3/5" "Gjendja e WSL"
$wslStatus = & wsl.exe --status 2>&1
if ($LASTEXITCODE -eq 0) {
    $wslStatus | ForEach-Object { Write-Host ("     " + $_) }
    Write-OK "WSL pergjigjet."
} else {
    $wslStatus | ForEach-Object { Write-Host ("     " + $_) }
    Write-Warn "WSL nuk pergjigjet si duhet."
}
$wslVersion = & wsl.exe --version 2>&1
if ($LASTEXITCODE -eq 0) {
    $wslVersion | Select-Object -First 3 | ForEach-Object { Write-Host ("     " + $_) }
}

# ---------------------------------------------------------------
Write-Host ""
Write-Step "4/5" "Docker Desktop / Engine"
$dockerDesktop = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'
$dockerCli     = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe'

if (-not (Test-Path $dockerCli)) {
    Write-Err "docker.exe nuk u gjet ne $dockerCli"
    $allOk = $false
} else {
    $proc = Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue
    if ($null -eq $proc) {
        if (Test-Path $dockerDesktop) {
            Write-Host "     Po hap Docker Desktop..."
            Start-Process -FilePath $dockerDesktop | Out-Null
        } else {
            Write-Err "Docker Desktop.exe nuk u gjet."
        }
    } else {
        Write-Host "     Docker Desktop eshte duke punuar (PID " + $proc.Id + ")."
    }

    Write-Host "     Po pres Engine-in (deri ne 4 minuta)..."
    for ($i = 1; $i -le 120; $i++) {
        & $dockerCli info *> $null
        if ($LASTEXITCODE -eq 0) {
            $dockerOk = $true
            break
        }
        if ($i % 10 -eq 0) { Write-Host ("       ... " + ($i * 2) + " sekonda") }
        Start-Sleep -Seconds 2
    }

    if ($dockerOk) {
        Write-OK "Docker Engine eshte gati."
        $ver = & $dockerCli version --format '{{.Server.Version}}' 2>$null
        Write-Host ("     Server version = " + $ver)
    } else {
        Write-Err "Docker Engine nuk u nis brenda 4 minutash."
        Write-Host "     Hap Docker Desktop manualisht dhe shiko mesazhin e gabimit."
        $allOk = $false
    }
}

# ---------------------------------------------------------------
Write-Host ""
Write-Step "5/5" "Nisja e kontejnereve db + redis"
if ($dockerOk) {
    $backend = Join-Path $PSScriptRoot '..\backend'
    $backend = (Resolve-Path $backend).Path
    Push-Location $backend
    try {
        Write-Host "     docker compose up -d db redis"
        & $dockerCli compose up -d db redis
        Write-Host ""
        Write-Host "     Gjendja e kontejnereve:"
        & $dockerCli compose ps
        Write-Host ""
        Write-Host "     Po pres qe Postgres te jete gati (pg_isready)..."
        $dbReady = $false
        for ($i = 1; $i -le 45; $i++) {
            $out = & $dockerCli compose exec -T db pg_isready -U shendet -d shendetplus 2>&1
            if ($LASTEXITCODE -eq 0) { $dbReady = $true; break }
            Start-Sleep -Seconds 2
        }
        if ($dbReady) {
            Write-OK "Postgres pranon lidhje."
        } else {
            Write-Warn "Postgres nuk u pergjigj ende. Shiko: docker compose logs db"
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Warn "Anashkaluar sepse Docker nuk eshte gati."
}

# ---------------------------------------------------------------
Write-Host ""
Write-Host ("=" * 58)
if ($allOk -and $hvOk -and $vmOk -and $dockerOk) {
    Write-Host "  PËRFUNDIM: GJITHÇKA GATI" -ForegroundColor Green
    Write-Host "  Tani kthehu te OpenCode dhe shkruaj: u ri-nisa"
} else {
    Write-Host "  PËRFUNDIM: KA PROBLEME (shiko mesazhet me te kuqe)" -ForegroundColor Yellow
}
Write-Host ("=" * 58)
Write-Host ""
