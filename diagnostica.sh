#!/bin/bash

# Script di diagnostica iOS Firebase
# Esegui questo script su entrambi i computer per confrontare le configurazioni

echo "🔍 DIAGNOSTICA iOS FIREBASE"
echo "=========================="
echo "Data: $(date)"
echo "Computer: $(hostname)"
echo ""

# Crea file di output
OUTPUT_FILE="diagnostica_results_$(hostname)_$(date +%Y%m%d_%H%M%S).txt"

echo "📝 Salvataggio risultati in: $OUTPUT_FILE"
echo ""

# Funzione per aggiungere sezione
add_section() {
    echo "" >> "$OUTPUT_FILE"
    echo "=== $1 ===" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

# Inizializza file
echo "DIAGNOSTICA iOS FIREBASE - $(hostname)" > "$OUTPUT_FILE"
echo "Data: $(date)" >> "$OUTPUT_FILE"
echo "Computer: $(hostname)" >> "$OUTPUT_FILE"

# 1. INFORMAZIONI SISTEMA
add_section "SISTEMA"
echo "🖥️ Sistema:" | tee -a "$OUTPUT_FILE"
sw_vers | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 2. XCODE
add_section "XCODE"
echo "🛠️ Xcode:" | tee -a "$OUTPUT_FILE"
xcodebuild -version | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 3. FLUTTER
add_section "FLUTTER"
echo "📱 Flutter:" | tee -a "$OUTPUT_FILE"
flutter --version | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 4. EMULATORI iOS
add_section "EMULATORI iOS"
echo "📱 Emulatori iOS:" | tee -a "$OUTPUT_FILE"
xcrun simctl list devices | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 5. RUNTIME iOS
add_section "RUNTIME iOS"
echo "📱 Runtime iOS:" | tee -a "$OUTPUT_FILE"
xcrun simctl list runtimes | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 6. DEVELOPER ACCOUNT
add_section "DEVELOPER ACCOUNT"
echo "🔐 Developer Account:" | tee -a "$OUTPUT_FILE"
security find-identity -v -p codesigning | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 7. PROFILI PROVISIONING
add_section "PROFILI PROVISIONING"
echo "📋 Profili Provisioning:" | tee -a "$OUTPUT_FILE"
if [ -d ~/Library/MobileDevice/Provisioning\ Profiles/ ]; then
    ls -la ~/Library/MobileDevice/Provisioning\ Profiles/ | tee -a "$OUTPUT_FILE"
else
    echo "Directory non trovata" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 8. FIREBASE iOS
add_section "FIREBASE iOS"
echo "🔥 Firebase iOS (GoogleService-Info.plist):" | tee -a "$OUTPUT_FILE"
if [ -f ios/Runner/GoogleService-Info.plist ]; then
    cat ios/Runner/GoogleService-Info.plist | tee -a "$OUTPUT_FILE"
else
    echo "File non trovato" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 9. FIREBASE ANDROID
add_section "FIREBASE ANDROID"
echo "🔥 Firebase Android (google-services.json):" | tee -a "$OUTPUT_FILE"
if [ -f android/app/google-services.json ]; then
    cat android/app/google-services.json | tee -a "$OUTPUT_FILE"
else
    echo "File non trovato" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 10. BUNDLE ID iOS
add_section "BUNDLE ID iOS"
echo "📦 Bundle ID iOS:" | tee -a "$OUTPUT_FILE"
if [ -f ios/Runner.xcodeproj/project.pbxproj ]; then
    grep -A 1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj | tee -a "$OUTPUT_FILE"
else
    echo "File project.pbxproj non trovato" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 11. PACKAGE NAME ANDROID
add_section "PACKAGE NAME ANDROID"
echo "📦 Package Name Android:" | tee -a "$OUTPUT_FILE"
if [ -f android/app/build.gradle ]; then
    grep "applicationId" android/app/build.gradle | tee -a "$OUTPUT_FILE"
else
    echo "File build.gradle non trovato" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 12. ENTITLEMENTS
add_section "ENTITLEMENTS"
echo "🔐 Entitlements:" | tee -a "$OUTPUT_FILE"
if [ -f ios/Runner/Runner.entitlements ]; then
    cat ios/Runner/Runner.entitlements | tee -a "$OUTPUT_FILE"
else
    echo "File entitlements non trovato" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 13. APPDELEGATE
add_section "APPDELEGATE"
echo "📱 AppDelegate.swift:" | tee -a "$OUTPUT_FILE"
if [ -f ios/Runner/AppDelegate.swift ]; then
    cat ios/Runner/AppDelegate.swift | tee -a "$OUTPUT_FILE"
else
    echo "File AppDelegate.swift non trovato" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 14. FIREBASE DEPENDENCIES
add_section "FIREBASE DEPENDENCIES"
echo "📦 Firebase Dependencies:" | tee -a "$OUTPUT_FILE"
if [ -f pubspec.yaml ]; then
    grep -A 10 -B 2 "firebase" pubspec.yaml | tee -a "$OUTPUT_FILE"
else
    echo "File pubspec.yaml non trovato" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 15. iOS PODS
add_section "iOS PODS"
echo "📦 iOS Pods Firebase:" | tee -a "$OUTPUT_FILE"
if [ -d ios ]; then
    cd ios
    if [ -f Podfile.lock ]; then
        grep -i firebase Podfile.lock | tee -a "../$OUTPUT_FILE"
    else
        echo "Podfile.lock non trovato" | tee -a "../$OUTPUT_FILE"
    fi
    cd ..
else
    echo "Directory ios non trovata" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 16. FIREBASE SERVICE
add_section "FIREBASE SERVICE"
echo "🔥 Firebase Service:" | tee -a "$OUTPUT_FILE"
if [ -f lib/core/services/firebase_service.dart ]; then
    grep -A 20 -B 5 "getAPNSToken\|getToken" lib/core/services/firebase_service.dart | tee -a "$OUTPUT_FILE"
else
    echo "File firebase_service.dart non trovato" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 17. INFO.PLIST
add_section "INFO.PLIST"
echo "📱 Info.plist:" | tee -a "$OUTPUT_FILE"
if [ -f ios/Runner/Info.plist ]; then
    grep -A 5 -B 5 "NSAppTransportSecurity\|CFBundleIdentifier" ios/Runner/Info.plist | tee -a "$OUTPUT_FILE"
else
    echo "File Info.plist non trovato" | tee -a "$OUTPUT_FILE"
fi
echo "" | tee -a "$OUTPUT_FILE"

# 18. KEYCHAIN ACCESS
add_section "KEYCHAIN ACCESS"
echo "🔐 Keychain Access:" | tee -a "$OUTPUT_FILE"
security dump-keychain | grep -i "apple development\|ios development\|push" | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 19. FLUTTER DOCTOR
add_section "FLUTTER DOCTOR"
echo "🩺 Flutter Doctor:" | tee -a "$OUTPUT_FILE"
flutter doctor -v | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

# 20. DISPOSITIVI FLUTTER
add_section "DISPOSITIVI FLUTTER"
echo "📱 Dispositivi Flutter:" | tee -a "$OUTPUT_FILE"
flutter devices | tee -a "$OUTPUT_FILE"
echo "" | tee -a "$OUTPUT_FILE"

echo ""
echo "✅ Diagnostica completata!"
echo "📁 File salvato: $OUTPUT_FILE"
echo ""
echo "📋 PROSSIMI PASSI:"
echo "1. Copia questo file sull'altro computer"
echo "2. Esegui lo stesso script sull'altro computer"
echo "3. Confronta i risultati con: diff file1.txt file2.txt"
echo "4. Identifica le differenze nelle configurazioni"
echo ""
echo "🔍 Per confrontare i file:"
echo "diff $OUTPUT_FILE altro_computer_results.txt"
echo ""
