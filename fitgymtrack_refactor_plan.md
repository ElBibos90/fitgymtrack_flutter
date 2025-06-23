# 📋 FitGymTrack - Piano Refactoring & Quick Actions

## 🎯 **Situazione Attuale & Obiettivi**

### **Quick Actions Scelte:**
1. **🏋️ Inizia Allenamento** → Navigation a `/workouts`
2. **🔢 Calcola 1RM** → Dialog popup con calculator
3. **🏆 Achievement** → Schermata achievement basic
4. **👤 Profilo** → Navigation al profilo esistente (non più "impostazioni")

### **Problema Attuale:**
- `home_screen.dart` troppo lungo (800+ righe)
- Logica mista tra UI e business logic
- Quick actions hardcoded nel main file

---

## 🗂️ **Piano Refactoring File Structure**

### **File da Creare:**

```
lib/features/home/
├── presentation/
│   ├── screens/
│   │   └── home_screen.dart (refactored - solo navigation)
│   └── widgets/
│       ├── dashboard_page.dart (dashboard completa)
│       ├── greeting_section.dart (saluto personalizzato)
│       ├── subscription_section.dart (status abbonamento)
│       ├── quick_actions_grid.dart (azioni rapide)
│       ├── recent_activity_section.dart (ultima attività)
│       ├── donation_banner.dart (banner donazioni)
│       └── help_section.dart (aiuto & feedback)
├── models/
│   └── quick_action.dart (model per azioni)
└── services/
    └── dashboard_service.dart (business logic)

lib/features/tools/
├── presentation/
│   ├── screens/
│   │   └── one_rep_max_screen.dart
│   └── widgets/
│       ├── one_rep_max_dialog.dart (popup calculator)
│       ├── weight_input_widget.dart
│       └── result_display_widget.dart
├── models/
│   └── one_rep_max_models.dart
└── services/
    └── one_rep_max_calculator.dart

lib/features/achievements/
├── presentation/
│   ├── screens/
│   │   └── achievements_screen.dart
│   └── widgets/
│       ├── achievement_card.dart
│       └── achievement_badge.dart
├── models/
│   └── achievement_models.dart
└── services/
    └── achievement_service.dart

lib/features/profile/
├── presentation/
│   ├── screens/
│   │   └── profile_screen.dart (usa user_profiles esistente)
│   └── widgets/
│       ├── profile_info_card.dart
│       ├── profile_edit_form.dart
│       └── profile_stats_card.dart
├── models/
│   └── user_profile_models.dart
├── repository/
│   └── profile_repository.dart (usa API esistente)
└── bloc/
    └── profile_bloc.dart
```

---

## 🔧 **Implementazione Quick Actions**

### **1. Model per Quick Actions:**

```dart
// lib/features/home/models/quick_action.dart
class QuickAction {
  final String id;
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;

  const QuickAction({
    required this.id,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
  });
}
```

### **2. Quick Actions Configuration:**

```dart
// lib/features/home/services/dashboard_service.dart
class DashboardService {
  static List<QuickAction> getQuickActions(BuildContext context) {
    return [
      QuickAction(
        id: 'start_workout',
        icon: Icons.play_circle_fill_rounded,
        title: 'Inizia\nAllenamento',
        color: const Color(0xFF48BB78),
        onTap: () => context.go('/workouts'),
      ),
      QuickAction(
        id: 'calculate_1rm',
        icon: Icons.calculate_rounded,
        title: 'Calcola\n1RM',
        color: const Color(0xFF667EEA),
        onTap: () => _showOneRepMaxDialog(context),
      ),
      QuickAction(
        id: 'achievements',
        icon: Icons.emoji_events_rounded,
        title: 'Achievement',
        color: const Color(0xFFED8936),
        onTap: () => context.go('/achievements'),
      ),
      QuickAction(
        id: 'profile',
        icon: Icons.person_rounded,
        title: 'Profilo',
        color: const Color(0xFF9F7AEA),
        onTap: () => context.go('/profile'),
      ),
    ];
  }

  static void _showOneRepMaxDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const OneRepMaxDialog(),
    );
  }
}
```

---

## 📱 **User Profile Integration**

### **Dati Esistenti da user_profiles.php:**

```dart
// lib/features/profile/models/user_profile_models.dart
class UserProfile {
  final int userId;
  final int? height;          // cm
  final double? weight;       // kg
  final int? age;            // anni
  final String? gender;      // male/female/other
  final String experienceLevel; // beginner/intermediate/advanced
  final String? fitnessGoals;   // general_fitness, etc.
  final String? injuries;       // note infortuni
  final String? preferences;    // preferenze allenamento
  final String? notes;          // note personali
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  double? get bmi => (height != null && weight != null) 
      ? weight! / ((height! / 100) * (height! / 100)) 
      : null;
      
  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'N/A';
    if (bmiValue < 18.5) return 'Sottopeso';
    if (bmiValue < 25) return 'Normale';
    if (bmiValue < 30) return 'Sovrappeso';
    return 'Obeso';
  }
}
```

### **API Repository:**

```dart
// lib/features/profile/repository/profile_repository.dart
class ProfileRepository {
  final ApiClient _apiClient;

  Future<Result<UserProfile>> getUserProfile([int? userId]) async {
    final queryParams = userId != null ? {'user_id': userId.toString()} : null;
    
    return Result.tryCallAsync(() async {
      final response = await _apiClient.get('/utente_profilo.php', queryParams);
      return UserProfile.fromJson(response);
    });
  }

  Future<Result<UserProfile>> updateUserProfile(UserProfile profile) async {
    return Result.tryCallAsync(() async {
      final response = await _apiClient.put('/utente_profilo.php', profile.toJson());
      return UserProfile.fromJson(response['profile']);
    });
  }
}
```

---

## 🏆 **Achievement System Basic**

### **Achievement basati su dati esistenti:**

```dart
// lib/features/achievements/models/achievement_models.dart
enum AchievementType {
  workoutCount,
  profileComplete,
  streak,
  experience,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementType type;
  final int targetValue;
  final int currentValue;
  final bool isUnlocked;

  bool get isCompleted => currentValue >= targetValue;
  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);
}

// lib/features/achievements/services/achievement_service.dart
class AchievementService {
  static List<Achievement> getBasicAchievements(
    int workoutCount, 
    UserProfile? profile,
    int currentStreak,
  ) {
    return [
      Achievement(
        id: 'first_workout',
        title: 'Primo Allenamento',
        description: 'Completa il tuo primo workout',
        icon: Icons.fitness_center,
        color: Colors.green,
        type: AchievementType.workoutCount,
        targetValue: 1,
        currentValue: workoutCount,
        isUnlocked: workoutCount >= 1,
      ),
      Achievement(
        id: 'profile_complete',
        title: 'Profilo Completo',
        description: 'Completa tutte le informazioni del profilo',
        icon: Icons.person,
        color: Colors.blue,
        type: AchievementType.profileComplete,
        targetValue: 1,
        currentValue: _calculateProfileCompleteness(profile),
        isUnlocked: _isProfileComplete(profile),
      ),
      // ... altri achievement
    ];
  }
}
```

---

## 🔢 **1RM Calculator Dialog**

### **Dialog Popup Semplice:**

```dart
// lib/features/tools/widgets/one_rep_max_dialog.dart
class OneRepMaxDialog extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Calcola 1RM'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WeightInputWidget(
            label: 'Peso (kg)',
            onChanged: (weight) => setState(() => _weight = weight),
          ),
          RepInputWidget(
            label: 'Ripetizioni',
            onChanged: (reps) => setState(() => _reps = reps),
          ),
          if (_oneRM != null) ...[
            SizedBox(height: 20),
            ResultDisplayWidget(oneRM: _oneRM!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Chiudi'),
        ),
        if (_weight != null && _reps != null)
          ElevatedButton(
            onPressed: _calculate,
            child: Text('Calcola'),
          ),
      ],
    );
  }

  void _calculate() {
    setState(() {
      _oneRM = OneRepMaxCalculator.epley(_weight!, _reps!);
    });
  }
}

// lib/features/tools/services/one_rep_max_calculator.dart
class OneRepMaxCalculator {
  static double epley(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * (1 + (reps / 30));
  }

  static Map<String, double> getPercentages(double oneRM) {
    return {
      '95%': oneRM * 0.95,
      '90%': oneRM * 0.90,
      '85%': oneRM * 0.85,
      '80%': oneRM * 0.80,
      '75%': oneRM * 0.75,
      '70%': oneRM * 0.70,
    };
  }
}
```

---

## 🚀 **Routes da Aggiungere**

```dart
// lib/core/router/app_router.dart (aggiungi queste route)

GoRoute(
  path: '/profile',
  name: 'profile',
  builder: (context, state) => AuthWrapper(
    authenticatedChild: const ProfileScreen(),
    unauthenticatedChild: const LoginScreen(),
  ),
),

GoRoute(
  path: '/achievements',
  name: 'achievements',
  builder: (context, state) => AuthWrapper(
    authenticatedChild: const AchievementsScreen(),
    unauthenticatedChild: const LoginScreen(),
  ),
),
```

---

## ⏱️ **Timeline Implementazione**

### **FASE 1: Refactoring (30 min)**
1. Sposta `DashboardPage` in file separato
2. Crea `QuickActionsGrid` widget
3. Configura `DashboardService`

### **FASE 2: Quick Actions (30 min)**  
1. Navigation workout ✅
2. ProfileScreen basic con `user_profiles`
3. 1RM Calculator dialog
4. AchievementsScreen basic

### **FASE 3: Polish (30 min)**
1. Loading states
2. Error handling  
3. UI refinements

---

## 💾 **File Principale per Nuova Chat**

Questo documento contiene:
- ✅ Piano refactoring completo
- ✅ File structure organizzata
- ✅ Quick actions configuration
- ✅ Integration con user_profiles esistente
- ✅ 1RM calculator implementation
- ✅ Achievement system basic
- ✅ Routes da aggiungere
- ✅ Timeline implementazione

**Ready per nuova chat e implementazione! 🚀**

---

## 🎯 **Note Importanti**

1. **user_profiles.php** già pronto - non serve creare nuove API
2. **Bottom navigation** ha già pulsante profilo - usiamo quello
3. **Refactoring** mantiene funzionalità esistenti
4. **Quick Actions** smart e veloci da implementare
5. **Achievement** basati su dati esistenti - no complexity

**Tutto progettato per essere implementato in 1.5 ore max! ⚡**