#!/bin/bash

# ══════════════════════════════════════════════════════════════════════
# FITGYMTRACK - Verifica Requisiti per Deploy
# ══════════════════════════════════════════════════════════════════════
# Controlla che tutti i requisiti siano soddisfatti prima del deploy
# ══════════════════════════════════════════════════════════════════════

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

ALL_OK=true

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}FitGymTrack - Verifica Requisiti Deploy${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Flutter
echo -n "Verifica Flutter... "
if [ -f "$HOME/flutter/bin/flutter" ]; then
    FLUTTER_VERSION=$($HOME/flutter/bin/flutter --version 2>&1 | head -n 1)
    echo -e "${GREEN}✓${NC}"
    echo -e "  ${BLUE}${FLUTTER_VERSION}${NC}"
else
    echo -e "${RED}✗ Non trovato${NC}"
    echo -e "  ${YELLOW}Installare Flutter in: $HOME/flutter${NC}"
    ALL_OK=false
fi

# Python
echo -n "Verifica Python... "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version)
    echo -e "${GREEN}✓${NC}"
    echo -e "  ${BLUE}${PYTHON_VERSION}${NC}"
    
    # Verifica mysql-connector
    echo -n "  Verifica mysql-connector-python... "
    if python3 -c "import mysql.connector" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo -e "    ${YELLOW}Installare con: pip3 install mysql-connector-python${NC}"
        ALL_OK=false
    fi
elif command -v python &> /dev/null; then
    PYTHON_VERSION=$(python --version)
    echo -e "${GREEN}✓${NC}"
    echo -e "  ${BLUE}${PYTHON_VERSION}${NC}"
    
    # Verifica mysql-connector
    echo -n "  Verifica mysql-connector-python... "
    if python -c "import mysql.connector" 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo -e "    ${YELLOW}Installare con: pip install mysql-connector-python${NC}"
        ALL_OK=false
    fi
else
    echo -e "${RED}✗ Non trovato${NC}"
    echo -e "  ${YELLOW}Installare Python 3${NC}"
    ALL_OK=false
fi

# Xcode (per iOS)
echo -n "Verifica Xcode... "
if command -v xcodebuild &> /dev/null; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    echo -e "${GREEN}✓${NC}"
    echo -e "  ${BLUE}${XCODE_VERSION}${NC}"
else
    echo -e "${YELLOW}⚠ Non trovato${NC}"
    echo -e "  ${YELLOW}Necessario per build iOS${NC}"
fi

# CocoaPods (per iOS)
echo -n "Verifica CocoaPods... "
if command -v pod &> /dev/null; then
    POD_VERSION=$(pod --version)
    echo -e "${GREEN}✓${NC}"
    echo -e "  ${BLUE}CocoaPods ${POD_VERSION}${NC}"
else
    echo -e "${YELLOW}⚠ Non trovato${NC}"
    echo -e "  ${YELLOW}Necessario per build iOS${NC}"
    echo -e "  ${YELLOW}Installare con: sudo gem install cocoapods${NC}"
fi

# Android SDK
echo -n "Verifica Android SDK... "
if [ -d "$HOME/Library/Android/sdk" ] || [ -d "$ANDROID_HOME" ]; then
    echo -e "${GREEN}✓${NC}"
    if [ -n "$ANDROID_HOME" ]; then
        echo -e "  ${BLUE}$ANDROID_HOME${NC}"
    else
        echo -e "  ${BLUE}$HOME/Library/Android/sdk${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Non trovato${NC}"
    echo -e "  ${YELLOW}Necessario per build Android${NC}"
fi

# Git
echo -n "Verifica Git... "
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version)
    echo -e "${GREEN}✓${NC}"
    echo -e "  ${BLUE}${GIT_VERSION}${NC}"
else
    echo -e "${YELLOW}⚠ Non trovato${NC}"
    echo -e "  ${YELLOW}Raccomandato per versionamento${NC}"
fi

# Connessione database
echo -n "Verifica connessione database... "
if command -v nc &> /dev/null; then
    if nc -z -w 3 138.68.80.170 3306 2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        echo -e "  ${BLUE}138.68.80.170:3306 raggiungibile${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo -e "  ${YELLOW}Impossibile raggiungere il database${NC}"
        ALL_OK=false
    fi
else
    echo -e "${YELLOW}⚠ Impossibile verificare (nc non disponibile)${NC}"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"

if [ "$ALL_OK" = true ]; then
    echo -e "${GREEN}✓ Tutti i requisiti essenziali sono soddisfatti!${NC}"
    echo ""
    echo -e "${WHITE}Puoi procedere con:${NC}"
    echo -e "  ${CYAN}./scripts/deploy_complete_macos.sh${NC}"
    echo ""
else
    echo -e "${RED}✗ Alcuni requisiti essenziali mancano${NC}"
    echo ""
    echo -e "${YELLOW}Risolvere i problemi indicati sopra prima di procedere${NC}"
    echo ""
    exit 1
fi

