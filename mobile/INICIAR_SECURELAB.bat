@echo off
setlocal
title SecureLab - app + backend principal

rem Esta pasta contem somente o cliente Flutter. A API e o firmware sao os
rem diretorios originais ao lado dela, e nunca as copias historicas daqui.
for %%I in ("%~dp0..") do set "WORKSPACE=%%~fI"
set "BACKEND=%WORKSPACE%\backend"

if not exist "%BACKEND%\main.py" (
  echo [ERRO] Backend principal nao encontrado em "%BACKEND%".
  pause
  exit /b 1
)
if not exist "%BACKEND%\.env" (
  echo [ERRO] Configure "%BACKEND%\.env" a partir de .env.example antes de iniciar.
  pause
  exit /b 1
)
where flutter >nul 2>nul || (
  echo [ERRO] Flutter nao encontrado no PATH.
  pause
  exit /b 1
)

if not exist "%BACKEND%\venv\Scripts\python.exe" (
  echo Criando ambiente Python no backend principal...
  python -m venv "%BACKEND%\venv" || goto :erro
  "%BACKEND%\venv\Scripts\python.exe" -m pip install -r "%BACKEND%\requirements.txt" || goto :erro
)

echo Iniciando o backend principal em http://127.0.0.1:8000 ...
start "SecureLab API (principal)" /D "%BACKEND%" cmd /k ""%BACKEND%\venv\Scripts\python.exe" -m uvicorn main:app --host 0.0.0.0 --port 8000"
echo Iniciando o aplicativo Flutter no Chrome...
cd /d "%~dp0"
call flutter pub get || goto :erro
call flutter run -d chrome
if errorlevel 1 call flutter run -d edge
exit /b %errorlevel%

:erro
echo [ERRO] Nao foi possivel iniciar o SecureLab.
pause
exit /b 1
