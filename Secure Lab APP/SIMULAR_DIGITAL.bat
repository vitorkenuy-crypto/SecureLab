@echo off
title SecureLab - Simulador do ESP32
cd /d "%~dp0"
echo ==================================================
echo   Simulador do sensor de digital (ESP32 + R307)
echo   Deixe o SecureLab ligado antes de usar.
echo.
echo   Digitais de exemplo:
echo     1 = Ana (ativa)        2 = Bruno (ativo)
echo     3 = Carla (inativa)   99 = desconhecida
echo   Portas: 1 = Porta Lab 1   2 = Sala de Servidores
echo ==================================================
:de_novo
echo.
set "T="
set "D="
set /p T=Numero da digital (ou Enter para sair): 
if "%T%"=="" exit /b 0
set /p D=Porta 1 ou 2 [1]: 
if "%D%"=="" set "D=1"
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\simular_esp32.ps1" -Template %T% -Dispositivo %D%
goto de_novo
