// lib/features/profile/models/user_profile_models.dart

/// Model per il profilo utente integrato con user_profiles.php
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

  /// Factory dal JSON dell'API
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: _parseInt(json['user_id']),
      height: _parseIntOrNull(json['height']),
      weight: _parseDoubleOrNull(json['weight']),
      age: _parseIntOrNull(json['age']),
      gender: json['gender'] as String?,
      experienceLevel: json['experience_level'] as String? ?? 'beginner',
      fitnessGoals: json['fitness_goals'] as String?,
      injuries: json['injuries'] as String?,
      preferences: json['preferences'] as String?,
      notes: json['notes'] as String?,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// Converte in JSON per l'API
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'height': height,
      'weight': weight,
      'age': age,
      'gender': gender,
      'experience_level': experienceLevel,
      'fitness_goals': fitnessGoals,
      'injuries': injuries,
      'preferences': preferences,
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
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
    if (bmiValue == null) return 'N/A';
    if (bmiValue < 18.5) return 'Sottopeso';
    if (bmiValue < 25) return 'Normale';
    if (bmiValue < 30) return 'Sovrappeso';
    return 'Obeso';
  }

  /// Calcola la completezza del profilo (0-100%)
  int get completenessPercentage {
    int completed = 0;
    const int totalFields = 7;

    if (height != null) completed++;
    if (weight != null) completed++;
    if (age != null) completed++;
    if (gender != null && gender!.isNotEmpty) completed++;
    if (experienceLevel.isNotEmpty) completed++;
    if (fitnessGoals != null && fitnessGoals!.isNotEmpty) completed++;
    if (preferences != null && preferences!.isNotEmpty) completed++;

    return ((completed / totalFields) * 100).round();
  }

  /// Indica se il profilo è completo (>80%)
  bool get isComplete => completenessPercentage >= 80;

  /// Lista dei campi mancanti
  List<String> get missingFields {
    final missing = <String>[];

    if (height == null) missing.add('Altezza');
    if (weight == null) missing.add('Peso');
    if (age == null) missing.add('Età');
    if (gender == null || gender!.isEmpty) missing.add('Genere');
    if (experienceLevel.isEmpty) missing.add('Livello esperienza');
    if (fitnessGoals == null || fitnessGoals!.isEmpty) missing.add('Obiettivi fitness');
    if (preferences == null || preferences!.isEmpty) missing.add('Preferenze');

    return missing;
  }

  /// Crea una copia con valori modificati
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

/// Enum per i livelli di esperienza
enum ExperienceLevel {
  beginner('beginner', 'Principiante', 'Nuovo al fitness o <6 mesi'),
  intermediate('intermediate', 'Intermedio', '6 mesi - 2 anni di esperienza'),
  advanced('advanced', 'Avanzato', '>2 anni di esperienza'),
  expert('expert', 'Esperto', 'Livello professionale');

  const ExperienceLevel(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;

  static ExperienceLevel fromString(String value) {
    return ExperienceLevel.values.firstWhere(
          (level) => level.value == value,
      orElse: () => ExperienceLevel.beginner,
    );
  }
}

/// Enum per gli obiettivi fitness
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
  final String displayName;
  final String description;

  static FitnessGoal fromString(String value) {
    return FitnessGoal.values.firstWhere(
          (goal) => goal.value == value,
      orElse: () => FitnessGoal.generalFitness,
    );
  }
}

/// Enum per i generi
enum Gender {
  male('male', 'Maschio', '♂️'),
  female('female', 'Femmina', '♀️'),
  other('other', 'Altro', '⚧️'),
  preferNotToSay('prefer_not_to_say', 'Preferisco non dirlo', '');

  const Gender(this.value, this.displayName, this.icon);

  final String value;
  final String displayName;
  final String icon;

  static Gender fromString(String value) {
    return Gender.values.firstWhere(
          (gender) => gender.value == value,
      orElse: () => Gender.preferNotToSay,
    );
  }
}