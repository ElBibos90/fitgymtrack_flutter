import 'package:json_annotation/json_annotation.dart';

part 'muscle_group.g.dart';

/// Modello per rappresentare un gruppo muscolare specifico
/// Corrisponde alla tabella muscle_groups nel database
class MuscleGroup {
  final int id;
  final String name;
  @JsonKey(name: 'name_en')
  final String? nameEn;
  @JsonKey(name: 'parent_category')
  final String parentCategory;
  final String? description;
  @JsonKey(name: 'sort_order')
  final int? sortOrder;
  @JsonKey(name: 'is_active')
  final bool isActive;

  const MuscleGroup({
    required this.id,
    required this.name,
    this.nameEn,
    required this.parentCategory,
    this.description,
    this.sortOrder,
    this.isActive = true,
  });

  factory MuscleGroup.fromJson(Map<String, dynamic> json) {
    // ✅ Parsing sicuro con supporto per "category" (API) e "parent_category" (DB)
    return MuscleGroup(
      id: _parseInt(json['id']) ?? 0,
      name: json['name'] as String? ?? '',
      nameEn: json['name_en'] as String?,
      parentCategory: (json['parent_category'] ?? json['category']) as String? ?? '',
      description: json['description'] as String?,
      sortOrder: _parseInt(json['sort_order']),
      isActive: _parseBool(json['is_active']) ?? true,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_en': nameEn,
      'parent_category': parentCategory,
      'description': description,
      'sort_order': sortOrder,
      'is_active': isActive,
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
  
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MuscleGroup &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MuscleGroup(id: $id, name: $name, category: $parentCategory)';
}

/// Risposta API per la lista dei gruppi muscolari
@JsonSerializable()
class MuscleGroupsResponse {
  final bool success;
  final List<MuscleGroup>? data;
  final String? message;

  const MuscleGroupsResponse({
    required this.success,
    this.data,
    this.message,
  });

  factory MuscleGroupsResponse.fromJson(Map<String, dynamic> json) => _$MuscleGroupsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MuscleGroupsResponseToJson(this);
}

