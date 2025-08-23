# FITGYMTRACK TOTAL DEPLOY SCRIPT (Final Fixed)
# Script completo per deploy: versioni + database + build AAB

# Configurazione
$ErrorActionPreference = "Stop"

# Verifica Flutter
Write-Host "Verifica Flutter..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRORE: Flutter non trovato o non configurato correttamente" -ForegroundColor Red
    exit 1
}
Write-Host $flutterVersion[0] -ForegroundColor Gray

# Verifica directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "ERRORE: Eseguire lo script dalla directory del progetto Flutter" -ForegroundColor Red
    exit 1
}

# Leggi versione corrente
Write-Host "Versione corrente:" -ForegroundColor Yellow
$pubspecContent = Get-Content "pubspec.yaml" -Raw
if ($pubspecContent -match 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
    $currentVersion = $matches[1]
    $currentBuild = $matches[2]
    Write-Host "   $currentVersion+$currentBuild" -ForegroundColor White
} else {
    Write-Host "   ERRORE: Impossibile leggere versione da pubspec.yaml" -ForegroundColor Red
    exit 1
}

# Richiedi nuova versione
$newVersion = Read-Host "Nuova versione (attuale: $currentVersion)"
if ([string]::IsNullOrWhiteSpace($newVersion)) {
    $newVersion = $currentVersion
}

# Richiedi nuovo build number
$newBuild = Read-Host "Nuovo build number (attuale: $currentBuild)"
if ([string]::IsNullOrWhiteSpace($newBuild)) {
    $newBuild = [int]$currentBuild + 1
}

# Gestisci caso in cui l'utente inserisce versione+build insieme (es: 1.0.2+5)
if ($newVersion -match '^(\d+\.\d+\.\d+)\+(\d+)$') {
    $newVersion = $matches[1]
    $newBuild = $matches[2]
    Write-Host "   Interpretato come: versione $newVersion, build $newBuild" -ForegroundColor Gray
}

# Richiedi se aggiornare la versione nel database
Write-Host "`nIMPORTANTE: Aggiornare la versione nel database?" -ForegroundColor Yellow
Write-Host "   - SÌ: Gli utenti riceveranno prompt di aggiornamento" -ForegroundColor Gray
Write-Host "   - NO: La versione rimane quella precedente nel database" -ForegroundColor Gray
Write-Host "   (Consigliato: NO se la nuova versione non è ancora negli store)" -ForegroundColor Cyan
$updateDatabase = Read-Host "Aggiornare versione nel database? (s/N)"
$updateDatabase = $updateDatabase.ToLower()

# Richiedi piattaforma
Write-Host "`nPiattaforma:" -ForegroundColor Yellow
Write-Host "   1. Android" -ForegroundColor White
Write-Host "   2. iOS" -ForegroundColor White
Write-Host "   3. Entrambe" -ForegroundColor White
$platformChoice = Read-Host "Scelta (1/2/3)"

switch ($platformChoice) {
    "1" { $platformTarget = "android" }
    "2" { $platformTarget = "ios" }
    "3" { $platformTarget = "both" }
    default { 
        Write-Host "Scelta non valida, uso Android" -ForegroundColor Yellow
        $platformTarget = "android"
    }
}

# Richiedi target audience
Write-Host "`nTarget Audience:" -ForegroundColor Yellow
Write-Host "   1. Production" -ForegroundColor White
Write-Host "   2. Tester" -ForegroundColor White
$audienceChoice = Read-Host "Scelta (1/2)"

switch ($audienceChoice) {
    "1" { $targetAudience = "production" }
    "2" { $targetAudience = "tester" }
    default { 
        Write-Host "Scelta non valida, uso Production" -ForegroundColor Yellow
        $targetAudience = "production"
    }
}

# Richiedi se è aggiornamento critico
$isCritical = Read-Host "`nAggiornamento critico? (s/N)"
$isCritical = $isCritical.ToLower() -eq "s"

# Richiedi messaggio di aggiornamento
$updateMessage = Read-Host "`nMessaggio di aggiornamento (opzionale)"

# Mostra riepilogo
Write-Host "`n=== RIEPILOGO ===" -ForegroundColor Cyan
Write-Host "   Versione: $currentVersion+$currentBuild -> $newVersion+$newBuild" -ForegroundColor White
Write-Host "   Piattaforma: $platformTarget" -ForegroundColor White
Write-Host "   Target: $targetAudience" -ForegroundColor White
Write-Host "   Critico: $(if ($isCritical) { 'SÌ' } else { 'NO' })" -ForegroundColor White
Write-Host "   Aggiorna DB: $(if ($updateDatabase -eq 's') { 'SÌ' } else { 'NO' })" -ForegroundColor White
if ($updateMessage) {
    Write-Host "   Messaggio: $updateMessage" -ForegroundColor White
}

$confirm = Read-Host "`nProcedere? (S/n)"
if ($confirm.ToLower() -eq "n") {
    Write-Host "Operazione annullata" -ForegroundColor Yellow
    exit 0
}

# STEP 1: Aggiornamento pubspec.yaml
Write-Host "`nSTEP 1: Aggiornamento pubspec.yaml..." -ForegroundColor Yellow
$newPubspecContent = $pubspecContent -replace "version:\s*$currentVersion\+$currentBuild", "version: $newVersion+$newBuild"
$newPubspecContent | Set-Content "pubspec.yaml"
Write-Host "   pubspec.yaml aggiornato: $newVersion+$newBuild" -ForegroundColor Green

# STEP 2: Calcola version code e aggiorna database (solo se richiesto)
if ($updateDatabase -eq 's') {
    Write-Host "`nSTEP 2: Aggiornamento database..." -ForegroundColor Yellow
    
    $versionCode = [int]($newVersion -replace '\.', '') * 1000 + [int]$newBuild
    
    # Verifica Python
    $path = Get-Command python -ErrorAction SilentlyContinue
    if (-not $path) {
        $path = Get-Command python3 -ErrorAction SilentlyContinue
    }
    
    if (-not $path) {
        Write-Host "ERRORE: Python non trovato" -ForegroundColor Red
        Write-Host "Eseguire manualmente:" -ForegroundColor Yellow
        Write-Host "   1. UPDATE app_versions SET is_active = 0;" -ForegroundColor Gray
        Write-Host "   2. INSERT INTO app_versions (version_name, build_number, version_code, is_active, update_required, update_message, release_date, min_required_version) VALUES ('$newVersion', $newBuild, $versionCode, 1, $(if ($isCritical) { 1 } else { 0 }), '$updateMessage', NOW(), '1.0.0');" -ForegroundColor Gray
    } else {
        $result = & $path --version 2>$null
        Write-Host "   Python trovato:" -ForegroundColor Gray
        Write-Host "   Versione: $result" -ForegroundColor Gray
        
        # Script Python per aggiornamento database
        $pythonScript = @"
import mysql.connector
from datetime import datetime
import sys

try:
    # Configurazione database
    config = {
        'host': 'localhost',
        'user': 'root',
        'password': 'root',
        'database': 'fitgymtrack'
    }
    
    # Connessione
    connection = mysql.connector.connect(**config)
    cursor = connection.cursor()
    
    print('Disattivazione versioni precedenti...')
    # Disattiva SOLO le versioni dello stesso target_audience
    cursor.execute("UPDATE app_versions SET is_active = 0 WHERE target_audience = %s", ('$targetAudience',))
    
    print('Inserimento nuova versione...')
    version_name = '$newVersion'
    build_number = $newBuild
    version_code = $versionCode
    is_critical = $(if ($isCritical) { 'True' } else { 'False' })
    
    cursor.execute("""
        INSERT INTO app_versions
        (version_name, build_number, version_code, is_active, update_required, update_message, release_date, min_required_version, platform, target_audience)
        VALUES (%s, %s, %s, 1, %s, %s, NOW(), '1.0.0', %s, %s)
    """, (version_name, build_number, version_code, is_critical, '$updateMessage', '$platformTarget', '$targetAudience'))
    
    connection.commit()
    print(f'SUCCESSO: Database aggiornato con {version_name}+{build_number} (code: {version_code})')
    
except Exception as e:
    print(f'ERRORE: {e}')
    sys.exit(1)
finally:
    if 'connection' in locals():
        connection.close()
"@
        
        # Sostituisci variabili nello script Python
        $pythonScript = $pythonScript -replace '\$newVersion', $newVersion
        $pythonScript = $pythonScript -replace '\$newBuild', $newBuild
        $pythonScript = $pythonScript -replace '\$versionCode', $versionCode
        $pythonScript = $pythonScript -replace '\$isCritical', $(if ($isCritical) { 'True' } else { 'False' })
        $pythonScript = $pythonScript -replace '\$updateMessage', $updateMessage
        $pythonScript = $pythonScript -replace '\$platformTarget', $platformTarget
        $pythonScript = $pythonScript -replace '\$targetAudience', $targetAudience
        
        # Salva e esegui script Python
        $pythonScript | Out-File -FilePath "temp_db_update.py" -Encoding UTF8
        & $path "temp_db_update.py"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   Database aggiornato con successo" -ForegroundColor Green
        } else {
            Write-Host "   ERRORE nell'aggiornamento database" -ForegroundColor Red
            Write-Host "   Eseguire manualmente:" -ForegroundColor Yellow
            Write-Host "   1. UPDATE app_versions SET is_active = 0;" -ForegroundColor Gray
            Write-Host "   2. INSERT INTO app_versions (version_name, build_number, version_code, is_active, update_required, update_message, release_date, min_required_version) VALUES ('$newVersion', $newBuild, $versionCode, 1, $(if ($isCritical) { 1 } else { 0 }), '$updateMessage', NOW(), '1.0.0');" -ForegroundColor Gray
        }
        
        # Pulisci file temporaneo
        Remove-Item "temp_db_update.py" -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "`nSTEP 2: Aggiornamento database SKIPPATO" -ForegroundColor Yellow
    Write-Host "   La versione nel database rimane quella precedente" -ForegroundColor Gray
    Write-Host "   Gli utenti non riceveranno prompt di aggiornamento" -ForegroundColor Gray
}

# STEP 3: Pulizia build precedente
Write-Host "`nSTEP 3: Pulizia build precedente..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -eq 0) {
    Write-Host "   Build pulita" -ForegroundColor Green
} else {
    Write-Host "   ERRORE nella pulizia build" -ForegroundColor Red
    exit 1
}

# STEP 4: Aggiornamento dipendenze
Write-Host "`nSTEP 4: Aggiornamento dipendenze..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "   Dipendenze aggiornate" -ForegroundColor Green
} else {
    Write-Host "   ERRORE nell'aggiornamento dipendenze" -ForegroundColor Red
    exit 1
}

# STEP 5: Compilazione
if ($platformTarget -eq "android" -or $platformTarget -eq "both") {
    Write-Host "`nSTEP 5: Compilazione AAB per Android..." -ForegroundColor Yellow
    flutter build appbundle --release
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   AAB generato: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor Green
    } else {
        Write-Host "   ERRORE nella compilazione Android" -ForegroundColor Red
        exit 1
    }
}

if ($platformTarget -eq "ios" -or $platformTarget -eq "both") {
    Write-Host "`nSTEP 5: Compilazione IPA per iOS..." -ForegroundColor Yellow
    flutter build ipa --release
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   IPA generato: build/ios/ipa/" -ForegroundColor Green
    } else {
        Write-Host "   ERRORE nella compilazione iOS" -ForegroundColor Red
        exit 1
    }
}

# Riepilogo finale
Write-Host "`n=== DEPLOY COMPLETATO ===" -ForegroundColor Green
Write-Host "Versione: $newVersion+$newBuild" -ForegroundColor White
Write-Host "Piattaforma: $platformTarget" -ForegroundColor White
Write-Host "Target: $targetAudience" -ForegroundColor White
if ($updateDatabase -eq 's') {
    Write-Host "Database: AGGIORNATO" -ForegroundColor Green
} else {
    Write-Host "Database: NON AGGIORNATO" -ForegroundColor Yellow
    Write-Host "   Ricordati di aggiornare il database quando pubblichi negli store!" -ForegroundColor Cyan
}

Write-Host "`nProssimi passi:" -ForegroundColor Yellow
if ($platformTarget -eq "android" -or $platformTarget -eq "both") {
    Write-Host "   Android: Carica AAB su Google Play Console" -ForegroundColor White
}
if ($platformTarget -eq "ios" -or $platformTarget -eq "both") {
    Write-Host "   iOS: Carica IPA su App Store Connect" -ForegroundColor White
}
if ($updateDatabase -ne 's') {
    Write-Host "   Database: Aggiorna versione quando pubblichi negli store" -ForegroundColor Cyan
} 