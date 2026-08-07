# Script de Build para Flutter Web
# Este script compila o projeto usando o renderizador CanvasKit e organiza arquivos do Drift.

$ErrorActionPreference = "Stop"

Write-Host "--- Iniciando processo de Build Web ---" -ForegroundColor Cyan

# 0. Definir pasta de distribuição fora da pasta 'build'
$distPath = "dist\web"
if (-not (Test-Path "dist")) { New-Item -ItemType Directory -Path "dist" | Out-Null }
if (Test-Path $distPath) { Remove-Item $distPath -Recurse -Force }
New-Item -ItemType Directory -Path $distPath | Out-Null

Write-Host "1. Limpando cache anterior..." -ForegroundColor Gray
try {
    flutter clean
} catch {
    Write-Host "Aviso: Nao foi possivel limpar a pasta 'build' totalmente. Certifique-se de que nenhum programa esta usando a pasta e tente novamente." -ForegroundColor Yellow
}

Write-Host "2. Obtendo dependencias..." -ForegroundColor Gray
flutter pub get

Write-Host "3. Compilando para Web (Release) via CanvasKit..." -ForegroundColor Yellow
# Usamos canvaskit para garantir a precisao dos desenhos no Canvas.
# Nota: Em versões recentes do Flutter (3.44+), a flag --web-renderer foi removida.
# Usamos --dart-define para forçar o renderizador CanvasKit.
flutter build web --release --dart-define=FLUTTER_WEB_RENDERER=canvaskit --base-href "/"

Write-Host "4. Verificando arquivos do Banco de Dados (Drift)..." -ForegroundColor Cyan
$webFiles = @("sqlite3.wasm", "drift_worker.js")

if (-not (Test-Path "build\web")) {
    Write-Host "ERRO: A pasta 'build\web' nao foi criada. O build falhou!" -ForegroundColor Red
    exit 1
}

foreach ($file in $webFiles) {
    $targetPath = "build\web\$file"
    $sourcePath = "web\$file"

    if (Test-Path $targetPath) {
        Write-Host "OK: $file ja esta na pasta build." -ForegroundColor Green
    } else {
        if (Test-Path $sourcePath) {
            Write-Host "Copiando $file para a pasta build..." -ForegroundColor DarkYellow
            Copy-Item $sourcePath $targetPath
        } else {
            Write-Host "ERRO: $file nao encontrado em 'web\'. O banco de dados nao funcionara no browser!" -ForegroundColor Red
        }
    }
}

Write-Host "`n5. Copiando para pasta de distribuicao..." -ForegroundColor Gray
Copy-Item "build\web\*" $distPath -Recurse -Force

Write-Host "`n6. Implantando no Servidor Local (XAMPP)..." -ForegroundColor Cyan
$deployPath = "C:\xampp\htdocs\caderno-backend\public"

if (Test-Path $deployPath) {
    Write-Host "Copiando arquivos para: $deployPath" -ForegroundColor Gray
    # Copia o conteúdo de build\web para a pasta public do backend
    Copy-Item "build\web\*" $deployPath -Recurse -Force
    Write-Host "✅ Implantacao concluida com sucesso no XAMPP!" -ForegroundColor Green
} else {
    Write-Host "❌ ERRO: Caminho de implantacao nao encontrado: $deployPath" -ForegroundColor Red
    Write-Host "Certifique-se de que o XAMPP esta instalado e o caminho esta correto." -ForegroundColor Yellow
}

Write-Host "`n--- Processo completo concluido! ---" -ForegroundColor Green
Write-Host "Arquivos em: dist\web\" -ForegroundColor Gray
Write-Host "Para testar use: npx serve dist\web" -ForegroundColor Cyan
