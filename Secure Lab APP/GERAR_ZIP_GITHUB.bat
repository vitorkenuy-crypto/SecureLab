@echo off
title SecureLab - gerar zip para o GitHub
cd /d "%~dp0"
echo ==================================================
echo   Gera o SecureLab_GitHub.zip na sua Area de Trabalho
echo   (codigo-fonte + app ja compilado, sem arquivos temporarios)
echo ==================================================
echo.
if not exist "backend\app_web\index.html" (
  echo [ERRO] Falta o app compilado em backend\app_web.
  echo        Rode o GERAR_PACOTE.bat primeiro e depois este arquivo de novo.
  pause
  exit /b 1
)

echo [1/2] Separando os arquivos...
set "ST=%TEMP%\SecureLab_github"
if exist "%ST%" rmdir /s /q "%ST%"
robocopy "%~dp0." "%ST%\SecureLab" /E /XD venv .dart_tool build APP .idea .git .gradle __pycache__ ephemeral chrome-device /XF securelab_local.db pronto.txt .env *.pyc *.zip *.iml local.properties .flutter-plugins-dependencies Generated.xcconfig flutter_export_environment.sh /NFL /NDL /NJH /NJS >nul
if not exist "%ST%\SecureLab\README.md" (
  echo [ERRO] Falha ao copiar os arquivos. Mande um print desta tela.
  pause
  exit /b 1
)

echo [2/2] Compactando...
set "ZIP=%USERPROFILE%\Desktop\SecureLab_GitHub.zip"
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
echo Extraia o zip e siga a Parte 3 do README.md para subir no GitHub.
explorer /select,"%ZIP%"
pause
