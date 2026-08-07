# Script de Build para Windows (EXE)
# Este script compila o projeto e organiza o executavel com suas dependencias.

$ErrorActionPreference = "Stop"

Write-Host "--- Iniciando processo de Build Windows ---" -ForegroundColor Cyan

# 0. Definir pasta de distribuição fora da pasta 'build' para evitar limpeza acidental
$distPath = "dist\windows"
if (-not (Test-Path "dist")) { New-Item -ItemType Directory -Path "dist" | Out-Null }
if (Test-Path $distPath) { Remove-Item $distPath -Recurse -Force }
New-Item -ItemType Directory -Path $distPath | Out-Null

Write-Host "1. Limpando cache anterior..." -ForegroundColor Gray
try {
    flutter clean
} catch {
    Write-Host "Aviso: Nao foi possivel limpar a pasta 'build' totalmente." -ForegroundColor Yellow
}

Write-Host "2. Obtendo dependencias..." -ForegroundColor Gray
flutter pub get

Write-Host "3. Compilando para Windows (Release)..." -ForegroundColor Yellow
flutter build windows --release

Write-Host "4. Organizando artefatos para distribuicao..." -ForegroundColor Cyan
$winBuildPath = "build\windows\x64\runner\Release"
if (Test-Path $winBuildPath) {
    # Copia todo o conteudo da pasta de release (EXE + DLLs + data) para a pasta dist raiz
    Copy-Item "$winBuildPath\*" $distPath -Recurse -Force
    Write-Host "✅ Executavel e dependencias organizados em: $distPath" -ForegroundColor Green
    Write-Host "💡 Dica: Voce pode compactar esta pasta para distribuir o app." -ForegroundColor Cyan
} else {
    Write-Host "❌ ERRO: Pasta de build Windows nao encontrada em $winBuildPath" -ForegroundColor Red
    exit 1
}

Write-Host "`n--- Build Windows concluido! ---" -ForegroundColor Green
