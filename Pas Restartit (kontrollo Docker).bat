@echo off
chcp 65001 >nul
title Shendet+ - Kontroll pas restartit dhe nisja e Docker

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\pas_restartit.ps1"

echo.
echo  ------------------------------------------------
echo   Nese cdo gje doli OK, kthehu te OpenCode
echo   dhe shkruaj:  u ri-nisa
echo  ------------------------------------------------
echo.
pause
