# SecureLab - configuracao do app mobile (rode UMA vez, dentro da pasta mobile)
#   PowerShell:  .\configurar.ps1
# Se o Windows bloquear o script:  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter nao encontrado no PATH. Instale: https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Red
    exit 1
}

# 1) Gera as pastas android/ e ios/ (nao sobrescreve lib/ nem pubspec.yaml)
Write-Host "`n[1/4] Gerando projeto (navegador, Android, iOS)..." -ForegroundColor Cyan
flutter create . --project-name securelab_app --org br.edu.unipam --platforms web,android,ios

# 2) Libera HTTP (a API local roda sem HTTPS) e garante permissao de internet
Write-Host "`n[2/4] Ajustando AndroidManifest..." -ForegroundColor Cyan
$manifest = "android\app\src\main\AndroidManifest.xml"
if (Test-Path $manifest) {
$xml = Get-Content $manifest -Raw
if ($xml -notmatch "usesCleartextTraffic") {
    $xml = $xml -replace "<application", "<application`n        android:usesCleartextTraffic=`"true`""
}
if ($xml -notmatch "android.permission.INTERNET") {
    $xml = $xml -replace "<application", "<uses-permission android:name=`"android.permission.INTERNET`"/>`n    <application"
}
Set-Content -Path $manifest -Value $xml -Encoding UTF8
}

# 3) Baixa os icones do prototipo Figma (links validos ate ~08/11/2026)
Write-Host "`n[3/4] Baixando icones do Figma..." -ForegroundColor Cyan
$icons = @(
    @("shield_blue", "https://www.figma.com/api/mcp/asset/fab8b13b-2755-4e6f-aaf1-c24806338d82/ed31f.png"),
    @("fingerprint_blue", "https://www.figma.com/api/mcp/asset/fab8b13b-2755-4e6f-aaf1-c24806338d82/2d97d.png"),
    @("lock", "https://www.figma.com/api/mcp/asset/fab8b13b-2755-4e6f-aaf1-c24806338d82/6296a.png"),
    @("eye", "https://www.figma.com/api/mcp/asset/fab8b13b-2755-4e6f-aaf1-c24806338d82/e09c6.png"),
    @("user_white", "https://www.figma.com/api/mcp/asset/fab8b13b-2755-4e6f-aaf1-c24806338d82/dc319.png"),
    @("shield_white", "https://www.figma.com/api/mcp/asset/bae8b5aa-1040-43b2-8c36-b4ce9e095536/afb9f.png"),
    @("fingerprint_white", "https://www.figma.com/api/mcp/asset/bae8b5aa-1040-43b2-8c36-b4ce9e095536/eb80a.png"),
    @("bell_white", "https://www.figma.com/api/mcp/asset/bae8b5aa-1040-43b2-8c36-b4ce9e095536/600e8.png"),
    @("nav_config", "https://www.figma.com/api/mcp/asset/bae8b5aa-1040-43b2-8c36-b4ce9e095536/3094f.png"),
    @("nav_history", "https://www.figma.com/api/mcp/asset/bae8b5aa-1040-43b2-8c36-b4ce9e095536/90ab2.png"),
    @("nav_door", "https://www.figma.com/api/mcp/asset/bae8b5aa-1040-43b2-8c36-b4ce9e095536/621dc.png"),
    @("nav_users", "https://www.figma.com/api/mcp/asset/bae8b5aa-1040-43b2-8c36-b4ce9e095536/fd8d0.png"),
    @("nav_home_active", "https://www.figma.com/api/mcp/asset/bae8b5aa-1040-43b2-8c36-b4ce9e095536/65e7f.png"),
    @("cancel", "https://www.figma.com/api/mcp/asset/bae8b5aa-1040-43b2-8c36-b4ce9e095536/b7cbf.png"),
    @("enter", "https://www.figma.com/api/mcp/asset/bae8b5aa-1040-43b2-8c36-b4ce9e095536/e2d6b.png"),
    @("door_dark", "https://www.figma.com/api/mcp/asset/bae8b5aa-1040-43b2-8c36-b4ce9e095536/d4635.png"),
    @("user_dark", "https://www.figma.com/api/mcp/asset/bae8b5aa-1040-43b2-8c36-b4ce9e095536/39870.png"),
    @("server_blue", "https://www.figma.com/api/mcp/asset/bae8b5aa-1040-43b2-8c36-b4ce9e095536/fad0c.png"),
    @("check_blue", "https://www.figma.com/api/mcp/asset/bae8b5aa-1040-43b2-8c36-b4ce9e095536/1fc07.png"),
    @("nav_users_active", "https://www.figma.com/api/mcp/asset/60dc13a7-5cf9-4c9b-a251-814e1d5e4ff5/54bb3.png"),
    @("nav_home", "https://www.figma.com/api/mcp/asset/60dc13a7-5cf9-4c9b-a251-814e1d5e4ff5/33e0b.png"),
    @("arrow_back", "https://www.figma.com/api/mcp/asset/60dc13a7-5cf9-4c9b-a251-814e1d5e4ff5/2e251.png"),
    @("loading_ring", "https://www.figma.com/api/mcp/asset/60dc13a7-5cf9-4c9b-a251-814e1d5e4ff5/21819.png"),
    @("forward", "https://www.figma.com/api/mcp/asset/613f1bf4-7632-4c66-8a77-d28590306904/0ab0f.png"),
    @("search", "https://www.figma.com/api/mcp/asset/613f1bf4-7632-4c66-8a77-d28590306904/85c5e.png"),
    @("plus", "https://www.figma.com/api/mcp/asset/613f1bf4-7632-4c66-8a77-d28590306904/62df5.png"),
    @("workstation", "https://www.figma.com/api/mcp/asset/dd4a8bfb-95dd-45c9-86d8-d808f4c9d035/c1b6a.png"),
    @("adjust", "https://www.figma.com/api/mcp/asset/dd4a8bfb-95dd-45c9-86d8-d808f4c9d035/36024.png"),
    @("server_white", "https://www.figma.com/api/mcp/asset/dd4a8bfb-95dd-45c9-86d8-d808f4c9d035/adfd0.png"),
    @("nav_history_active", "https://www.figma.com/api/mcp/asset/10550e95-b01a-4f0b-86af-96d3df6cfffc/4f03d.png"),
    @("download", "https://www.figma.com/api/mcp/asset/10550e95-b01a-4f0b-86af-96d3df6cfffc/4fb12.png"),
    @("nav_config_active", "https://www.figma.com/api/mcp/asset/e67f3bf3-965b-4cea-bf66-30b5113aae7a/5b0ec.png"),
    @("bell_blue", "https://www.figma.com/api/mcp/asset/e67f3bf3-965b-4cea-bf66-30b5113aae7a/1ee1c.png"),
    @("check_blue_2", "https://www.figma.com/api/mcp/asset/e67f3bf3-965b-4cea-bf66-30b5113aae7a/cb536.png")
)
New-Item -ItemType Directory -Force -Path "assets\icons" | Out-Null
$falhas = 0
foreach ($i in $icons) {
    $dest = "assets\icons\$($i[0]).png"
    try {
        Invoke-WebRequest -Uri $i[1] -OutFile $dest -UseBasicParsing
        Write-Host "  ok  $($i[0])"
    } catch {
        Write-Host "  falhou  $($i[0])" -ForegroundColor Yellow
        $falhas++
    }
}
if ($falhas -gt 0) {
    Write-Host "  $falhas icones nao baixaram. O app usa icones padrao no lugar deles." -ForegroundColor Yellow
}

# 4) Dependencias
Write-Host "`n[4/4] flutter pub get..." -ForegroundColor Cyan
flutter pub get

Write-Host "`nPronto! Suba a API e rode:  flutter run" -ForegroundColor Green
