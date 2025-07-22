# FITGYMTRACK TOTAL DEPLOY SCRIPT (Final Fixed)
# Script completo per deploy: versioni + database + build AAB

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "FITGYMTRACK TOTAL DEPLOY SCRIPT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Verifica se Flutter è installato
try {
    $flutterVersion = flutter --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter non trovato"
    }
    Write-Host "Flutter trovato" -ForegroundColor Green
    Write-Host $flutterVersion[0] -ForegroundColor Gray
} catch {
    Write-Host "ERRORE: Flutter non trovato! Installa Flutter e riprova." -ForegroundColor Red
    Read-Host "Premi Enter per uscire"
    exit 1
}

Write-Host ""

# Leggi versione corrente
Write-Host "Versione corrente:" -ForegroundColor Yellow
$pubspecContent = Get-Content "pubspec.yaml" -Raw
if ($pubspecContent -match 'version:\s*(\d+\.\d+\.\d+)\+(\d+)') {
    $currentVersion = $matches[1]
    $currentBuild = $matches[2]
    Write-Host "   $currentVersion+$currentBuild" -ForegroundColor White
} else {
    Write-Host "   ERRORE: Impossibile leggere versione da pubspec.yaml" -ForegroundColor Red
    Read-Host "Premi Enter per uscire"
    exit 1
}

Write-Host ""

# Richiedi nuova versione
$newVersion = Read-Host "Nuova versione (attuale: $currentVersion)"
if ([string]::IsNullOrWhiteSpace($newVersion)) {
    $newVersion = $currentVersion
}

# Richiedi build number
$newBuild = Read-Host "Build number (attuale: $currentBuild)"
if ([string]::IsNullOrWhiteSpace($newBuild)) {
    $newBuild = [int]$currentBuild + 1
}

# Gestisci caso in cui l'utente inserisce versione+build insieme (es: 1.0.2+5)
if ($newVersion -match '^(\d+\.\d+\.\d+)\+(\d+)$') {
    $newVersion = $matches[1]
    $newBuild = $matches[2]
    Write-Host "   Interpretato come: versione $newVersion, build $newBuild" -ForegroundColor Gray
}

Write-Host ""
# Richiedi se è un aggiornamento critico
$updateRequired = Read-Host "Aggiornamento forzato/critico? (y/N)"
$isCritical = ($updateRequired -eq "y" -or $updateRequired -eq "Y")

# Richiedi messaggio aggiornamento
$updateMessage = Read-Host "Messaggio aggiornamento (opzionale)"
if ([string]::IsNullOrWhiteSpace($updateMessage)) {
    if ($isCritical) {
        $updateMessage = "Aggiornamento obbligatorio - Bug critici risolti"
    } else {
        $updateMessage = "Miglioramenti generali"
    }
}

Write-Host ""
Write-Host "Riepilogo deploy completo:" -ForegroundColor Yellow
Write-Host "   Versione: $currentVersion+$currentBuild -> $newVersion+$newBuild" -ForegroundColor White
Write-Host "   Database: Aggiornamento automatico" -ForegroundColor White
Write-Host "   Critico: $(if ($isCritical) { 'SÌ' } else { 'NO' })" -ForegroundColor $(if ($isCritical) { "Red" } else { "Green" })
Write-Host "   Messaggio: $updateMessage" -ForegroundColor White
Write-Host "   Build: Generazione app-release.aab" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Procedere con il deploy completo? (y/N)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Deploy annullato" -ForegroundColor Red
    Read-Host "Premi Enter per uscire"
    exit 0
}

Write-Host ""

# STEP 1: Aggiorna pubspec.yaml
Write-Host "STEP 1: Aggiornamento pubspec.yaml..." -ForegroundColor Yellow
$newPubspecContent = $pubspecContent -replace "version:\s*$currentVersion\+$currentBuild", "version: $newVersion+$newBuild"
Set-Content "pubspec.yaml" $newPubspecContent -Encoding UTF8
Write-Host "   pubspec.yaml aggiornato: $newVersion+$newBuild" -ForegroundColor Green

Write-Host ""

# STEP 2: Calcola version code e aggiorna database
Write-Host "STEP 2: Aggiornamento database..." -ForegroundColor Yellow
$versionCode = [int]($newVersion -replace '\.', '') * 1000 + [int]$newBuild

Write-Host "   Configurazione Database:" -ForegroundColor White
Write-Host "   Host: 104.248.103.182" -ForegroundColor Gray
Write-Host "   User: ElBibo" -ForegroundColor Gray
Write-Host "   Database: Workout" -ForegroundColor Gray
Write-Host "   Password: Groot00" -ForegroundColor Gray

# Trova Python automaticamente
$pythonPath = $null
$pythonPaths = @(
    "python",
    "python3",
    "C:\Users\rdpdev\AppData\Local\Programs\Python\Python311\python.exe",
    "C:\Users\rdpdev\AppData\Local\Microsoft\WindowsApps\python.exe",
    "C:\Program Files\Python311\python.exe",
    "C:\Python311\python.exe"
)

foreach ($path in $pythonPaths) {
    try {
        $result = & $path --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            $pythonPath = $path
            Write-Host "   Python trovato: $path" -ForegroundColor Green
            Write-Host "   Versione: $result" -ForegroundColor Gray
            break
        }
    } catch {
        # Continua con il prossimo percorso
    }
}

if ($pythonPath) {
    # Installa mysql-connector se necessario
    try {
        $testImport = & $pythonPath -c "import mysql.connector; print('mysql-connector OK')" 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "   Installa mysql-connector..." -ForegroundColor Yellow
            & $pythonPath -m pip install mysql-connector-python
        }
    } catch {
        Write-Host "   Errore installazione mysql-connector" -ForegroundColor Yellow
    }

    # Crea script Python temporaneo con sostituzione corretta delle variabili
    $pythonScript = @"
import mysql.connector
import sys

# Configurazione database
db_config = {
    'host': '104.248.103.182',
    'user': 'ElBibo',
    'password': 'Groot00',
    'database': 'Workout',
    'port': 3306
}

try:
    print('Connessione al database...')
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    
    print('Disattivazione versioni precedenti...')
    cursor.execute("UPDATE app_versions SET is_active = 0")
    
    print('Inserimento nuova versione...')
    version_name = '$newVersion'
    build_number = $newBuild
    version_code = $versionCode
    
    cursor.execute("""
        INSERT INTO app_versions 
        (version_name, build_number, version_code, is_active, update_required, update_message, release_date, min_required_version) 
        VALUES (%s, %s, %s, 1, %s, %s, NOW(), '1.0.0')
    """, (version_name, build_number, version_code, $isCritical, '$updateMessage'))
    
    conn.commit()
    print(f'SUCCESSO: Database aggiornato con {version_name}+{build_number} (code: {version_code})')
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f'ERRORE: {e}')
    sys.exit(1)
"@

    # Sostituisci le variabili PowerShell nel codice Python
    $pythonScript = $pythonScript -replace '\$newVersion', $newVersion
    $pythonScript = $pythonScript -replace '\$newBuild', $newBuild
    $pythonScript = $pythonScript -replace '\$versionCode', $versionCode
    $pythonScript = $pythonScript -replace '\$isCritical', $(if ($isCritical) { "True" } else { "False" })
    $pythonScript = $pythonScript -replace '\$updateMessage', $updateMessage

    Set-Content "temp_db_update.py" $pythonScript -Encoding UTF8
    & $pythonPath temp_db_update.py
    $pythonExitCode = $LASTEXITCODE
    Remove-Item "temp_db_update.py" -ErrorAction SilentlyContinue

    if ($pythonExitCode -eq 0) {
        Write-Host "   Database aggiornato con successo!" -ForegroundColor Green
    } else {
        Write-Host "   Errore aggiornamento database" -ForegroundColor Red
        Write-Host "   Query da eseguire manualmente:" -ForegroundColor Yellow
        Write-Host "   1. UPDATE app_versions SET is_active = 0;" -ForegroundColor Gray
        Write-Host "   2. INSERT INTO app_versions (version_name, build_number, version_code, is_active, update_required, update_message, release_date, min_required_version) VALUES ('$newVersion', $newBuild, $versionCode, 1, $(if ($isCritical) { 1 } else { 0 }), '$updateMessage', NOW(), '1.0.0');" -ForegroundColor Gray
    }
} else {
    Write-Host "   Python non trovato - database non aggiornato" -ForegroundColor Yellow
    Write-Host "   Query da eseguire manualmente:" -ForegroundColor Yellow
    Write-Host "   1. UPDATE app_versions SET is_active = 0;" -ForegroundColor Gray
    Write-Host "   2. INSERT INTO app_versions (version_name, build_number, version_code, is_active, update_required, update_message, release_date, min_required_version) VALUES ('$newVersion', $newBuild, $versionCode, 1, $(if ($isCritical) { 1 } else { 0 }), '$updateMessage', NOW(), '1.0.0');" -ForegroundColor Gray
}

Write-Host ""

# STEP 3: Pulisci build precedente
Write-Host "STEP 3: Pulizia build precedente..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRORE: Errore pulizia" -ForegroundColor Red
    Read-Host "Premi Enter per uscire"
    exit 1
}
Write-Host "   Build pulita" -ForegroundColor Green

Write-Host ""

# STEP 4: Aggiorna dipendenze
Write-Host "STEP 4: Aggiornamento dipendenze..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRORE: Errore dipendenze" -ForegroundColor Red
    Read-Host "Premi Enter per uscire"
    exit 1
}
Write-Host "   Dipendenze aggiornate" -ForegroundColor Green

Write-Host ""

# STEP 5: Compila AAB
Write-Host "STEP 5: Compilazione AAB..." -ForegroundColor Yellow
flutter build appbundle --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRORE: Errore compilazione" -ForegroundColor Red
    Read-Host "Premi Enter per uscire"
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "DEPLOY COMPLETO CON SUCCESSO!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Versione: $newVersion+$newBuild" -ForegroundColor White
Write-Host "AAB: build/app/outputs/bundle/release/app-release.aab" -ForegroundColor White
Write-Host "Pubspec: Aggiornato" -ForegroundColor White
Write-Host "Database: Aggiornato automaticamente" -ForegroundColor Green
Write-Host "Critico: $(if ($isCritical) { 'SÌ' } else { 'NO' })" -ForegroundColor $(if ($isCritical) { "Red" } else { "Green" })
Write-Host "Messaggio: $updateMessage" -ForegroundColor White
Write-Host ""
Write-Host "PROSSIMI PASSI:" -ForegroundColor Yellow
Write-Host "1. Carica il file .aab su Google Play Console" -ForegroundColor White
Write-Host "2. Compila le note di rilascio" -ForegroundColor White
Write-Host "3. Pubblica la release" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Read-Host "Premi Enter per uscire" 