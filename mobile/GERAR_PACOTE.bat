@echo off
title SecureLab - compilar aplicativo web
cd /d "%~dp0"
echo ==================================================
echo   Compila o cliente Flutter sem copiar backend ou firmware.
echo ==================================================
echo.
where flutter >nul 2>nul
if errorlevel 1 (
  for %%P in ("%USERPROFILE%\Desktop\securelab_app\flutter\bin" "C:\src\flutter\bin" "%USERPROFILE%\flutter\bin" "%LOCALAPPDATA%\flutter\bin" "%USERPROFILE%\Documents\flutter\bin") do (
    if exist "%%~P\flutter.bat" set "PATH=%%~P;%PATH%"
  )
)
where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERRO] Nao encontrei o Flutter. Mande um print desta tela para o Claude.
  pause
  exit /b 1
)
echo [ok] Flutter encontrado

if not exist "web\index.html" (
  echo Preparando o app...
  powershell -NoProfile -ExecutionPolicy Bypass -File "configurar.ps1"
)

echo.
echo [1/3] Compilando o app para navegador (1 a 3 minutos)...
call flutter build web --release
if not exist "build\web\index.html" (
  echo [ERRO] A compilacao falhou. Mande um print desta tela para o Claude.
  pause
  exit /b 1
)
echo [ok] App compilado em build\web
echo Para publicar, hospede essa pasta e configure a origem no CORS_ORIGIN_REGEX
echo do backend principal, se ela nao for localhost.
pause
