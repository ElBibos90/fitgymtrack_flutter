import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'course_models.g.dart';

// Converter per gestire i giorni di ricorrenza come JSON array
class RecurrenceDaysConverter implements JsonConverter<List<String>?, dynamic> {
  const RecurrenceDaysConverter();

  @override
  List<String>? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is List) {
      return json.map((e) => e.toString()).toList();
    }
    if (json is String) {
      // Se è una stringa, prova a fare il parse come JSON
      try {
        final decoded = jsonDecode(json);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (e) {
        // Se fallisce, restituisci null
      }
    }
    return null;
  }

  @override
  dynamic toJson(List<String>? object) {
    return object;
  }
}

// ============================================================================
// MODELLI CORSI
// ============================================================================

/// Modello per un corso della palestra
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
  @JsonKey(name: 'created_by_name')
  final String? createdByName;

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
    this.isUnlimited,
    this.isRecurring,
    this.recurrenceType,
    this.recurrenceDays,
    this.recurrenceEndDate,
    this.standardStartTime,
    this.standardEndTime,
    this.createdByName,
  });

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseToJson(this);

  /// Verifica se il corso è attivo
  bool get isActive => status == 'active';

  /// Ottieni i giorni della settimana dal pattern di ricorrenza

  /// Formatta l'orario in formato leggibile
  String get formattedTime {
    if (startTime == null || endTime == null) return 'Orario non specificato';
    final start = _parseTime(startTime!);
    final end = _parseTime(endTime!);
    return '${start.format} - ${end.format}';
  }

  /// Formatta i giorni della settimana in italiano
  String get formattedDays {
    const dayNames = {
      'MON': 'Lun',
      'TUE': 'Mar', 
      'WED': 'Mer',
      'THU': 'Gio',
      'FRI': 'Ven',
      'SAT': 'Sab',
      'SUN': 'Dom',
    };
    
    return (recurrenceDays ?? [])
        .map((day) => dayNames[day] ?? day)
        .join(', ');
  }

  /// Verifica se il corso ha posti limitati
  bool get hasLimitedSpots => maxParticipants != null && maxParticipants! > 0;

  /// Ottieni il colore come Color
  int get colorValue {
    try {
      return int.parse((color ?? '#3B82F6').replaceFirst('#', '0xFF'));
    } catch (e) {
      return 0xFF3B82F6; // Default blue
    }
  }

  /// Helper per parsare l'orario
  _TimeInfo _parseTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return _TimeInfo(hour: hour, minute: minute);
  }
}

/// Helper per gestire l'orario
class _TimeInfo {
  final int hour;
  final int minute;

  _TimeInfo({required this.hour, required this.minute});

  String get format {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ============================================================================
// MODELLI SESSIONI
// ============================================================================

/// Modello per una sessione di corso
@JsonSerializable()
class CourseSession {
  final int id;
  final int courseId;
  final String? courseTitle;
  final String? sessionDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final String? status;
  final int? currentParticipants;
  final int? maxParticipants;
  final String? color;
  final bool isFull;

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
    this.color,
    required this.isFull,
  });

  factory CourseSession.fromJson(Map<String, dynamic> json) => 
      _$CourseSessionFromJson(json);
  Map<String, dynamic> toJson() => _$CourseSessionToJson(this);

  /// Verifica se la sessione è programmata
  bool get isScheduled => status == 'scheduled';

  /// Verifica se ci sono posti disponibili
  bool get hasAvailableSpots => !isFull && (maxParticipants == null || (currentParticipants ?? 0) < maxParticipants!);

  /// Ottieni il numero di posti disponibili
  int get availableSpots {
    if (maxParticipants == null) return 999; // Illimitati
    return maxParticipants! - (currentParticipants ?? 0);
  }

  /// Formatta la data in formato leggibile
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

  /// Formatta l'orario
  String get formattedTime {
    if (startTime == null || endTime == null) return 'Orario non specificato';
    final start = _parseTime(startTime!);
    final end = _parseTime(endTime!);
    return '${start.format} - ${end.format}';
  }

  /// Ottieni il colore come int
  int get colorValue {
    try {
      return int.parse((color ?? '#3B82F6').replaceFirst('#', '0xFF'));
    } catch (e) {
      return 0xFF3B82F6; // Default blue
    }
  }

  /// Helper per parsare l'orario
  _TimeInfo _parseTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return _TimeInfo(hour: hour, minute: minute);
  }
}

// ============================================================================
// MODELLI ISCRIZIONI
// ============================================================================

/// Modello per un'iscrizione a un corso
@JsonSerializable()
class CourseEnrollment {
  final int enrollmentId;
  final String enrollmentStatus;
  final String enrolledAt;
  final String? attendedAt;
  final int sessionId;
  final String sessionDate;
  final String startTime;
  final String endTime;
  final String location;
  final String sessionStatus;
  final int? currentParticipants;
  final int? maxParticipants;
  final int courseId;
  final String courseTitle;
  final String courseDescription;
  final String category;
  final String color;

  const CourseEnrollment({
    required this.enrollmentId,
    required this.enrollmentStatus,
    required this.enrolledAt,
    this.attendedAt,
    required this.sessionId,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.sessionStatus,
    this.currentParticipants,
    this.maxParticipants,
    required this.courseId,
    required this.courseTitle,
    required this.courseDescription,
    required this.category,
    required this.color,
  });

  factory CourseEnrollment.fromJson(Map<String, dynamic> json) => 
      _$CourseEnrollmentFromJson(json);
  Map<String, dynamic> toJson() => _$CourseEnrollmentToJson(this);

  /// Verifica se l'iscrizione è attiva
  bool get isEnrolled => enrollmentStatus == 'enrolled';

  /// Verifica se l'utente ha partecipato
  bool get hasAttended => attendedAt != null;

  /// Verifica se la sessione è programmata
  bool get isSessionScheduled => sessionStatus == 'scheduled';

  /// Formatta la data della sessione
  String get formattedSessionDate {
    try {
      final date = DateTime.parse(sessionDate);
      const months = [
        'Gen', 'Feb', 'Mar', 'Apr', 'Mag', 'Giu',
        'Lug', 'Ago', 'Set', 'Ott', 'Nov', 'Dic'
      ];
      const days = ['Dom', 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab'];
      return '${days[date.weekday % 7]} ${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return sessionDate;
    }
  }

  /// Formatta l'orario
  String get formattedTime {
    if (startTime == null || endTime == null) return 'Orario non specificato';
    final start = _parseTime(startTime!);
    final end = _parseTime(endTime!);
    return '${start.format} - ${end.format}';
  }

  /// Ottieni il colore del corso
  int get colorValue {
    try {
      return int.parse((color ?? '#3B82F6').replaceFirst('#', '0xFF'));
    } catch (e) {
      return 0xFF3B82F6; // Default blue
    }
  }

  /// Helper per parsare l'orario
  _TimeInfo _parseTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return _TimeInfo(hour: hour, minute: minute);
  }
}

// ============================================================================
// MODELLI RISPOSTE API
// ============================================================================

/// Risposta per la lista corsi
@JsonSerializable()
class CoursesResponse {
  final bool success;
  final List<Course> courses;
  final int count;

  const CoursesResponse({
    required this.success,
    required this.courses,
    required this.count,
  });

  factory CoursesResponse.fromJson(Map<String, dynamic> json) => 
      _$CoursesResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CoursesResponseToJson(this);
}

/// Risposta per la lista sessioni
@JsonSerializable()
class SessionsResponse {
  final bool success;
  final List<CourseSession> sessions;
  final int count;

  const SessionsResponse({
    required this.success,
    required this.sessions,
    required this.count,
  });

  factory SessionsResponse.fromJson(Map<String, dynamic> json) => 
      _$SessionsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SessionsResponseToJson(this);
}

/// Risposta per le iscrizioni
@JsonSerializable()
class EnrollmentsResponse {
  final bool success;
  final List<CourseEnrollment> enrollments;
  final int count;

  const EnrollmentsResponse({
    required this.success,
    required this.enrollments,
    required this.count,
  });

  factory EnrollmentsResponse.fromJson(Map<String, dynamic> json) => 
      _$EnrollmentsResponseFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentsResponseToJson(this);
}

/// Risposta per operazioni (iscrizione/annullamento)
@JsonSerializable()
class CourseOperationResponse {
  final bool success;
  final String message;
  final int? enrollmentId;

  const CourseOperationResponse({
    required this.success,
    required this.message,
    this.enrollmentId,
  });

  factory CourseOperationResponse.fromJson(Map<String, dynamic> json) => 
      _$CourseOperationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseOperationResponseToJson(this);
}

/// Risposta di errore
@JsonSerializable()
class CourseErrorResponse {
  final bool success;
  final String error;

  const CourseErrorResponse({
    required this.success,
    required this.error,
  });

  factory CourseErrorResponse.fromJson(Map<String, dynamic> json) => 
      _$CourseErrorResponseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseErrorResponseToJson(this);
}
