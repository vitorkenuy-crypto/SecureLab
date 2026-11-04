# SecureLab - prepara TUDO para rodar no VS Code (rode UMA vez, na pasta Secure Lab):
#   powershell -ExecutionPolicy Bypass -File tools\preparar.ps1
$raiz = Split-Path $PSScriptRoot -Parent
Set-Location $raiz

function Passo($m) { Write-Host "`n$m" -ForegroundColor Cyan }
function Ok($m)    { Write-Host "  ok  $m" -ForegroundColor Green }
function Falha($m) { Write-Host "`n  ERRO: $m`n" -ForegroundColor Red; exit 1 }

Passo "[1/4] Conferindo Python e Flutter..."
$py = ""
try { $py = (& python --version 2>&1) | Out-String } catch {}
if ($py -notmatch "Python 3") {
    Falha "Python nao encontrado. No terminal do VS Code rode:  winget install -e --id Python.Python.3.12   Depois feche e abra o VS Code e rode este script de novo."
}
Ok $py.Trim()
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Falha "Flutter nao encontrado. Veja o passo 2 do guia (Flutter: New Project > Download SDK > Add SDK to PATH) e reabra o VS Code."
}
Ok "Flutter encontrado"

Passo "[2/4] Preparando a API (ambiente Python + bibliotecas)... pode levar alguns minutos"
Set-Location "$raiz\backend"
if (-not (Test-Path "venv\Scripts\python.exe")) { python -m venv venv }
if (-not (Test-Path "venv\Scripts\python.exe")) { Falha "nao consegui criar o ambiente Python (backend\venv)." }
& .\venv\Scripts\python.exe -m pip install --upgrade pip --quiet
& .\venv\Scripts\python.exe -m pip install -r requirements.txt --quiet
if ($LASTEXITCODE -ne 0) { Falha "pip install falhou. Copie a mensagem acima e mande para o Claude." }
Ok "API pronta"

Passo "[3/4] Configurando o VS Code (botao F5 e tarefas)..."
Set-Location $raiz
New-Item -ItemType Directory -Force -Path ".vscode" | Out-Null
Copy-Item "tools\vscode\*" ".vscode" -Force
Ok "pasta .vscode criada"

Passo "[4/4] Preparando o app (Flutter)..."
& "$raiz\mobile\configurar.ps1"
Set-Location $raiz

Write-Host "`nTudo pronto!" -ForegroundColor Green
Write-Host "Agora: Ctrl+Shift+D  >  escolha 'SecureLab (tudo local)'  >  F5" -ForegroundColor Green
