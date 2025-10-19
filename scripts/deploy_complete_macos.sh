#!/bin/bash

# ══════════════════════════════════════════════════════════════════════
# FITGYMTRACK COMPLETE DEPLOY SCRIPT (macOS)
# ══════════════════════════════════════════════════════════════════════
# Script unificato per deploy completo: versioni + database + build Android + iOS
# Esegui dalla directory fitgymtrack_flutter: ./scripts/deploy_complete_macos.sh
# ══════════════════════════════════════════════════════════════════════

set -e  # Exit on error

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# ══════════════════════════════════════════════════════════════════════
# CONFIGURAZIONE
# ══════════════════════════════════════════════════════════════════════

FLUTTER_PATH="$HOME/flutter/bin/flutter"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Database configuration
DB_HOST="138.68.80.170"
DB_PORT="3306"
DB_USER="ElBibo"
DB_PASS="Groot00"
DB_NAME="Workout"

# ══════════════════════════════════════════════════════════════════════
# FUNZIONI UTILITY
# ══════════════════════════════════════════════════════════════════════

print_header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}$1${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_step() {
    echo ""
    echo -e "${YELLOW}▶ STEP $1: $2${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# ══════════════════════════════════════════════════════════════════════
# VALIDAZIONI INIZIALI
# ══════════════════════════════════════════════════════════════════════

print_header "FITGYMTRACK COMPLETE DEPLOY - macOS"

# Verifica Flutter
if [ ! -f "$FLUTTER_PATH" ]; then
    print_error "Flutter non trovato in: $FLUTTER_PATH"
    exit 1
fi

FLUTTER_VERSION=$($FLUTTER_PATH --version | head -n 1)
print_success "Flutter trovato: $FLUTTER_VERSION"

# Verifica directory progetto
cd "$PROJECT_DIR"
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml non trovato. Eseguire lo script dalla directory del progetto."
    exit 1
fi
print_info "Directory progetto: $PROJECT_DIR"

# Verifica Python
PYTHON_CMD=""
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    print_error "Python non trovato. Necessario per aggiornare il database."
    exit 1
fi
PYTHON_VERSION=$($PYTHON_CMD --version)
print_success "Python trovato: $PYTHON_VERSION"

# ══════════════════════════════════════════════════════════════════════
# LETTURA VERSIONE CORRENTE
# ══════════════════════════════════════════════════════════════════════

print_step "1" "Lettura versione corrente"

CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: *//' | cut -d'+' -f1)
CURRENT_BUILD=$(grep "^version:" pubspec.yaml | sed 's/version: *//' | cut -d'+' -f2)

echo -e "${WHITE}Versione corrente: ${CURRENT_VERSION}+${CURRENT_BUILD}${NC}"

# ══════════════════════════════════════════════════════════════════════
# INPUT UTENTE
# ══════════════════════════════════════════════════════════════════════

print_step "2" "Configurazione nuova versione"

# Nuova versione
echo -ne "${CYAN}Nuova versione [${CURRENT_VERSION}]: ${NC}"
read NEW_VERSION
if [ -z "$NEW_VERSION" ]; then
    NEW_VERSION="$CURRENT_VERSION"
fi

# Gestisci formato versione+build (es: 1.0.2+5)
if [[ $NEW_VERSION =~ ^([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$ ]]; then
    NEW_VERSION="${BASH_REMATCH[1]}"
    NEW_BUILD="${BASH_REMATCH[2]}"
    print_info "Interpretato come: versione $NEW_VERSION, build $NEW_BUILD"
else
    # Nuovo build number
    NEXT_BUILD=$((CURRENT_BUILD + 1))
    echo -ne "${CYAN}Nuovo build number [${NEXT_BUILD}]: ${NC}"
    read NEW_BUILD
    if [ -z "$NEW_BUILD" ]; then
        NEW_BUILD="$NEXT_BUILD"
    fi
fi

# Piattaforma
echo ""
echo -e "${YELLOW}Piattaforma:${NC}"
echo -e "  ${WHITE}1.${NC} Android"
echo -e "  ${WHITE}2.${NC} iOS"
echo -e "  ${WHITE}3.${NC} Entrambe (Android + iOS)"
echo -ne "${CYAN}Scelta [1]: ${NC}"
read PLATFORM_CHOICE
case "$PLATFORM_CHOICE" in
    2) PLATFORM="ios" ;;
    3) PLATFORM="both" ;;
    *) PLATFORM="android" ;;
esac

# Target Audience
echo ""
echo -e "${YELLOW}Target Audience:${NC}"
echo -e "  ${WHITE}1.${NC} Production"
echo -e "  ${WHITE}2.${NC} Tester"
echo -ne "${CYAN}Scelta [1]: ${NC}"
read AUDIENCE_CHOICE
case "$AUDIENCE_CHOICE" in
    2) TARGET_AUDIENCE="test" ;;
    *) TARGET_AUDIENCE="production" ;;
esac

# Aggiornamento critico
echo ""
echo -ne "${CYAN}Aggiornamento critico? [s/N]: ${NC}"
read IS_CRITICAL
case "$IS_CRITICAL" in
    s|S|si|SI) IS_CRITICAL_VALUE=1 ;;
    *) IS_CRITICAL_VALUE=0 ;;
esac

# Messaggio aggiornamento
echo ""
echo -ne "${CYAN}Messaggio di aggiornamento (opzionale): ${NC}"
read UPDATE_MESSAGE

# Attivazione database
echo ""
echo -e "${YELLOW}IMPORTANTE: Aggiornare la versione nel database?${NC}"
echo -e "  ${GRAY}• SÌ: Gli utenti riceveranno prompt di aggiornamento (is_active = 1)${NC}"
echo -e "  ${GRAY}• NO: La versione viene inserita ma non attiva (is_active = 0)${NC}"
echo -e "  ${CYAN}Consigliato: NO se la nuova versione non è ancora negli store${NC}"
echo -ne "${CYAN}Attivare nel database? [s/N]: ${NC}"
read UPDATE_DB
case "$UPDATE_DB" in
    s|S|si|SI) 
        UPDATE_DB_ACTIVE=1 
        DB_STATUS="ATTIVA"
        ;;
    *) 
        UPDATE_DB_ACTIVE=0 
        DB_STATUS="INATTIVA"
        ;;
esac

# ══════════════════════════════════════════════════════════════════════
# RIEPILOGO E CONFERMA
# ══════════════════════════════════════════════════════════════════════

print_header "RIEPILOGO CONFIGURAZIONE"

echo -e "${WHITE}Versione:${NC}       ${CURRENT_VERSION}+${CURRENT_BUILD} → ${GREEN}${NEW_VERSION}+${NEW_BUILD}${NC}"
echo -e "${WHITE}Piattaforma:${NC}    ${PLATFORM}"
echo -e "${WHITE}Target:${NC}         ${TARGET_AUDIENCE}"
echo -e "${WHITE}Critico:${NC}        $([ $IS_CRITICAL_VALUE -eq 1 ] && echo -e "${RED}SÌ${NC}" || echo "NO")"
echo -e "${WHITE}Database:${NC}       ${DB_STATUS}"
if [ -n "$UPDATE_MESSAGE" ]; then
    echo -e "${WHITE}Messaggio:${NC}      $UPDATE_MESSAGE"
fi

echo ""
echo -ne "${CYAN}Procedere con il deploy? [S/n]: ${NC}"
read CONFIRM
case "$CONFIRM" in
    n|N|no|NO) 
        print_warning "Operazione annullata"
        exit 0
        ;;
esac

# ══════════════════════════════════════════════════════════════════════
# AGGIORNAMENTO PUBSPEC.YAML
# ══════════════════════════════════════════════════════════════════════

print_step "3" "Aggiornamento pubspec.yaml"

sed -i.bak "s/^version: ${CURRENT_VERSION}+${CURRENT_BUILD}/version: ${NEW_VERSION}+${NEW_BUILD}/" pubspec.yaml
rm pubspec.yaml.bak

print_success "pubspec.yaml aggiornato: ${NEW_VERSION}+${NEW_BUILD}"

# ══════════════════════════════════════════════════════════════════════
# AGGIORNAMENTO DATABASE
# ══════════════════════════════════════════════════════════════════════

print_step "4" "Aggiornamento database"

# Calcola version code
VERSION_CODE=$((${NEW_VERSION//./} * 1000 + NEW_BUILD))
print_info "Version code calcolato: $VERSION_CODE"

# Crea script Python per aggiornamento database
cat > /tmp/fitgymtrack_db_update.py << PYTHON_SCRIPT
import mysql.connector
from datetime import datetime
import sys

try:
    # Configurazione database
    config = {
        'host': '${DB_HOST}',
        'port': ${DB_PORT},
        'user': '${DB_USER}',
        'password': '${DB_PASS}',
        'database': '${DB_NAME}'
    }
    
    # Connessione
    connection = mysql.connector.connect(**config)
    cursor = connection.cursor()
    
    # Disattiva SOLO le versioni dello stesso target_audience SE la nuova versione deve essere attiva
    if ${UPDATE_DB_ACTIVE} == 1:
        cursor.execute("UPDATE app_versions SET is_active = 0 WHERE target_audience = %s", ('${TARGET_AUDIENCE}',))
        print('Versioni precedenti disattivate per target_audience: ${TARGET_AUDIENCE}')
    
    # Inserimento nuova versione
    cursor.execute("""
        INSERT INTO app_versions
        (version_name, build_number, version_code, is_active, update_required, update_message, release_date, min_required_version, platform, target_audience)
        VALUES (%s, %s, %s, %s, %s, %s, NOW(), '1.0.0', %s, %s)
    """, ('${NEW_VERSION}', ${NEW_BUILD}, ${VERSION_CODE}, ${UPDATE_DB_ACTIVE}, ${IS_CRITICAL_VALUE}, '${UPDATE_MESSAGE}', '${PLATFORM}', '${TARGET_AUDIENCE}'))
    
    connection.commit()
    print(f'✓ Database aggiornato: ${NEW_VERSION}+${NEW_BUILD} (code: ${VERSION_CODE}) - Stato: ${DB_STATUS}')
    
except Exception as e:
    print(f'✗ ERRORE DATABASE: {e}')
    sys.exit(1)
finally:
    if 'connection' in locals():
        connection.close()
PYTHON_SCRIPT

# Esegui script Python
$PYTHON_CMD /tmp/fitgymtrack_db_update.py

if [ $? -eq 0 ]; then
    print_success "Database aggiornato con successo (${DB_STATUS})"
    if [ $UPDATE_DB_ACTIVE -eq 0 ]; then
        print_warning "Ricorda: attiva la versione quando pubblichi negli store!"
    fi
else
    print_error "Errore aggiornamento database"
    echo -e "${YELLOW}Eseguire manualmente:${NC}"
    echo -e "${GRAY}Database: ${DB_NAME} (${DB_HOST}:${DB_PORT})${NC}"
    echo -e "${GRAY}User: ${DB_USER}${NC}"
    echo -e "${GRAY}1. UPDATE app_versions SET is_active = 0 WHERE target_audience = '${TARGET_AUDIENCE}';${NC}"
    echo -e "${GRAY}2. INSERT INTO app_versions (version_name, build_number, version_code, is_active, update_required, update_message, release_date, min_required_version, platform, target_audience) VALUES ('${NEW_VERSION}', ${NEW_BUILD}, ${VERSION_CODE}, ${UPDATE_DB_ACTIVE}, ${IS_CRITICAL_VALUE}, '${UPDATE_MESSAGE}', NOW(), '1.0.0', '${PLATFORM}', '${TARGET_AUDIENCE}');${NC}"
    exit 1
fi

# Pulisci file temporaneo
rm -f /tmp/fitgymtrack_db_update.py

# ══════════════════════════════════════════════════════════════════════
# BUILD ANDROID (se richiesto)
# ══════════════════════════════════════════════════════════════════════

if [ "$PLATFORM" == "android" ] || [ "$PLATFORM" == "both" ]; then
    print_step "5" "Build Android (AAB)"
    
    print_info "Pulizia build precedente..."
    $FLUTTER_PATH clean
    
    print_info "Aggiornamento dipendenze..."
    $FLUTTER_PATH pub get
    
    print_info "Compilazione AAB (può richiedere qualche minuto)..."
    $FLUTTER_PATH build appbundle --release
    
    if [ $? -eq 0 ]; then
        AAB_PATH="$PROJECT_DIR/build/app/outputs/bundle/release/app-release.aab"
        if [ -f "$AAB_PATH" ]; then
            AAB_SIZE=$(du -h "$AAB_PATH" | cut -f1)
            print_success "AAB generato: $AAB_PATH ($AAB_SIZE)"
        else
            print_error "AAB non trovato"
            exit 1
        fi
    else
        print_error "Errore nella compilazione Android"
        exit 1
    fi
fi

# ══════════════════════════════════════════════════════════════════════
# PREPARAZIONE iOS (se richiesto)
# ══════════════════════════════════════════════════════════════════════

if [ "$PLATFORM" == "ios" ] || [ "$PLATFORM" == "both" ]; then
    print_step "6" "Preparazione iOS"
    
    # Se abbiamo già fatto clean per Android, skippiamo
    if [ "$PLATFORM" == "ios" ]; then
        print_info "Pulizia build precedente..."
        $FLUTTER_PATH clean
        
        print_info "Aggiornamento dipendenze..."
        $FLUTTER_PATH pub get
    fi
    
    print_info "Rimozione Pods e Podfile.lock..."
    rm -rf "$PROJECT_DIR/ios/Pods"
    rm -f "$PROJECT_DIR/ios/Podfile.lock"
    
    print_info "Installazione CocoaPods..."
    cd "$PROJECT_DIR/ios"
    
    # Verifica che pod sia installato
    if ! command -v pod &> /dev/null; then
        print_error "CocoaPods non trovato. Installa con: sudo gem install cocoapods"
        exit 1
    fi
    
    pod install
    
    if [ $? -eq 0 ]; then
        print_success "CocoaPods installati con successo"
    else
        print_error "Errore nell'installazione dei Pods"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
    
    # Verifica versione in Generated.xcconfig
    if [ -f "$PROJECT_DIR/ios/Flutter/Generated.xcconfig" ]; then
        BUILD_NAME=$(grep "FLUTTER_BUILD_NAME=" "$PROJECT_DIR/ios/Flutter/Generated.xcconfig" | cut -d'=' -f2)
        BUILD_NUMBER=$(grep "FLUTTER_BUILD_NUMBER=" "$PROJECT_DIR/ios/Flutter/Generated.xcconfig" | cut -d'=' -f2)
        print_success "Versione iOS configurata: $BUILD_NAME ($BUILD_NUMBER)"
    fi
fi

# ══════════════════════════════════════════════════════════════════════
# RIEPILOGO FINALE E PROSSIMI PASSI
# ══════════════════════════════════════════════════════════════════════

print_header "DEPLOY COMPLETATO CON SUCCESSO!"

echo -e "${WHITE}Versione:${NC}       ${GREEN}${NEW_VERSION}+${NEW_BUILD}${NC}"
echo -e "${WHITE}Version Code:${NC}   ${VERSION_CODE}"
echo -e "${WHITE}Piattaforma:${NC}    ${PLATFORM}"
echo -e "${WHITE}Target:${NC}         ${TARGET_AUDIENCE}"
echo -e "${WHITE}Database:${NC}       ${DB_STATUS}"

print_header "PROSSIMI PASSI"

# Prossimi passi Android
if [ "$PLATFORM" == "android" ] || [ "$PLATFORM" == "both" ]; then
    echo -e "${YELLOW}📱 ANDROID:${NC}"
    echo -e "${WHITE}1.${NC} Vai su Google Play Console"
    echo -e "${WHITE}2.${NC} Carica il file AAB:"
    echo -e "   ${GRAY}$PROJECT_DIR/build/app/outputs/bundle/release/app-release.aab${NC}"
    echo -e "${WHITE}3.${NC} Compila le note di rilascio"
    echo -e "${WHITE}4.${NC} Pubblica l'aggiornamento"
    echo ""
fi

# Prossimi passi iOS
if [ "$PLATFORM" == "ios" ] || [ "$PLATFORM" == "both" ]; then
    echo -e "${YELLOW}🍎 iOS:${NC}"
    echo -e "${WHITE}1.${NC} Apri Xcode:"
    echo -e "   ${GRAY}open $PROJECT_DIR/ios/Runner.xcworkspace${NC}"
    echo -e "${WHITE}2.${NC} Product → Clean Build Folder (⌘+Shift+K)"
    echo -e "${WHITE}3.${NC} Product → Archive"
    echo -e "${WHITE}4.${NC} Distribuisci su App Store Connect"
    echo -e "${WHITE}5.${NC} Compila le informazioni su App Store Connect"
    echo -e "${WHITE}6.${NC} Invia per la revisione"
    echo ""
fi

# Promemoria database
if [ $UPDATE_DB_ACTIVE -eq 0 ]; then
    echo -e "${YELLOW}💾 DATABASE:${NC}"
    echo -e "${WHITE}IMPORTANTE:${NC} ${RED}La versione è INATTIVA${NC}"
    echo -e "Quando pubblichi negli store, attiva la versione con:"
    echo -e "${GRAY}UPDATE app_versions SET is_active = 1 WHERE version_name = '${NEW_VERSION}' AND build_number = ${NEW_BUILD} AND target_audience = '${TARGET_AUDIENCE}';${NC}"
    echo ""
fi

# Suggerimento commit Git
echo -e "${YELLOW}📦 GIT:${NC}"
echo -e "${WHITE}Sugggerito:${NC} Committa e pusha le modifiche:"
echo -e "${GRAY}git add pubspec.yaml${NC}"
echo -e "${GRAY}git commit -m \"chore: bump version to ${NEW_VERSION}+${NEW_BUILD}\"${NC}"
echo -e "${GRAY}git push${NC}"
echo ""

# Apertura Xcode automatica (solo se iOS e utente conferma)
if [ "$PLATFORM" == "ios" ] || [ "$PLATFORM" == "both" ]; then
    echo -ne "${CYAN}Aprire Xcode ora? [S/n]: ${NC}"
    read OPEN_XCODE
    case "$OPEN_XCODE" in
        n|N|no|NO) 
            print_info "Ricorda di aprire Xcode manualmente"
            ;;
        *) 
            print_info "Apertura Xcode..."
            open "$PROJECT_DIR/ios/Runner.xcworkspace"
            ;;
    esac
fi

print_success "Script completato!"
echo ""

