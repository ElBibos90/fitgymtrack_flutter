# 🔔 SISTEMA NOTIFICHE IN-APP - FITGYMTRACK

## 📋 **INDICE**
1. [Panoramica](#panoramica)
2. [Architettura Sistema](#architettura-sistema)
3. [Fase 1 - Sistema Base](#fase-1---sistema-base)
4. [Fasi Future](#fasi-future)
5. [Linee Guida Implementazione](#linee-guida-implementazione)
6. [Database Schema](#database-schema)
7. [API Endpoints](#api-endpoints)
8. [Frontend Components](#frontend-components)
9. [Mobile Implementation](#mobile-implementation)

---

## 🎯 **PANORAMICA**

Il sistema di notifiche in-app permette alle palestre e ai trainer di comunicare direttamente con i propri utenti attraverso l'applicazione mobile e la webapp.

### **Obiettivi:**
- Comunicazione diretta palestra → utenti
- Messaggi personalizzati o broadcast
- Sistema anti-spam per notifiche già lette
- Integrazione con feature future (corsi, promozioni)

---

## 🏗️ **ARCHITETTURA SISTEMA**

### **Ruoli Utenti:**
- **`admin`** - Amministratore sistema (accesso completo)
- **`gym`** - Gestore palestra (gestisce membri della sua palestra)
- **`trainer`** - Personal trainer (gestisce clienti della sua palestra)
- **`user`** - Utente normale (legato a palestra/trainer)
- **`standalone`** - Utente indipendente (gestisce tutto da solo)

### **Relazioni Chiave:**
- **Palestra → Trainer → Utenti**: Gerarchia con `gym_id` e `trainer_id`
- **Utenti Standalone**: Indipendenti con `is_standalone = 1`
- **Sistema di Permessi**: Basato su `gym_id` per accessi cross-palestra

### **Flusso Notifiche:**
1. **Gym/Trainer** crea messaggio → seleziona destinatari → invia
2. **Utenti** ricevono notifica in-app → possono leggerla
3. **Sistema** traccia stato (inviata/letta) e previene spam

---

## 🚀 **FASE 1 - SISTEMA BASE**

### **✅ COMPLETATO E TESTATO - 25 Settembre 2025:**

#### **1. Database Schema**
- ✅ Tabella `notifications` con campi essenziali
- ✅ Tabella `notification_broadcast_log` per statistiche
- ✅ Relazioni con `users` esistenti
- ✅ Supporto per sender/recipient con ruoli
- ✅ **FIX**: Broadcast invia solo ai membri (ruolo 'user'), non ai trainer

#### **2. API Backend (PHP)**
- ✅ `notifications.php` con operazioni CRUD complete
- ✅ Endpoint per:
  - Inviare notifica singola o broadcast
  - Recuperare notifiche per utente
  - Marcare come lette
  - Recuperare notifiche inviate (per gym/trainer)
- ✅ Permessi basati su `gym_id`
- ✅ **FIX**: Query broadcast filtrata per ruolo 'user' solo
- ✅ **FIX**: Permessi `gym` aggiunti a `users.php` API

#### **3. Frontend Web (React)**
- ✅ Componente `NotificationManager.jsx` condiviso per Gym/Trainer
- ✅ Form per creare messaggi con:
  - Campo titolo e messaggio
  - Selezione destinatari (singolo o tutti)
  - Tipo (messaggio, annuncio, promemoria)
  - Priorità (bassa, normale, alta)
- ✅ Lista notifiche inviate con statistiche
- ✅ UI responsive e moderna
- ✅ **FIX**: Tema scuro completamente integrato
- ✅ **FIX**: Filtro destinatari solo per membri (ruolo 'user')
- ✅ **FIX**: Integrazione completa in pannelli Gym/Trainer

#### **4. Mobile (Flutter) - PRONTO PER INTEGRAZIONE**
- ✅ Modelli `notification_models.dart` con serializzazione JSON
- ✅ Repository `notification_repository.dart` per API calls
- ✅ BLoC `notification_bloc.dart` per gestione stato
- ✅ Schermata `notifications_screen.dart` con:
  - Lista notifiche ricevute
  - Badge counter per notifiche non lette
  - Sistema anti-spam (notifiche lette non generano nuove notifiche)
  - Pull-to-refresh e paginazione
  - UI nativa con indicatori visivi
- 🔄 **DA INTEGRARE**: Route in app router e badge counter

### **🔧 Caratteristiche Tecniche:**
- **Sistema Anti-Spam**: Notifiche già lette non vengono più mostrate come "nuove"
- **Permessi**: Gym/Trainer possono inviare solo agli utenti della propria palestra
- **Broadcast**: Possibilità di inviare a tutti gli utenti della palestra
- **Statistiche**: Tracking di notifiche inviate, consegnate e lette
- **Performance**: Paginazione e lazy loading per liste lunghe

---

## 🚀 **FASE 2 - INTEGRAZIONE MOBILE COMPLETA**

### **✅ COMPLETATO E TESTATO - 25 Settembre 2025:**

#### **1. Architettura Mobile Flutter**
- ✅ **Modelli** - `Notification`, `NotificationResponse`, `NotificationPagination`
- ✅ **Repository** - `NotificationRepository` con Dio HTTP client
- ✅ **BLoC** - `NotificationBloc` per gestione stati e eventi
- ✅ **UI Components** - `NotificationsScreen`, `NotificationPopup`, `NotificationBadgeIcon`

#### **2. Integrazione Sistema**
- ✅ **Dependency Injection** - GetIt per NotificationRepository e NotificationBloc
- ✅ **Routing** - GoRouter per `/notifications` con AuthWrapper
- ✅ **Navigazione** - Tab "Notifiche" in bottom navigation bar
- ✅ **Badge Counter** - Contatore dinamico notifiche non lette

#### **3. Funzionalità Avanzate**
- ✅ **Popup Interattivo** - Tap notifica → popup con dettagli completi
- ✅ **Azioni Dinamiche** - "Segna come letta" + "Chiudi"
- ✅ **Struttura Estendibile** - Pronta per azioni future (corsi, iscrizioni)
- ✅ **Feedback Utente** - SnackBar per conferme azioni
- ✅ **Tema Scuro** - Supporto completo per tutti i componenti

#### **4. Gestione Errori e Fix**
- ✅ **JSON Parsing** - Campo `is_broadcast` nullable gestito correttamente
- ✅ **BLoC States** - Gestione corretta stati senza loop infiniti
- ✅ **UI Responsive** - Layout adattivo per diversi dispositivi
- ✅ **Performance** - Caricamento ottimizzato con paginazione

#### **5. Test Completati**
- ✅ **Invio Webapp** - Gym/Trainer → Membro funzionante
- ✅ **Ricezione Mobile** - Badge counter si aggiorna dinamicamente
- ✅ **Popup Funzionante** - Tap notifica → popup con dettagli completi
- ✅ **Segna come Letta** - Aggiornamento UI immediato e feedback
- ✅ **Tema Scuro** - Supporto completo senza errori
- ✅ **Zero Errori** - Sistema stabile e completamente funzionante

---

## 🔥 **FASE 3 - FIREBASE PUSH NOTIFICATIONS**

### **✅ COMPLETATO E TESTATO - 25 Settembre 2025:**

#### **1. Firebase Integration Android**
- ✅ **Firebase Core** - Inizializzazione corretta in `FirebaseService`
- ✅ **Firebase Messaging** - FCM token registration e management
- ✅ **Local Notifications** - `flutter_local_notifications` per foreground
- ✅ **Push Notifications** - Arrivano correttamente quando app è chiusa
- ✅ **BLoC Integration** - Badge campanellina si aggiorna automaticamente

#### **2. Server-Side Implementation**
- ✅ **Database Schema** - Tabella `user_fcm_tokens` per storage token
- ✅ **Token Registration** - API `register_token.php` per salvare FCM token
- ✅ **Push Sending** - API `send_push_notification_v1.php` con Firebase V1 API
- ✅ **JWT Authentication** - Service Account per autenticazione Firebase
- ✅ **Broadcast Support** - Invio a tutti gli utenti della palestra

#### **3. Mobile Features**
- ✅ **Foreground Handling** - Notifiche mostrate quando app è aperta
- ✅ **Background Handling** - Navigazione automatica quando app è chiusa
- ✅ **Badge Update** - Contatore notifiche si aggiorna in tempo reale
- ✅ **Popup Integration** - Notifiche push si integrano con popup esistente
- ✅ **Anti-Spam** - Sistema previene notifiche duplicate

#### **4. UI/UX Improvements**
- ✅ **Bell Icon** - Rimosso tab bottom navigation, aggiunto bell in AppBar
- ✅ **Popup Overlay** - Modern popup con lista notifiche recenti
- ✅ **Dark Theme** - Supporto completo per tema scuro
- ✅ **Responsive Design** - Layout adattivo per diversi dispositivi
- ✅ **User Feedback** - Log con tag `[NOTIFICHE]` per debug

#### **5. Technical Implementation**
- ✅ **GetIt Integration** - Accesso diretto al BLoC senza navigatorKey
- ✅ **Error Handling** - Gestione errori Firebase e network
- ✅ **Performance** - Ottimizzazioni per notifiche multiple
- ✅ **Security** - Autenticazione e autorizzazione corrette
- ✅ **Testing** - Test completi con Postman e app reale

#### **6. Configuration Files**
- ✅ **Android** - `google-services.json` con package `com.fitgymtracker`
- ✅ **Gradle** - Configurazione Firebase plugin e dependencies
- ✅ **Service Account** - Credenziali Firebase per server-side
- ✅ **API Keys** - Configurazione corretta per V1 API

#### **7. Test Results**
- ✅ **Push Arrival** - Notifiche arrivano correttamente
- ✅ **Badge Update** - Campanellina si aggiorna dinamicamente
- ✅ **Popup Display** - Lista notifiche mostra contenuti corretti
- ✅ **Mark as Read** - Funzionalità segna come letta funzionante
- ✅ **Dark Theme** - Supporto completo senza errori
- ✅ **Zero Errors** - Sistema stabile e completamente funzionante

---

## 🔮 **FASI FUTURE**

### **📅 FASE 4 - iOS Push Notifications (IN CORSO)**
- **🔍 STEP 1**: Controlli sistema iOS - Verificare dettagli sistema, configurazione Xcode
- **🔍 STEP 2**: iOS Firebase Integration - APNs + Firebase per iOS
- **🔍 STEP 3**: iOS Configuration - `GoogleService-Info.plist` e setup Xcode
- **🔍 STEP 4**: iOS Testing - Test su dispositivi iOS reali
- **🔍 STEP 5**: Cross-Platform - Notifiche funzionanti su Android e iOS

### **📅 FASE 5 - Deep Linking Avanzato**
- **Deep Linking**: Apertura diretta a sezioni specifiche
- **Course Linking**: Link diretti a corsi specifici
- **Event Linking**: Link diretti a eventi prenotati
- **Profile Linking**: Link diretti a profili utenti

### **📅 FASE 6 - Rich Notifications**
- **Immagini**: Notifiche con immagini personalizzate
- **Azioni**: Bottoni "Iscriviti", "Conferma", "Rifiuta"
- **Suoni**: Suoni personalizzati per tipi di notifica
- **Vibrazioni**: Pattern vibrazione personalizzati

### **📅 FASE 7 - Gruppi e Broadcast Avanzati**
- **Gruppi Personalizzati**: Creazione gruppi utenti (es. "Corso Yoga", "Premium")
- **Filtri Dinamici**: Gruppi automatici per età, obiettivi, frequenza
- **Templates**: Messaggi predefiniti per tipologie comuni
- **Scheduling**: Invio notifiche programmate

### **📅 FASE 8 - Notifiche Programmabili**
- **Ricorrenti**: "Promemoria allenamento ogni Lunedì"
- **Condizionali**: "Se non ti alleni da 3 giorni"
- **Eventi**: "1 ora prima del corso prenotato"
- **Workflow**: Automazioni basate su trigger

### **📅 FASE 9 - Integrazione Corsi e Eventi**
- **Inviti Corsi**: Notifiche automatiche per nuovi corsi
- **Promemoria**: Ricordi per allenamenti programmati
- **Check-in**: Notifiche per conferma presenza
- **Feedback**: Raccolta opinioni post-corso
- **Azioni Popup**: "Iscriviti al Corso", "Conferma Partecipazione"

### **📅 FASE 10 - Analytics e Ottimizzazioni**
- **Dashboard Analytics**: Tasso apertura, engagement, orari ottimali
- **A/B Testing**: Testare diversi messaggi
- **Personalizzazione**: Orari preferiti, frequenza
- **Segnalazioni**: Sistema feedback utenti

### **📅 FASE 11 - AI e Automazioni Avanzate**
- **Smart Scheduling**: Orari ottimali per invio
- **Content Suggestions**: Suggerimenti messaggi
- **Sentiment Analysis**: Analisi feedback utenti
- **Chat Integrata**: Messaggi bidirezionali con reazioni

---

## 📝 **LINEE GUIDA IMPLEMENTAZIONE**

### **⚠️ REGOLE IMPORTANTI:**
1. **Sempre presentare le feature** prima di implementare
2. **Aspettare approvazione** prima di scrivere codice
3. **Solo controllo errori IDE**, niente build
4. **Un comando alla volta** per troubleshooting
5. **Un cambiamento alla volta** e aspettare test
6. **Creare file di documentazione** alla fine

### **🔄 Processo di Sviluppo:**
1. **Analisi**: Studiare architettura esistente
2. **Progettazione**: Definire feature e API
3. **Approvazione**: Attendere OK dall'utente
4. **Implementazione**: Codice con controlli IDE
5. **Test**: Verifica funzionamento
6. **Documentazione**: Aggiornare questo file

---

## 🗄️ **DATABASE SCHEMA**

### **Tabella `notifications`:**
```sql
CREATE TABLE notifications (
    id INT PRIMARY KEY AUTO_INCREMENT,
    sender_id INT NOT NULL,           -- Gym owner o Trainer
    sender_type ENUM('gym', 'trainer') NOT NULL,
    recipient_id INT,                 -- NULL per broadcast
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('message', 'announcement', 'reminder') DEFAULT 'message',
    priority ENUM('low', 'normal', 'high') DEFAULT 'normal',
    status ENUM('sent', 'delivered', 'read') DEFAULT 'sent',
    is_broadcast BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    
    INDEX idx_sender (sender_id),
    INDEX idx_recipient (recipient_id),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    INDEX idx_broadcast (is_broadcast),
    
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### **Tabella `notification_broadcast_log`:**
```sql
CREATE TABLE notification_broadcast_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    notification_id INT NOT NULL,
    recipient_id INT NOT NULL,
    delivered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    read_at TIMESTAMP NULL,
    
    INDEX idx_notification (notification_id),
    INDEX idx_recipient (recipient_id),
    
    FOREIGN KEY (notification_id) REFERENCES notifications(id) ON DELETE CASCADE,
    FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE
);
```

---

## 🌐 **API ENDPOINTS**

### **Base URL**: `/notifications.php`

#### **GET /notifications.php**
- **Descrizione**: Recupera notifiche per utente
- **Parametri**: `page`, `limit`
- **Risposta**: Lista notifiche con paginazione

#### **POST /notifications.php**
- **Descrizione**: Invia notifica (singola o broadcast)
- **Body**: `{title, message, type, priority, recipient_id?, is_broadcast}`
- **Permessi**: Solo gym/trainer

#### **PUT /notifications.php?id={id}&action=read**
- **Descrizione**: Marca notifica come letta
- **Parametri**: `id` (notification_id)
- **Risposta**: Conferma aggiornamento

#### **GET /notifications.php?action=sent**
- **Descrizione**: Recupera notifiche inviate (per gym/trainer)
- **Parametri**: `page`, `limit`
- **Risposta**: Lista notifiche inviate con statistiche

---

## 💻 **FRONTEND COMPONENTS**

### **React Component: `NotificationManager.jsx`**
- **Posizione**: `Gym-2.0/src/components/notifications/`
- **Funzionalità**:
  - Form invio messaggi
  - Selezione destinatari
  - Lista notifiche inviate
  - Statistiche engagement
- **UI**: Moderna con Tailwind CSS
- **Responsive**: Mobile-first design

### **Integrazione**:
- Aggiungere route in App.js
- Importare in pagine Gym e Trainer
- Stesso componente per entrambi i ruoli

---

## 📱 **MOBILE IMPLEMENTATION**

### **Flutter Structure**:
```
lib/features/notifications/
├── models/
│   └── notification_models.dart
├── repositories/
│   └── notification_repository.dart
├── bloc/
│   └── notification_bloc.dart
└── presentation/
    └── screens/
        └── notifications_screen.dart
```

### **Features Implementate**:
- **Lista Notifiche**: Con pull-to-refresh e paginazione
- **Badge Counter**: Solo per notifiche non lette
- **Sistema Anti-Spam**: Notifiche lette non generano nuove notifiche
- **UI Nativa**: Con indicatori visivi per priorità e stato
- **Gestione Errori**: Con retry automatico

### **Integrazione**:
- Aggiungere route in app router
- Integrare badge counter in navigation
- Configurare notifiche push (futuro)

---

## 🔧 **CONFIGURAZIONE NECESSARIA**

### **Database**:
1. Eseguire `notifications_schema.sql`
2. Verificare permessi utenti
3. Testare relazioni foreign key

### **Backend**:
1. Copiare `notifications.php` in API server
2. Verificare autenticazione
3. Testare endpoint con Postman

### **Frontend Web**:
1. Copiare `NotificationManager.jsx`
2. Aggiungere route in App.js
3. Importare in pagine Gym/Trainer

### **Mobile Flutter**:
1. Copiare tutti i file in `lib/features/notifications/`
2. Eseguire `flutter packages pub run build_runner build`
3. Aggiungere route in app router
4. Configurare dependency injection

---

## 🧪 **TESTING**

### **Test da Eseguire**:
1. **Database**: Inserimento, lettura, aggiornamento notifiche
2. **API**: Tutti gli endpoint con diversi ruoli utente
3. **Frontend**: Invio messaggi, visualizzazione liste
4. **Mobile**: Ricezione, lettura, badge counter
5. **Permessi**: Verifica accessi cross-palestra

### **Scenari di Test**:
- Gym invia a tutti gli utenti
- Trainer invia a singolo utente
- Utente legge notifica
- Broadcast con statistiche
- Errori di permessi

---

## 📊 **MONITORAGGIO**

### **Metriche da Tracciare**:
- Notifiche inviate per giorno
- Tasso di apertura
- Tempo medio di lettura
- Errori API
- Performance database

### **Log da Monitorare**:
- Errori PHP in `error_log`
- Errori Flutter in console
- Errori React in browser console
- Performance database queries

---

## 🚨 **TROUBLESHOOTING**

### **Problemi Comuni**:
1. **Notifiche non arrivano**: Verificare `gym_id` e permessi
2. **Badge counter non aggiorna**: Controllare stato `read_at`
3. **Errori API**: Verificare autenticazione e parametri
4. **Performance lente**: Controllare indici database

### **Debug Steps**:
1. Controllare log PHP
2. Verificare query database
3. Testare endpoint con Postman
4. Controllare console browser/mobile

---

## 📚 **RISORSE AGGIUNTIVE**

### **Documentazione Tecnica**:
- [Flutter BLoC Pattern](https://bloclibrary.dev/)
- [React Hooks](https://reactjs.org/docs/hooks-intro.html)
- [PHP PDO](https://www.php.net/manual/en/book.pdo.php)
- [MySQL Indexes](https://dev.mysql.com/doc/refman/8.0/en/mysql-indexes.html)

### **File di Riferimento**:
- `fitgymtrack_flutter/Api server/notifications_schema.sql`
- `fitgymtrack_flutter/Api server/notifications.php`
- `fitgymtrack_flutter/Api server/firebase/fcm_tokens_schema.sql`
- `fitgymtrack_flutter/Api server/firebase/register_token.php`
- `fitgymtrack_flutter/Api server/firebase/send_push_notification_v1.php`
- `Gym-2.0/src/components/notifications/NotificationManager.jsx`
- `fitgymtrack_flutter/lib/features/notifications/`
- `fitgymtrack_flutter/lib/core/services/firebase_service.dart`
- `fitgymtrack_flutter/android/app/google-services.json`
- `fitgymtrack_flutter/ios/Runner/GoogleService-Info.plist`

---

## 📝 **CHANGELOG**

### **v1.0.0 - Fase 1 (COMPLETATA E TESTATA)**
- ✅ Database schema base
- ✅ API backend completa
- ✅ Frontend React component
- ✅ Mobile Flutter implementation (pronto per integrazione)
- ✅ Sistema anti-spam
- ✅ Permessi e sicurezza
- ✅ **FIX**: Broadcast solo ai membri
- ✅ **FIX**: Tema scuro integrato
- ✅ **FIX**: Filtri destinatari corretti
- ✅ **FIX**: Permessi gym in users.php

### **v2.0.0 - Fase 2 (COMPLETATA E TESTATA)**
- ✅ Integrazione mobile completa
- ✅ BLoC pattern implementation
- ✅ Popup interattivo
- ✅ Badge counter dinamico
- ✅ Tema scuro support
- ✅ Zero errori sistema

### **v3.0.0 - Fase 3 (COMPLETATA E TESTATA)**
- ✅ Firebase Push Notifications Android
- ✅ FCM token registration
- ✅ Server-side push sending
- ✅ BLoC integration automatica
- ✅ Bell icon in AppBar
- ✅ Popup overlay moderno
- ✅ Anti-spam system
- ✅ Dark theme completo

### **v4.0.0 - Fase 4 (IN CORSO - iOS Push Notifications)**
- 🔄 **PROSSIMO STEP**: Controlli sistema iOS
- 🔄 **DA VERIFICARE**: Dettagli sistema iOS, configurazione Xcode
- 🔄 **DA IMPLEMENTARE**: iOS Push Notifications
- 🔄 **DA IMPLEMENTARE**: APNs integration
- 🔄 **DA IMPLEMENTARE**: Cross-platform testing

### **v5.0.0 - Fase 5 (Pianificata)**
- 🔄 Deep Linking avanzato
- 🔄 Course/Event linking
- 🔄 Profile linking

### **v6.0.0 - Fase 6 (Pianificata)**
- 🔄 Rich Notifications
- 🔄 Immagini e azioni
- 🔄 Suoni personalizzati

---

**📅 Ultimo Aggiornamento**: 26/09/2025  
**👨‍💻 Sviluppatore**: AI Assistant  
**📋 Versione Documentazione**: 3.1.0  
**🎯 Stato**: Fase 3 Completata (Android) - **IN CORSO Fase 4 (iOS) - STEP 1: Controlli Sistema iOS**
