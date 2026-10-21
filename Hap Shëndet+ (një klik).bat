@echo off
chcp 65001 >nul
title Shendet+ - Hap aplikacionin
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\hap_app.ps1"
echo.
pause
