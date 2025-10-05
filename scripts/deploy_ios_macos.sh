#!/bin/bash

# FITGYMTRACK iOS DEPLOY SCRIPT (macOS)
# Script completo per deploy iOS: versioni + database + build IPA/Archive
# Automatizza tutto il processo senza aprire Xcode manualmente

set -e  # Exit on any error

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Funzione per log colorato
log() {
    echo -e "${2:-$WHITE}$1${NC}"
}

# Funzione per errore
error() {
    log "❌ $1" $RED
    exit 1
}

# Funzione per successo
success() {
    log "✅ $1" $GREEN
}

# Funzione per warning
warning() {
    log "⚠️  $1" $YELLOW
}

# Funzione per info
info() {
    log "ℹ️  $1" $BLUE
}

log "🍎 FITGYMTRACK iOS DEPLOY SCRIPT" $CYAN
log "Script completo per deploy iOS automatizzato" $CYAN
echo ""

# Verifica Flutter
log "Verifica Flutter..." $YELLOW
FLUTTER_PATH="$HOME/flutter/bin"
if [ -d "$FLUTTER_PATH" ]; then
    export PATH="$FLUTTER_PATH:$PATH"
    FLUTTER_VERSION=$(flutter --version 2>/dev/null | head -n 1)
    if [ $? -ne 0 ]; then
        error "Flutter non configurato correttamente"
    fi
    log "   $FLUTTER_VERSION" $WHITE
else
    error "Flutter non trovato in $FLUTTER_PATH"
fi

# Verifica directory
if [ ! -f "pubspec.yaml" ]; then
    error "Eseguire lo script dalla directory del progetto Flutter"
fi

# Verifica Xcode
log "Verifica Xcode..." $YELLOW
if ! command -v xcodebuild &> /dev/null; then
    error "Xcode non trovato. Installare Xcode Command Line Tools"
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1)
log "   $XCODE_VERSION" $WHITE

# Verifica CocoaPods
log "Verifica CocoaPods..." $YELLOW
if ! command -v pod &> /dev/null; then
    error "CocoaPods non trovato. Installare con: sudo gem install cocoapods"
fi

POD_VERSION=$(pod --version)
log "   CocoaPods $POD_VERSION" $WHITE

# Leggi versione corrente
log "Versione corrente:" $YELLOW
if grep -q 'version:' pubspec.yaml; then
    CURRENT_VERSION=$(grep 'version:' pubspec.yaml | sed 's/version: *//' | sed 's/+.*//')
    CURRENT_BUILD=$(grep 'version:' pubspec.yaml | sed 's/.*+//')
    log "   $CURRENT_VERSION+$CURRENT_BUILD" $WHITE
else
    error "Impossibile leggere versione da pubspec.yaml"
fi

# Richiedi nuova versione
echo ""
read -p "Nuova versione (attuale: $CURRENT_VERSION): " NEW_VERSION
if [ -z "$NEW_VERSION" ]; then
    NEW_VERSION=$CURRENT_VERSION
fi

# Richiedi nuovo build number
read -p "Nuovo build number (attuale: $CURRENT_BUILD): " NEW_BUILD
if [ -z "$NEW_BUILD" ]; then
    NEW_BUILD=$((CURRENT_BUILD + 1))
fi

# Gestisci caso in cui l'utente inserisce versione+build insieme (es: 1.0.2+5)
if [[ $NEW_VERSION =~ ^([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$ ]]; then
    NEW_VERSION=${BASH_REMATCH[1]}
    NEW_BUILD=${BASH_REMATCH[2]}
    log "   Interpretato come: versione $NEW_VERSION, build $NEW_BUILD" $WHITE
fi

# Richiedi se aggiornare la versione nel database
echo ""
log "IMPORTANTE: Aggiornare la versione nel database?" $YELLOW
log "   - SÌ: Gli utenti riceveranno prompt di aggiornamento (is_active = 1)" $WHITE
log "   - NO: La versione viene inserita ma non attiva (is_active = 0)" $WHITE
log "   (Consigliato: NO se la nuova versione non è ancora negli store)" $CYAN
read -p "Aggiornare versione nel database? (s/N): " UPDATE_DATABASE
if [ -z "$UPDATE_DATABASE" ]; then
    UPDATE_DATABASE="n"
fi
UPDATE_DATABASE=$(echo "$UPDATE_DATABASE" | tr '[:upper:]' '[:lower:]')

# Richiedi target audience
echo ""
log "Target Audience:" $YELLOW
log "   1. Production" $WHITE
log "   2. Tester" $WHITE
read -p "Scelta (1/2): " AUDIENCE_CHOICE
if [ -z "$AUDIENCE_CHOICE" ]; then
    AUDIENCE_CHOICE="1"
fi

case $AUDIENCE_CHOICE in
    "1") TARGET_AUDIENCE="production" ;;
    "2") TARGET_AUDIENCE="test" ;;
    *) 
        warning "Scelta non valida, uso Production"
        TARGET_AUDIENCE="production"
        ;;
esac

# Richiedi se è aggiornamento critico
read -p "Aggiornamento critico? (s/N): " IS_CRITICAL
if [ -z "$IS_CRITICAL" ]; then
    IS_CRITICAL="n"
fi
IS_CRITICAL=$(echo "$IS_CRITICAL" | tr '[:upper:]' '[:lower:]')
IS_CRITICAL=$([ "$IS_CRITICAL" = "s" ] && echo "true" || echo "false")

# Richiedi messaggio di aggiornamento
read -p "Messaggio di aggiornamento (opzionale): " UPDATE_MESSAGE

# Mostra riepilogo
echo ""
log "=== RIEPILOGO ===" $CYAN
log "   Versione: $CURRENT_VERSION+$CURRENT_BUILD -> $NEW_VERSION+$NEW_BUILD" $WHITE
log "   Piattaforma: ios" $WHITE
log "   Target: $TARGET_AUDIENCE" $WHITE
log "   Critico: $([ "$IS_CRITICAL" = "true" ] && echo "SÌ" || echo "NO")" $WHITE
log "   Aggiorna DB: $([ "$UPDATE_DATABASE" = "s" ] && echo "SÌ (attiva)" || echo "SÌ (inattiva)")" $WHITE
if [ ! -z "$UPDATE_MESSAGE" ]; then
    log "   Messaggio: $UPDATE_MESSAGE" $WHITE
fi

echo ""
read -p "Procedere? (S/n): " CONFIRM
if [ -z "$CONFIRM" ]; then
    CONFIRM="s"
fi
if [ "$(echo "$CONFIRM" | tr '[:upper:]' '[:lower:]')" = "n" ]; then
    log "Operazione annullata" $YELLOW
    exit 0
fi

# STEP 1: Aggiornamento pubspec.yaml
log "STEP 1: Aggiornamento pubspec.yaml..." $YELLOW
sed -i '' "s/version: $CURRENT_VERSION+$CURRENT_BUILD/version: $NEW_VERSION+$NEW_BUILD/" pubspec.yaml
success "pubspec.yaml aggiornato: $NEW_VERSION+$NEW_BUILD"

# STEP 2: Calcola version code e aggiorna database
log "STEP 2: Aggiornamento database..." $YELLOW

VERSION_CODE=$(echo "$NEW_VERSION" | sed 's/\.//g' | awk '{print $1 * 1000 + '"$NEW_BUILD"'}')

# Verifica Python
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    warning "Python non trovato"
    log "Eseguire manualmente:" $YELLOW
    log "   1. UPDATE app_versions SET is_active = 0 WHERE target_audience = '$TARGET_AUDIENCE';" $WHITE
    log "   2. INSERT INTO app_versions (version_name, build_number, version_code, is_active, update_required, update_message, release_date, min_required_version, platform, target_audience) VALUES ('$NEW_VERSION', $NEW_BUILD, $VERSION_CODE, $([ "$UPDATE_DATABASE" = "s" ] && echo "1" || echo "0"), $([ "$IS_CRITICAL" = "true" ] && echo "1" || echo "0"), '$UPDATE_MESSAGE', NOW(), '1.0.0', 'ios', '$TARGET_AUDIENCE');" $WHITE
else
    PYTHON_VERSION=$($PYTHON_CMD --version 2>/dev/null)
    log "   Python trovato:" $WHITE
    log "   $PYTHON_VERSION" $WHITE
    
    # Script Python per aggiornamento database
    cat > temp_db_update.py << EOF
import mysql.connector
from datetime import datetime
import sys

try:
    # Configurazione database
    config = {
        'host': '138.68.80.170',
        'port': 3306,
        'user': 'ElBibo',
        'password': 'Groot00',
        'database': 'Workout'
    }
    
    # Connessione
    connection = mysql.connector.connect(**config)
    cursor = connection.cursor()
    
    # Disattiva SOLO le versioni dello stesso target_audience SE la nuova versione deve essere attiva
    update_database_active = $([ "$UPDATE_DATABASE" = "s" ] && echo "True" || echo "False")
    if update_database_active:
        cursor.execute("UPDATE app_versions SET is_active = 0 WHERE target_audience = %s", ('$TARGET_AUDIENCE',))
    
    # Inserimento nuova versione
    version_name = '$NEW_VERSION'
    build_number = $NEW_BUILD
    version_code = $VERSION_CODE
    is_critical = $IS_CRITICAL
    is_active = update_database_active
    
    cursor.execute("""
        INSERT INTO app_versions
        (version_name, build_number, version_code, is_active, update_required, update_message, release_date, min_required_version, platform, target_audience)
        VALUES (%s, %s, %s, %s, %s, %s, NOW(), '1.0.0', 'ios', %s)
    """, (version_name, build_number, version_code, is_active, is_critical, '$UPDATE_MESSAGE', '$TARGET_AUDIENCE'))
    
    connection.commit()
    print(f'SUCCESSO: Database aggiornato con {version_name}+{build_number} (code: {version_code})')
    
except Exception as e:
    print(f'ERRORE: {e}')
    sys.exit(1)
finally:
    if 'connection' in locals():
        connection.close()
EOF
    
    # Esegui script Python
    $PYTHON_CMD temp_db_update.py
    
    if [ $? -eq 0 ]; then
        if [ "$UPDATE_DATABASE" = "s" ]; then
            success "Database aggiornato con successo (versione attiva)"
        else
            success "Database aggiornato con successo (versione inattiva)"
        fi
    else
        error "Errore nell'aggiornamento database"
    fi
    
    # Pulisci file temporaneo
    rm -f temp_db_update.py
fi

# STEP 3: Pulizia build precedente
log "STEP 3: Pulizia build precedente..." $YELLOW
flutter clean
if [ $? -eq 0 ]; then
    success "Build pulita"
else
    error "Errore nella pulizia build"
fi

# STEP 4: Aggiornamento dipendenze
log "STEP 4: Aggiornamento dipendenze..." $YELLOW
flutter pub get
if [ $? -eq 0 ]; then
    success "Dipendenze aggiornate"
else
    error "Errore nell'aggiornamento dipendenze"
fi

# STEP 5: Pulizia iOS specifica
log "STEP 5: Pulizia iOS specifica..." $YELLOW
if [ -d "ios/Pods" ]; then
    rm -rf ios/Pods
    log "   Cartella Pods rimossa" $WHITE
fi
if [ -f "ios/Podfile.lock" ]; then
    rm ios/Podfile.lock
    log "   Podfile.lock rimosso" $WHITE
fi

# STEP 6: Installazione Pods
log "STEP 6: Installazione Pods..." $YELLOW
cd ios
pod install
if [ $? -eq 0 ]; then
    success "Pods installati"
else
    error "Errore nell'installazione Pods"
fi
cd ..

# STEP 7: Generazione Archive con xcodebuild
log "STEP 7: Generazione Archive iOS..." $YELLOW
log "Questo processo può richiedere diversi minuti..." $CYAN

# Configurazione workspace e scheme
WORKSPACE="ios/Runner.xcworkspace"
SCHEME="Runner"
ARCHIVE_PATH="build/ios/archive/Runner.xcarchive"

# Crea directory per archive se non esiste
mkdir -p build/ios/archive

# Comando xcodebuild per archive
xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="" \
    PROVISIONING_PROFILE_SPECIFIER=""

if [ $? -eq 0 ]; then
    success "Archive generato: $ARCHIVE_PATH"
else
    error "Errore nella generazione Archive"
fi

# STEP 8: Esportazione IPA (opzionale)
echo ""
read -p "Generare anche file IPA per distribuzione? (s/N): " GENERATE_IPA
if [ "$(echo "$GENERATE_IPA" | tr '[:upper:]' '[:lower:]')" = "s" ]; then
    log "STEP 8: Esportazione IPA..." $YELLOW
    
    # Crea directory per IPA
    mkdir -p build/ios/ipa
    
    # Esporta IPA per App Store
    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "build/ios/ipa" \
        -exportOptionsPlist ios/ExportOptions.plist
    
    if [ $? -eq 0 ]; then
        success "IPA generato in build/ios/ipa/"
    else
        warning "Errore nella generazione IPA (potrebbe mancare ExportOptions.plist)"
        info "Creare manualmente ExportOptions.plist se necessario"
    fi
fi

# Riepilogo finale
echo ""
log "=== DEPLOY COMPLETATO ===" $GREEN
log "Versione: $NEW_VERSION+$NEW_BUILD" $WHITE
log "Piattaforma: ios" $WHITE
log "Target: $TARGET_AUDIENCE" $WHITE
if [ "$UPDATE_DATABASE" = "s" ]; then
    log "Database: AGGIORNATO (versione attiva)" $GREEN
else
    log "Database: AGGIORNATO (versione inattiva)" $GREEN
    log "   Ricordati di attivare la versione quando pubblichi negli store!" $CYAN
fi

log "Archive: $ARCHIVE_PATH" $GREEN

echo ""
log "Prossimi passi:" $YELLOW
log "   iOS: Apri Xcode Organizer (Window → Organizer)" $WHITE
log "   iOS: Seleziona l'archive e clicca 'Distribute App'" $WHITE
log "   iOS: Scegli 'App Store Connect' per pubblicare" $WHITE
if [ "$UPDATE_DATABASE" != "s" ]; then
    log "   Database: Attiva la versione quando pubblichi negli store:" $CYAN
    log "   UPDATE app_versions SET is_active = 1 WHERE version_name = '$NEW_VERSION' AND build_number = $NEW_BUILD" $CYAN
fi

echo ""
success "Deploy iOS completato con successo! 🎉"

