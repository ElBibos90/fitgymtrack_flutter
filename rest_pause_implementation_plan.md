# 📋 **LISTA AGGIORNATA - FILE DA MODIFICARE**

## 🎯 **FEATURE: REST-PAUSE SET**

### **Descrizione Funzionalità:**
- Nuova funzionalità aggiuntiva che funziona con tutti i `set_type` (normal, superset, giantset, circuit)
- Non modifica `set_type`, ma aggiunge flag `is_rest_pause`
- Esempi: "10+4+2" reps con pause di 15" tra segmenti
- `ripetizioni` mantiene somma totale (16) per compatibilità
- Massimo 3 segmenti REST-PAUSE
- UI: Schermo normale mostra somma, dialog per inserire segmenti
- Recovery: Recupera dati storici effettivi, non solo pianificati

---

## 🗄️ **LAYER DATABASE**

### **Database Migration/Schema:**
```sql
-- Tabella scheda_esercizi (pianificazione)
ALTER TABLE scheda_esercizi ADD COLUMN is_rest_pause TINYINT(1) DEFAULT 0;
ALTER TABLE scheda_esercizi ADD COLUMN rest_pause_reps TEXT NULL;
ALTER TABLE scheda_esercizi ADD COLUMN rest_pause_rest_seconds INT DEFAULT 15;

-- Tabella serie_completate (esecuzione storica)
ALTER TABLE serie_completate ADD COLUMN is_rest_pause TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Flag per indicare se questa serie era REST-PAUSE';
ALTER TABLE serie_completate ADD COLUMN rest_pause_reps TEXT NULL COMMENT 'Sequenza REST-PAUSE effettivamente completata (es: "10+4+2")';
ALTER TABLE serie_completate ADD COLUMN rest_pause_rest_seconds INT NULL COMMENT 'Secondi di pausa usati tra i segmenti';
```

---

## 🏗️ **LAYER MODELS & SERIALIZATION**

```
📁 lib/features/workouts/models/
├── ✏️ workout_plan_models.dart          - Aggiungere campi REST-PAUSE a WorkoutExercise
├── 🔄 workout_plan_models.g.dart        - RIGENERARE dopo modifiche
├── ✏️ active_workout_models.dart        - Aggiungere campi REST-PAUSE a CompletedSeriesData + SeriesData
└── 🔄 active_workout_models.g.dart      - RIGENERARE dopo modifiche
```

**Campi da aggiungere:**
- `WorkoutExercise`: `isRestPause`, `restPauseReps`, `restPauseRestSeconds`
- `CompletedSeriesData`: `isRestPause`, `restPauseReps`, `restPauseRestSeconds`
- `SeriesData`: `isRestPause`, `restPauseReps`, `restPauseRestSeconds`

---

## 🌐 **LAYER NETWORK & REPOSITORY**

```
📁 lib/core/network/
├── ✏️ api_client.dart                   - Aggiungere endpoint se necessario

📁 lib/features/workouts/repository/
└── ✏️ workout_repository.dart           - Verificare compatibilità con nuovi campi
```

---

## 🧠 **LAYER BUSINESS LOGIC**

```
📁 lib/features/workouts/bloc/
└── ✏️ active_workout_bloc.dart          - Recovery intelligente REST-PAUSE storico
```

**Logica da implementare:**
- Recovery prioritario da `serie_completate` per REST-PAUSE
- Fallback ai valori pianificati da `scheda_esercizi`
- Compatibilità con sistema esistente

---

## 🎨 **LAYER PRESENTATION - SCREENS**

```
📁 lib/features/workouts/presentation/screens/
├── ✏️ create_workout_screen.dart        - UI per impostare REST-PAUSE in pianificazione
├── ✏️ active_workout_screen.dart        - Dialog REST-PAUSE durante allenamento
└── ✏️ bloc_active_workout_screen.dart   - Supporto REST-PAUSE (se utilizzato)
```

---

## 🎯 **LAYER PRESENTATION - WIDGETS**

```
📁 lib/features/workouts/presentation/widgets/
├── ✏️ workout_widgets.dart              - Export nuovo widget REST-PAUSE
├── ✏️ workout_plan_card.dart            - Display REST-PAUSE nella card (opzionale)
├── ➕ rest_pause_dialog.dart            - CREARE - Dialog per esecuzione REST-PAUSE
└── ➕ rest_pause_input_widget.dart      - CREARE - Widget input segmenti in pianificazione
```

---

## 🔧 **LAYER BACKEND (PHP) - ✅ COMPLETATO**

```
📁 Backend API files:
├── ✅ create_scheda_standalone.php      - ✅ COMPLETATO - Supporto campi REST-PAUSE
├── ✅ schede_standalone.php             - ✅ COMPLETATO - Lettura campi REST-PAUSE
├── ✅ save_completed_series.php         - ✅ COMPLETATO - Salvataggio dati REST-PAUSE eseguiti
└── ✅ get_completed_series_standalone.php - ✅ COMPLETATO - Recovery dati REST-PAUSE storici
```

**🎉 BACKEND COMPLETATO E TESTATO:**
- ✅ **Creazione**: Schede con REST-PAUSE funzionano
- ✅ **Lettura/Aggiornamento**: GET/PUT con campi REST-PAUSE
- ✅ **Salvataggio**: Esecuzioni REST-PAUSE salvate correttamente
- ✅ **Recovery**: Dati storici REST-PAUSE recuperabili

---

## 📊 **RIEPILOGO MODIFICHE**

| Layer | File da Modificare | File da Creare | File da Rigenerare | Status |
|-------|-------------------|-----------------|------------------|--------|
| **Database** | 0 | 1 migration | 0 | ✅ **DONE** |
| **Models** | 2 | 0 | 2 | ⏳ TODO |
| **Network** | 2 | 0 | 0 | ⏳ TODO |
| **Bloc** | 1 | 0 | 0 | ⏳ TODO |
| **Screens** | 3 | 0 | 0 | ⏳ TODO |
| **Widgets** | 2 | 2 | 0 | ⏳ TODO |
| **Backend** | 4 | 0 | 0 | ✅ **DONE** |
| **TOTALE** | **10** | **3** | **2** | **2/7 LAYERS** |

---

## 🎯 **PRIORITÀ DI IMPLEMENTAZIONE - AGGIORNATA**

### **✅ FASE 1 - BACKEND (Completata)**
1. ✅ **Database Migration** - Entrambe le tabelle (`scheda_esercizi` + `serie_completate`)
2. ✅ **create_scheda_standalone.php** - Creazione schede con REST-PAUSE
3. ✅ **schede_standalone.php** - Lettura/aggiornamento schede con REST-PAUSE
4. ✅ **save_completed_series.php** - Salvataggio esecuzioni REST-PAUSE
5. ✅ **get_completed_series_standalone.php** - Recovery storico REST-PAUSE

### **🔥 FASE 2 - CORE MODELS (Prossimi)**
6. **active_workout_models.dart** - `CompletedSeriesData` + `SeriesData` REST-PAUSE
7. **workout_plan_models.dart** - `WorkoutExercise` REST-PAUSE
8. **Rigenerare .g.dart** - Serialization

### **⚡ FASE 3 - LOGIC (Importanti)**  
9. **active_workout_bloc.dart** - Recovery intelligente REST-PAUSE
10. **workout_repository.dart** - Compatibilità nuovi campi

### **🎨 FASE 4 - UX (Miglioramenti)**
11. **create_workout_screen.dart** - UI pianificazione
12. **active_workout_screen.dart** - Dialog esecuzione
13. **rest_pause_dialog.dart** - Widget UX
14. **rest_pause_input_widget.dart** - Input pianificazione

---

## 💡 **FILE PIÙ CRITICI DA INIZIARE**

1. **`active_workout_models.dart`** - Base per recovery storico
2. **`workout_plan_models.dart`** - Base per pianificazione
3. **`active_workout_bloc.dart`** - Logica recovery intelligente
4. **`rest_pause_input_widget.dart`** - Core UX

---

## 💭 **SCENARIO DI UTILIZZO COMPLETO - TESTATO**

1. **✅ PIANIFICAZIONE**: Utente imposta "Panca 3x REST-PAUSE 10+4+2" → Salvato in `scheda_esercizi`
2. **✅ PRIMA ESECUZIONE**: Utente fa realmente "8+4+2" → salvato in `serie_completate`
3. **🔄 RECOVERY**: Prossima volta gli viene suggerito "8+4+2" (dato storico) non "10+4+2" (dato pianificato)
4. **🔄 FLESSIBILITÀ**: Può seguire il suggerimento o modificare in tempo reale

---

## 🔄 **COMPATIBILITÀ TESTATA**

- ✅ **Sistema esistente**: `ripetizioni` mantiene somma totale
- ✅ **Recovery normale**: Funziona senza modifiche per serie normali
- ✅ **Tutti i set_type**: Compatible con normal, superset, giantset, circuit
- ✅ **UI compatta**: Display normale + dialog per dettagli
- ✅ **Database**: Migration applicata e testata
- ✅ **Backend**: 4 endpoint testati e funzionanti

---

## 🚀 **PROSSIMI PASSI - NUOVA SESSIONE**

**Iniziare con i MODELS DART:**
1. **`active_workout_models.dart`** - Aggiungere campi REST-PAUSE
2. **`workout_plan_models.dart`** - Aggiungere campi REST-PAUSE
3. **Rigenerare** file `.g.dart` 
4. **Testare** serializzazione

**Backend completato al 100% e pronto per integrazione Flutter!** 🎉