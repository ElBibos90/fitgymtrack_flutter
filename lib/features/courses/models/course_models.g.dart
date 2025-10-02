// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      recurrencePattern: json['recurrencePattern'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      maxParticipants: (json['max_participants'] as num?)?.toInt(),
      status: json['status'] as String?,
      color: json['color'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      totalSessions: (json['total_sessions'] as num?)?.toInt(),
      upcomingSessions: (json['upcoming_sessions'] as num?)?.toInt(),
      gymId: (json['gym_id'] as num?)?.toInt(),
      createdBy: (json['created_by'] as num?)?.toInt(),
      isUnlimited: (json['is_unlimited'] as num?)?.toInt(),
      isRecurring: (json['is_recurring'] as num?)?.toInt(),
      recurrenceType: json['recurrence_type'] as String?,
      recurrenceDays:
          const RecurrenceDaysConverter().fromJson(json['recurrence_days']),
      recurrenceEndDate: json['recurrence_end_date'] as String?,
      standardStartTime: json['standard_start_time'] as String?,
      standardEndTime: json['standard_end_time'] as String?,
      createdByName: json['created_by_name'] as String?,
    );

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'category': instance.category,
      'recurrencePattern': instance.recurrencePattern,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'max_participants': instance.maxParticipants,
      'status': instance.status,
      'color': instance.color,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'total_sessions': instance.totalSessions,
      'upcoming_sessions': instance.upcomingSessions,
      'gym_id': instance.gymId,
      'created_by': instance.createdBy,
      'is_unlimited': instance.isUnlimited,
      'is_recurring': instance.isRecurring,
      'recurrence_type': instance.recurrenceType,
      'recurrence_days':
          const RecurrenceDaysConverter().toJson(instance.recurrenceDays),
      'recurrence_end_date': instance.recurrenceEndDate,
      'standard_start_time': instance.standardStartTime,
      'standard_end_time': instance.standardEndTime,
      'created_by_name': instance.createdByName,
    };

CourseSession _$CourseSessionFromJson(Map<String, dynamic> json) =>
    CourseSession(
      id: (json['id'] as num).toInt(),
      courseId: (json['courseId'] as num).toInt(),
      courseTitle: json['courseTitle'] as String?,
      sessionDate: json['sessionDate'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      location: json['location'] as String?,
      status: json['status'] as String?,
      currentParticipants: (json['currentParticipants'] as num?)?.toInt(),
      maxParticipants: (json['maxParticipants'] as num?)?.toInt(),
      color: json['color'] as String?,
      isFull: json['isFull'] as bool,
    );

Map<String, dynamic> _$CourseSessionToJson(CourseSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'courseId': instance.courseId,
      'courseTitle': instance.courseTitle,
      'sessionDate': instance.sessionDate,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'location': instance.location,
      'status': instance.status,
      'currentParticipants': instance.currentParticipants,
      'maxParticipants': instance.maxParticipants,
      'color': instance.color,
      'isFull': instance.isFull,
    };

CourseEnrollment _$CourseEnrollmentFromJson(Map<String, dynamic> json) =>
    CourseEnrollment(
      enrollmentId: (json['enrollmentId'] as num).toInt(),
      enrollmentStatus: json['enrollmentStatus'] as String,
      enrolledAt: json['enrolledAt'] as String,
      attendedAt: json['attendedAt'] as String?,
      sessionId: (json['sessionId'] as num).toInt(),
      sessionDate: json['sessionDate'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      location: json['location'] as String,
      sessionStatus: json['sessionStatus'] as String,
      currentParticipants: (json['currentParticipants'] as num?)?.toInt(),
      maxParticipants: (json['maxParticipants'] as num?)?.toInt(),
      courseId: (json['courseId'] as num).toInt(),
      courseTitle: json['courseTitle'] as String,
      courseDescription: json['courseDescription'] as String,
      category: json['category'] as String,
      color: json['color'] as String,
    );

Map<String, dynamic> _$CourseEnrollmentToJson(CourseEnrollment instance) =>
    <String, dynamic>{
      'enrollmentId': instance.enrollmentId,
      'enrollmentStatus': instance.enrollmentStatus,
      'enrolledAt': instance.enrolledAt,
      'attendedAt': instance.attendedAt,
      'sessionId': instance.sessionId,
      'sessionDate': instance.sessionDate,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'location': instance.location,
      'sessionStatus': instance.sessionStatus,
      'currentParticipants': instance.currentParticipants,
      'maxParticipants': instance.maxParticipants,
      'courseId': instance.courseId,
      'courseTitle': instance.courseTitle,
      'courseDescription': instance.courseDescription,
      'category': instance.category,
      'color': instance.color,
    };

CoursesResponse _$CoursesResponseFromJson(Map<String, dynamic> json) =>
    CoursesResponse(
      success: json['success'] as bool,
      courses: (json['courses'] as List<dynamic>)
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$CoursesResponseToJson(CoursesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'courses': instance.courses,
      'count': instance.count,
    };

SessionsResponse _$SessionsResponseFromJson(Map<String, dynamic> json) =>
    SessionsResponse(
      success: json['success'] as bool,
      sessions: (json['sessions'] as List<dynamic>)
          .map((e) => CourseSession.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$SessionsResponseToJson(SessionsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'sessions': instance.sessions,
      'count': instance.count,
    };

EnrollmentsResponse _$EnrollmentsResponseFromJson(Map<String, dynamic> json) =>
    EnrollmentsResponse(
      success: json['success'] as bool,
      enrollments: (json['enrollments'] as List<dynamic>)
          .map((e) => CourseEnrollment.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$EnrollmentsResponseToJson(
        EnrollmentsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'enrollments': instance.enrollments,
      'count': instance.count,
    };

CourseOperationResponse _$CourseOperationResponseFromJson(
        Map<String, dynamic> json) =>
    CourseOperationResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      enrollmentId: (json['enrollmentId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CourseOperationResponseToJson(
        CourseOperationResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'enrollmentId': instance.enrollmentId,
    };

CourseErrorResponse _$CourseErrorResponseFromJson(Map<String, dynamic> json) =>
    CourseErrorResponse(
      success: json['success'] as bool,
      error: json['error'] as String,
    );

Map<String, dynamic> _$CourseErrorResponseToJson(
        CourseErrorResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'error': instance.error,
    };
