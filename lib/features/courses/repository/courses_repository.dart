import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/course_models_clean.dart';

part 'courses_repository.g.dart';

// ============================================================================
// REPOSITORY CORSI
// ============================================================================

@RestApi()
abstract class CoursesRepository {
  factory CoursesRepository(Dio dio, {String baseUrl}) = _CoursesRepository;

  // ============================================================================
  // ENDPOINT CORSI
  // ============================================================================

  /// Ottieni la lista di tutti i corsi disponibili
  @GET('/gym_courses.php')
  Future<CoursesResponse> getCourses(
    @Query('action') String action,
  );

  /// Ottieni i dettagli di un corso specifico
  @GET('/gym_courses.php')
  Future<CourseResponse> getCourse(
    @Query('action') String action,
    @Query('id') int courseId,
  );

  /// Ottieni le sessioni di un corso per un mese specifico
  @GET('/gym_courses.php')
  Future<SessionsResponse> getSessions(
    @Query('action') String action,
    @Query('course_id') int? courseId,
    @Query('month') String? month,
  );

  /// Ottieni i dettagli di una sessione specifica
  @GET('/gym_courses.php')
  Future<CourseSession> getSession(
    @Query('action') String action,
    @Query('id') int sessionId,
  );

  /// Ottieni le iscrizioni dell'utente corrente (formato my_enrollments)
  @GET('/gym_courses.php')
  Future<MyEnrollmentsResponse> getMyEnrollments(
    @Query('action') String action,
  );

  /// Ottieni le iscrizioni dell'utente corrente (formato standard)
  @GET('/gym_courses.php')
  Future<EnrollmentsResponse> getMyEnrollmentsStandard(
    @Query('action') String action,
  );

  // ============================================================================
  // ENDPOINT SELF-SERVICE
  // ============================================================================

  /// Iscriviti a una sessione di corso
  @POST('/gym_courses.php')
  Future<CourseOperationResponse> enrollInSession(
    @Query('action') String action,
    @Body() Map<String, dynamic> body,
  );

  /// Annulla l'iscrizione a una sessione
  @POST('/gym_courses.php')
  Future<CourseOperationResponse> cancelEnrollment(
    @Query('action') String action,
    @Body() Map<String, dynamic> body,
  );
}

// ============================================================================
// HELPER CLASSES PER REQUESTS
// ============================================================================

/// Request per iscriversi a una sessione
class EnrollRequest {
  final int sessionId;

  const EnrollRequest({required this.sessionId});

  Map<String, dynamic> toJson() => {
    'session_id': sessionId,
  };
}

/// Request per annullare un'iscrizione
class CancelRequest {
  final int enrollmentId;

  const CancelRequest({required this.enrollmentId});

  Map<String, dynamic> toJson() => {
    'enrollment_id': enrollmentId,
  };
}

// ============================================================================
// EXTENSION PER FACILITARE L'USO
// ============================================================================

extension CoursesRepositoryExtension on CoursesRepository {
  
  /// Ottieni tutti i corsi disponibili
  Future<CoursesResponse> getAllCourses() async {
    return await getCourses('list_courses');
  }

  /// Ottieni i dettagli di un corso
  Future<Course> getCourseDetails(int courseId) async {
    try {
      final result = await getCourse('get_course', courseId);
      return result.course;
    } catch (e) {
      rethrow;
    }
  }

  /// Ottieni le sessioni per un mese specifico
  Future<SessionsResponse> getSessionsForMonth(String month, {int? courseId}) async {
    //debugPrint('[DEBUG] 📅 Repository: getSessionsForMonth chiamato con month=$month, courseId=$courseId');
    final response = await getSessions('list_sessions', courseId, month);
    
    
    return response;
  }

  /// Ottieni le sessioni per il mese corrente
  Future<SessionsResponse> getCurrentMonthSessions({int? courseId}) async {
    final now = DateTime.now();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    return await getSessionsForMonth(month, courseId: courseId);
  }

  /// Ottieni i dettagli di una sessione
  Future<CourseSession> getSessionDetails(int sessionId) async {
    return await getSession('get_session', sessionId);
  }

  /// Ottieni le mie iscrizioni (formato my_enrollments)
  Future<MyEnrollmentsResponse> getMyCourseEnrollments() async {
    //debugPrint('[COURSES_DEBUG] 🔍 CoursesRepository: Chiamando getMyCourseEnrollments (formato my_enrollments)');
    final response = await getMyEnrollments('my_enrollments');
    //debugPrint('[COURSES_DEBUG] 🔍 CoursesRepository: Ricevute ${response.enrollments.length} iscrizioni (formato my_enrollments)');
    return response;
  }

  /// Ottieni le mie iscrizioni (formato standard)
  Future<EnrollmentsResponse> getMyCourseEnrollmentsStandard() async {
    //debugPrint('[COURSES_DEBUG] 🔍 CoursesRepository: Chiamando getMyEnrollmentsStandard');
    final response = await getMyEnrollmentsStandard('my_enrollments');
    //debugPrint('[COURSES_DEBUG] 🔍 CoursesRepository: Ricevute ${response.enrollments.length} iscrizioni');
    return response;
  }

  /// Iscriviti a una sessione
  Future<CourseOperationResponse> enrollInCourseSession(int sessionId) async {
    return await enrollInSession('self_enroll', EnrollRequest(sessionId: sessionId).toJson());
  }

  /// Annulla un'iscrizione
  Future<CourseOperationResponse> cancelCourseEnrollment(int enrollmentId) async {
    return await cancelEnrollment('self_cancel', CancelRequest(enrollmentId: enrollmentId).toJson());
  }
}
