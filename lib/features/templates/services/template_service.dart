// lib/features/templates/services/template_service.dart
import 'package:dio/dio.dart';
import '../../../core/di/dependency_injection.dart';
import '../models/template_models.dart';

/// Servizio per gestire le operazioni sui template di allenamento
class TemplateService {
  final Dio _dio = getIt<Dio>();

  /// Ottiene la lista dei template con filtri opzionali
  Future<TemplatesResponse> getTemplates({
    int? categoryId,
    String? difficulty,
    String? goal,
    bool? featured,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      //debugPrint('🔍 TemplateService.getTemplates: Starting with params: categoryId=$categoryId, difficulty=$difficulty, goal=$goal, featured=$featured, search=$search, limit=$limit, offset=$offset');
      
      final queryParams = <String, dynamic>{
        'limit': limit,
        'page': (offset / limit).floor() + 1, // Converti offset in page
      };

      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (difficulty != null) queryParams['difficulty'] = difficulty;
      if (goal != null) queryParams['goal'] = goal;
      if (featured != null) queryParams['featured'] = featured;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      //debugPrint('🔍 TemplateService.getTemplates: Query params: $queryParams');

      final response = await _dio.get(
        '/workout_templates.php',
        queryParameters: queryParams,
      );

      //debugPrint('🔍 TemplateService.getTemplates: API Response status: ${response.statusCode}');
      //debugPrint('🔍 TemplateService.getTemplates: API Response data: ${response.data}');

      final result = TemplatesResponse.fromJson(response.data);
      //debugPrint('🔍 TemplateService.getTemplates: Parsed ${result.templates.length} templates successfully');
      
      return result;
    } catch (e) {
      //debugPrint('❌ TemplateService.getTemplates ERROR: $e');
      //debugPrint('❌ TemplateService.getTemplates ERROR stack: ${e.toString()}');
      throw Exception('Errore nel recupero dei template: $e');
    }
  }

  /// Ottiene i dettagli di un template specifico
  Future<TemplateDetailsResponse> getTemplateDetails(int templateId) async {
    try {
      //debugPrint('🔍 TemplateService.getTemplateDetails: Starting for templateId=$templateId');
      
      final response = await _dio.get(
        '/template_details.php',
        queryParameters: {'id': templateId},
      );

      //debugPrint('🔍 TemplateService.getTemplateDetails: API Response status: ${response.statusCode}');
      //debugPrint('🔍 TemplateService.getTemplateDetails: API Response data: ${response.data}');

      final result = TemplateDetailsResponse.fromJson(response.data);
      //debugPrint('🔍 TemplateService.getTemplateDetails: Parsed template ${result.template.name} with ${result.template.exercises?.length ?? 0} exercises successfully');
      
      return result;
    } catch (e) {
      //debugPrint('❌ TemplateService.getTemplateDetails ERROR: $e');
      //debugPrint('❌ TemplateService.getTemplateDetails ERROR stack: ${e.toString()}');
      throw Exception('Errore nel recupero dei dettagli del template: $e');
    }
  }

  /// Crea una scheda di allenamento da un template
  Future<CreateWorkoutFromTemplateResponse> createWorkoutFromTemplate(
    CreateWorkoutFromTemplateRequest request,
  ) async {
    try {
      //debugPrint('🔍 TemplateService.createWorkoutFromTemplate: Starting with request: ${request.toJson()}');
      
      final response = await _dio.post(
        '/create_workout_from_template.php',
        data: request.toJson(),
      );

      //debugPrint('🔍 TemplateService.createWorkoutFromTemplate: API Response status: ${response.statusCode}');
      //debugPrint('🔍 TemplateService.createWorkoutFromTemplate: API Response data: ${response.data}');

      // Controlla se la risposta contiene un errore
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('error')) {
          //debugPrint('❌ TemplateService.createWorkoutFromTemplate: API returned error: ${data['error']}');
          throw Exception('Errore del server: ${data['error']}');
        }
      }

      final result = CreateWorkoutFromTemplateResponse.fromJson(response.data);
      //debugPrint('🔍 TemplateService.createWorkoutFromTemplate: Parsed response successfully');
      
      return result;
    } catch (e) {
      //debugPrint('❌ TemplateService.createWorkoutFromTemplate ERROR: $e');
      //debugPrint('❌ TemplateService.createWorkoutFromTemplate ERROR stack: ${e.toString()}');
      throw Exception('Errore nella creazione della scheda: $e');
    }
  }

  /// Ottiene le categorie dei template
  Future<List<TemplateCategory>> getTemplateCategories() async {
    try {
      final response = await _dio.get('/template_categories.php');

      final List<dynamic> categoriesJson = response.data['categories'] ?? [];
      return categoriesJson
          .map((json) => TemplateCategory.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Errore nel recupero delle categorie: $e');
    }
  }

  /// Invia una valutazione per un template
  Future<void> submitTemplateRating({
    required int templateId,
    required double rating,
    String? review,
  }) async {
    try {
      //debugPrint('🔍 TemplateService.submitTemplateRating: Starting with templateId=$templateId, rating=$rating');
      
      final response = await _dio.post(
        '/template_ratings.php',
        data: {
          'template_id': templateId,
          'rating': rating,
          'review': review,
        },
      );

      //debugPrint('🔍 TemplateService.submitTemplateRating: API Response status: ${response.statusCode}');
      //debugPrint('🔍 TemplateService.submitTemplateRating: API Response data: ${response.data}');

      // Controlla se la risposta contiene un errore
      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        if (data.containsKey('error')) {
          //debugPrint('❌ TemplateService.submitTemplateRating: API returned error: ${data['error']}');
          throw Exception('Errore del server: ${data['error']}');
        }
        if (data.containsKey('success') && data['success'] == false) {
          //debugPrint('❌ TemplateService.submitTemplateRating: API returned success=false');
          throw Exception('Errore del server: ${data['message'] ?? 'Operazione fallita'}');
        }
      }

      //debugPrint('🔍 TemplateService.submitTemplateRating: Rating submitted successfully');
    } catch (e) {
      //debugPrint('❌ TemplateService.submitTemplateRating ERROR: $e');
      //debugPrint('❌ TemplateService.submitTemplateRating ERROR stack: ${e.toString()}');
      throw Exception('Errore nell\'invio della valutazione: $e');
    }
  }

  /// Ottiene le valutazioni di un template
  Future<List<UserTemplateRating>> getTemplateRatings(int templateId) async {
    try {
      final response = await _dio.get(
        '/template_ratings.php',
        queryParameters: {'template_id': templateId},
      );

      final List<dynamic> ratingsJson = response.data['ratings'] ?? [];
      return ratingsJson
          .map((json) => UserTemplateRating.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Errore nel recupero delle valutazioni: $e');
    }
  }

  /// Ottiene le categorie dei template (alias per getTemplateCategories)
  Future<List<TemplateCategory>> getCategories() async {
    return getTemplateCategories();
  }

  /// Valuta un template (alias per submitTemplateRating)
  Future<void> rateTemplate({
    required int templateId,
    required double rating,
    String? review,
  }) async {
    return submitTemplateRating(
      templateId: templateId,
      rating: rating,
      review: review,
    );
  }

  /// Rimuove una valutazione di un template
  Future<void> removeTemplateRating(int templateId) async {
    try {
      await _dio.delete(
        '/template_ratings.php',
        queryParameters: {'template_id': templateId},
      );
    } catch (e) {
      throw Exception('Errore nella rimozione della valutazione: $e');
    }
  }

  /// Ottiene i template per principianti
  Future<TemplatesResponse> getBeginnerTemplates({int limit = 20}) async {
    return getTemplatesByDifficulty(
      difficulty: 'Beginner',
      limit: limit,
    );
  }

  /// Ottiene i template più popolari
  Future<TemplatesResponse> getPopularTemplates({int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/workout_templates.php',
        queryParameters: {
          'featured': true,
          'limit': limit,
        },
      );

      return TemplatesResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Errore nel recupero dei template popolari: $e');
    }
  }

  /// Ottiene i template consigliati per l'utente
  Future<TemplatesResponse> getRecommendedTemplates({
    int? userId,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };

      if (userId != null) queryParams['user_id'] = userId;

      final response = await _dio.get(
        '/workout_templates.php',
        queryParameters: queryParams,
      );

      return TemplatesResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Errore nel recupero dei template consigliati: $e');
    }
  }

  /// Cerca template per testo
  Future<TemplatesResponse> searchTemplates({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/workout_templates.php',
        queryParameters: {
          'search': query,
          'limit': limit,
          'offset': offset,
        },
      );

      return TemplatesResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Errore nella ricerca dei template: $e');
    }
  }

  /// Ottiene i template per categoria
  Future<TemplatesResponse> getTemplatesByCategory({
    required int categoryId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/workout_templates.php',
        queryParameters: {
          'category_id': categoryId,
          'limit': limit,
          'offset': offset,
        },
      );

      return TemplatesResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Errore nel recupero dei template per categoria: $e');
    }
  }

  /// Ottiene i template per difficoltà
  Future<TemplatesResponse> getTemplatesByDifficulty({
    required String difficulty,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/workout_templates.php',
        queryParameters: {
          'difficulty': difficulty,
          'limit': limit,
          'offset': offset,
        },
      );

      return TemplatesResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Errore nel recupero dei template per difficoltà: $e');
    }
  }

  /// Ottiene i template per obiettivo
  Future<TemplatesResponse> getTemplatesByGoal({
    required String goal,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/workout_templates.php',
        queryParameters: {
          'goal': goal,
          'limit': limit,
          'offset': offset,
        },
      );

      return TemplatesResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Errore nel recupero dei template per obiettivo: $e');
    }
  }
}