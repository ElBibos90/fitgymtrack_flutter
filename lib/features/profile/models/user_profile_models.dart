// lib/features/profile/models/user_profile_models.dart
// 🔧 CORRECTED: Consistent with existing code using displayName

/// Model per il profilo utente integrato con utente_profilo.php
class UserProfile {
  final int userId;
  final int? height;          // cm
  final double? weight;       // kg
  final int? age;            // anni
  final String? gender;      // male/female/other
  final String experienceLevel; // beginner/intermediate/advanced
  final String? fitnessGoals;   // general_fitness, muscle_gain, etc.
  final String? injuries;       // note infortuni
  final String? preferences;    // preferenze allenamento
  final String? notes;          // note personali
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.userId,
    this.height,
    this.weight,
    this.age,
    this.gender,
    required this.experienceLevel,
    this.fitnessGoals,
    this.injuries,
    this.preferences,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory per creare un profilo vuoto per un nuovo utente
  factory UserProfile.empty(int userId) {
    final now = DateTime.now();
    return UserProfile(
      userId: userId,
      experienceLevel: 'beginner',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// 🔧 FIXED: Factory dal JSON dell'API (compatibile con utente_profilo.php)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: _parseInt(json['user_id']),
      height: _parseIntOrNull(json['height']),
      weight: _parseDoubleOrNull(json['weight']),
      age: _parseIntOrNull(json['age']),
      gender: json['gender'] as String?,
      // 🔧 FIX: Il backend restituisce experienceLevel già come stringa
      experienceLevel: json['experienceLevel'] as String? ?? 'beginner',
      fitnessGoals: json['fitnessGoals'] as String?,
      injuries: json['injuries'] as String?,
      preferences: json['preferences'] as String?,
      notes: json['notes'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// 🔧 FIXED: Converte in JSON per l'API (compatibile con utente_profilo.php)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (age != null) 'age': age,
      if (gender != null) 'gender': gender,
      'experienceLevel': experienceLevel, // Il backend gestisce la conversione string->int
      if (fitnessGoals != null) 'fitnessGoals': fitnessGoals,
      if (injuries != null) 'injuries': injuries,
      if (preferences != null) 'preferences': preferences,
      if (notes != null) 'notes': notes,
    };
  }

  /// Computed properties
  double? get bmi {
    if (height == null || weight == null) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Non calcolabile';

    if (bmiValue < 18.5) return 'Sottopeso';
    if (bmiValue < 25) return 'Normopeso';
    if (bmiValue < 30) return 'Sovrappeso';
    return 'Obeso';
  }

  /// Calcola la percentuale di completamento del profilo
  int get completenessPercentage {
    int filledFields = 0;
    const totalFields = 9; // Campi principali da compilare

    if (height != null) filledFields++;
    if (weight != null) filledFields++;
    if (age != null) filledFields++;
    if (gender != null && gender!.isNotEmpty) filledFields++;
    filledFields++; // experienceLevel è sempre presente
    if (fitnessGoals != null && fitnessGoals!.isNotEmpty) filledFields++;
    if (injuries != null && injuries!.isNotEmpty) filledFields++;
    if (preferences != null && preferences!.isNotEmpty) filledFields++;
    if (notes != null && notes!.isNotEmpty) filledFields++;

    return ((filledFields / totalFields) * 100).round();
  }

  /// Verifica se il profilo è considerato completo (>= 70%)
  bool get isComplete => completenessPercentage >= 70;

  /// Ottiene lista di campi mancanti per completare il profilo
  List<String> get missingFields {
    final missing = <String>[];

    if (height == null) missing.add('Altezza');
    if (weight == null) missing.add('Peso');
    if (age == null) missing.add('Età');
    if (gender == null || gender!.isEmpty) missing.add('Genere');
    if (fitnessGoals == null || fitnessGoals!.isEmpty) missing.add('Obiettivi fitness');

    return missing;
  }

  /// Crea una copia con modifiche
  UserProfile copyWith({
    int? userId,
    int? height,
    double? weight,
    int? age,
    String? gender,
    String? experienceLevel,
    String? fitnessGoals,
    String? injuries,
    String? preferences,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      injuries: injuries ?? this.injuries,
      preferences: preferences ?? this.preferences,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() => 'UserProfile(userId: $userId, completeness: $completenessPercentage%)';

  // ============================================================================
  // HELPER METHODS PRIVATI
  // ============================================================================

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static int? _parseIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static double? _parseDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}

// ============================================================================
// 🔧 FIXED: ENUMS CON displayName (non label) per coerenza
// ============================================================================

/// Livelli di esperienza - 🔧 FIXED: usa displayName
enum ExperienceLevel {
  beginner('beginner', 'Principiante', 'Nuovo al fitness o <6 mesi'),
  intermediate('intermediate', 'Intermedio', '6 mesi - 2 anni di esperienza'),
  advanced('advanced', 'Avanzato', '>2 anni di esperienza');

  const ExperienceLevel(this.value, this.displayName, this.description);
  final String value;
  final String displayName; // 🔧 FIXED: displayName invece di label
  final String description;

  static ExperienceLevel fromString(String value) {
    return ExperienceLevel.values.firstWhere(
          (level) => level.value == value,
      orElse: () => ExperienceLevel.beginner,
    );
  }
}

/// Obiettivi fitness - 🔧 FIXED: usa displayName
enum FitnessGoal {
  generalFitness('general_fitness', 'Fitness Generale', 'Migliorare la forma fisica'),
  weightLoss('weight_loss', 'Perdita Peso', 'Perdere peso e grasso corporeo'),
  muscleGain('muscle_gain', 'Aumento Massa', 'Aumentare massa muscolare'),
  strength('strength', 'Forza', 'Aumentare la forza massimale'),
  endurance('endurance', 'Resistenza', 'Migliorare resistenza cardiovascolare'),
  flexibility('flexibility', 'Flessibilità', 'Migliorare mobilità e flessibilità'),
  sport('sport', 'Sport Specifico', 'Preparazione per sport specifici'),
  rehabilitation('rehabilitation', 'Riabilitazione', 'Recupero da infortuni');

  const FitnessGoal(this.value, this.displayName, this.description);
  final String value;
  final String displayName; // 🔧 FIXED: displayName invece di label
  final String description;

  static FitnessGoal fromString(String value) {
    return FitnessGoal.values.firstWhere(
          (goal) => goal.value == value,
      orElse: () => FitnessGoal.generalFitness,
    );
  }
}

/// Generi - 🔧 FIXED: usa displayName + icon
enum Gender {
  male('male', 'Maschio', '♂️'),
  female('female', 'Femmina', '♀️'),
  other('other', 'Altro', '⚧️');

  const Gender(this.value, this.displayName, this.icon);
  final String value;
  final String displayName; // 🔧 FIXED: displayName invece di label
  final String icon; // 🔧 FIXED: aggiunto icon

  static Gender fromString(String value) {
    return Gender.values.firstWhere(
          (gender) => gender.value == value,
      orElse: () => Gender.male,
    );
  }
}