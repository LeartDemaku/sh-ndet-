$ErrorActionPreference = 'Stop'
$root = 'C:\dev\shendetplus'

& "$root\scripts\stop-dev.ps1" -Quiet

Write-Host ''
Write-Host 'Po nis API-ne...' -ForegroundColor Cyan
Start-Process -FilePath 'cmd.exe' -ArgumentList @(
    '/k',
    'title Shendet API & cd /d C:\dev\shendetplus\backend & .venv\Scripts\python.exe -m uvicorn app.main:app --host 0.0.0.0 --port 8000'
) -WorkingDirectory "$root\backend" -WindowStyle Normal
Start-Sleep -Seconds 3

Write-Host 'Po nis web-in...' -ForegroundColor Cyan
Start-Process -FilePath 'cmd.exe' -ArgumentList @(
    '/k',
    'title Shendet Web & cd /d C:\dev\shendetplus\mobile\build\web & C:\dev\shendetplus\backend\.venv\Scripts\python.exe -m http.server 5001 --bind 0.0.0.0'
) -WorkingDirectory "$root\mobile\build\web" -WindowStyle Normal
Start-Sleep -Seconds 5

Write-Host ''
Write-Host 'Duke kontrolluar serverat...' -ForegroundColor Cyan
try {
    $r = Invoke-WebRequest -Uri 'http://127.0.0.1:8000/health' -UseBasicParsing -TimeoutSec 5
    Write-Host "API: OK ($($r.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host 'API: NUK PUNON - shiko dritaren Shendet API' -ForegroundColor Red
}

try {
    $r = Invoke-WebRequest -Uri 'http://127.0.0.1:5001' -UseBasicParsing -TimeoutSec 5
    Write-Host "WEB: OK ($($r.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host 'WEB: NUK PUNON - shiko dritaren Shendet Web' -ForegroundColor Red
}

Write-Host ''
Write-Host 'Nese te dyja jane OK, hape vete ne browser:' -ForegroundColor White
Write-Host 'http://192.168.0.34:5001' -ForegroundColor Yellow
Write-Host ''
Write-Host 'Per ta ndaluar: kliko "Ndalo Shendet+" ose mbyll te dyja dritaret.' -ForegroundColor White
