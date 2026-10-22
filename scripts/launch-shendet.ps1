param(
    [switch]$NoBrowser,
    [switch]$Headless,
    [int]$AutoCloseSeconds = 0
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$root = 'C:\dev\shendetplus'
$backend = Join-Path $root 'backend'
$webDir = Join-Path $root 'mobile\build\web'
$py = Join-Path $backend '.venv\Scripts\python.exe'
$logs = Join-Path $backend 'logs'
$url = 'http://127.0.0.1:5001'
$docker = 'C:\Program Files\Docker\Docker\resources\bin\docker.exe'
$dockerDesktop = 'C:\Program Files\Docker\Docker\Docker Desktop.exe'

New-Item -ItemType Directory -Force -Path $logs | Out-Null

# Vetëm një dritare kontrolli. Nëse hapet përsëri, thjesht hap aplikacionin.
$mutex = New-Object System.Threading.Mutex($false, 'Global\ShendetPlusLauncher')
if (-not $mutex.WaitOne(0)) {
    if (-not $NoBrowser) { Start-Process $url | Out-Null }
    exit 0
}

$splash = $null
if (-not $Headless) {
    $splash = New-Object System.Windows.Forms.Form
    $splash.Text = 'Shëndet+'
    $splash.ClientSize = New-Object System.Drawing.Size(380, 112)
    $splash.StartPosition = 'CenterScreen'
    $splash.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $splash.MaximizeBox = $false
    $splash.MinimizeBox = $false
    $splash.TopMost = $true
    $splash.BackColor = [System.Drawing.Color]::FromArgb(247, 250, 249)

    $splashTitle = New-Object System.Windows.Forms.Label
    $splashTitle.Text = 'Po nis Shëndet+...'
    $splashTitle.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
    $splashTitle.ForeColor = [System.Drawing.Color]::FromArgb(15, 118, 110)
    $splashTitle.AutoSize = $true
    $splashTitle.Location = New-Object System.Drawing.Point(24, 20)
    $splash.Controls.Add($splashTitle)

    $splashInfo = New-Object System.Windows.Forms.Label
    $splashInfo.Text = 'API · Web · Kujtesat'
    $splashInfo.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $splashInfo.ForeColor = [System.Drawing.Color]::DimGray
    $splashInfo.AutoSize = $true
    $splashInfo.Location = New-Object System.Drawing.Point(26, 58)
    $splash.Controls.Add($splashInfo)

    $splash.Show()
    $splash.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

function Test-DockerRunning {
    if (-not (Test-Path $docker)) { return $false }
    $check = Start-Process -FilePath $docker -ArgumentList @('info') `
        -WindowStyle Hidden -Wait -PassThru
    return ($check.ExitCode -eq 0)
}

function Stop-Shendet {
    foreach ($proc in @($script:api, $script:worker, $script:web)) {
        if ($null -ne $proc) {
            try {
                if (-not $proc.HasExited) { Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue }
            } catch { }
        }
    }
    foreach ($port in 8000, 5001) {
        Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
            ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
    }
    Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.CommandLine -match 'uvicorn app\.main:app' -or
            $_.CommandLine -match 'http\.server 5001' -or
            $_.CommandLine -match 'arq app\.worker'
        } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

try {
    Stop-Shendet

    # Docker Desktop ndonjëherë nuk është gati pas nisjes së Windows.
    if (Test-Path $docker) {
        if (-not (Test-DockerRunning)) {
            if (Test-Path $dockerDesktop) {
                if ($null -ne $splash) {
                    $splashInfo.Text = 'Docker po nis... (mund të zgjasë ~1 minutë)'
                    $splashInfo.Refresh()
                    [System.Windows.Forms.Application]::DoEvents()
                }
                Start-Process -FilePath $dockerDesktop | Out-Null
                for ($i = 0; $i -lt 90; $i++) {
                    Start-Sleep -Seconds 1
                    if (Test-DockerRunning) { break }
                }
            }
        }
        if (Test-DockerRunning) {
            Start-Process -FilePath $docker -ArgumentList @('compose', 'up', '-d', 'db', 'redis') `
                -WorkingDirectory $backend -WindowStyle Hidden -Wait | Out-Null
        }
    }

    $script:api = Start-Process -FilePath $py -ArgumentList @(
        '-m', 'uvicorn', 'app.main:app', '--host', '0.0.0.0', '--port', '8000'
    ) -WorkingDirectory $backend -WindowStyle Hidden `
      -RedirectStandardOutput (Join-Path $logs 'api.out.log') `
      -RedirectStandardError (Join-Path $logs 'api.err.log') -PassThru

    $script:worker = Start-Process -FilePath $py -ArgumentList @(
        '-m', 'arq', 'app.worker.WorkerSettings'
    ) -WorkingDirectory $backend -WindowStyle Hidden `
      -RedirectStandardOutput (Join-Path $logs 'worker.out.log') `
      -RedirectStandardError (Join-Path $logs 'worker.err.log') -PassThru

    $script:web = Start-Process -FilePath $py -ArgumentList @(
        '-m', 'http.server', '5001', '--bind', '0.0.0.0', '--directory', $webDir
    ) -WorkingDirectory $webDir -WindowStyle Hidden `
      -RedirectStandardOutput (Join-Path $logs 'web.out.log') `
      -RedirectStandardError (Join-Path $logs 'web.err.log') -PassThru

    $apiUp = $false
    for ($i = 0; $i -lt 60; $i++) {
        try {
            $r = Invoke-RestMethod 'http://127.0.0.1:8000/health' -TimeoutSec 2
            if ($r.status -eq 'ok') { $apiUp = $true; break }
        } catch { Start-Sleep -Milliseconds 500 }
    }

    $webUp = $false
    for ($i = 0; $i -lt 30; $i++) {
        try {
            $r = Invoke-WebRequest $url -UseBasicParsing -TimeoutSec 2
            if ($r.StatusCode -eq 200) { $webUp = $true; break }
        } catch { Start-Sleep -Milliseconds 500 }
    }

    if ($null -ne $splash) {
        $splash.Close()
        $splash.Dispose()
        $splash = $null
    }

    if (-not $apiUp -or -not $webUp) {
        $detail = if (-not $apiUp) { 'API-ja nuk u nis.' } else { 'Web-i nuk u nis.' }
        $hint = "Shiko logjet: $logs"
        if (-not $apiUp) {
            $tail = Get-Content (Join-Path $logs 'api.err.log') -Tail 8 -ErrorAction SilentlyContinue
            if ($tail) { $hint = ($tail -join "`n") }
        }
        [System.Windows.Forms.MessageBox]::Show(
            "$detail`n`n$hint",
            'Shëndet+',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        Stop-Shendet
        exit 1
    }

    if ($Headless) {
        Write-Host 'API: OK'
        Write-Host 'WEB: OK'
        Stop-Shendet
        exit 0
    }

    if (-not $NoBrowser) { Start-Process $url | Out-Null }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Shëndet+'
    $form.ClientSize = New-Object System.Drawing.Size(430, 215)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $form.MaximizeBox = $false
    $form.MinimizeBox = $true
    $form.BackColor = [System.Drawing.Color]::FromArgb(247, 250, 249)

    $title = New-Object System.Windows.Forms.Label
    $title.Text = 'Shëndet+ është hapur'
    $title.Font = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
    $title.ForeColor = [System.Drawing.Color]::FromArgb(15, 118, 110)
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(24, 22)
    $form.Controls.Add($title)

    $info = New-Object System.Windows.Forms.Label
    $info.Text = "Aplikacioni punon në:$([Environment]::NewLine)$url"
    $info.Font = New-Object System.Drawing.Font('Segoe UI', 10)
    $info.AutoSize = $true
    $info.Location = New-Object System.Drawing.Point(26, 64)
    $form.Controls.Add($info)

    $hint = New-Object System.Windows.Forms.Label
    $hint.Text = 'Për ta ndaluar, mbyll këtë dritare ose kliko "Ndal".'
    $hint.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $hint.ForeColor = [System.Drawing.Color]::DimGray
    $hint.AutoSize = $true
    $hint.Location = New-Object System.Drawing.Point(26, 96)
    $form.Controls.Add($hint)

    $open = New-Object System.Windows.Forms.Button
    $open.Text = 'Hap aplikacionin'
    $open.Location = New-Object System.Drawing.Point(26, 145)
    $open.Size = New-Object System.Drawing.Size(180, 38)
    $open.Add_Click({ Start-Process $url | Out-Null })
    $form.Controls.Add($open)

    $stop = New-Object System.Windows.Forms.Button
    $stop.Text = 'Ndal dhe mbyll'
    $stop.Location = New-Object System.Drawing.Point(220, 145)
    $stop.Size = New-Object System.Drawing.Size(180, 38)
    $stop.Add_Click({ $form.Close() })
    $form.Controls.Add($stop)

    $form.Add_FormClosing({ Stop-Shendet })

    if ($AutoCloseSeconds -gt 0) {
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = $AutoCloseSeconds * 1000
        $timer.Add_Tick({ $timer.Stop(); $form.Close() })
        $form.Add_Shown({ $timer.Start() })
    }

    [System.Windows.Forms.Application]::Run($form)
}
finally {
    if ($null -ne $splash) {
        try { $splash.Close(); $splash.Dispose() } catch { }
    }
    Stop-Shendet
    try { $mutex.ReleaseMutex() } catch { }
    $mutex.Dispose()
}
