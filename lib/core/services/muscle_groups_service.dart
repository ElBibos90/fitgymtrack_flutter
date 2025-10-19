// lib/core/services/muscle_groups_service.dart

import 'package:dio/dio.dart';
import '../../features/exercises/models/muscle_group.dart';
import '../config/app_config.dart';

/// 🏋️ Servizio per gestire i gruppi muscolari
/// Fornisce accesso ai muscoli specifici dal sistema multi-muscolo
class MuscleGroupsService {
  final Dio _dio;
  
  // Cache locale dei muscoli per evitare chiamate ripetute
  List<MuscleGroup>? _cachedMuscles;
  DateTime? _cacheTime;
  static const Duration _cacheValidDuration = Duration(hours: 24);

  MuscleGroupsService(this._dio);

  /// Ottiene tutti i gruppi muscolari dall'API
  /// Usa cache locale se disponibile e valida
  Future<List<MuscleGroup>> getAllMuscleGroups({bool forceRefresh = false}) async {
    // Verifica se la cache è valida
    if (!forceRefresh && 
        _cachedMuscles != null && 
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheValidDuration) {
      return _cachedMuscles!;
    }

    try {
      final response = await _dio.get(
        '${AppConfig.baseUrl}/muscle_groups.php',
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      // Gestisci la risposta dall'API
      final responseData = response.data;
      
      if (responseData is Map<String, dynamic>) {
        // Formato: { "success": true, "data": [...] }
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> musclesJson = responseData['data'];
          _cachedMuscles = musclesJson
              .map((json) => MuscleGroup.fromJson(json as Map<String, dynamic>))
              .toList();
          _cacheTime = DateTime.now();
          return _cachedMuscles!;
        }
      } else if (responseData is List) {
        // Formato diretto: [...]
        _cachedMuscles = responseData
            .map((json) => MuscleGroup.fromJson(json as Map<String, dynamic>))
            .toList();
        _cacheTime = DateTime.now();
        return _cachedMuscles!;
      }

      return [];
    } catch (e) {
      print('❌ Errore durante il fetch dei muscoli: $e');
      // Se c'è un errore ma abbiamo cache, restituiamo quella
      if (_cachedMuscles != null) {
        return _cachedMuscles!;
      }
      rethrow;
    }
  }

  /// Ottiene i gruppi muscolari filtrati per categoria
  Future<List<MuscleGroup>> getMusclesByCategory(String category) async {
    try {
      final response = await _dio.get(
        '${AppConfig.baseUrl}/muscle_groups.php',
        queryParameters: {'category': category},
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
        ),
      );

      final responseData = response.data;
      
      if (responseData is Map<String, dynamic>) {
        if (responseData['success'] == true && responseData['data'] != null) {
          final List<dynamic> musclesJson = responseData['data'];
          return musclesJson
              .map((json) => MuscleGroup.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      } else if (responseData is List) {
        return responseData
            .map((json) => MuscleGroup.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      return [];
    } catch (e) {
      print('❌ Errore durante il fetch dei muscoli per categoria $category: $e');
      // Fallback: filtra dalla cache locale se disponibile
      if (_cachedMuscles != null) {
        return _cachedMuscles!
            .where((m) => m.parentCategory == category)
            .toList();
      }
      rethrow;
    }
  }

  /// Ottiene un gruppo muscolare specifico per ID
  MuscleGroup? getMuscleById(int id) {
    if (_cachedMuscles == null) {
      return null;
    }
    try {
      return _cachedMuscles!.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Ottiene tutte le categorie disponibili (deduplicate)
  List<String> getAvailableCategories() {
    if (_cachedMuscles == null) {
      return [];
    }
    return _cachedMuscles!
        .map((m) => m.parentCategory)
        .toSet()
        .toList()
        ..sort();
  }

  /// Raggruppa i muscoli per categoria
  Map<String, List<MuscleGroup>> getMusclesGroupedByCategory() {
    if (_cachedMuscles == null) {
      return {};
    }
    
    final Map<String, List<MuscleGroup>> grouped = {};
    for (final muscle in _cachedMuscles!) {
      if (!grouped.containsKey(muscle.parentCategory)) {
        grouped[muscle.parentCategory] = [];
      }
      grouped[muscle.parentCategory]!.add(muscle);
    }
    
    // Ordina i muscoli all'interno di ogni categoria per sort_order
    for (final category in grouped.keys) {
      grouped[category]!.sort((a, b) {
        final aOrder = a.sortOrder ?? 999;
        final bOrder = b.sortOrder ?? 999;
        return aOrder.compareTo(bOrder);
      });
    }
    
    return grouped;
  }

  /// Pulisce la cache dei muscoli (utile dopo logout o cambio server)
  void clearCache() {
    _cachedMuscles = null;
    _cacheTime = null;
  }

  /// Verifica se la cache è valida
  bool get hasCachedData => _cachedMuscles != null && _cacheTime != null;

  /// Ottiene il timestamp della cache
  DateTime? get cacheTime => _cacheTime;
}












