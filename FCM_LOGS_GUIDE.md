# 🔥 GUIDA LOG FCM - FITGYMTRACK

## 📋 **OVERVIEW**

Tutti i log relativi a Firebase Cloud Messaging (FCM) sono ora contrassegnati con il tag `[CONSOLE] [FCM]` per facilitare il debugging e il testing.

---

## 🏷️ **TAG LOG UTILIZZATI**

### **Tag Principale:**
- `[CONSOLE] [FCM]` - Tutti i log relativi a FCM

### **Altri Tag Correlati:**
- `[CONSOLE] [auth_bloc]` - Log di autenticazione (quando non FCM)
- `[CONSOLE] [NOTIFICHE]` - Log delle notifiche in-app (quando non FCM)

---

## 📱 **LOG FCM DISPONIBILI**

### **🔥 Inizializzazione Firebase:**
```
[CONSOLE] [FCM] 🔥 Firebase initialized successfully
[CONSOLE] [FCM] 📱 FCM Token: [token_value]
[CONSOLE] [FCM] 📱 Notification permission status: [status]
```

### **📱 Gestione Token:**
```
[CONSOLE] [FCM] 📱 FCM Token saved locally (not sent to server yet)
[CONSOLE] [FCM] 🔥 Registering FCM token for user [user_id]...
[CONSOLE] [FCM] 📱 FCM Token registered for user [user_id]
[CONSOLE] [FCM] ✅ FCM token registered successfully for user [user_id]
[CONSOLE] [FCM] 🔥 Clearing FCM token for user [user_id]...
[CONSOLE] [FCM] 📱 FCM Token cleared for user [user_id]
[CONSOLE] [FCM] ✅ FCM token cleared successfully for user [user_id]
```

### **📨 Notifiche Ricevute:**
```
[CONSOLE] [FCM] 📱 Foreground message received: [title]
[CONSOLE] [FCM] 📱 Background message received: [title]
[CONSOLE] [FCM] 📱 Showing local notification with ID: [id]
[CONSOLE] [FCM] 📱 Title: [title]
[CONSOLE] [FCM] 📱 Body: [body]
[CONSOLE] [FCM] 📱 Notification tapped: [payload]
```

### **🔄 Aggiornamento BLoC:**
```
[CONSOLE] [FCM] 📱 Calling _updateNotificationBloc...
[CONSOLE] [FCM] 📱 _updateNotificationBloc called
[CONSOLE] [FCM] 📱 BLoC obtained from GetIt
[CONSOLE] [FCM] 📱 Adding LoadNotificationsEvent...
[CONSOLE] [FCM] 📱 Notification BLoC updated successfully
```

### **❌ Errori:**
```
[CONSOLE] [FCM] ❌ Firebase initialization error: [error]
[CONSOLE] [FCM] ❌ Error getting FCM token: [error]
[CONSOLE] [FCM] ❌ Error registering token for user [user_id]: [error]
[CONSOLE] [FCM] ❌ Error clearing token for user [user_id]: [error]
[CONSOLE] [FCM] ❌ Error updating notification BLoC: [error]
[CONSOLE] [FCM] ❌ BLoC is null, cannot update
```

---

## 🚀 **COMANDI PER FILTRARE LOG FCM**

### **PowerShell (Windows):**
```powershell
# Filtra solo log FCM
flutter run --debug | Select-String '\[CONSOLE\] \[FCM\]'

# Comando alternativo
flutter run --debug | findstr /C:'[CONSOLE] [FCM]'
```

### **Bash (Linux/Mac):**
```bash
# Filtra solo log FCM
flutter run --debug | grep '\[CONSOLE\] \[FCM\]'
```

### **Script Automatico:**
```powershell
# Usa lo script fornito
.\scripts\filter_fcm_logs.ps1
```

---

## 🧪 **SCENARI DI TEST**

### **1. Avvio App (Prima Volta):**
```
[CONSOLE] [FCM] 🔥 Firebase initialized successfully
[CONSOLE] [FCM] 📱 FCM Token: [token]
[CONSOLE] [FCM] 📱 FCM Token saved locally (not sent to server yet)
```

### **2. Login Utente:**
```
[CONSOLE] [FCM] 🔥 Registering FCM token for user 33...
[CONSOLE] [FCM] 📱 FCM Token registered for user 33
[CONSOLE] [FCM] ✅ FCM token registered successfully for user 33
```

### **3. Logout Utente:**
```
[CONSOLE] [FCM] 🔥 Clearing FCM token for user 33...
[CONSOLE] [FCM] 📱 FCM Token cleared for user 33
[CONSOLE] [FCM] ✅ FCM token cleared successfully for user 33
```

### **4. Notifica Ricevuta:**
```
[CONSOLE] [FCM] 📱 Foreground message received: Test Notification
[CONSOLE] [FCM] 📱 Showing local notification with ID: 12345
[CONSOLE] [FCM] 📱 Title: Test Notification
[CONSOLE] [FCM] 📱 Body: This is a test message
[CONSOLE] [FCM] 📱 Calling _updateNotificationBloc...
[CONSOLE] [FCM] 📱 _updateNotificationBloc called
[CONSOLE] [FCM] 📱 BLoC obtained from GetIt
[CONSOLE] [FCM] 📱 Adding LoadNotificationsEvent...
[CONSOLE] [FCM] 📱 Notification BLoC updated successfully
```

---

## 🔍 **DEBUGGING**

### **Problemi Comuni:**

#### **Token non registrato:**
```
[CONSOLE] [FCM] ❌ Error registering token for user 33: [error]
```
**Soluzione**: Verificare connessione internet e autenticazione

#### **BLoC null:**
```
[CONSOLE] [FCM] ❌ BLoC is null, cannot update
```
**Soluzione**: Verificare che NotificationBloc sia registrato in GetIt

#### **Token non pulito:**
```
[CONSOLE] [FCM] ❌ Error clearing token for user 33: [error]
```
**Soluzione**: Verificare endpoint `clear_token.php`

---

## 📊 **MONITORAGGIO**

### **Metriche da Tracciare:**
- ✅ Token registrati con successo
- ❌ Errori di registrazione token
- ✅ Token puliti con successo
- ❌ Errori di pulizia token
- 📱 Notifiche ricevute
- 🔄 Aggiornamenti BLoC

### **Log da Monitorare:**
```bash
# Conta token registrati
grep "FCM token registered successfully" logs.txt | wc -l

# Conta errori
grep "❌ Error" logs.txt | wc -l

# Conta notifiche ricevute
grep "message received" logs.txt | wc -l
```

---

## 🛠️ **CONFIGURAZIONE**

### **Abilitare/Disabilitare Log FCM:**
I log FCM sono abilitati solo in modalità debug (`kDebugMode`). Per disabilitarli temporaneamente, modificare `firebase_service.dart`:

```dart
// Disabilita temporaneamente
if (false && kDebugMode) {
  print('[CONSOLE] [FCM] ...');
}
```

### **Livello di Verbosità:**
- **Minimo**: Solo errori e successi
- **Normale**: Tutti i log FCM (default)
- **Massimo**: Tutti i log + dettagli tecnici

---

## 📅 **CHANGELOG**

### **v1.0.0 - Log FCM Organizzati (25/09/2025)**
- ✅ Aggiunto tag `[CONSOLE] [FCM]` a tutti i log FCM
- ✅ Creato script di filtro `filter_fcm_logs.ps1`
- ✅ Documentazione completa dei log disponibili
- ✅ Guide per debugging e testing
- ✅ Comandi per filtrare log FCM

---

**📅 Data**: 25/09/2025  
**👨‍💻 Sviluppatore**: AI Assistant  
**🎯 Stato**: Completato  
**📱 Piattaforma**: Android (iOS in sviluppo)
