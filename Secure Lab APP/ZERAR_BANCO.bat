@echo off
cd /d "%~dp0"
echo Isto apaga os dados de teste e volta aos dados de exemplo.
echo Feche antes a janela preta do SecureLab.
pause
del /q "backend\securelab_local.db" 2>nul
echo Pronto. Clique de novo em RODAR_SECURELAB.bat [ou INICIAR_SECURELAB.bat].
pause
