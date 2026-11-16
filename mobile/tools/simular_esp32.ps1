# SecureLab - simula o ESP32 enviando uma leitura de digital para a API.
# Mais facil: no VS Code, Ctrl+Shift+P > "Tasks: Run Task" > "Simular leitura do ESP32".
# Pelo terminal:
#   powershell -ExecutionPolicy Bypass -File tools\simular_esp32.ps1 -Template 1
#   powershell -ExecutionPolicy Bypass -File tools\simular_esp32.ps1 -Template 2 -Dispositivo 2
# Informe sempre a chave criada pelo backend principal para o dispositivo.
param(
    [int]$Template = 1,
    [int]$Dispositivo = 1,
    [Parameter(Mandatory = $true)]
    [string]$Chave,
    [string]$Api = "http://127.0.0.1:8000"
)

Write-Host "Lendo digital... template $Template no dispositivo $Dispositivo"
$body = @{ dispositivo_id = $Dispositivo; template_id_lido = $Template } | ConvertTo-Json
try {
    $r = Invoke-RestMethod -Method Post -Uri "$Api/acessos" `
        -Headers @{ "X-API-Key" = $Chave } -ContentType "application/json" -Body $body
    if ($r.resultado -eq "AUTORIZADO") {
        Write-Host "AUTORIZADO  (usuario $($r.usuario_id))  -> fechadura abre, LED verde" -ForegroundColor Green
    } else {
        Write-Host "NEGADO  -> fechadura trancada, LED vermelho + buzzer" -ForegroundColor Red
    }
} catch {
    $resp = $_.Exception.Response
    if ($resp -and [int]$resp.StatusCode -eq 401) {
        Write-Host "401: dispositivo inexistente ou chave errada." -ForegroundColor Yellow
    } else {
        Write-Host "Nao consegui falar com a API em $Api. Ela esta rodando? ($($_.Exception.Message))" -ForegroundColor Yellow
    }
}
