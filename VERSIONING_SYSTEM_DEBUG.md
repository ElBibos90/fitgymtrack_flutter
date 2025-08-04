# 🔧 SISTEMA VERSIONING TARGETED - DEBUG IN CORSO

## 📋 **STATO ATTUALE**

### **✅ IMPLEMENTATO:**
- Database con campi `is_tester`, `platform`, `target_audience`
- API `version.php` con targeting funzionante
- Script deploy PowerShell con logica corretta
- App Flutter con `AppUpdateService` integrato
- Modello `User` con campo `is_tester`

### **🎯 PROBLEMA IDENTIFICATO:**
L'app non rileva che l'utente è un tester perché i dati salvati localmente non includono `is_tester`.

### **🔧 ULTIMA MODIFICA:**
Modificato `app_update_service.dart` per chiamare direttamente l'API `verify` invece di usare i dati locali.

## 📊 **DATABASE ATTUALE**

```sql
-- PRODUZIONE (sempre attiva)
ID 23: 1.0.25 (both, production) - is_active = 1 ✅

-- TEST (solo iOS attiva)
ID 24: 1.0.26 (ios, test) - is_active = 0 ❌ (disattivata)
ID 26: 1.0.27 (both, test) - is_active = 0 ❌ (disattivata)  
ID 27: 1.0.28 (ios, test) - is_active = 1 ✅ (attiva)
```

## 🧪 **TEST API - FUNZIONANTI**

### **Tester iOS:**
```
GET https://104.248.103.182/api/version.php?platform=ios&is_tester=1
→ {"version": "1.0.28", "target_audience": "test"}
```

### **Produzione:**
```
GET https://104.248.103.182/api/version.php
→ {"version": "1.0.25", "target_audience": "production"}
```

### **User Data:**
```
GET https://104.248.103.182/api/auth.php?action=verify
→ {"is_tester": 1, "role_name": "standalone"}
```

## 🔍 **ULTIMI LOG APP**

```
flutter: [CONSOLE] [app_update_service]📱 Current version: 1.0.27 (27)
flutter: [CONSOLE] [app_update_service]🔍 DEBUG: User data: {is_tester: null}
flutter: [CONSOLE] [app_update_service]👤 User tester status: false
flutter: [CONSOLE] [app_update_service]🌐 Calling API with params: platform=ios, isTester=false
flutter: [CONSOLE] [app_update_service]🌐 API Response: {version: 1.0.25, target_audience: production}
```

## 🚀 **PROSSIMO STEP**

1. **Testare la versione modificata** dell'app (chiama direttamente API verify)
2. **Verificare che rilevi `is_tester: 1`** dal server
3. **Confermare che invii `isTester=true`** all'API version
4. **Verificare che riceva versione 1.0.28** (test)
5. **Confermare che mostri l'aggiornamento** da 1.0.27 a 1.0.28

## 📁 **FILE MODIFICATI**

### **Backend:**
- `Api server/version.php` - Targeting per platform e is_tester
- `Api server/users.php` - Aggiunto campo is_tester alle query
- `Api server/auth_functions.php` - Aggiunto campo is_tester a validateAuthToken

### **Frontend:**
- `lib/features/auth/models/login_response.dart` - Aggiunto campo isTester al modello User
- `lib/core/services/app_update_service.dart` - Logica targeting e debug logs
- `lib/core/network/api_client.dart` - Parametri per getAppVersion

### **Script:**
- `scripts/deploy_final_fixed.ps1` - Logica per disattivare solo versioni dello stesso target

## 🎯 **OBIETTIVO FINALE**

Sistema di versioning che permette:
- **Deploy TEST** → Solo tester vedono aggiornamento
- **Deploy PRODUZIONE** → Tutti vedono aggiornamento
- **Targeting per piattaforma** → iOS/Android specifici
- **Due versioni attive contemporaneamente** → Test e produzione

## 🔧 **COMANDI UTILI**

```bash
# Compilare per iOS
flutter build ios --debug

# Log dettagliati
flutter logs --verbose

# Test API
curl "https://104.248.103.182/api/version.php?platform=ios&is_tester=1"
```

## 📞 **CONTATTO**

Utente: Eddy (ID: 17, is_tester: 1, role: standalone)
Versione corrente: 1.0.27
Piattaforma: iOS
Risultato atteso: Aggiornamento a 1.0.28 