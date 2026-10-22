@echo off
title Ndalo Shendet+
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\stop-dev.ps1"
echo.
echo Kjo dritare mbyllet vete pas pak sekondash.
ping -n 5 127.0.0.1 >nul