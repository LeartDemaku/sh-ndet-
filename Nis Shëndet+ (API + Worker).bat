@echo off
chcp 65001 >nul
title Shendet+ - Nisja e backend-it
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\nis_backend.ps1"
echo.
pause
