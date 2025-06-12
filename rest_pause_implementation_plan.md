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

## 🔧 **LAYER BACKEND (PHP)**

```
📁 Backend API files:
├── ✏️ create_scheda_standalone.php      - Supporto campi REST-PAUSE
├── ✏️ schede_standalone.php             - Lettura campi REST-PAUSE
├── ✏️ save_completed_series.php         - Salvataggio dati REST-PAUSE eseguiti
└── ✏️ get_completed_series_standalone.php - Recovery dati REST-PAUSE storici
```

---

## 📊 **RIEPILOGO MODIFICHE**

| Layer | File da Modificare | File da Creare | File da Rigenerare |
|-------|-------------------|-----------------|------------------|
| **Database** | 0 | 1 migration | 0 |
| **Models** | 2 | 0 | 2 |
| **Network** | 2 | 0 | 0 |
| **Bloc** | 1 | 0 | 0 |
| **Screens** | 3 | 0 | 0 |
| **Widgets** | 2 | 2 | 0 |
| **Backend** | 4 | 0 | 0 |
| **TOTALE** | **14** | **3** | **2** |

---

## 🎯 **PRIORITÀ DI IMPLEMENTAZIONE**

### **🔥 FASE 1 - CORE (Critici)**
1. **Database Migration** - Entrambe le tabelle (`scheda_esercizi` + `serie_completate`)
2. **active_workout_models.dart** - `CompletedSeriesData` + `SeriesData` REST-PAUSE
3. **workout_plan_models.dart** - `WorkoutExercise` REST-PAUSE
4. **Backend PHP** - Supporto REST-PAUSE in salvataggio/recovery

### **⚡ FASE 2 - LOGIC (Importanti)**  
5. **active_workout_bloc.dart** - Recovery intelligente REST-PAUSE
6. **create_workout_screen.dart** - UI pianificazione
7. **Rigenerare .g.dart** - Serialization

### **🎨 FASE 3 - UX (Miglioramenti)**
8. **active_workout_screen.dart** - Dialog esecuzione
9. **rest_pause_dialog.dart** - Widget UX
10. **rest_pause_input_widget.dart** - Input pianificazione

---

## 💡 **FILE PIÙ CRITICI DA INIZIARE**

1. **`active_workout_models.dart`** - Base per recovery storico
2. **`workout_plan_models.dart`** - Base per pianificazione
3. **Backend PHP** - Per persistenza dati
4. **`rest_pause_input_widget.dart`** - Core UX

---

## 💭 **SCENARIO DI UTILIZZO COMPLETO**

1. **PIANIFICAZIONE**: Utente imposta "Panca 3x REST-PAUSE 10+4+2"
2. **PRIMA ESECUZIONE**: Utente fa realmente "8+3+1" → salvato in `serie_completate`
3. **RECOVERY**: Prossima volta gli viene suggerito "8+3+1" (dato storico) non "10+4+2" (dato pianificato)
4. **FLESSIBILITÀ**: Può seguire il suggerimento o modificare in tempo reale

---

## 🔄 **COMPATIBILITÀ**

- ✅ **Sistema esistente**: `ripetizioni` mantiene somma totale
- ✅ **Recovery normale**: Funziona senza modifiche per serie normali
- ✅ **Tutti i set_type**: Compatible con normal, superset, giantset, circuit
- ✅ **UI compatta**: Display normale + dialog per dettagli

---

## 🚀 **PROSSIMI PASSI**

Iniziare con **`active_workout_models.dart`** dato che include anche il recovery storico, seguito da **`workout_plan_models.dart`** per la pianificazione.