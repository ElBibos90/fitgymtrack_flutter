#!/bin/bash

# FITGYMTRACK iOS CLEAN BUILD SCRIPT
# Uso: ./ios_clean.sh
# Funzione: Pulisce e ricompila il progetto iOS con la versione aggiornata

echo "🍎 FITGYMTRACK iOS CLEAN BUILD"
echo "Pulizia e ricompilazione progetto iOS..."
echo ""

# Imposta il percorso Flutter
FLUTTER_PATH="$HOME/flutter/bin"
if [ -d "$FLUTTER_PATH" ]; then
    export PATH="$FLUTTER_PATH:$PATH"
    echo "✅ Flutter path configurato: $FLUTTER_PATH"
else
    echo "⚠️  Flutter non trovato in $FLUTTER_PATH"
    echo "Assicurati che Flutter sia installato correttamente"
fi

# Vai alla directory del progetto
cd "$(dirname "$0")/.."
echo "📁 Directory progetto: $(pwd)"

echo ""
echo "🧹 STEP 1: Pulizia completa..."
flutter clean
if [ $? -ne 0 ]; then
    echo "❌ Errore durante flutter clean"
    exit 1
fi

echo ""
echo "🗑️  STEP 2: Rimozione Pods e Podfile.lock..."
if [ -d "ios/Pods" ]; then
    rm -rf ios/Pods
    echo "✅ Cartella Pods rimossa"
fi
if [ -f "ios/Podfile.lock" ]; then
    rm ios/Podfile.lock
    echo "✅ Podfile.lock rimosso"
fi

echo ""
echo "📦 STEP 3: Installazione dipendenze..."
flutter pub get
if [ $? -ne 0 ]; then
    echo "❌ Errore durante flutter pub get"
    exit 1
fi

echo ""
echo "🍎 STEP 4: Installazione Pods iOS..."
cd ios
pod install
if [ $? -ne 0 ]; then
    echo "❌ Errore durante pod install"
    cd ..
    exit 1
fi
cd ..

echo ""
echo "✅ STEP 5: Verifica versione..."
if [ -f "ios/Flutter/Generated.xcconfig" ]; then
    BUILD_NAME=$(grep "FLUTTER_BUILD_NAME=" ios/Flutter/Generated.xcconfig | cut -d'=' -f2)
    BUILD_NUMBER=$(grep "FLUTTER_BUILD_NUMBER=" ios/Flutter/Generated.xcconfig | cut -d'=' -f2)
    echo "📱 Versione configurata: $BUILD_NAME ($BUILD_NUMBER)"
else
    echo "⚠️  File Generated.xcconfig non trovato"
fi

echo ""
echo "🎉 PULIZIA COMPLETATA!"
echo ""
echo "📋 PROSSIMI PASSI:"
echo "1. Apri Xcode"
echo "2. Product → Clean Build Folder (⌘+Shift+K)"
echo "3. Product → Build (⌘+B)"
echo "4. Product → Archive"
echo ""
echo "💡 La versione dovrebbe ora essere aggiornata nel progetto Xcode" 