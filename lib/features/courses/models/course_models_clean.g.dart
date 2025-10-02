// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_models_clean.dart';

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
      createdByName: json['created_by_name'] as String?,
      isUnlimited: (json['is_unlimited'] as num?)?.toInt(),
      isRecurring: (json['is_recurring'] as num?)?.toInt(),
      recurrenceType: json['recurrence_type'] as String?,
      recurrenceDays:
          const RecurrenceDaysConverter().fromJson(json['recurrence_days']),
      recurrenceEndDate: json['recurrence_end_date'] as String?,
      standardStartTime: json['standard_start_time'] as String?,
      standardEndTime: json['standard_end_time'] as String?,
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
      'created_by_name': instance.createdByName,
      'is_unlimited': instance.isUnlimited,
      'is_recurring': instance.isRecurring,
      'recurrence_type': instance.recurrenceType,
      'recurrence_days':
          const RecurrenceDaysConverter().toJson(instance.recurrenceDays),
      'recurrence_end_date': instance.recurrenceEndDate,
      'standard_start_time': instance.standardStartTime,
      'standard_end_time': instance.standardEndTime,
    };

CoursesResponse _$CoursesResponseFromJson(Map<String, dynamic> json) =>
    CoursesResponse(
      success: json['success'] as bool,
      courses: (json['courses'] as List<dynamic>)
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CoursesResponseToJson(CoursesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'courses': instance.courses,
    };

CourseResponse _$CourseResponseFromJson(Map<String, dynamic> json) =>
    CourseResponse(
      success: json['success'] as bool,
      course: Course.fromJson(json['course'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CourseResponseToJson(CourseResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'course': instance.course,
    };

CourseSession _$CourseSessionFromJson(Map<String, dynamic> json) =>
    CourseSession(
      id: (json['id'] as num).toInt(),
      courseId: (json['course_id'] as num).toInt(),
      courseTitle: json['course_title'] as String?,
      sessionDate: json['session_date'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      location: json['location'] as String?,
      status: json['status'] as String?,
      currentParticipants: (json['current_participants'] as num?)?.toInt(),
      maxParticipants: (json['max_participants'] as num?)?.toInt(),
      enrolledCount: (json['enrolled_count'] as num?)?.toInt(),
      color: json['color'] as String?,
    );

Map<String, dynamic> _$CourseSessionToJson(CourseSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'course_id': instance.courseId,
      'course_title': instance.courseTitle,
      'session_date': instance.sessionDate,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'location': instance.location,
      'status': instance.status,
      'current_participants': instance.currentParticipants,
      'max_participants': instance.maxParticipants,
      'enrolled_count': instance.enrolledCount,
      'color': instance.color,
    };

SessionsResponse _$SessionsResponseFromJson(Map<String, dynamic> json) =>
    SessionsResponse(
      success: json['success'] as bool,
      sessions: (json['sessions'] as List<dynamic>)
          .map((e) => CourseSession.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SessionsResponseToJson(SessionsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'sessions': instance.sessions,
    };

CourseEnrollment _$CourseEnrollmentFromJson(Map<String, dynamic> json) =>
    CourseEnrollment(
      id: (json['id'] as num).toInt(),
      sessionId: (json['session_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      gymId: (json['gym_id'] as num).toInt(),
      status: json['status'] as String,
      notified: json['notified'] as bool,
      notificationId: (json['notification_id'] as num?)?.toInt(),
      enrolledAt: json['enrolled_at'] as String,
      attendedAt: json['attended_at'] as String?,
      cancelledAt: json['cancelled_at'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$CourseEnrollmentToJson(CourseEnrollment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'session_id': instance.sessionId,
      'user_id': instance.userId,
      'gym_id': instance.gymId,
      'status': instance.status,
      'notified': instance.notified,
      'notification_id': instance.notificationId,
      'enrolled_at': instance.enrolledAt,
      'attended_at': instance.attendedAt,
      'cancelled_at': instance.cancelledAt,
      'notes': instance.notes,
    };

MyEnrollment _$MyEnrollmentFromJson(Map<String, dynamic> json) => MyEnrollment(
      enrollmentId: (json['enrollment_id'] as num).toInt(),
      enrollmentStatus: json['enrollment_status'] as String,
      enrolledAt: json['enrolled_at'] as String,
      attendedAt: json['attended_at'] as String?,
      sessionId: (json['session_id'] as num).toInt(),
      sessionDate: json['session_date'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      location: json['location'] as String,
      sessionStatus: json['session_status'] as String,
      currentParticipants: (json['current_participants'] as num?)?.toInt(),
      maxParticipants: (json['max_participants'] as num?)?.toInt(),
      courseId: (json['course_id'] as num).toInt(),
      courseTitle: json['course_title'] as String,
      courseDescription: json['course_description'] as String,
      category: json['category'] as String,
      color: json['color'] as String,
    );

Map<String, dynamic> _$MyEnrollmentToJson(MyEnrollment instance) =>
    <String, dynamic>{
      'enrollment_id': instance.enrollmentId,
      'enrollment_status': instance.enrollmentStatus,
      'enrolled_at': instance.enrolledAt,
      'attended_at': instance.attendedAt,
      'session_id': instance.sessionId,
      'session_date': instance.sessionDate,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'location': instance.location,
      'session_status': instance.sessionStatus,
      'current_participants': instance.currentParticipants,
      'max_participants': instance.maxParticipants,
      'course_id': instance.courseId,
      'course_title': instance.courseTitle,
      'course_description': instance.courseDescription,
      'category': instance.category,
      'color': instance.color,
    };

EnrollmentsResponse _$EnrollmentsResponseFromJson(Map<String, dynamic> json) =>
    EnrollmentsResponse(
      success: json['success'] as bool,
      enrollments: (json['enrollments'] as List<dynamic>)
          .map((e) => CourseEnrollment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$EnrollmentsResponseToJson(
        EnrollmentsResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'enrollments': instance.enrollments,
    };

MyEnrollmentsResponse _$MyEnrollmentsResponseFromJson(
        Map<String, dynamic> json) =>
    MyEnrollmentsResponse(
      success: json['success'] as bool,
      enrollments: (json['enrollments'] as List<dynamic>)
          .map((e) => MyEnrollment.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num).toInt(),
    );

Map<String, dynamic> _$MyEnrollmentsResponseToJson(
        MyEnrollmentsResponse instance) =>
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
      courseId: (json['courseId'] as num?)?.toInt(),
      enrollmentId: (json['enrollmentId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CourseOperationResponseToJson(
        CourseOperationResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'courseId': instance.courseId,
      'enrollmentId': instance.enrollmentId,
    };

EnrollmentResponse _$EnrollmentResponseFromJson(Map<String, dynamic> json) =>
    EnrollmentResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      enrollmentId: (json['enrollmentId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$EnrollmentResponseToJson(EnrollmentResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'enrollmentId': instance.enrollmentId,
    };
