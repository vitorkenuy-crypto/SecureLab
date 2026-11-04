@echo off
title SecureLab - gerar pacote para os colegas
cd /d "%~dp0"
echo ==================================================
echo   Gera o SecureLab_teste.zip na sua Area de Trabalho
echo   (app ja compilado: os colegas nao precisam de Flutter)
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

if not exist "mobile\web\index.html" (
  echo Preparando o app...
  powershell -NoProfile -ExecutionPolicy Bypass -File "mobile\configurar.ps1"
)

echo.
echo [1/3] Compilando o app para navegador (1 a 3 minutos)...
cd mobile
call flutter build web --release --base-href /app/
cd ..
if not exist "mobile\build\web\index.html" (
  echo [ERRO] A compilacao falhou. Mande um print desta tela para o Claude.
  pause
  exit /b 1
)
robocopy "mobile\build\web" "backend\app_web" /MIR /NFL /NDL /NJH /NJS >nul
echo [ok] App compilado em backend\app_web

echo.
echo [2/3] Separando os arquivos (sem senhas, ambientes e arquivos temporarios)...
set "ST=%TEMP%\SecureLab_pacote"
if exist "%ST%" rmdir /s /q "%ST%"
robocopy "%~dp0." "%ST%\SecureLab" /E /XD venv .dart_tool build APP .vscode .idea .git android ios linux macos windows __pycache__ /XF securelab_local.db pronto.txt .env *.pyc /NFL /NDL /NJH /NJS >nul
if not exist "%ST%\SecureLab\RODAR_SECURELAB.bat" (
  echo [ERRO] Falha ao copiar os arquivos. Mande um print desta tela.
  pause
  exit /b 1
)

echo [3/3] Compactando...
set "ZIP=%USERPROFILE%\Desktop\SecureLab_teste.zip"
if exist "%ZIP%" del /q "%ZIP%"
powershell -NoProfile -Command "Compress-Archive -Path '%ST%\SecureLab' -DestinationPath '%ZIP%' -Force"
rmdir /s /q "%ST%"
if not exist "%ZIP%" (
  echo [ERRO] Falha ao criar o zip. Mande um print desta tela.
  pause
  exit /b 1
)
echo.
echo Pronto! Arquivo criado: %ZIP%
echo Mande esse zip para os colegas. Eles extraem e clicam em RODAR_SECURELAB.bat
explorer /select,"%ZIP%"
pause
