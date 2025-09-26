# 🔍 DIAGNOSTICA iOS FIREBASE - CONFRONTO CONFIGURAZIONI

## 📋 **ISTRUZIONI**

Esegui questi comandi su **ENTRAMBI** i computer e confronta i risultati per identificare le differenze.

---

## 🖥️ **1. INFORMAZIONI SISTEMA**

### **macOS Version**
```bash
sw_vers
```

### **Xcode Version**
```bash
xcodebuild -version
```

### **Flutter Version**
```bash
flutter --version
```

### **Dart Version**
```bash
dart --version
```

---

## 📱 **2. EMULATORI iOS DISPONIBILI**

### **Lista Emulatori**
```bash
xcrun simctl list devices
```

### **Emulatori Booted**
```bash
xcrun simctl list devices | grep Booted
```

### **Runtime iOS Disponibili**
```bash
xcrun simctl list runtimes
```

---

## 🔐 **3. APPLE DEVELOPER ACCOUNT**

### **Identità di Firma**
```bash
security find-identity -v -p codesigning
```

### **Profili di Provisioning**
```bash
ls ~/Library/MobileDevice/Provisioning\ Profiles/
```

### **Keychain Access**
```bash
security dump-keychain | grep -i "apple development\|ios development\|push"
```

---

## 🔥 **4. FIREBASE CONFIGURAZIONE**

### **File GoogleService-Info.plist (iOS)**
```bash
cat ios/Runner/GoogleService-Info.plist
```

### **File google-services.json (Android)**
```bash
cat android/app/google-services.json
```

### **Verifica Bundle ID iOS**
```bash
grep -A 1 "PRODUCT_BUNDLE_IDENTIFIER" ios/Runner.xcodeproj/project.pbxproj
```

### **Verifica Package Name Android**
```bash
grep "applicationId" android/app/build.gradle
```

---

## 📦 **5. DIPENDENZE FLUTTER**

### **Pubspec.yaml Firebase**
```bash
grep -A 10 -B 2 "firebase" pubspec.yaml
```

### **Flutter Packages**
```bash
flutter pub deps | grep firebase
```

### **iOS Pods**
```bash
cd ios && pod list | grep Firebase
```

---

## 🛠️ **6. CONFIGURAZIONE XCODE**

### **Project Settings**
```bash
# Apri Xcode e verifica:
# 1. ios/Runner.xcworkspace
# 2. Target "Runner" → "Signing & Capabilities"
# 3. Verifica Team selezionato
# 4. Verifica "Push Notifications" capability
```

### **Entitlements File**
```bash
cat ios/Runner/Runner.entitlements
```

### **Info.plist**
```bash
cat ios/Runner/Info.plist | grep -A 5 -B 5 "NSAppTransportSecurity\|CFBundleIdentifier"
```

---

## 🔧 **7. CONFIGURAZIONE FIREBASE SERVICE**

### **FirebaseService.dart**
```bash
grep -A 20 -B 5 "getAPNSToken\|getToken" lib/core/services/firebase_service.dart
```

### **AppDelegate.swift**
```bash
cat ios/Runner/AppDelegate.swift
```

---

## 📊 **8. LOG DI RUNTIME**

### **Flutter Run con Log Dettagliati**
```bash
flutter run -d "DEVICE_ID" --verbose
```

### **Xcode Console Log**
```bash
# Apri Xcode → Window → Devices and Simulators
# Seleziona emulatore → View Device Logs
# Filtra per "APNs" o "Firebase"
```

---

## 🧪 **9. TEST SPECIFICI**

### **Test APNs Token**
```bash
# Nel codice Flutter, aggiungi questo log:
# print('APNs Token: ${await FirebaseMessaging.instance.getAPNSToken()}');
```

### **Test FCM Token**
```bash
# Nel codice Flutter, aggiungi questo log:
# print('FCM Token: ${await FirebaseMessaging.instance.getToken()}');
```

### **Test Permessi Notifiche**
```bash
# Nel codice Flutter, aggiungi questo log:
# print('Permission Status: ${await FirebaseMessaging.instance.getNotificationSettings()}');
```

---

## 🔍 **10. VERIFICA FIREBASE CONSOLE**

### **Configurazioni da Verificare**
1. **Project ID**: `fitgymtrack-1c62f`
2. **iOS App**: Bundle ID `com.fitgymtrack.app`
3. **Android App**: Package Name `com.fitgymtracker`
4. **APNs Certificates**: Verifica se sono configurati
5. **Service Account**: Verifica se è configurato per push notifications

---

## 📝 **11. COMANDI DI CONFRONTO**

### **Crea File di Confronto**
```bash
# Computer 1 (quello che funziona)
./diagnostica.sh > computer1_results.txt

# Computer 2 (quello con problemi)
./diagnostica.sh > computer2_results.txt

# Confronta i risultati
diff computer1_results.txt computer2_results.txt
```

### **Script Diagnostica Completa**
```bash
#!/bin/bash
echo "=== DIAGNOSTICA iOS FIREBASE ===" > diagnostica_results.txt
echo "Data: $(date)" >> diagnostica_results.txt
echo "" >> diagnostica_results.txt

echo "=== SISTEMA ===" >> diagnostica_results.txt
sw_vers >> diagnostica_results.txt
echo "" >> diagnostica_results.txt

echo "=== XCODE ===" >> diagnostica_results.txt
xcodebuild -version >> diagnostica_results.txt
echo "" >> diagnostica_results.txt

echo "=== FLUTTER ===" >> diagnostica_results.txt
flutter --version >> diagnostica_results.txt
echo "" >> diagnostica_results.txt

echo "=== EMULATORI ===" >> diagnostica_results.txt
xcrun simctl list devices >> diagnostica_results.txt
echo "" >> diagnostica_results.txt

echo "=== DEVELOPER ACCOUNT ===" >> diagnostica_results.txt
security find-identity -v -p codesigning >> diagnostica_results.txt
echo "" >> diagnostica_results.txt

echo "=== FIREBASE iOS ===" >> diagnostica_results.txt
cat ios/Runner/GoogleService-Info.plist >> diagnostica_results.txt
echo "" >> diagnostica_results.txt

echo "=== FIREBASE ANDROID ===" >> diagnostica_results.txt
cat android/app/google-services.json >> diagnostica_results.txt
echo "" >> diagnostica_results.txt

echo "=== ENTITLEMENTS ===" >> diagnostica_results.txt
cat ios/Runner/Runner.entitlements >> diagnostica_results.txt
echo "" >> diagnostica_results.txt

echo "=== APPDELEGATE ===" >> diagnostica_results.txt
cat ios/Runner/AppDelegate.swift >> diagnostica_results.txt
echo "" >> diagnostica_results.txt

echo "Diagnostica completata: diagnostica_results.txt"
```

---

## 🎯 **12. CHECKLIST PROBLEMI COMUNI**

### **✅ Verifica Questi Punti**
- [ ] **iOS Version**: Stessa versione iOS su entrambi i computer?
- [ ] **Xcode Version**: Stessa versione Xcode?
- [ ] **Apple Developer Account**: Stesso account configurato?
- [ ] **Bundle ID**: Stesso bundle ID in Firebase Console?
- [ ] **APNs Certificates**: Certificati configurati in Firebase Console?
- [ ] **Push Notifications Capability**: Aggiunta in Xcode?
- [ ] **Team Selection**: Team corretto selezionato in Xcode?
- [ ] **Entitlements**: File entitlements configurato correttamente?
- [ ] **Firebase Service Account**: Configurato per push notifications?

---

## 🚨 **13. SOLUZIONI RAPIDE**

### **Se APNs Token non funziona:**
1. Verifica Apple Developer Account
2. Aggiungi Push Notifications capability in Xcode
3. Verifica Team selection in Xcode
4. Prova con iOS stabile (non beta)
5. Reset emulatore iOS

### **Se FCM Token è null:**
1. Verifica GoogleService-Info.plist
2. Verifica Bundle ID corrispondente
3. Verifica Firebase Console configuration
4. Verifica Service Account permissions

### **Se notifiche non arrivano:**
1. Verifica APNs certificates in Firebase Console
2. Verifica entitlements file
3. Verifica AppDelegate configuration
4. Testa su dispositivo reale (non emulatore)

---

## 📞 **14. SUPPORTO**

### **Log da Inviare per Supporto:**
1. Output di tutti i comandi sopra
2. Screenshot Firebase Console
3. Screenshot Xcode Signing & Capabilities
4. Log Flutter run completo
5. Log Xcode Console

### **File da Condividere:**
- `diagnostica_results.txt`
- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`
- `ios/Runner/Runner.entitlements`
- `ios/Runner/AppDelegate.swift`

---

**📅 Creato**: $(date)  
**👨‍💻 Per**: Confronto configurazioni iOS Firebase  
**🎯 Obiettivo**: Identificare differenze tra computer funzionante e non funzionante
