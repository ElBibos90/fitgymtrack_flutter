# 🔥 FIX: Gestione Token FCM Firebase

## 📋 **PROBLEMA RISOLTO**

**Problema**: Il token FCM veniva registrato nel database immediatamente all'avvio dell'app, prima che l'utente fosse effettivamente loggato. Questo causava problemi quando si faceva login con un altro utente, perché il token rimaneva associato all'utente precedente.

**Soluzione**: Spostare la registrazione del token FCM nel momento del login effettivo dell'utente.

---

## 🔧 **MODIFICHE APPORTATE**

### **1. FirebaseService (`lib/core/services/firebase_service.dart`)**

#### **Modifiche:**
- ✅ **Rimosso** invio automatico del token al server durante l'inizializzazione
- ✅ **Aggiunto** metodo `registerTokenForUser(int userId)` per registrare token solo dopo login
- ✅ **Aggiunto** metodo `clearTokenForUser(int userId)` per pulire token durante logout
- ✅ **Mantenuto** salvataggio locale del token per uso futuro

#### **Nuovi Metodi:**
```dart
/// Invia FCM token al server (solo quando utente è loggato)
Future<void> registerTokenForUser(int userId) async

/// Pulisce il token FCM quando l'utente fa logout
Future<void> clearTokenForUser(int userId) async
```

### **2. AuthBloc (`lib/features/auth/bloc/auth_bloc.dart`)**

#### **Modifiche:**
- ✅ **Aggiunto** import di `FirebaseService`
- ✅ **Aggiunto** metodo `_registerFCMTokenAfterLogin(int userId)`
- ✅ **Aggiunto** metodo `_clearFCMTokenOnLogout(int userId)`
- ✅ **Integrato** registrazione token nel flusso di login
- ✅ **Integrato** pulizia token nel flusso di logout
- ✅ **Gestito** token per utenti già autenticati all'avvio

#### **Flusso Aggiornato:**
1. **Login**: Dopo login riuscito → registra token FCM
2. **Avvio App**: Se utente già autenticato → registra token FCM
3. **Logout**: Prima del logout → pulisce token FCM

### **3. API Backend**

#### **File Aggiornati:**
- ✅ **`register_token.php`**: Aggiornato per gestire `user_id` dal client
- ✅ **`clear_token.php`**: Nuovo endpoint per pulire token FCM

#### **Nuovo Endpoint:**
```php
POST /api/firebase/clear_token.php
{
    "fcm_token": "token_value",
    "user_id": 123
}
```

---

## 🚀 **FLUSSO CORRETTO**

### **Prima (PROBLEMA):**
```
1. App si avvia
2. Firebase si inizializza
3. Token FCM viene registrato nel DB (senza user_id corretto)
4. Utente fa login
5. Token rimane associato all'utente precedente
```

### **Dopo (RISOLTO):**
```
1. App si avvia
2. Firebase si inizializza
3. Token FCM viene salvato solo localmente
4. Utente fa login
5. Token FCM viene registrato nel DB con user_id corretto
6. Utente fa logout
7. Token FCM viene rimosso dal DB
```

---

## 🧪 **TESTING**

### **Scenari da Testare:**
1. ✅ **Login nuovo utente**: Token deve essere registrato con user_id corretto
2. ✅ **Logout utente**: Token deve essere rimosso dal database
3. ✅ **Login con utente diverso**: Token precedente deve essere pulito
4. ✅ **Avvio app con utente già autenticato**: Token deve essere registrato
5. ✅ **Notifiche push**: Devono arrivare all'utente corretto

### **Verifica Database:**
```sql
-- Controlla token FCM per utente specifico
SELECT * FROM user_fcm_tokens WHERE user_id = 33;

-- Controlla tutti i token attivi
SELECT * FROM user_fcm_tokens WHERE is_active = 1;
```

---

## 📱 **COMPORTAMENTO MOBILE**

### **Android:**
- ✅ Token FCM viene ottenuto all'avvio
- ✅ Token viene registrato solo dopo login
- ✅ Token viene pulito durante logout
- ✅ Notifiche push funzionano correttamente

### **iOS (Futuro):**
- 🔄 Stesso comportamento di Android
- 🔄 Integrazione con APNs

---

## 🔍 **DEBUG E LOG**

### **Log da Monitorare:**
```
[CONSOLE] [auth_bloc] 🔥 Registering FCM token for user 33...
[CONSOLE] [auth_bloc] ✅ FCM token registered successfully for user 33
[CONSOLE] [auth_bloc] 🔥 Clearing FCM token for user 33...
[CONSOLE] [auth_bloc] ✅ FCM token cleared successfully for user 33
```

### **Verifica Token:**
```dart
// Nel FirebaseService
'📱 FCM Token: $_fcmToken');
```

---

## ⚠️ **NOTE IMPORTANTI**

1. **Autenticazione API**: Gli endpoint `register_token.php` e `clear_token.php` attualmente usano autenticazione temporanea per test. In produzione, abilitare `authMiddleware`.

2. **Gestione Errori**: Tutti i metodi hanno gestione errori completa con log dettagliati.

3. **Performance**: La registrazione del token avviene in background e non blocca l'UI.

4. **Compatibilità**: Le modifiche sono retrocompatibili e non rompono funzionalità esistenti.

---

## 📅 **CHANGELOG**

### **v1.0.0 - Fix Token FCM (25/09/2025)**
- ✅ Risolto problema registrazione token FCM prematura
- ✅ Aggiunta gestione corretta user_id
- ✅ Integrato flusso login/logout
- ✅ Creato endpoint clear_token.php
- ✅ Aggiornato register_token.php
- ✅ Aggiunta gestione errori completa
- ✅ Test completi su Android

---

**📅 Data**: 25/09/2025  
**👨‍💻 Sviluppatore**: AI Assistant  
**🎯 Stato**: Completato e Testato  
**📱 Piattaforma**: Android (iOS in sviluppo)
