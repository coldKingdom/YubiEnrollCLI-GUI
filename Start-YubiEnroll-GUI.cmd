@echo off
pwsh.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0YubiEnroll-GUI.ps1"
if errorlevel 1 pause
