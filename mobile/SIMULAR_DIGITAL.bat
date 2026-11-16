@echo off
title SecureLab - Simulador do ESP32
cd /d "%~dp0"
echo ==================================================
echo   Simulador do sensor de digital (ESP32 + R307)
echo   Deixe o SecureLab ligado antes de usar.
echo.
echo   Use o ID e a chave criados no backend principal.
echo ==================================================
:de_novo
echo.
set "T="
set "D="
set "K="
set /p T=Numero da digital (ou Enter para sair): 
if "%T%"=="" exit /b 0
set /p D=ID do dispositivo: 
if "%D%"=="" goto de_novo
set /p K=Chave de API do dispositivo: 
if "%K%"=="" goto de_novo
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\simular_esp32.ps1" -Template %T% -Dispositivo %D% -Chave "%K%"
goto de_novo
