import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'course_models_clean.g.dart';

/// Converter per gestire i giorni di ricorrenza come array JSON
class RecurrenceDaysConverter implements JsonConverter<List<String>?, dynamic> {
  const RecurrenceDaysConverter();

  @override
  List<String>? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is List) {
      return json.map((e) => e.toString()).toList();
    }
    if (json is String) {
      try {
        final decoded = jsonDecode(json);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (e) {
        // Se il parsing fallisce, restituisci null
        return null;
      }
    }
    return null;
  }

  @override
  dynamic toJson(List<String>? object) {
    return object;
  }
}

/// Modello per un corso
@JsonSerializable()
class Course {
  final int id;
  final String title;
  final String? description;
  final String? category;
  final String? recurrencePattern;
  final String? startTime;
  final String? endTime;
  
  @JsonKey(name: 'max_participants')
  final int? maxParticipants;
  
  final String? status;
  final String? color;
  
  @JsonKey(name: 'created_at')
  final String? createdAt;
  
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  
  @JsonKey(name: 'total_sessions')
  final int? totalSessions;
  
  @JsonKey(name: 'upcoming_sessions')
  final int? upcomingSessions;
  
  @JsonKey(name: 'gym_id')
  final int? gymId;
  
  @JsonKey(name: 'created_by')
  final int? createdBy;
  
  @JsonKey(name: 'created_by_name')
  final String? createdByName;
  
  @JsonKey(name: 'is_unlimited')
  final int? isUnlimited;
  
  @JsonKey(name: 'is_recurring')
  final int? isRecurring;
  
  @JsonKey(name: 'recurrence_type')
  final String? recurrenceType;
  
  @JsonKey(name: 'recurrence_days')
  @RecurrenceDaysConverter()
  final List<String>? recurrenceDays;
  
  @JsonKey(name: 'recurrence_end_date')
  final String? recurrenceEndDate;
  
  @JsonKey(name: 'standard_start_time')
  final String? standardStartTime;
  
  @JsonKey(name: 'standard_end_time')
  final String? standardEndTime;

  const Course({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.recurrencePattern,
    this.startTime,
    this.endTime,
    this.maxParticipants,
    this.status,
    this.color,
    this.createdAt,
    this.updatedAt,
    this.totalSessions,
    this.upcomingSessions,
    this.gymId,
    this.createdBy,
    this.createdByName,
    this.isUnlimited,
    this.isRecurring,
    this.recurrenceType,
    this.recurrenceDays,
    this.recurrenceEndDate,
    this.standardStartTime,
    this.standardEndTime,
  });

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseToJson(this);

  /// Verifica se il corso è attivo
  bool get isActive => status == 'active';

  /// Converte il colore in un valore intero per Flutter
  int get colorValue {
    try {
      return int.parse((color ?? '#3B82F6').replaceFirst('#', '0xFF'));
    } catch (e) {
      return 0xFF3B82F6; // Colore di default
    }
  }

  /// Formatta i giorni di ricorrenza in italiano
  String get formattedRecurrenceDays {
    if (recurrenceDays == null || recurrenceDays!.isEmpty) {
      return 'Non specificato';
    }

    const dayNames = {
      'monday': 'Lun',
      'tuesday': 'Mar',
      'wednesday': 'Mer',
      'thursday': 'Gio',
      'friday': 'Ven',
      'saturday': 'Sab',
      'sunday': 'Dom',
    };

    return recurrenceDays!
        .map((day) => dayNames[day.toLowerCase()] ?? day)
        .join(', ');
  }

  /// Alias per formattedRecurrenceDays
  String get formattedDays => formattedRecurrenceDays;

  /// Numero totale di sessioni (con fallback)
  int get totalSessionsCount => totalSessions ?? 0;

  /// Numero di sessioni future (con fallback)
  int get upcomingSessionsCount => upcomingSessions ?? 0;

  /// Formatta l'orario del corso
  String get formattedTime {
    if (standardStartTime == null || standardEndTime == null) {
      return 'Orario non specificato';
    }
    return '$standardStartTime - $standardEndTime';
  }

  /// Verifica se il corso ha posti limitati
  bool get hasLimitedSpots {
    return maxParticipants != null && maxParticipants! > 0;
  }

  /// Numero massimo di partecipanti (con fallback)
  int get maxParticipantsCount => maxParticipants ?? 0;

  /// Numero di partecipanti attuali (con fallback)
  int get currentParticipantsCount => 0; // Placeholder, da implementare
}

/// Risposta per la lista dei corsi
@JsonSerializable()
class CoursesResponse {
  final bool success;
  final List<Course> courses;

  const CoursesResponse({
    required this.success,
    required this.courses,
  });

  factory CoursesResponse.fromJson(Map<String, dynamic> json) => _$CoursesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CoursesResponseToJson(this);
}

/// Risposta per i dettagli di un singolo corso
@JsonSerializable()
class CourseResponse {
  final bool success;
  final Course course;

  const CourseResponse({
    required this.success,
    required this.course,
  });

  factory CourseResponse.fromJson(Map<String, dynamic> json) => _$CourseResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseResponseToJson(this);
}

/// Modello per una sessione di corso
@JsonSerializable()
class CourseSession {
  final int id;
  @JsonKey(name: 'course_id')
  final int courseId;
  @JsonKey(name: 'course_title')
  final String? courseTitle;
  @JsonKey(name: 'session_date')
  final String? sessionDate;
  @JsonKey(name: 'start_time')
  final String? startTime;
  @JsonKey(name: 'end_time')
  final String? endTime;
  final String? location;
  final String? status;
  @JsonKey(name: 'current_participants')
  final int? currentParticipants;
  @JsonKey(name: 'max_participants')
  final int? maxParticipants;
  @JsonKey(name: 'enrolled_count')
  final int? enrolledCount;
  @JsonKey(name: 'is_enrolled')
  final int? isEnrolled;
  @JsonKey(name: 'user_enrollment_id')
  final int? userEnrollmentId;
  @JsonKey(name: 'user_enrollment_status')
  final String? userEnrollmentStatus;
  @JsonKey(name: 'user_enrolled_at')
  final String? userEnrolledAt;
  final String? color;

  const CourseSession({
    required this.id,
    required this.courseId,
    this.courseTitle,
    this.sessionDate,
    this.startTime,
    this.endTime,
    this.location,
    this.status,
    this.currentParticipants,
    this.maxParticipants,
    this.enrolledCount,
    this.isEnrolled,
    this.userEnrollmentId,
    this.userEnrollmentStatus,
    this.userEnrolledAt,
    this.color,
  });

  factory CourseSession.fromJson(Map<String, dynamic> json) => _$CourseSessionFromJson(json);
  Map<String, dynamic> toJson() => _$CourseSessionToJson(this);

  /// Verifica se la sessione è programmata
  bool get isScheduled => status == 'scheduled';

  /// Verifica se la sessione è piena
  bool get isFull {
    if (maxParticipants == null) return false;
    return (currentParticipants ?? 0) >= maxParticipants!;
  }

  /// Verifica se ci sono posti disponibili
  bool get hasAvailableSpots {
    if (maxParticipants == null) return true;
    return (currentParticipants ?? 0) < maxParticipants!;
  }

  /// Calcola i posti disponibili
  int get availableSpots {
    if (maxParticipants == null) return 999;
    return maxParticipants! - (currentParticipants ?? 0);
  }

  /// Numero massimo di partecipanti (con fallback)
  int get maxParticipantsCount => maxParticipants ?? 0;

  /// Numero di partecipanti attuali (con fallback)
  int get currentParticipantsCount => currentParticipants ?? 0;

  /// Verifica se l'utente è iscritto (usando i nuovi campi dall'API)
  bool get isUserEnrolled {
    // Prima prova con i nuovi campi
    if (userEnrollmentId != null && userEnrollmentStatus == 'enrolled') {
      return true;
    }
    // Fallback al campo legacy
    return (isEnrolled ?? 0) == 1;
  }

  /// Formatta la data della sessione
  String get formattedDate {
    if (sessionDate == null) return 'Data non specificata';
    try {
      final date = DateTime.parse(sessionDate!);
      const months = [
        'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
        'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return sessionDate!;
    }
  }

  /// Formatta l'orario della sessione
  String get formattedTime {
    if (startTime == null || endTime == null) return 'Orario non specificato';
    return '$startTime - $endTime';
  }

  /// Converte il colore in un valore intero per Flutter
  int get colorValue {
    try {
      return int.parse((color ?? '#3B82F6').replaceFirst('#', '0xFF'));
    } catch (e) {
      return 0xFF3B82F6; // Colore di default
    }
  }
}

/// Risposta per la lista delle sessioni
@JsonSerializable()
class SessionsResponse {
  final bool success;
  final List<CourseSession> sessions;

  const SessionsResponse({
    required this.success,
    required this.sessions,
  });

  factory SessionsResponse.fromJson(Map<String, dynamic> json) => _$SessionsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SessionsResponseToJson(this);
}

/// Modello per l'iscrizione a un corso
@JsonSerializable()
class CourseEnrollment {
  final int id;
  @JsonKey(name: 'session_id')
  final int sessionId;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'gym_id')
  final int gymId;
  final String status;
  final bool notified;
  @JsonKey(name: 'notification_id')
  final int? notificationId;
  @JsonKey(name: 'enrolled_at')
  final String enrolledAt;
  @JsonKey(name: 'attended_at')
  final String? attendedAt;
  @JsonKey(name: 'cancelled_at')
  final String? cancelledAt;
  final String? notes;

  const CourseEnrollment({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.gymId,
    required this.status,
    required this.notified,
    this.notificationId,
    required this.enrolledAt,
    this.attendedAt,
    this.cancelledAt,
    this.notes,
  });

  factory CourseEnrollment.fromJson(Map<String, dynamic> json) => _$CourseEnrollmentFromJson(json);
  Map<String, dynamic> toJson() => _$CourseEnrollmentToJson(this);

  /// Verifica se l'utente è iscritto
  bool get isEnrolled => status == 'enrolled';

  /// Verifica se la sessione è programmata
  bool get isSessionScheduled => status == 'enrolled';

  /// Verifica se l'utente ha partecipato
  bool get hasAttended => attendedAt != null;

  /// ID dell'iscrizione (alias)
  int get enrollmentId => id;

  /// Titolo del corso (placeholder)
  String get courseTitle => 'Corso';

  /// Formatta la data della sessione
  String get formattedSessionDate {
    if (enrolledAt == null) return 'Data non specificata';
    try {
      final date = DateTime.parse(enrolledAt);
      const months = [
        'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
        'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
      ];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return enrolledAt;
    }
  }

  /// Formatta l'orario (placeholder)
  String get formattedTime => 'Orario non specificato';

  /// Categoria del corso (placeholder)
  String get category => 'Generale';

  /// Colore del corso (placeholder)
  int get colorValue => 0xFF3B82F6;

  /// Luogo del corso (placeholder)
  String get location => '';
}

/// Modello per la risposta my_enrollments (formato diverso dall'API)
@JsonSerializable()
class MyEnrollment {
  @JsonKey(name: 'enrollment_id')
  final int enrollmentId;
  @JsonKey(name: 'enrollment_status')
  final String enrollmentStatus;
  @JsonKey(name: 'enrolled_at')
  final String enrolledAt;
  @JsonKey(name: 'attended_at')
  final String? attendedAt;
  @JsonKey(name: 'session_id')
  final int sessionId;
  @JsonKey(name: 'session_date')
  final String sessionDate;
  @JsonKey(name: 'start_time')
  final String startTime;
  @JsonKey(name: 'end_time')
  final String endTime;
  final String? location;
  @JsonKey(name: 'session_status')
  final String sessionStatus;
  @JsonKey(name: 'current_participants')
  final int? currentParticipants;
  @JsonKey(name: 'max_participants')
  final int? maxParticipants;
  @JsonKey(name: 'course_id')
  final int courseId;
  @JsonKey(name: 'course_title')
  final String courseTitle;
  @JsonKey(name: 'course_description')
  final String? courseDescription;
  final String? category;
  final String? color;

  const MyEnrollment({
    required this.enrollmentId,
    required this.enrollmentStatus,
    required this.enrolledAt,
    this.attendedAt,
    required this.sessionId,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    this.location,
    required this.sessionStatus,
    this.currentParticipants,
    this.maxParticipants,
    required this.courseId,
    required this.courseTitle,
    this.courseDescription,
    this.category,
    this.color,
  });

  factory MyEnrollment.fromJson(Map<String, dynamic> json) => _$MyEnrollmentFromJson(json);
  Map<String, dynamic> toJson() => _$MyEnrollmentToJson(this);

  /// Converte MyEnrollment in CourseEnrollment
  CourseEnrollment toCourseEnrollment() {
    return CourseEnrollment(
      id: enrollmentId,
      sessionId: sessionId,
      userId: 0, // Non disponibile in my_enrollments
      gymId: 0, // Non disponibile in my_enrollments
      status: enrollmentStatus,
      notified: false, // Non disponibile in my_enrollments
      notificationId: null,
      enrolledAt: enrolledAt,
      attendedAt: attendedAt,
      cancelledAt: null,
      notes: null,
    );
  }
}

/// Risposta per la lista delle iscrizioni
@JsonSerializable()
class EnrollmentsResponse {
  final bool success;
  final List<CourseEnrollment> enrollments;

  const EnrollmentsResponse({
    required this.success,
    required this.enrollments,
  });

  factory EnrollmentsResponse.fromJson(Map<String, dynamic> json) => _$EnrollmentsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentsResponseToJson(this);
}

/// Risposta per my_enrollments
@JsonSerializable()
class MyEnrollmentsResponse {
  final bool success;
  final List<MyEnrollment> enrollments;
  final int count;

  const MyEnrollmentsResponse({
    required this.success,
    required this.enrollments,
    required this.count,
  });

  factory MyEnrollmentsResponse.fromJson(Map<String, dynamic> json) => _$MyEnrollmentsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MyEnrollmentsResponseToJson(this);
}

/// Risposta per operazioni sui corsi
@JsonSerializable()
class CourseOperationResponse {
  final bool success;
  final String message;
  final int? courseId;
  final int? enrollmentId;

  const CourseOperationResponse({
    required this.success,
    required this.message,
    this.courseId,
    this.enrollmentId,
  });

  factory CourseOperationResponse.fromJson(Map<String, dynamic> json) => _$CourseOperationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseOperationResponseToJson(this);
}

/// Risposta per iscrizioni
@JsonSerializable()
class EnrollmentResponse {
  final bool success;
  final String message;
  final int? enrollmentId;

  const EnrollmentResponse({
    required this.success,
    required this.message,
    this.enrollmentId,
  });

  factory EnrollmentResponse.fromJson(Map<String, dynamic> json) => _$EnrollmentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentResponseToJson(this);
}