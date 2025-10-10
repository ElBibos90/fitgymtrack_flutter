import 'package:json_annotation/json_annotation.dart';

part 'secondary_muscle.g.dart';

/// Modello per rappresentare un muscolo secondario con livello di attivazione
/// Corrisponde ai dati restituiti dalla tabella exercise_muscles
class SecondaryMuscle {
  final int id;
  final String name;
  @JsonKey(name: 'activation_level')
  final String activationLevel; // 'high', 'medium', 'low'
  @JsonKey(name: 'parent_category')
  final String? parentCategory;

  const SecondaryMuscle({
    required this.id,
    required this.name,
    required this.activationLevel,
    this.parentCategory,
  });

  /// Verifica se il livello di attivazione è alto
  bool get isHighActivation => activationLevel == 'high';

  /// Verifica se il livello di attivazione è medio
  bool get isMediumActivation => activationLevel == 'medium';

  /// Verifica se il livello di attivazione è basso
  bool get isLowActivation => activationLevel == 'low';

  /// Ottiene un'etichetta leggibile per il livello di attivazione
  String get activationLabel {
    switch (activationLevel) {
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Media';
      case 'low':
        return 'Bassa';
      default:
        return activationLevel;
    }
  }

  factory SecondaryMuscle.fromJson(Map<String, dynamic> json) {
    // ✅ Parsing sicuro con supporto per formati diversi
    return SecondaryMuscle(
      id: _parseInt(json['id']) ?? 0,
      name: json['name'] as String? ?? '',
      activationLevel: json['activation_level'] as String? ?? 'medium',
      parentCategory: json['parent_category'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'activation_level': activationLevel,
      'parent_category': parentCategory,
    };
  }
  
  // ✅ Helper per parsing sicuro
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecondaryMuscle &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          activationLevel == other.activationLevel;

  @override
  int get hashCode => id.hashCode ^ activationLevel.hashCode;

  @override
  String toString() => 'SecondaryMuscle(id: $id, name: $name, activation: $activationLevel)';
}

/// Modello per creare/aggiornare muscoli secondari nelle richieste API
@JsonSerializable()
class SecondaryMuscleRequest {
  @JsonKey(name: 'muscle_id')
  final int muscleId;
  @JsonKey(name: 'activation_level')
  final String activationLevel; // 'high', 'medium', 'low'

  const SecondaryMuscleRequest({
    required this.muscleId,
    required this.activationLevel,
  });

  factory SecondaryMuscleRequest.fromJson(Map<String, dynamic> json) => _$SecondaryMuscleRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SecondaryMuscleRequestToJson(this);
}

