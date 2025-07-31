# FITGYMTRACK iOS CLEAN BUILD SCRIPT
# Uso: ios_clean_build
# Funzione: Pulisce e ricompila il progetto iOS con la versione aggiornata

Write-Host "🍎 FITGYMTRACK iOS CLEAN BUILD" -ForegroundColor Cyan
Write-Host "Pulizia e ricompilazione progetto iOS..." -ForegroundColor Yellow
Write-Host ""

# Imposta il percorso Flutter
$flutterPath = "$env:USERPROFILE\flutter\bin"
if (Test-Path $flutterPath) {
    $env:PATH = "$flutterPath;$env:PATH"
    Write-Host "✅ Flutter path configurato: $flutterPath" -ForegroundColor Green
} else {
    Write-Host "⚠️  Flutter non trovato in $flutterPath" -ForegroundColor Yellow
    Write-Host "Assicurati che Flutter sia installato correttamente" -ForegroundColor Yellow
}

# Vai alla directory del progetto
Set-Location $PSScriptRoot\..
Write-Host "📁 Directory progetto: $(Get-Location)" -ForegroundColor Green

Write-Host ""
Write-Host "🧹 STEP 1: Pulizia completa..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Errore durante flutter clean" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🗑️  STEP 2: Rimozione Pods e Podfile.lock..." -ForegroundColor Yellow
if (Test-Path "ios\Pods") {
    Remove-Item -Recurse -Force "ios\Pods"
    Write-Host "✅ Cartella Pods rimossa" -ForegroundColor Green
}
if (Test-Path "ios\Podfile.lock") {
    Remove-Item -Force "ios\Podfile.lock"
    Write-Host "✅ Podfile.lock rimosso" -ForegroundColor Green
}

Write-Host ""
Write-Host "📦 STEP 3: Installazione dipendenze..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Errore durante flutter pub get" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🍎 STEP 4: Installazione Pods iOS..." -ForegroundColor Yellow
Set-Location ios
pod install
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Errore durante pod install" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..

Write-Host ""
Write-Host "✅ STEP 5: Verifica versione..." -ForegroundColor Yellow
if (Test-Path "ios\Flutter\Generated.xcconfig") {
    $configContent = Get-Content "ios\Flutter\Generated.xcconfig"
    $buildName = ($configContent | Select-String "FLUTTER_BUILD_NAME=").ToString().Split("=")[1]
    $buildNumber = ($configContent | Select-String "FLUTTER_BUILD_NUMBER=").ToString().Split("=")[1]
    Write-Host "📱 Versione configurata: $buildName ($buildNumber)" -ForegroundColor Green
} else {
    Write-Host "⚠️  File Generated.xcconfig non trovato" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 PULIZIA COMPLETATA!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 PROSSIMI PASSI:" -ForegroundColor Cyan
Write-Host "1. Apri Xcode" -ForegroundColor White
Write-Host "2. Product → Clean Build Folder (⌘+Shift+K)" -ForegroundColor White
Write-Host "3. Product → Build (⌘+B)" -ForegroundColor White
Write-Host "4. Product → Archive" -ForegroundColor White
Write-Host ""
Write-Host "💡 La versione dovrebbe ora essere aggiornata nel progetto Xcode" -ForegroundColor Cyan 