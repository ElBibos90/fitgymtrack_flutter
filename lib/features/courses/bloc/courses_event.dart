import 'package:equatable/equatable.dart';
import 'courses_state.dart';

// ============================================================================
// EVENTI BLOC CORSI
// ============================================================================

/// Eventi base per il BLoC corsi
abstract class CoursesEvent extends Equatable {
  const CoursesEvent();

  @override
  List<Object?> get props => [];
}

// ============================================================================
// EVENTI LISTA CORSI
// ============================================================================

/// Carica la lista di tutti i corsi disponibili
class LoadCoursesEvent extends CoursesEvent {
  const LoadCoursesEvent();
}

/// Aggiorna la lista corsi (refresh)
class RefreshCoursesEvent extends CoursesEvent {
  const RefreshCoursesEvent();
}

/// Filtra i corsi per categoria
class FilterCoursesByCategoryEvent extends CoursesEvent {
  final String? category;

  const FilterCoursesByCategoryEvent({this.category});

  @override
  List<Object?> get props => [category];
}

/// Cerca corsi per nome
class SearchCoursesEvent extends CoursesEvent {
  final String query;

  const SearchCoursesEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

// ============================================================================
// EVENTI DETTAGLIO CORSO
// ============================================================================

/// Carica i dettagli di un corso specifico
class LoadCourseDetailsEvent extends CoursesEvent {
  final int courseId;

  const LoadCourseDetailsEvent({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

/// Carica le sessioni di un corso per un mese specifico
class LoadCourseSessionsEvent extends CoursesEvent {
  final int courseId;
  final String? month;

  const LoadCourseSessionsEvent({
    required this.courseId,
    this.month,
  });

  @override
  List<Object?> get props => [courseId, month];
}

/// Resetta i dettagli del corso corrente
class ResetCourseDetailsEvent extends CoursesEvent {
  final CoursesState? previousState;
  
  const ResetCourseDetailsEvent({this.previousState});
  
  @override
  List<Object?> get props => [previousState];
}

// ============================================================================
// EVENTI ISCRIZIONI
// ============================================================================

/// Carica le iscrizioni dell'utente corrente
class LoadMyEnrollmentsEvent extends CoursesEvent {
  const LoadMyEnrollmentsEvent();
}

/// Aggiorna le iscrizioni (refresh)
class RefreshMyEnrollmentsEvent extends CoursesEvent {
  const RefreshMyEnrollmentsEvent();
}

/// Iscriviti a una sessione di corso
class EnrollInSessionEvent extends CoursesEvent {
  final int sessionId;

  const EnrollInSessionEvent({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

/// Annulla l'iscrizione a una sessione
class CancelEnrollmentEvent extends CoursesEvent {
  final int enrollmentId;

  const CancelEnrollmentEvent({required this.enrollmentId});

  @override
  List<Object?> get props => [enrollmentId];
}

// ============================================================================
// EVENTI NAVIGAZIONE
// ============================================================================

/// Naviga al dettaglio di un corso
class NavigateToCourseDetailsEvent extends CoursesEvent {
  final int courseId;

  const NavigateToCourseDetailsEvent({required this.courseId});

  @override
  List<Object?> get props => [courseId];
}

/// Naviga alla lista delle mie iscrizioni
class NavigateToMyCoursesEvent extends CoursesEvent {
  const NavigateToMyCoursesEvent();
}

/// Torna indietro dalla schermata corrente
class NavigateBackEvent extends CoursesEvent {
  const NavigateBackEvent();
}

// ============================================================================
// EVENTI UTILITY
// ============================================================================

/// Pulisce lo stato del BLoC
class ClearCoursesStateEvent extends CoursesEvent {
  const ClearCoursesStateEvent();
}

/// Resetta i filtri applicati
class ResetFiltersEvent extends CoursesEvent {
  const ResetFiltersEvent();
}
