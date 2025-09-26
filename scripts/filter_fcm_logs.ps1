# fitgymtrack_flutter/scripts/filter_fcm_logs.ps1
# Script per filtrare solo i log FCM durante il testing

Write-Host "🔥 FCM Logs Filter - FitGymTrack" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Questo script filtra solo i log con tag [CONSOLE] [FCM]" -ForegroundColor Yellow
Write-Host ""

# Comando per avviare Flutter con filtro sui log FCM
Write-Host "Comando per avviare l'app con solo log FCM:" -ForegroundColor Green
Write-Host ""
Write-Host "flutter run --debug | Select-String '\[CONSOLE\] \[FCM\]'" -ForegroundColor White
Write-Host ""

# Comando alternativo per Windows
Write-Host "Comando alternativo per Windows:" -ForegroundColor Green
Write-Host ""
Write-Host "flutter run --debug | findstr /C:'[CONSOLE] [FCM]'" -ForegroundColor White
Write-Host ""

# Comando per logcat Android (se necessario)
Write-Host "Per logcat Android (se necessario):" -ForegroundColor Green
Write-Host ""
Write-Host "adb logcat | findstr /C:'[CONSOLE] [FCM]'" -ForegroundColor White
Write-Host ""

Write-Host "Log FCM che vedrai:" -ForegroundColor Yellow
Write-Host "- 🔥 Firebase initialized successfully" -ForegroundColor Gray
Write-Host "- 📱 FCM Token saved locally" -ForegroundColor Gray
Write-Host "- 🔥 Registering FCM token for user X" -ForegroundColor Gray
Write-Host "- ✅ FCM token registered successfully" -ForegroundColor Gray
Write-Host "- 🔥 Clearing FCM token for user X" -ForegroundColor Gray
Write-Host "- ✅ FCM token cleared successfully" -ForegroundColor Gray
Write-Host "- 📱 Foreground/Background message received" -ForegroundColor Gray
Write-Host ""

Write-Host "Premi INVIO per avviare l'app con filtro FCM..." -ForegroundColor Cyan
Read-Host

# Avvia l'app con filtro
Write-Host "Avviando app con filtro FCM..." -ForegroundColor Green
flutter run --debug | Select-String '\[CONSOLE\] \[FCM\]'
