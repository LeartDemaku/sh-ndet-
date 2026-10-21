@echo off
chcp 65001 >nul
title Shendet+ - Instalimi i WSL2 (kerkohet per Docker)

:: =====================================================================
::  Ky skript instalon komponentet e WSL2 qe Docker Desktop-i i kerkon.
::  Duhet te ekzekutohet me te drejta Administratori (do te pyetese).
::  Pas ekzekutimit duhet RIISJER kompjuteri.
:: =====================================================================

echo.
echo  ========================================================
echo   SHENDET+ - Instalimi i WSL2 per Docker
echo  ========================================================
echo.

:: 1) Verifiko nese jemi Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo  [!] Ky skript kerkon te drejta Administratori.
    echo  Po hapim nje dritare te re me privilegj...
    echo      Prano kerkesen "User Account Control" (Po).
    echo.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo  [1/3] Instaloj komponentet e WSL2...
echo.
wsl --install --no-distribution
echo.

echo  [2/3] Gjendja pas instalimit:
echo  --------------------------------------------------------
wsl --status
echo  --------------------------------------------------------
echo.

echo  [3/3] PËRFUNDON.
echo.
echo  => Mbyll kete dritare.
echo  => RIIS kompjuterin tani.
echo  => Pas ri-nisjes hap "Docker Desktop" dhe prit derisa
echo     te shfaqet "Engine running".
echo  => Pastaj kthehu te projekti dhe thuaj "u ri-nisa".
echo.
pause
