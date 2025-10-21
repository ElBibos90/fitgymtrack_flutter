import 'package:equatable/equatable.dart';
import '../models/course_models_clean.dart';

// ============================================================================
// STATI BLOC CORSI
// ============================================================================

/// Stati base per il BLoC corsi
abstract class CoursesState extends Equatable {
  const CoursesState();

  @override
  List<Object?> get props => [];
}

// ============================================================================
// STATI LISTA CORSI
// ============================================================================

/// Stato iniziale
class CoursesInitialState extends CoursesState {
  const CoursesInitialState();
}

/// Caricamento lista corsi
class CoursesLoadingState extends CoursesState {
  const CoursesLoadingState();
}

/// Lista corsi caricata con successo
class CoursesLoadedState extends CoursesState {
  final List<Course> courses;
  final List<Course> filteredCourses;
  final String? selectedCategory;
  final String? searchQuery;
  final bool isRefreshing;

  const CoursesLoadedState({
    required this.courses,
    required this.filteredCourses,
    this.selectedCategory,
    this.searchQuery,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [
    courses,
    filteredCourses,
    selectedCategory,
    searchQuery,
    isRefreshing,
  ];

  /// Crea una copia dello stato con nuovi valori
  CoursesLoadedState copyWith({
    List<Course>? courses,
    List<Course>? filteredCourses,
    String? selectedCategory,
    String? searchQuery,
    bool? isRefreshing,
  }) {
    return CoursesLoadedState(
      courses: courses ?? this.courses,
      filteredCourses: filteredCourses ?? this.filteredCourses,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Errore nel caricamento lista corsi
class CoursesErrorState extends CoursesState {
  final String message;
  final List<Course>? previousCourses;

  const CoursesErrorState({
    required this.message,
    this.previousCourses,
  });

  @override
  List<Object?> get props => [message, previousCourses];
}

// ============================================================================
// STATI DETTAGLIO CORSO
// ============================================================================

/// Stato iniziale per i dettagli del corso
class CourseDetailsInitialState extends CoursesState {
  const CourseDetailsInitialState();
}

/// Caricamento dettagli corso
class CourseDetailsLoadingState extends CoursesState {
  const CourseDetailsLoadingState();
}

/// Dettagli corso caricati con successo
class CourseDetailsLoadedState extends CoursesState {
  final Course course;
  final List<CourseSession> sessions;
  final String? selectedMonth;
  final bool isRefreshing;

  const CourseDetailsLoadedState({
    required this.course,
    required this.sessions,
    this.selectedMonth,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [
    course,
    sessions,
    selectedMonth,
    isRefreshing,
  ];

  /// Crea una copia dello stato con nuovi valori
  CourseDetailsLoadedState copyWith({
    Course? course,
    List<CourseSession>? sessions,
    String? selectedMonth,
    bool? isRefreshing,
  }) {
    return CourseDetailsLoadedState(
      course: course ?? this.course,
      sessions: sessions ?? this.sessions,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Errore nel caricamento dettagli corso
class CourseDetailsErrorState extends CoursesState {
  final String message;
  final Course? previousCourse;

  const CourseDetailsErrorState({
    required this.message,
    this.previousCourse,
  });

  @override
  List<Object?> get props => [message, previousCourse];
}

// ============================================================================
// STATI ISCRIZIONI
// ============================================================================

/// Caricamento iscrizioni utente
class MyEnrollmentsLoadingState extends CoursesState {
  const MyEnrollmentsLoadingState();
}

/// Iscrizioni utente caricate con successo
class MyEnrollmentsLoadedState extends CoursesState {
  final List<MyEnrollment> enrollments;
  final bool isRefreshing;

  const MyEnrollmentsLoadedState({
    required this.enrollments,
    this.isRefreshing = false,
  });

  @override
  List<Object?> get props => [enrollments, isRefreshing];

  /// Crea una copia dello stato con nuovi valori
  MyEnrollmentsLoadedState copyWith({
    List<MyEnrollment>? enrollments,
    bool? isRefreshing,
  }) {
    return MyEnrollmentsLoadedState(
      enrollments: enrollments ?? this.enrollments,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Errore nel caricamento iscrizioni
class MyEnrollmentsErrorState extends CoursesState {
  final String message;
  final List<MyEnrollment>? previousEnrollments;

  const MyEnrollmentsErrorState({
    required this.message,
    this.previousEnrollments,
  });

  @override
  List<Object?> get props => [message, previousEnrollments];
}

// ============================================================================
// STATI OPERAZIONI
// ============================================================================

/// Operazione in corso (iscrizione/annullamento)
class CourseOperationInProgressState extends CoursesState {
  final String operation;
  final int? sessionId;
  final int? enrollmentId;

  const CourseOperationInProgressState({
    required this.operation,
    this.sessionId,
    this.enrollmentId,
  });

  @override
  List<Object?> get props => [operation, sessionId, enrollmentId];
}

/// Operazione completata con successo
class CourseOperationSuccessState extends CoursesState {
  final String message;
  final String operation;
  final int? enrollmentId;

  const CourseOperationSuccessState({
    required this.message,
    required this.operation,
    this.enrollmentId,
  });

  @override
  List<Object?> get props => [message, operation, enrollmentId];
}

/// Errore durante un'operazione
class CourseOperationErrorState extends CoursesState {
  final String message;
  final String operation;

  const CourseOperationErrorState({
    required this.message,
    required this.operation,
  });

  @override
  List<Object?> get props => [message, operation];
}

// ============================================================================
// STATI NAVIGAZIONE
// ============================================================================

/// Navigazione al dettaglio corso
class NavigateToCourseDetailsState extends CoursesState {
  final int courseId;

  const NavigateToCourseDetailsState({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

/// Navigazione alle mie iscrizioni
class NavigateToMyCoursesState extends CoursesState {
  const NavigateToMyCoursesState();
}

/// Navigazione indietro
class NavigateBackState extends CoursesState {
  const NavigateBackState();
}
