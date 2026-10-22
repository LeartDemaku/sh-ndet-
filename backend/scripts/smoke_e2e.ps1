# =====================================================================
#  Shendet+ - Smoke test end-to-end (API reale, DB reale, Redis real)
#  Kerkon: uvicorn duke degjuar ne http://127.0.0.1:8000
#  Perdorimi:  .\scripts\smoke_e2e.ps1
#  Krijon nje user test-*, e fshin ne fund.
# =====================================================================

param(
    [string]$Base = 'http://127.0.0.1:8000',
    [switch]$KeepUser
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$backend = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$py      = Join-Path $backend '.venv\Scripts\python.exe'

$script:pass = 0
$script:fail = 0

function Check([string]$name, [bool]$ok, [string]$detail = '') {
    if ($ok) {
        $script:pass++
        Write-Host ("  [OK]    " + $name) -ForegroundColor Green
    } else {
        $script:fail++
        Write-Host ("  [FAIL]  " + $name + $(if ($detail) { "  -> $detail" } else { "" })) -ForegroundColor Red
    }
}

function Invoke-Api {
    param([string]$Method, [string]$Path, $Body, [string]$Token)
    $headers = @{}
    if ($Token) { $headers['Authorization'] = "Bearer $Token" }
    $params = @{
        Method         = $Method
        Uri            = "$Base$Path"
        Headers        = $headers
        UseBasicParsing = $true
        TimeoutSec     = 120
    }
    if ($null -ne $Body) {
        $json = $Body | ConvertTo-Json -Compress -Depth 10
        $params['ContentType'] = 'application/json; charset=utf-8'
        $params['Body'] = [System.Text.Encoding]::UTF8.GetBytes($json)
    }
    try {
        $r = Invoke-WebRequest @params
        return [pscustomobject]@{ Status = [int]$r.StatusCode; Content = $r.Content }
    } catch {
        $resp = $_.Exception.Response
        if ($resp) {
            $code = [int]$resp.StatusCode
            $stream = $resp.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $txt = $reader.ReadToEnd()
            return [pscustomobject]@{ Status = $code; Content = $txt }
        }
        return [pscustomobject]@{ Status = 0; Content = $_.Exception.Message }
    }
}

# Vetëm për smoke-test lokal: kodi krijohet në DB, pa dërguar email.
# Skripti refuzon production dhe çdo adresë jo-test.
function Get-DevVerificationCode([string]$Email) {
    Push-Location $backend
    try {
        $out = & $py 'scripts\dev_email_code.py' $Email 2>$null
        $code = ($out | Select-Object -Last 1).ToString().Trim()
    } finally {
        Pop-Location
    }
    if ($code -notmatch '^\d{6}$') {
        throw "Nuk u krijua kod verifikimi për $Email"
    }
    return $code
}

Write-Host ""
Write-Host "=========================================================="
Write-Host "  SHENDET+ - SMOKE TEST END-TO-END"
Write-Host "  $Base"
Write-Host "=========================================================="
Write-Host ""

# ---------------------------------------------------------------
Write-Host "1) Shendeti i API-se"
$h = Invoke-Api GET '/health'
Check 'GET /health -> 200' ($h.Status -eq 200) $h.Content

# ---------------------------------------------------------------
$stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$email  = "test-$stamp@example.com"
$passwd = 'TestFjalekalim123!'

Write-Host ""
Write-Host "2) Regjistrimi, kodi i emailit dhe autentikimi"
$reg = Invoke-Api POST '/v1/auth/register' @{
    first_name = 'Test'; last_name = 'User'
    email = $email; password = $passwd; country = 'XK'
    accept_terms = $true; accept_health_data = $true
}
Check 'POST /v1/auth/register -> 201' ($reg.Status -eq 201) $reg.Content
$regJson = $reg.Content | ConvertFrom-Json
Check 'kerkohet verifikim i emailit' ($regJson.verification_required -eq $true)
Check 'asnje token para verifikimit' (-not $regJson.access_token)
Check 'email_sent=false per @example.com' ($regJson.email_sent -eq $false)

$dup = Invoke-Api POST '/v1/auth/register' @{
    first_name = 'Test'; last_name = 'User'
    email = $email; password = $passwd; country = 'XK'
    accept_terms = $true; accept_health_data = $true
}
Check 'regjistrim i dyfishte -> 409' ($dup.Status -eq 409) ("status=" + $dup.Status)

$bad = Invoke-Api POST '/v1/auth/login' @{ email = $email; password = 'gabim-i-gabim' }
Check 'login me fjalekalim te gabuar -> 401' ($bad.Status -eq 401) ("status=" + $bad.Status)

$unverified = Invoke-Api POST '/v1/auth/login' @{ email = $email; password = $passwd }
Check 'login para verifikimit -> 403' ($unverified.Status -eq 403) ("status=" + $unverified.Status)

$resendEarly = Invoke-Api POST '/v1/auth/resend-verification' @{ email = $email }
Check 'ridergim brenda cooldown -> 429' ($resendEarly.Status -eq 429) ("status=" + $resendEarly.Status)

$code = Get-DevVerificationCode $email
$wrongCode = if ($code -eq '000000') { '999999' } else { '000000' }
$wrong = Invoke-Api POST '/v1/auth/verify-email' @{ email = $email; code = $wrongCode }
Check 'kod i gabuar -> 400' ($wrong.Status -eq 400) ("status=" + $wrong.Status)

$verify = Invoke-Api POST '/v1/auth/verify-email' @{ email = $email; code = $code }
Check 'POST /v1/auth/verify-email -> 200' ($verify.Status -eq 200) $verify.Content
$token = ($verify.Content | ConvertFrom-Json).access_token
Check 'token pas verifikimit' ([bool]$token)

$login = Invoke-Api POST '/v1/auth/login' @{ email = $email; password = $passwd }
Check 'POST /v1/auth/login pas verifikimit -> 200' ($login.Status -eq 200) $login.Content
$token = ($login.Content | ConvertFrom-Json).access_token

$me = Invoke-Api GET '/v1/me' $null $token
Check 'GET /v1/me -> 200' ($me.Status -eq 200) $me.Content
$meJson = $me.Content | ConvertFrom-Json
Check 'email i sakte' ($meJson.profile.email -eq $email) $meJson.profile.email
Check 'emri i sakte' ($meJson.profile.first_name -eq 'Test') $meJson.profile.first_name
Check 'mbiemri i sakte' ($meJson.profile.last_name -eq 'User') $meJson.profile.last_name
Check 'pelqimi terms i dhene' ([bool]($meJson.consents | Where-Object { $_.kind -eq 'terms' -and $_.granted }))
Check 'pelqimi health_data i dhene' ([bool]($meJson.consents | Where-Object { $_.kind -eq 'health_data' -and $_.granted }))

# ---------------------------------------------------------------
Write-Host ""
Write-Host "3) SSE - rruga e emergjences (deterministike, pa LLM)"
$em = Invoke-Api POST '/v1/chat/stream' @{ message = 'Kam dhimbje te forta ne gjoks dhe nuk mund te marr fryme' } $token
Check 'POST /v1/chat/stream -> 200' ($em.Status -eq 200) ("status=" + $em.Status)
Check 'event: meta' ($em.Content -match 'event: meta')
Check 'event: emergency' ($em.Content -match 'event: emergency')

# Vetëm data-rreshti i ngjarjes "emergency" kontrollohet për numrin; UUID-ja
# e bisedës mund të përmbajë shifra të çfarëdoshme dhe nuk duhet të ndikojë.
$emLines = $em.Content -split "`r?`n"
$emIndex = [array]::IndexOf($emLines, 'event: emergency')
$emData = if ($emIndex -ge 0 -and $emIndex + 1 -lt $emLines.Count -and
              $emLines[$emIndex + 1].StartsWith('data:')) {
    $emLines[$emIndex + 1].Substring(5).Trim()
} else { '' }
Check 'numri 194 në mesazhin e emergjencës' ($emData -match '194') $emData
Check 'mesazhi i emergjencës nuk përmban 112' (-not ($emData -match '112')) $emData
Check 'event: done' ($em.Content -match 'event: done')

$exp1 = Invoke-Api GET '/v1/me/export' $null $token
$e1 = $exp1.Content | ConvertFrom-Json
$conv1 = @($e1.conversations) | Select-Object -First 1
Check 'eksporti ka 1 bisede' (@($e1.conversations).Count -eq 1) ("count=" + @($e1.conversations).Count)
Check 'biseda ka 2 mesazhe (user + assistant)' ($null -ne $conv1 -and @($conv1.messages).Count -eq 2) ("count=" + $(if ($conv1) { @($conv1.messages).Count } else { 'n/a' }))
Check 'mesazhi i asistences ka safety_level=emergency' ($null -ne $conv1 -and ($conv1.messages | Where-Object { $_.role -eq 'assistant' }).safety_level -eq 'emergency')

# ---------------------------------------------------------------
Write-Host ""
Write-Host "4) SSE - rruga jo-emergjente (pergjigje LLM ose gabim i kontrolluar)"
$norm = Invoke-Api POST '/v1/chat/stream' @{ message = 'Cfare eshte diabeti?' } $token
Check 'POST /v1/chat/stream -> 200' ($norm.Status -eq 200) ("status=" + $norm.Status)
Check 'pergjigje ose gabim i kontrolluar' (($norm.Content -match 'event: token') -or ($norm.Content -match 'event: blocked') -or ($norm.Content -match 'event: error'))
Check 'event: done' ($norm.Content -match 'event: done')
Check 'pa crash (nuk kthen 500)' ($norm.Status -ne 500)

# ---------------------------------------------------------------
Write-Host ""
Write-Host "5) Privatesia - terheqja e pelqimit per historik"
$expMid = Invoke-Api GET '/v1/me/export' $null $token
$eMid = $expMid.Content | ConvertFrom-Json
$convBefore = @($eMid.conversations).Count
$msgsBefore = (@($eMid.conversations) | ForEach-Object { @($_.messages).Count } | Measure-Object -Sum).Sum
if ($null -eq $msgsBefore) { $msgsBefore = 0 }
Write-Host ("     para terheqjes: " + $convBefore + " bisede, " + $msgsBefore + " mesazhe")

$rev = Invoke-Api PUT '/v1/me/consents/history' @{ granted = $false } $token
Check 'PUT /v1/me/consents/history (granted=false) -> 200' ($rev.Status -eq 200) $rev.Content

$em2 = Invoke-Api POST '/v1/chat/stream' @{ message = 'Nuk mund te marr fryme' } $token
Check 'emergjenca funksionon edhe pa historik' ($em2.Content -match 'event: emergency')

$exp2 = Invoke-Api GET '/v1/me/export' $null $token
$e2 = $exp2.Content | ConvertFrom-Json
$convAfter = @($e2.conversations).Count
$msgsAfter = (@($e2.conversations) | ForEach-Object { @($_.messages).Count } | Measure-Object -Sum).Sum
if ($null -eq $msgsAfter) { $msgsAfter = 0 }
Write-Host ("     pas terheqjes:  " + $convAfter + " bisede, " + $msgsAfter + " mesazhe")
Check 'asnje bisede e re nuk u ruajt' ($convAfter -eq $convBefore) ("para=$convBefore pas=$convAfter")
Check 'asnje mesazh i re nuk u ruajt' ($msgsAfter -eq $msgsBefore) ("para=$msgsBefore pas=$msgsAfter")

$reg2 = Invoke-Api PUT '/v1/me/consents/history' @{ granted = $true } $token
Check 'rikthimi i pelqimit -> 200' ($reg2.Status -eq 200) $reg2.Content

# ---------------------------------------------------------------
Write-Host ""
Write-Host "6) Izolimi mes perdoruesve"
$emailB = "test-b-$stamp@example.com"
$regB = Invoke-Api POST '/v1/auth/register' @{
    first_name = 'Test'; last_name = 'User B'
    email = $emailB; password = $passwd; country = 'XK'
    accept_terms = $true; accept_health_data = $true
}
Check 'regjistrimi i perdoruesit B -> 201' ($regB.Status -eq 201) $regB.Content
$codeB = Get-DevVerificationCode $emailB
$verifyB = Invoke-Api POST '/v1/auth/verify-email' @{ email = $emailB; code = $codeB }
Check 'verifikimi i perdoruesit B -> 200' ($verifyB.Status -eq 200) $verifyB.Content
$tokenB = ($verifyB.Content | ConvertFrom-Json).access_token

$convA = @($e2.conversations)[0].id
$cross = Invoke-Api POST '/v1/chat/stream' @{ message = 'pershendetje'; conversation_id = $convA } $tokenB
Check 'B nuk mund te perdore biseden e A -> 404' ($cross.Status -eq 404) ("status=" + $cross.Status)

$expB = Invoke-Api GET '/v1/me/export' $null $tokenB
$eB = $expB.Content | ConvertFrom-Json
Check 'B nuk sheh te dhenat e A' (@($eB.conversations).Count -eq 0) ("count=" + @($eB.conversations).Count)

# ---------------------------------------------------------------
Write-Host ""
Write-Host "7) Fshirja e bisedave dhe kategorive te vecanta"
$convCount = @($e2.conversations).Count
$crossDel = Invoke-Api DELETE "/v1/me/conversations/$convA" $null $tokenB
Check 'B nuk mund te fshije biseden e A -> 404' ($crossDel.Status -eq 404) ("status=" + $crossDel.Status)

$delOne = Invoke-Api DELETE "/v1/me/conversations/$convA" $null $token
Check 'A fshin nje bisede -> 200' ($delOne.Status -eq 200) $delOne.Content
$expOne = Invoke-Api GET '/v1/me/export' $null $token
$eOne = $expOne.Content | ConvertFrom-Json
Check 'biseda u hoq nga eksporti' (@($eOne.conversations).Count -eq ($convCount - 1)) ("para=$convCount pas=" + @($eOne.conversations).Count)

$delAll = Invoke-Api DELETE '/v1/me/conversations' $null $token
Check 'A fshin te gjitha bisedat -> 200' ($delAll.Status -eq 200) $delAll.Content
$expAll = Invoke-Api GET '/v1/me/export' $null $token
$eAll = $expAll.Content | ConvertFrom-Json
Check 'nuk mbeti asnje bisede' (@($eAll.conversations).Count -eq 0) ("count=" + @($eAll.conversations).Count)

$delMeds = Invoke-Api DELETE '/v1/me/medications' $null $token
Check 'A fshin te gjitha ilacet -> 200' ($delMeds.Status -eq 200) $delMeds.Content

Invoke-Api DELETE '/v1/me' @{ confirm = $true } $tokenB | Out-Null

# ---------------------------------------------------------------
Write-Host ""
Write-Host "8) Fshirja e llogarise (e drejta per t'u harruar)"
if ($KeepUser) {
    Write-Host "  [SKIP]  -KeepUser u dha" -ForegroundColor Yellow
} else {
    $del = Invoke-Api DELETE '/v1/me' @{ confirm = $true } $token
    Check 'DELETE /v1/me -> 200' ($del.Status -eq 200) $del.Content

    $after = Invoke-Api GET '/v1/me' $null $token
    Check 'token-i i vjeter nuk vlen me (401)' ($after.Status -eq 401) ("status=" + $after.Status)
}

# ---------------------------------------------------------------
Write-Host ""
Write-Host "=========================================================="
Write-Host ("  REZULTAT:  " + $script:pass + " OK / " + $script:fail + " FAIL")
Write-Host "=========================================================="
Write-Host ""

if ($script:fail -gt 0) { exit 1 } else { exit 0 }
