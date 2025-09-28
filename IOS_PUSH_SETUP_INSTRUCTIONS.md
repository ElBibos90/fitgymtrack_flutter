# 📱 SETUP NOTIFICHE PUSH iOS - ISTRUZIONI COMPLETE

## 🎯 **PANORAMICA**
Questa guida ti accompagnerà nell'implementazione delle notifiche push iOS per FitGymTrack, completando la Fase 4 del sistema notifiche.

---

## 📋 **PREREQUISITI**
- ✅ Xcode installato (già presente)
- ✅ Flutter installato (già presente)
- ✅ Firebase configurato (già presente)
- ❌ CocoaPods da installare
- ❌ APNs da configurare

---

## 🔧 **STEP 1: INSTALLAZIONE COCOAPODS**

### **Opzione A: Con Homebrew (Raccomandato)**
```bash
# Installa Homebrew se non presente
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installa CocoaPods
brew install cocoapods
```

### **Opzione B: Con RubyGems**
```bash
# Aggiorna Ruby (se necessario)
rbenv install 3.0.0
rbenv global 3.0.0

# Installa CocoaPods
sudo gem install cocoapods
```

### **Verifica Installazione**
```bash
pod --version
# Dovrebbe mostrare la versione di CocoaPods
```

---

## 🔧 **STEP 2: CONFIGURAZIONE PROGETTO iOS**

### **2.1 Aggiorna AppDelegate.swift**
```bash
# Backup del file esistente
cp ios/Runner/AppDelegate.swift ios/Runner/AppDelegate_backup.swift

# Sostituisci con la versione aggiornata
cp ios/Runner/AppDelegate_updated.swift ios/Runner/AppDelegate.swift
```

### **2.2 Aggiorna Info.plist**
Aggiungi le seguenti configurazioni al file `ios/Runner/Info.plist`:

```xml
<!-- Aggiungi questi elementi dentro <dict> -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
    <string>background-processing</string>
</array>

<key>com.apple.developer.usernotifications.filtering</key>
<true/>

<key>com.apple.developer.usernotifications.time-sensitive</key>
<true/>

<key>FirebaseAppDelegateProxyEnabled</key>
<false/>

<key>aps-environment</key>
<string>development</string>
```

---

## 🔧 **STEP 3: INSTALLAZIONE DIPENDENZE iOS**

### **3.1 Installa Pods**
```bash
cd ios
pod install
cd ..
```

### **3.2 Verifica Installazione**
```bash
# Controlla che i pod siano installati
ls ios/Pods/
# Dovrebbe mostrare le cartelle Firebase
```

---

## 🔧 **STEP 4: CONFIGURAZIONE APNs**

### **4.1 Apple Developer Console**
1. Vai su [Apple Developer Console](https://developer.apple.com/account/)
2. Seleziona il tuo Team ID
3. Vai su **Certificates, Identifiers & Profiles**
4. Seleziona **Identifiers** → **App IDs**
5. Trova `com.fitgymtrack.app`

### **4.2 Abilita Push Notifications**
1. Clicca su `com.fitgymtrack.app`
2. Spunta **Push Notifications**
3. Clicca **Save**

### **4.3 Crea Certificato APNs**
1. Vai su **Certificates**
2. Clicca **+** per nuovo certificato
3. Seleziona **Apple Push Notification service SSL (Sandbox & Production)**
4. Seleziona App ID: `com.fitgymtrack.app`
5. Carica CSR (Certificate Signing Request)
6. Scarica il certificato `.cer`

### **4.4 Installa Certificato**
1. Doppio click sul file `.cer`
2. Aggiungi al Keychain Access
3. Esporta come `.p12` con password

---

## 🔧 **STEP 5: CONFIGURAZIONE FIREBASE**

### **5.1 Upload Certificato APNs**
1. Vai su [Firebase Console](https://console.firebase.google.com/)
2. Seleziona progetto `fitgymtrack-1c62f`
3. Vai su **Project Settings** → **Cloud Messaging**
4. Sezione **Apple app configuration**
5. Upload del certificato `.p12`
6. Inserisci password del certificato

### **5.2 Verifica Configurazione**
- Bundle ID: `com.fitgymtrack.app`
- Certificato APNs: ✅ Uploaded
- GoogleService-Info.plist: ✅ Presente

---

## 🔧 **STEP 6: TEST NOTIFICHE PUSH**

### **6.1 Build e Run**
```bash
# Clean build
flutter clean
flutter pub get
cd ios && pod install && cd ..

# Build per iOS
flutter build ios --debug
```

### **6.2 Test su Dispositivo Reale**
1. Collega iPhone/iPad
2. Seleziona dispositivo in Xcode
3. Run app su dispositivo
4. Verifica log FCM token in console

### **6.3 Test Invio Notifica**
1. Usa API `send_push_notification_v1.php`
2. Invia notifica di test
3. Verifica ricezione su dispositivo

---

## 🔧 **STEP 7: CONFIGURAZIONE PRODUZIONE**

### **7.1 Certificato Produzione**
1. Crea nuovo certificato APNs per **Production**
2. Upload su Firebase Console
3. Aggiorna `aps-environment` in Info.plist:
```xml
<key>aps-environment</key>
<string>production</string>
```

### **7.2 Build Release**
```bash
flutter build ios --release
```

---

## 🧪 **TESTING CHECKLIST**

### **✅ Test da Eseguire:**
- [ ] App si avvia senza errori
- [ ] FCM token viene generato
- [ ] Token viene inviato al server
- [ ] Notifiche arrivano quando app è chiusa
- [ ] Notifiche arrivano quando app è in foreground
- [ ] Tap su notifica apre app
- [ ] Badge counter si aggiorna
- [ ] Popup notifiche funziona

### **🔍 Debug Commands:**
```bash
# Verifica log iOS
flutter logs

# Verifica configurazione Firebase
flutter doctor -v

# Verifica pod install
cd ios && pod install --verbose
```

---

## 🚨 **TROUBLESHOOTING**

### **Problema: CocoaPods non si installa**
```bash
# Soluzione: Aggiorna Ruby
rbenv install 3.0.0
rbenv global 3.0.0
gem install cocoapods
```

### **Problema: Pod install fallisce**
```bash
# Soluzione: Clean e reinstall
cd ios
rm -rf Pods Podfile.lock
pod install
```

### **Problema: FCM token non generato**
- Verifica `GoogleService-Info.plist` presente
- Verifica `FirebaseApp.configure()` in AppDelegate
- Verifica permessi notifiche

### **Problema: Notifiche non arrivano**
- Verifica certificato APNs su Firebase
- Verifica `aps-environment` in Info.plist
- Verifica Bundle ID corrispondente

---

## 📚 **FILE DI RIFERIMENTO**

### **File Creati:**
- `ios/Runner/AppDelegate_updated.swift` - AppDelegate con notifiche
- `ios/Runner/Info_plist_additions.xml` - Configurazioni Info.plist
- `IOS_PUSH_SETUP_INSTRUCTIONS.md` - Questa guida

### **File da Modificare:**
- `ios/Runner/AppDelegate.swift` - Sostituire con versione aggiornata
- `ios/Runner/Info.plist` - Aggiungere configurazioni notifiche

---

## 🎯 **PROSSIMI STEP**

Dopo aver completato questa configurazione:

1. **Test Completo**: Verifica tutte le funzionalità
2. **Documentazione**: Aggiorna `NOTIFICATION_SYSTEM_DOCUMENTATION.md`
3. **Fase 5**: Deep Linking avanzato
4. **Fase 6**: Rich Notifications

---

**📅 Data**: 28 Settembre 2025  
**👨‍💻 Sviluppatore**: AI Assistant  
**📋 Versione**: 4.0.0 - iOS Push Notifications Setup  
**🎯 Stato**: Pronto per implementazione
