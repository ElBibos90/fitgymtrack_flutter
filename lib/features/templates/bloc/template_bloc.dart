// lib/features/templates/bloc/template_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/template_models.dart';
import '../services/template_service.dart';

// ============================================================================
// EVENTS
// ============================================================================

abstract class TemplateEvent extends Equatable {
  const TemplateEvent();

  @override
  List<Object?> get props => [];
}

/// Evento per caricare i template
class LoadTemplates extends TemplateEvent {
  final int? categoryId;
  final String? difficulty;
  final String? goal;
  final bool? featured;
  final String? search;
  final int limit;
  final int offset;
  final bool refresh;

  const LoadTemplates({
    this.categoryId,
    this.difficulty,
    this.goal,
    this.featured,
    this.search,
    this.limit = 20,
    this.offset = 0,
    this.refresh = false,
  });

  @override
  List<Object?> get props => [
        categoryId,
        difficulty,
        goal,
        featured,
        search,
        limit,
        offset,
        refresh,
      ];
}

/// Evento per caricare i dettagli di un template
class LoadTemplateDetails extends TemplateEvent {
  final int templateId;

  const LoadTemplateDetails(this.templateId);

  @override
  List<Object> get props => [templateId];
}

/// Evento per caricare le categorie
class LoadCategories extends TemplateEvent {
  final bool includeAll;

  const LoadCategories({this.includeAll = false});

  @override
  List<Object> get props => [includeAll];
}

/// Evento per creare una scheda da template
class CreateWorkoutFromTemplate extends TemplateEvent {
  final CreateWorkoutFromTemplateRequest request;

  const CreateWorkoutFromTemplate(this.request);

  @override
  List<Object> get props => [request];
}

/// Evento per valutare un template
class RateTemplate extends TemplateEvent {
  final TemplateRatingRequest request;

  const RateTemplate(this.request);

  @override
  List<Object> get props => [request];
}

/// Evento per rimuovere un rating
class RemoveTemplateRating extends TemplateEvent {
  final int templateId;

  const RemoveTemplateRating(this.templateId);

  @override
  List<Object> get props => [templateId];
}

/// Evento per caricare template popolari
class LoadPopularTemplates extends TemplateEvent {
  final int limit;

  const LoadPopularTemplates({this.limit = 10});

  @override
  List<Object> get props => [limit];
}

/// Evento per caricare template per principianti
class LoadBeginnerTemplates extends TemplateEvent {
  final int limit;

  const LoadBeginnerTemplates({this.limit = 10});

  @override
  List<Object> get props => [limit];
}

/// Evento per cercare template
class SearchTemplates extends TemplateEvent {
  final String query;
  final int limit;
  final int offset;

  const SearchTemplates({
    required this.query,
    this.limit = 20,
    this.offset = 0,
  });

  @override
  List<Object> get props => [query, limit, offset];
}

/// Evento per resettare lo stato
class ResetTemplateState extends TemplateEvent {}

// ============================================================================
// STATES
// ============================================================================

abstract class TemplateState extends Equatable {
  const TemplateState();

  @override
  List<Object?> get props => [];
}

/// Stato iniziale
class TemplateInitial extends TemplateState {}

/// Stato di caricamento
class TemplateLoading extends TemplateState {}

/// Stato di caricamento per dettagli
class TemplateDetailsLoading extends TemplateState {}

/// Stato di caricamento per creazione scheda
class CreatingWorkoutFromTemplate extends TemplateState {}

/// Stato di caricamento per rating
class RatingTemplate extends TemplateState {}

/// Stato di successo per lista template
class TemplatesLoaded extends TemplateState {
  final List<WorkoutTemplate> templates;
  final TemplatesPagination pagination;
  final bool userPremium;
  final bool hasMore;

  const TemplatesLoaded({
    required this.templates,
    required this.pagination,
    required this.userPremium,
    required this.hasMore,
  });

  @override
  List<Object> get props => [templates, pagination, userPremium, hasMore];
}

/// Stato di successo per dettagli template
class TemplateDetailsLoaded extends TemplateState {
  final WorkoutTemplate template;
  final bool userPremium;

  const TemplateDetailsLoaded({
    required this.template,
    required this.userPremium,
  });

  @override
  List<Object> get props => [template, userPremium];
}

/// Stato di successo per categorie
class CategoriesLoaded extends TemplateState {
  final List<TemplateCategory> categories;

  const CategoriesLoaded(this.categories);

  @override
  List<Object> get props => [categories];
}

/// Stato di successo per creazione scheda
class WorkoutCreatedFromTemplate extends TemplateState {
  final CreateWorkoutFromTemplateResponse response;

  const WorkoutCreatedFromTemplate(this.response);

  @override
  List<Object> get props => [response];
}

/// Stato di successo per rating
class TemplateRated extends TemplateState {
  final TemplateRatingResponse response;

  const TemplateRated(this.response);

  @override
  List<Object> get props => [response];
}

/// Stato di successo per rimozione rating
class TemplateRatingRemoved extends TemplateState {
  final int templateId;

  const TemplateRatingRemoved(this.templateId);

  @override
  List<Object> get props => [templateId];
}

/// Stato di errore
class TemplateError extends TemplateState {
  final String message;

  const TemplateError(this.message);

  @override
  List<Object> get props => [message];
}

// ============================================================================
// BLOC
// ============================================================================

class TemplateBloc extends Bloc<TemplateEvent, TemplateState> {
  final TemplateService _templateService;

  TemplateBloc({required TemplateService templateService})
      : _templateService = templateService,
        super(TemplateInitial()) {
    on<LoadTemplates>(_onLoadTemplates);
    on<LoadTemplateDetails>(_onLoadTemplateDetails);
    on<LoadCategories>(_onLoadCategories);
    on<CreateWorkoutFromTemplate>(_onCreateWorkoutFromTemplate);
    on<RateTemplate>(_onRateTemplate);
    on<RemoveTemplateRating>(_onRemoveTemplateRating);
    on<LoadPopularTemplates>(_onLoadPopularTemplates);
    on<LoadBeginnerTemplates>(_onLoadBeginnerTemplates);
    on<SearchTemplates>(_onSearchTemplates);
    on<ResetTemplateState>(_onResetTemplateState);
  }

  Future<void> _onLoadTemplates(
    LoadTemplates event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      print('🔍 TemplateBloc._onLoadTemplates: Starting with event: $event');
      print('🔍 TemplateBloc._onLoadTemplates: Current state: ${state.runtimeType}');
      
      if (event.refresh || state is TemplateInitial) {
        print('🔍 TemplateBloc._onLoadTemplates: Emitting TemplateLoading');
        emit(TemplateLoading());
      }

      print('🔍 TemplateBloc._onLoadTemplates: Calling _templateService.getTemplates');
      final response = await _templateService.getTemplates(
        categoryId: event.categoryId,
        difficulty: event.difficulty,
        goal: event.goal,
        featured: event.featured,
        search: event.search,
        limit: event.limit,
        offset: event.offset,
      );
      
      print('🔍 TemplateBloc._onLoadTemplates: Service returned ${response.templates.length} templates');

      if (event.refresh || state is TemplateInitial) {
        print('🔍 TemplateBloc._onLoadTemplates: Emitting TemplatesLoaded (refresh/initial)');
        emit(TemplatesLoaded(
          templates: response.templates,
          pagination: response.pagination,
          userPremium: response.userPremium,
          hasMore: response.pagination.hasMore,
        ));
      } else if (state is TemplatesLoaded) {
        print('🔍 TemplateBloc._onLoadTemplates: Appending to existing TemplatesLoaded state');
        final currentState = state as TemplatesLoaded;
        final allTemplates = [...currentState.templates, ...response.templates];
        
        emit(TemplatesLoaded(
          templates: allTemplates,
          pagination: response.pagination,
          userPremium: response.userPremium,
          hasMore: response.pagination.hasMore,
        ));
      }
    } catch (e) {
      print('❌ TemplateBloc._onLoadTemplates ERROR: $e');
      print('❌ TemplateBloc._onLoadTemplates ERROR stack: ${e.toString()}');
      emit(TemplateError('Errore nel caricamento dei template: $e'));
    }
  }

  Future<void> _onLoadTemplateDetails(
    LoadTemplateDetails event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      print('🔍 TemplateBloc._onLoadTemplateDetails: Starting for templateId=${event.templateId}');
      print('🔍 TemplateBloc._onLoadTemplateDetails: Current state: ${state.runtimeType}');
      
      emit(TemplateDetailsLoading());
      print('🔍 TemplateBloc._onLoadTemplateDetails: Emitted TemplateDetailsLoading');

      print('🔍 TemplateBloc._onLoadTemplateDetails: Calling _templateService.getTemplateDetails');
      final response = await _templateService.getTemplateDetails(event.templateId);
      print('🔍 TemplateBloc._onLoadTemplateDetails: Service returned template ${response.template.name}');

      emit(TemplateDetailsLoaded(
        template: response.template,
        userPremium: response.userPremium,
      ));
      print('🔍 TemplateBloc._onLoadTemplateDetails: Emitted TemplateDetailsLoaded');
    } catch (e) {
      print('❌ TemplateBloc._onLoadTemplateDetails ERROR: $e');
      print('❌ TemplateBloc._onLoadTemplateDetails ERROR stack: ${e.toString()}');
      emit(TemplateError('Errore nel caricamento dei dettagli: $e'));
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      final categories = await _templateService.getCategories();

      emit(CategoriesLoaded(categories));
    } catch (e) {
      emit(TemplateError('Errore nel caricamento delle categorie: $e'));
    }
  }

  Future<void> _onCreateWorkoutFromTemplate(
    CreateWorkoutFromTemplate event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      print('🔍 TemplateBloc._onCreateWorkoutFromTemplate: Starting with event: $event');
      print('🔍 TemplateBloc._onCreateWorkoutFromTemplate: Current state: ${state.runtimeType}');
      
      emit(CreatingWorkoutFromTemplate());
      print('🔍 TemplateBloc._onCreateWorkoutFromTemplate: Emitted CreatingWorkoutFromTemplate');

      final response = await _templateService.createWorkoutFromTemplate(event.request);
      print('🔍 TemplateBloc._onCreateWorkoutFromTemplate: Service call completed successfully');

      emit(WorkoutCreatedFromTemplate(response));
      print('🔍 TemplateBloc._onCreateWorkoutFromTemplate: Emitted WorkoutCreatedFromTemplate');
    } catch (e) {
      print('❌ TemplateBloc._onCreateWorkoutFromTemplate ERROR: $e');
      print('❌ TemplateBloc._onCreateWorkoutFromTemplate ERROR stack: ${e.toString()}');
      emit(TemplateError('Errore nella creazione della scheda: $e'));
    }
  }

  Future<void> _onRateTemplate(
    RateTemplate event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      emit(RatingTemplate());

      await _templateService.rateTemplate(
        templateId: event.request.templateId,
        rating: event.request.rating.toDouble(),
        review: event.request.review,
      );

      emit(TemplateRated(TemplateRatingResponse(
        success: true,
        message: 'Valutazione inviata con successo',
        rating: event.request.rating,
        review: event.request.review,
      )));
    } catch (e) {
      emit(TemplateError('Errore nella valutazione: $e'));
    }
  }

  Future<void> _onRemoveTemplateRating(
    RemoveTemplateRating event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      await _templateService.removeTemplateRating(event.templateId);

      emit(TemplateRatingRemoved(event.templateId));
    } catch (e) {
      emit(TemplateError('Errore nella rimozione del rating: $e'));
    }
  }

  Future<void> _onLoadPopularTemplates(
    LoadPopularTemplates event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      emit(TemplateLoading());

      final response = await _templateService.getPopularTemplates(limit: event.limit);

      emit(TemplatesLoaded(
        templates: response.templates,
        pagination: response.pagination,
        userPremium: response.userPremium,
        hasMore: response.pagination.hasMore,
      ));
    } catch (e) {
      emit(TemplateError('Errore nel caricamento dei template popolari: $e'));
    }
  }

  Future<void> _onLoadBeginnerTemplates(
    LoadBeginnerTemplates event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      emit(TemplateLoading());

      final response = await _templateService.getBeginnerTemplates(limit: event.limit);

      emit(TemplatesLoaded(
        templates: response.templates,
        pagination: response.pagination,
        userPremium: response.userPremium,
        hasMore: response.pagination.hasMore,
      ));
    } catch (e) {
      emit(TemplateError('Errore nel caricamento dei template per principianti: $e'));
    }
  }

  Future<void> _onSearchTemplates(
    SearchTemplates event,
    Emitter<TemplateState> emit,
  ) async {
    try {
      emit(TemplateLoading());

      final response = await _templateService.searchTemplates(
        query: event.query,
        limit: event.limit,
        offset: event.offset,
      );

      emit(TemplatesLoaded(
        templates: response.templates,
        pagination: response.pagination,
        userPremium: response.userPremium,
        hasMore: response.pagination.hasMore,
      ));
    } catch (e) {
      emit(TemplateError('Errore nella ricerca: $e'));
    }
  }

  void _onResetTemplateState(
    ResetTemplateState event,
    Emitter<TemplateState> emit,
  ) {
    emit(TemplateInitial());
  }
}
