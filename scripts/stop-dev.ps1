param([switch]$Quiet)

$ErrorActionPreference = 'SilentlyContinue'

# Mbyll serverat e projektit edhe nëse porta ka mbetur e varur.
$ports = 8000, 5001
foreach ($port in $ports) {
    Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
        ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }
}

# Mbyll dritaret e hapura nga skripti i nisjes.
Get-Process |
    Where-Object { $_.MainWindowTitle -in @('Shendet API', 'Shendet Web') } |
    Stop-Process -Force -ErrorAction SilentlyContinue

# Fallback: mbyll çdo proces të vjetër të projektit.
Get-CimInstance Win32_Process |
    Where-Object {
        $_.CommandLine -match 'uvicorn app\.main:app' -or
        $_.CommandLine -match 'http\.server 5001'
    } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

if (-not $Quiet) {
    Write-Host ''
    Write-Host 'Shendet+ u ndal.' -ForegroundColor Green
    Write-Host 'Nese ndonje dritare mbeti e hapur, mbyllja me X.' -ForegroundColor DarkGray
}
