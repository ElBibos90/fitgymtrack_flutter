import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/course_models_clean.dart';
import '../repository/courses_repository.dart';
import 'courses_event.dart';
import 'courses_state.dart';

// ============================================================================
// BLOC CORSI
// ============================================================================

class CoursesBloc extends Bloc<CoursesEvent, CoursesState> {
  final CoursesRepository _repository;
  StreamSubscription? _subscription;

  CoursesBloc({required CoursesRepository repository})
      : _repository = repository,
        super(const CoursesInitialState()) {
    
    // ============================================================================
    // REGISTRAZIONE HANDLERS
    // ============================================================================
    
    // Lista corsi
    on<LoadCoursesEvent>(_onLoadCourses);
    on<RefreshCoursesEvent>(_onRefreshCourses);
    on<FilterCoursesByCategoryEvent>(_onFilterCoursesByCategory);
    on<SearchCoursesEvent>(_onSearchCourses);
    
    // Dettaglio corso
    on<LoadCourseDetailsEvent>(_onLoadCourseDetails);
    on<LoadCourseSessionsEvent>(_onLoadCourseSessions);
    on<ResetCourseDetailsEvent>(_onResetCourseDetails);
    
    // Iscrizioni
    on<LoadMyEnrollmentsEvent>(_onLoadMyEnrollments);
    on<RefreshMyEnrollmentsEvent>(_onRefreshMyEnrollments);
    on<EnrollInSessionEvent>(_onEnrollInSession);
    on<CancelEnrollmentEvent>(_onCancelEnrollment);
    on<CancelSessionEnrollmentEvent>(_onCancelSessionEnrollment);
    
    // Navigazione
    on<NavigateToCourseDetailsEvent>(_onNavigateToCourseDetails);
    on<NavigateToMyCoursesEvent>(_onNavigateToMyCourses);
    on<NavigateBackEvent>(_onNavigateBack);
    
    // Utility
    on<ClearCoursesStateEvent>(_onClearCoursesState);
    on<ResetFiltersEvent>(_onResetFilters);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  // ============================================================================
  // HANDLERS LISTA CORSI
  // ============================================================================

  Future<void> _onLoadCourses(
    LoadCoursesEvent event,
    Emitter<CoursesState> emit,
  ) async {
    print('[COURSES_DEBUG] 🔍 _onLoadCourses: INIZIATO');
    try {
      emit(const CoursesLoadingState());
      
      // 🔧 FIX: Retry automatico per problemi di timing dopo logout/login
      CoursesResponse? response;
      int retryCount = 0;
      const maxRetries = 2;
      
      while (retryCount <= maxRetries) {
        try {
          response = await _repository.getAllCourses();
          break; // Successo, esci dal loop
        } catch (e) {
          retryCount++;
          if (retryCount <= maxRetries) {
            // Aspetta un po' prima di riprovare
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
            continue;
          } else {
            // Ultimo tentativo fallito, rilancia l'errore
            rethrow;
          }
        }
      }
      
      if (response != null && response.success) {
        print('[COURSES_DEBUG] 🔍 _onLoadCourses: Caricati ${response.courses.length} corsi');
        emit(CoursesLoadedState(
          courses: response.courses,
          filteredCourses: response.courses,
        ));
      } else {
        emit(const CoursesErrorState(
          message: 'Errore nel caricamento dei corsi',
        ));
      }
    } catch (e) {
      emit(CoursesErrorState(
        message: 'Errore di connessione: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRefreshCourses(
    RefreshCoursesEvent event,
    Emitter<CoursesState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is CoursesLoadedState) {
      emit(currentState.copyWith(isRefreshing: true));
    }
    
    try {
      final response = await _repository.getAllCourses();
      
      if (response.success) {
        final filteredCourses = _applyFilters(
          response.courses,
          currentState is CoursesLoadedState ? currentState.selectedCategory : null,
          currentState is CoursesLoadedState ? currentState.searchQuery : null,
        );
        
        emit(CoursesLoadedState(
          courses: response.courses,
          filteredCourses: filteredCourses,
          selectedCategory: currentState is CoursesLoadedState ? currentState.selectedCategory : null,
          searchQuery: currentState is CoursesLoadedState ? currentState.searchQuery : null,
          isRefreshing: false,
        ));
      } else {
        emit(CoursesErrorState(
          message: 'Errore nel refresh dei corsi',
          previousCourses: currentState is CoursesLoadedState ? currentState.courses : null,
        ));
      }
    } catch (e) {
      emit(CoursesErrorState(
        message: 'Errore di connessione: ${e.toString()}',
        previousCourses: currentState is CoursesLoadedState ? currentState.courses : null,
      ));
    }
  }

  Future<void> _onFilterCoursesByCategory(
    FilterCoursesByCategoryEvent event,
    Emitter<CoursesState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is CoursesLoadedState) {
      final filteredCourses = _applyFilters(
        currentState.courses,
        event.category,
        currentState.searchQuery,
      );
      
      emit(currentState.copyWith(
        filteredCourses: filteredCourses,
        selectedCategory: event.category,
      ));
    }
  }

  Future<void> _onSearchCourses(
    SearchCoursesEvent event,
    Emitter<CoursesState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is CoursesLoadedState) {
      final filteredCourses = _applyFilters(
        currentState.courses,
        currentState.selectedCategory,
        event.query.isEmpty ? null : event.query,
      );
      
      emit(currentState.copyWith(
        filteredCourses: filteredCourses,
        searchQuery: event.query.isEmpty ? null : event.query,
      ));
    }
  }

  // ============================================================================
  // HANDLERS DETTAGLIO CORSO
  // ============================================================================

  Future<void> _onLoadCourseDetails(
    LoadCourseDetailsEvent event,
    Emitter<CoursesState> emit,
  ) async {
    print('[COURSES_DEBUG] 🔍 _onLoadCourseDetails: INIZIATO per courseId=${event.courseId}');
    try {
      emit(const CourseDetailsLoadingState());
      
      final course = await _repository.getCourseDetails(event.courseId);
      print('[COURSES_DEBUG] 🔍 _onLoadCourseDetails: Corso caricato - id=${course.id}, title=${course.title}');
      
      emit(CourseDetailsLoadedState(
        course: course,
        sessions: [],
      ));
    } catch (e) {
      emit(CourseDetailsErrorState(
        message: 'Errore nel caricamento del corso: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadCourseSessions(
    LoadCourseSessionsEvent event,
    Emitter<CoursesState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is CourseDetailsLoadedState) {
      emit(currentState.copyWith(isRefreshing: true));
    }
    
    try {
      print('[COURSES_DEBUG] 🔍 _onLoadCourseSessions: INIZIATO per courseId=${event.courseId}, month=${event.month}');
      final response = event.month != null
          ? await _repository.getSessionsForMonth(event.month!, courseId: event.courseId)
          : await _repository.getCurrentMonthSessions(courseId: event.courseId);
      
      print('[COURSES_DEBUG] 🔍 _onLoadCourseSessions: Caricate ${response.sessions.length} sessioni');
      
      
      if (response.success) {
        if (currentState is CourseDetailsLoadedState) {
          emit(currentState.copyWith(
            sessions: response.sessions,
            selectedMonth: event.month,
            isRefreshing: false,
          ));
        } else {
          
          // Se lo stato corrente non è CourseDetailsLoadedState, creiamo un nuovo stato
          // Questo può succedere se siamo in CourseOperationSuccessState
          if (currentState is CourseOperationSuccessState) {
            // Dobbiamo ottenere i dettagli del corso per creare il nuovo stato
            try {
              final course = await _repository.getCourseDetails(event.courseId);
              emit(CourseDetailsLoadedState(
                course: course,
                sessions: response.sessions,
                selectedMonth: event.month,
              ));
            } catch (e) {
              emit(CourseDetailsErrorState(
                message: 'Errore nel ricaricamento delle sessioni',
              ));
            }
          }
        }
      } else {
        // Se il ricaricamento fallisce, torna allo stato precedente
        if (currentState is CourseDetailsLoadedState) {
          emit(currentState.copyWith(
            isRefreshing: false,
          ));
        } else {
          emit(CourseDetailsErrorState(
            message: 'Errore nel caricamento delle sessioni',
            previousCourse: currentState is CourseDetailsLoadedState ? currentState.course : null,
          ));
        }
      }
    } catch (e) {
      // Se il ricaricamento fallisce, torna allo stato precedente
      if (currentState is CourseDetailsLoadedState) {
        emit(currentState.copyWith(
          isRefreshing: false,
        ));
      } else {
        emit(CourseDetailsErrorState(
          message: 'Errore di connessione: ${e.toString()}',
          previousCourse: currentState is CourseDetailsLoadedState ? currentState.course : null,
        ));
      }
    }
  }

  Future<void> _onResetCourseDetails(
    ResetCourseDetailsEvent event,
    Emitter<CoursesState> emit,
  ) async {
    
    // Se abbiamo uno stato precedente con la lista corsi, torniamo a quello
    final currentState = state;
    if (currentState is CourseDetailsLoadedState || 
        currentState is CourseDetailsLoadingState ||
        currentState is CourseDetailsErrorState) {
      
      // Se abbiamo uno stato precedente valido, torniamo a quello
      if (event.previousState != null) {
        emit(event.previousState!);
        return;
      }
      
      // Altrimenti ricarica la lista corsi
      try {
        emit(const CoursesLoadingState());
        
        final response = await _repository.getAllCourses();
        
        if (response.success) {
          emit(CoursesLoadedState(
            courses: response.courses,
            filteredCourses: response.courses,
          ));
        } else {
          emit(CoursesErrorState(message: 'Errore nel ricaricamento dei corsi'));
        }
      } catch (e) {
        emit(CoursesErrorState(message: 'Errore di connessione: ${e.toString()}'));
      }
    }
  }

  // ============================================================================
  // HANDLERS ISCRIZIONI
  // ============================================================================

  Future<void> _onLoadMyEnrollments(
    LoadMyEnrollmentsEvent event,
    Emitter<CoursesState> emit,
  ) async {
    print('[COURSES_DEBUG] 🔍 _onLoadMyEnrollments: INIZIATO');
    try {
      emit(const MyEnrollmentsLoadingState());
      
      // 🔧 FIX: Retry automatico per problemi di timing dopo logout/login
      EnrollmentsResponse? response;
      int retryCount = 0;
      const maxRetries = 2;
      
      while (retryCount <= maxRetries) {
        try {
          response = await _repository.getMyCourseEnrollmentsStandard();
          break; // Successo, esci dal loop
        } catch (e) {
          retryCount++;
          if (retryCount <= maxRetries) {
            // Aspetta un po' prima di riprovare
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
            continue;
          } else {
            // Ultimo tentativo fallito, rilancia l'errore
            rethrow;
          }
        }
      }
      
      if (response != null && response.success) {
        // DEBUG: Log per verificare i dati ricevuti
        print('[COURSES_DEBUG] 🔍 MyEnrollments: Ricevute ${response.enrollments.length} iscrizioni');
        if (response.enrollments.isNotEmpty) {
          print('[COURSES_DEBUG] 🔍 MyEnrollments: Prima iscrizione - enrollment_id: ${response.enrollments.first.enrollmentId}');
        }
        
        emit(MyEnrollmentsLoadedState(
          enrollments: response.enrollments,
        ));
      } else {
        emit(const MyEnrollmentsErrorState(
          message: 'Errore nel caricamento delle iscrizioni',
        ));
      }
    } catch (e) {
      emit(MyEnrollmentsErrorState(
        message: 'Errore di connessione: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRefreshMyEnrollments(
    RefreshMyEnrollmentsEvent event,
    Emitter<CoursesState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is MyEnrollmentsLoadedState) {
      emit(currentState.copyWith(isRefreshing: true));
    }
    
    try {
      final response = await _repository.getMyCourseEnrollmentsStandard();
      
      if (response.success) {
        emit(MyEnrollmentsLoadedState(
          enrollments: response.enrollments,
          isRefreshing: false,
        ));
      } else {
        emit(MyEnrollmentsErrorState(
          message: 'Errore nel refresh delle iscrizioni',
          previousEnrollments: currentState is MyEnrollmentsLoadedState ? currentState.enrollments : null,
        ));
      }
    } catch (e) {
      emit(MyEnrollmentsErrorState(
        message: 'Errore di connessione: ${e.toString()}',
        previousEnrollments: currentState is MyEnrollmentsLoadedState ? currentState.enrollments : null,
      ));
    }
  }

  Future<void> _onEnrollInSession(
    EnrollInSessionEvent event,
    Emitter<CoursesState> emit,
  ) async {
    try {
      // Salva lo stato precedente
      final previousState = state;
      
      emit(CourseOperationInProgressState(
        operation: 'Iscrizione in corso...',
        sessionId: event.sessionId,
      ));
      
      final response = await _repository.enrollInCourseSession(event.sessionId);
      
      if (response.success) {
        emit(CourseOperationSuccessState(
          message: response.message,
          operation: 'Iscrizione completata',
          enrollmentId: response.enrollmentId,
        ));
        
        // Dopo 2 secondi, ricarica le sessioni per aggiornare lo stato
        await Future.delayed(const Duration(seconds: 2));
        
        if (state is CourseOperationSuccessState && previousState is CourseDetailsLoadedState) {
          // Ricarica le sessioni per aggiornare lo stato dell'iscrizione
          add(LoadCourseSessionsEvent(
            courseId: previousState.course.id,
            month: previousState.selectedMonth ?? _getCurrentMonth(),
          ));
        }
      } else {
        emit(CourseOperationErrorState(
          message: response.message,
          operation: 'Iscrizione',
        ));
      }
    } catch (e) {
      emit(CourseOperationErrorState(
        message: 'Errore di connessione: ${e.toString()}',
        operation: 'Iscrizione',
      ));
    }
  }

  Future<void> _onCancelEnrollment(
    CancelEnrollmentEvent event,
    Emitter<CoursesState> emit,
  ) async {
    try {
      // Salva lo stato precedente
      final previousState = state;
      
      emit(CourseOperationInProgressState(
        operation: 'Annullamento in corso...',
        enrollmentId: event.enrollmentId,
      ));
      
      final response = await _repository.cancelCourseEnrollment(event.enrollmentId);
      
      if (response.success) {
        emit(CourseOperationSuccessState(
          message: response.message,
          operation: 'Annullamento completato',
        ));
        
        // Dopo 2 secondi, torna allo stato precedente
        await Future.delayed(const Duration(seconds: 2));
        if (state is CourseOperationSuccessState && previousState is CourseDetailsLoadedState) {
          emit(CourseDetailsLoadedState(
            course: previousState.course,
            sessions: previousState.sessions,
            selectedMonth: previousState.selectedMonth,
          ));
        }
      } else {
        emit(CourseOperationErrorState(
          message: response.message,
          operation: 'Annullamento',
        ));
      }
    } catch (e) {
      emit(CourseOperationErrorState(
        message: 'Errore di connessione: ${e.toString()}',
        operation: 'Annullamento',
      ));
    }
  }

  Future<void> _onCancelSessionEnrollment(
    CancelSessionEnrollmentEvent event,
    Emitter<CoursesState> emit,
  ) async {
    try {
      print('[DEBUG] 🚫 BLoC: _onCancelSessionEnrollment INIZIATO per sessionId: ${event.sessionId}');
      
      // Salva lo stato precedente
      final previousState = state;
      
      emit(CourseOperationInProgressState(
        operation: 'Disiscrizione in corso...',
        sessionId: event.sessionId,
      ));
      
      // Prima otteniamo l'enrollmentId per questa sessione
      print('[DEBUG] 🚫 Recupero iscrizioni utente...');
      final enrollmentsResponse = await _repository.getMyCourseEnrollments();
      
      print('[DEBUG] 🚫 Risposta iscrizioni: success=${enrollmentsResponse.success}, count=${enrollmentsResponse.enrollments.length}');
      
      // Debug: stampa il primo enrollment per vedere la struttura
      if (enrollmentsResponse.enrollments.isNotEmpty) {
        final firstEnrollment = enrollmentsResponse.enrollments.first;
        print('[DEBUG] 🚫 Primo enrollment: enrollmentId=${firstEnrollment.enrollmentId}, sessionId=${firstEnrollment.sessionId}, status=${firstEnrollment.enrollmentStatus}');
      }
      
      if (enrollmentsResponse.success) {
        // Cerchiamo l'iscrizione per questa sessione
        final enrollment = enrollmentsResponse.enrollments
            .where((e) => e.sessionId == event.sessionId)
            .firstOrNull;
        
        print('[DEBUG] 🚫 Iscrizione trovata: ${enrollment != null}');
        if (enrollment != null) {
          print('[DEBUG] 🚫 EnrollmentId: ${enrollment.enrollmentId}, SessionId: ${enrollment.sessionId}');
        }
        
        if (enrollment != null) {
          // Ora possiamo cancellare l'iscrizione
          print('[DEBUG] 🚫 Chiamata API per cancellare enrollmentId: ${enrollment.enrollmentId}');
          final response = await _repository.cancelCourseEnrollment(enrollment.enrollmentId);
          
          print('[DEBUG] 🚫 Risposta cancellazione: success=${response.success}, message=${response.message}');
          
          if (response.success) {
            emit(CourseOperationSuccessState(
              message: response.message,
              operation: 'Disiscrizione completata',
            ));
            
            // Dopo 2 secondi, ricarica le sessioni per aggiornare lo stato
            await Future.delayed(const Duration(seconds: 2));
            
            if (state is CourseOperationSuccessState && previousState is CourseDetailsLoadedState) {
              // Ricarica le sessioni per aggiornare lo stato dell'iscrizione
              add(LoadCourseSessionsEvent(
                courseId: previousState.course.id,
                month: previousState.selectedMonth ?? _getCurrentMonth(),
              ));
            }
          } else {
            emit(CourseOperationErrorState(
              message: response.message,
              operation: 'Disiscrizione',
            ));
          }
        } else {
          print('[DEBUG] 🚫 ERRORE: Iscrizione non trovata per sessionId: ${event.sessionId}');
          emit(CourseOperationErrorState(
            message: 'Iscrizione non trovata per questa sessione',
            operation: 'Disiscrizione',
          ));
        }
      } else {
        print('[DEBUG] 🚫 ERRORE: Fallimento nel recupero iscrizioni');
        emit(CourseOperationErrorState(
          message: 'Errore nel recupero delle iscrizioni',
          operation: 'Disiscrizione',
        ));
      }
    } catch (e) {
      print('[DEBUG] 🚫 ERRORE: Exception durante disiscrizione: $e');
      emit(CourseOperationErrorState(
        message: 'Errore di connessione: ${e.toString()}',
        operation: 'Disiscrizione',
      ));
    }
  }

  // ============================================================================
  // HANDLERS NAVIGAZIONE
  // ============================================================================

  void _onNavigateToCourseDetails(
    NavigateToCourseDetailsEvent event,
    Emitter<CoursesState> emit,
  ) {
    emit(NavigateToCourseDetailsState(courseId: event.courseId));
  }

  void _onNavigateToMyCourses(
    NavigateToMyCoursesEvent event,
    Emitter<CoursesState> emit,
  ) {
    emit(const NavigateToMyCoursesState());
  }

  void _onNavigateBack(
    NavigateBackEvent event,
    Emitter<CoursesState> emit,
  ) {
    emit(const NavigateBackState());
  }

  // ============================================================================
  // HANDLERS UTILITY
  // ============================================================================

  void _onClearCoursesState(
    ClearCoursesStateEvent event,
    Emitter<CoursesState> emit,
  ) {
    emit(const CoursesInitialState());
  }

  void _onResetFilters(
    ResetFiltersEvent event,
    Emitter<CoursesState> emit,
  ) {
    final currentState = state;
    
    if (currentState is CoursesLoadedState) {
      emit(currentState.copyWith(
        filteredCourses: currentState.courses,
        selectedCategory: null,
        searchQuery: null,
      ));
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Applica filtri alla lista corsi
  List<Course> _applyFilters(
    List<Course> courses,
    String? category,
    String? searchQuery,
  ) {
    var filtered = courses;

    // Filtro per categoria
    if (category != null && category.isNotEmpty) {
      filtered = filtered.where((course) => course.category == category).toList();
    }

    // Filtro per ricerca
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((course) =>
          course.title.toLowerCase().contains(query) ||
          (course.description?.toLowerCase().contains(query) ?? false) ||
          (course.category?.toLowerCase().contains(query) ?? false)).toList();
    }

    return filtered;
  }

  /// Ottieni il mese corrente nel formato YYYY-MM
  String _getCurrentMonth() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }
}
