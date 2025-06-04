# File Necessari per Modulo Workout Completo

## 🎯 Core Files (Essenziali)

### Models
```
lib/features/workouts/models/
├── workout_models.dart                    # ✅ Barrel file
├── workout_plan_models.dart              # ✅ Modelli schede
├── active_workout_models.dart            # ✅ Modelli allenamenti attivi
├── series_request_models.dart            # ✅ Modelli serie
└── workout_response_types.dart           # ✅ Response types
```

### Repository & Network
```
lib/features/workouts/repository/
└── workout_repository.dart               # ✅ Repository principale

lib/core/network/
├── api_client.dart                       # ✅ Client API
├── dio_client.dart                       # ✅ Configurazione Dio
├── auth_interceptor.dart                 # ✅ Interceptor auth
└── error_interceptor.dart                # ✅ Gestione errori
```

### BLoC
```
lib/features/workouts/bloc/
├── workout_blocs.dart                    # ✅ Barrel file
├── workout_bloc.dart                     # ✅ Gestione schede
├── active_workout_bloc.dart              # ✅ Allenamenti attivi
└── workout_history_bloc.dart             # ✅ Cronologia
```

### Screens
```
lib/features/workouts/presentation/screens/
├── workout_plans_screen.dart             # ✅ Lista schede
├── create_workout_screen.dart            # ✅ Creazione/Modifica schede
├── edit_workout_screen.dart              # ✅ Modifica schede
└── active_workout_screen.dart            # ✅ Allenamento attivo
```

### Widgets
```
lib/features/workouts/presentation/widgets/
├── workout_widgets.dart                  # ✅ Barrel file
├── workout_plan_card.dart                # ✅ Card scheda
└── exercise_editor_card.dart             # ✅ Editor esercizio
```

## 🎯 Shared Components (Necessari)

### Widgets Condivisi
```
lib/shared/widgets/
├── custom_app_bar.dart                   # ✅ AppBar personalizzata
├── custom_button.dart                    # ✅ Bottoni
├── custom_text_field.dart                # ✅ Input text
├── custom_card.dart                      # ✅ Card base
├── loading_overlay.dart                  # ✅ Loading overlay
├── custom_snackbar.dart                  # ✅ Snackbar
├── error_state.dart                      # ✅ Stato errore
├── empty_state.dart                      # ✅ Stato vuoto
├── form_section.dart                     # ✅ Sezioni form
├── auth_wrapper.dart                     # ✅ Wrapper autenticazione
├── responsive_builder.dart               # ✅ Layout responsive
├── workout_exercise_editor.dart          # ✅ Editor esercizi
└── exercise_selection_dialog.dart        # ✅ Dialog selezione esercizi
```

### Theme
```
lib/shared/theme/
├── app_theme.dart                        # ✅ Tema principale
└── app_colors.dart                       # ✅ Colori
```

## 🎯 Core Infrastructure

### Configuration
```
lib/core/config/
├── app_config.dart                       # ✅ Configurazione app
├── environment.dart                      # ✅ Environment variables
└── dependency_injection.dart             # ✅ DI setup
```

### Services
```
lib/core/services/
└── session_service.dart                  # ✅ Gestione sessione
```

### Utils
```
lib/core/utils/
├── constants.dart                        # ✅ Costanti
├── formatters.dart                       # ✅ Formattatori
├── validators.dart                       # ✅ Validatori
└── result.dart                           # ✅ Result pattern
```

### Extensions
```
lib/core/extensions/
├── context_extensions.dart               # ✅ Context extensions
└── string_extensions.dart                # ✅ String extensions
```

### Router
```
lib/core/router/
└── app_router.dart                       # ✅ Routing
```

## 🎯 Exercise Models (Dipendenza)

```
lib/features/exercises/models/
├── exercise.dart                         # ✅ Modelli esercizi
└── exercises_response.dart               # ✅ Response esercizi
```

## 🎯 Auth Models (Dipendenza)

```
lib/features/auth/models/
├── login_response.dart                   # ✅ Per User model
└── register_response.dart                # ✅ Per User model
```

## 🎯 Stats Models (Opzionale)

```
lib/features/stats/models/
└── user_stats_models.dart                # ✅ Per workout history
```

## 🎯 Main Files

```
lib/
├── main.dart                             # ✅ Entry point
└── pubspec.yaml                          # ✅ Dipendenze
```

## ❌ File NON Necessari (Possono essere rimossi)

### Se non usi altre features:
```
lib/features/auth/                        # ❌ (tranne models)
lib/features/stats/                       # ❌ (tranne models)
lib/features/exercises/                   # ❌ (tranne models)
```

### Assets non utilizzati:
```
assets/                                   # ❌ Se non usi immagini/icone
```

### Test files:
```
test/                                     # ❌ Se non fai testing
```

## 🔧 Fix Necessari

### 1. Fix WorkoutBloc (problema nome scheda)
Nel `workout_bloc.dart`, metodo `_onGetWorkoutPlanDetails`:

```dart
// ❌ PROBLEMATICO:
workoutPlan = WorkoutPlan(
  id: event.schedaId,
  nome: 'Scheda ${event.schedaId}',  // Genera nome fittizio
  descrizione: null,
  //...
);

// ✅ FIX: Carica sempre prima le schede
```

### 2. Fix EditWorkoutScreen (loading infinito)
Nel `edit_workout_screen.dart`, gestione stati:

```dart
// ✅ AGGIUNGERE reset esplicito di _isLoading
else if (state is WorkoutPlanDetailsLoaded) {
  setState(() {
    _isLoading = false; // ← AGGIUNGERE QUESTO
  });
  _resetState(state.workoutPlan, state.exercises);
}
```

## 📊 Statistiche

- **File Essenziali**: ~35 file
- **File Opzionali**: ~15 file  
- **File Rimovibili**: Tutto il resto
- **Dimensione Stimata**: ~2-3MB di codice