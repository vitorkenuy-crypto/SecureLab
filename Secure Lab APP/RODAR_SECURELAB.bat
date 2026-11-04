@echo off
title SecureLab
cd /d "%~dp0"
echo ==================================================
echo   SecureLab - versao de teste
echo   Deixe esta janela aberta enquanto testa.
echo   Para desligar, feche esta janela.
echo ==================================================
echo.
if not exist "backend\app_web\index.html" (
  echo [ERRO] Esta pasta nao tem o app pronto.
  echo        Peca ao Gabriel o arquivo SecureLab_teste.zip mais recente.
  pause
  exit /b 1
)
set "PY="
call :acha_python
if not defined PY (
  echo.
  echo Instalando o Python 3.12, aguarde alguns minutos...
  where pymanager >nul 2>nul && pymanager install 3.12
  call :acha_python
)
if not defined PY (
  py install 3.12 2>nul
  call :acha_python
)
if not defined PY (
  winget install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements
  call :acha_python
)
if not defined PY (
  echo [ERRO] Nao consegui instalar o Python 3.12.
  echo        Instale pelo site python.org [versao 3.12, marque "Add python.exe to PATH"] e clique de novo.
  pause
  exit /b 1
)
echo [ok] Python 3.12 encontrado

if exist "backend\venv\Scripts\python.exe" (
  backend\venv\Scripts\python.exe -c "import sys; sys.exit(0 if sys.version_info[:2] in [(3,12),(3,13)] else 1)"
  if errorlevel 1 (
    echo Apagando o ambiente antigo da API, feito com outra versao do Python...
    rmdir /s /q backend\venv
  )
)
if not exist "backend\venv\Scripts\python.exe" (
  echo.
  echo Preparando a API pela primeira vez, pode levar alguns minutos...
  "%PY%" -m venv backend\venv
)
if not exist "backend\venv\Scripts\python.exe" (
  echo [ERRO] Nao consegui criar o ambiente da API. Mande um print desta tela.
  pause
  exit /b 1
)
if not exist "backend\venv\pronto.txt" (
  backend\venv\Scripts\python.exe -m pip install --upgrade pip --quiet
  backend\venv\Scripts\python.exe -m pip install -r backend\requirements-local.txt --only-binary=:all: --quiet
  if errorlevel 1 (
    echo [ERRO] Falha ao instalar as bibliotecas da API. Mande um print desta tela.
    pause
    exit /b 1
  )
  echo ok> backend\venv\pronto.txt
)
echo [ok] API pronta

echo.
echo Se o Windows perguntar sobre o Firewall, marque "Redes privadas" e clique em Permitir.
call :mostra_ips
echo Abrindo o app no navegador...
start "" /b powershell -NoProfile -Command "Start-Sleep 5; Start-Process 'http://localhost:8000/app/'"
cd backend
venv\Scripts\python.exe -m uvicorn main_local:app --host 0.0.0.0 --port 8000
pause
exit /b 0

:acha_python
for %%E in ("%LOCALAPPDATA%\Python\pythoncore-3.12-64\python.exe" "%LOCALAPPDATA%\Programs\Python\Python312\python.exe" "%LOCALAPPDATA%\Python\pythoncore-3.13-64\python.exe" "%LOCALAPPDATA%\Programs\Python\Python313\python.exe" "C:\Program Files\Python312\python.exe" "C:\Program Files\Python313\python.exe") do (
  if not defined PY if exist "%%~E" set "PY=%%~E"
)
exit /b 0

:mostra_ips
echo.
echo ==================================================
echo   Enderecos deste PC na rede Wi-Fi:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do for /f "tokens=*" %%b in ("%%a") do (
  echo     App no celular:  http://%%b:8000/app
  echo     API para o ESP32: http://%%b:8000/acessos
)
echo   Chaves do ESP32 [modo local]:
echo     dispositivo_id 1 = Porta Lab 1          chave: chave-lab1
echo     dispositivo_id 2 = Sala de Servidores   chave: chave-servidores
echo   Login do app: admin / admin123
echo ==================================================
echo.
exit /b 0
