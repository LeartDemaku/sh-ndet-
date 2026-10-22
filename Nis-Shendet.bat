@echo off
setlocal
title Nis Shendet+
cd /d "%~dp0"

if not exist "C:\dev\shendetplus\backend\.venv\Scripts\python.exe" (
  echo Gabim: nuk u gjet Python i projektit.
  pause
  exit /b 1
)

if not exist "C:\dev\shendetplus\mobile\build\web\index.html" (
  echo Gabim: nuk u gjet build-i i web-it.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start-dev.ps1"
echo.
echo Kjo dritare mbyllet vete pas pak sekondash.
ping -n 11 127.0.0.1 >nul