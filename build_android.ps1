# Script de Build para Android (APK)
# Este script compila o projeto em modo Release e organiza o APK final.

$ErrorActionPreference = "Stop"

Write-Host "--- Iniciando processo de Build Android ---" -ForegroundColor Cyan

# 0. Definir pasta de distribuição fora da pasta 'build' para evitar limpeza acidental
$distPath = "dist\android"
if (-not (Test-Path "dist")) { New-Item -ItemType Directory -Path "dist" | Out-Null }
if (-not (Test-Path $distPath)) { New-Item -ItemType Directory -Path $distPath | Out-Null }

Write-Host "1. Limpando cache e arquivos temporarios..." -ForegroundColor Gray
try {
    # Tenta remover pastas que costumam causar conflitos de escrita
    # flutter clean remove a pasta build inteira
    flutter clean
} catch {
    Write-Host "Aviso: Nao foi possivel limpar a pasta 'build' totalmente. Certifique-se de fechar o Android Studio se o erro persistir." -ForegroundColor Yellow
}

Write-Host "2. Obtendo dependencias..." -ForegroundColor Gray
flutter pub get

Write-Host "3. Compilando APK (Release)..." -ForegroundColor Yellow
# Adicionamos --no-tree-shake-icons para evitar erros de snapshot no Windows
# Se o erro 255 persistir, tente desativar o Antivirus temporariamente.
flutter build apk --release --no-tree-shake-icons

Write-Host "4. Organizando artefatos..." -ForegroundColor Cyan
$apkSource = "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apkSource) {
    $apkDest = "$distPath\caderno_digital_release.apk"
    Copy-Item $apkSource $apkDest -Force
    Write-Host "✅ APK gerado com sucesso em: $apkDest" -ForegroundColor Green
} else {
    Write-Host "❌ ERRO: APK nao encontrado em $apkSource" -ForegroundColor Red
    exit 1
}

Write-Host "`n--- Build Android concluido! ---" -ForegroundColor Green
