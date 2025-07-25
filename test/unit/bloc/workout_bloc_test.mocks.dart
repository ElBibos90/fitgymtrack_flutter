// Mocks generated by Mockito 5.4.6 from annotations
// in fitgymtrack/test/unit/bloc/workout_bloc_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;

import 'package:fitgymtrack/core/utils/result.dart' as _i2;
import 'package:fitgymtrack/features/exercises/models/exercises_response.dart'
    as _i7;
import 'package:fitgymtrack/features/stats/models/user_stats_models.dart'
    as _i9;
import 'package:fitgymtrack/features/workouts/models/active_workout_models.dart'
    as _i8;
import 'package:fitgymtrack/features/workouts/models/workout_plan_models.dart'
    as _i5;
import 'package:fitgymtrack/features/workouts/models/workout_response_types.dart'
    as _i6;
import 'package:fitgymtrack/features/workouts/repository/workout_repository.dart'
    as _i3;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeResult_0<T> extends _i1.SmartFake implements _i2.Result<T> {
  _FakeResult_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [WorkoutRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockWorkoutRepository extends _i1.Mock implements _i3.WorkoutRepository {
  MockWorkoutRepository() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<_i2.Result<List<_i5.WorkoutPlan>>> getWorkoutPlans(int? userId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getWorkoutPlans,
          [userId],
        ),
        returnValue: _i4.Future<_i2.Result<List<_i5.WorkoutPlan>>>.value(
            _FakeResult_0<List<_i5.WorkoutPlan>>(
          this,
          Invocation.method(
            #getWorkoutPlans,
            [userId],
          ),
        )),
      ) as _i4.Future<_i2.Result<List<_i5.WorkoutPlan>>>);

  @override
  _i4.Future<_i2.Result<List<_i5.WorkoutExercise>>> getWorkoutExercises(
          int? schedaId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getWorkoutExercises,
          [schedaId],
        ),
        returnValue: _i4.Future<_i2.Result<List<_i5.WorkoutExercise>>>.value(
            _FakeResult_0<List<_i5.WorkoutExercise>>(
          this,
          Invocation.method(
            #getWorkoutExercises,
            [schedaId],
          ),
        )),
      ) as _i4.Future<_i2.Result<List<_i5.WorkoutExercise>>>);

  @override
  _i4.Future<_i2.Result<_i6.DeleteWorkoutPlanResponse>> deleteWorkoutPlan(
          int? schedaId) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteWorkoutPlan,
          [schedaId],
        ),
        returnValue:
            _i4.Future<_i2.Result<_i6.DeleteWorkoutPlanResponse>>.value(
                _FakeResult_0<_i6.DeleteWorkoutPlanResponse>(
          this,
          Invocation.method(
            #deleteWorkoutPlan,
            [schedaId],
          ),
        )),
      ) as _i4.Future<_i2.Result<_i6.DeleteWorkoutPlanResponse>>);

  @override
  _i4.Future<_i2.Result<_i6.UpdateWorkoutPlanResponse>> updateWorkoutPlan(
          _i5.UpdateWorkoutPlanRequest? request) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateWorkoutPlan,
          [request],
        ),
        returnValue:
            _i4.Future<_i2.Result<_i6.UpdateWorkoutPlanResponse>>.value(
                _FakeResult_0<_i6.UpdateWorkoutPlanResponse>(
          this,
          Invocation.method(
            #updateWorkoutPlan,
            [request],
          ),
        )),
      ) as _i4.Future<_i2.Result<_i6.UpdateWorkoutPlanResponse>>);

  @override
  _i4.Future<_i2.Result<_i6.CreateWorkoutPlanResponse>> createWorkoutPlan(
          _i5.CreateWorkoutPlanRequest? request) =>
      (super.noSuchMethod(
        Invocation.method(
          #createWorkoutPlan,
          [request],
        ),
        returnValue:
            _i4.Future<_i2.Result<_i6.CreateWorkoutPlanResponse>>.value(
                _FakeResult_0<_i6.CreateWorkoutPlanResponse>(
          this,
          Invocation.method(
            #createWorkoutPlan,
            [request],
          ),
        )),
      ) as _i4.Future<_i2.Result<_i6.CreateWorkoutPlanResponse>>);

  @override
  _i4.Future<_i2.Result<List<_i7.ExerciseItem>>> getAvailableExercises(
          int? userId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getAvailableExercises,
          [userId],
        ),
        returnValue: _i4.Future<_i2.Result<List<_i7.ExerciseItem>>>.value(
            _FakeResult_0<List<_i7.ExerciseItem>>(
          this,
          Invocation.method(
            #getAvailableExercises,
            [userId],
          ),
        )),
      ) as _i4.Future<_i2.Result<List<_i7.ExerciseItem>>>);

  @override
  _i4.Future<_i2.Result<_i8.StartWorkoutResponse>> startWorkout(
    int? userId,
    int? schedaId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #startWorkout,
          [
            userId,
            schedaId,
          ],
        ),
        returnValue: _i4.Future<_i2.Result<_i8.StartWorkoutResponse>>.value(
            _FakeResult_0<_i8.StartWorkoutResponse>(
          this,
          Invocation.method(
            #startWorkout,
            [
              userId,
              schedaId,
            ],
          ),
        )),
      ) as _i4.Future<_i2.Result<_i8.StartWorkoutResponse>>);

  @override
  _i4.Future<_i2.Result<List<_i8.CompletedSeriesData>>> getCompletedSeries(
          int? allenamentoId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getCompletedSeries,
          [allenamentoId],
        ),
        returnValue:
            _i4.Future<_i2.Result<List<_i8.CompletedSeriesData>>>.value(
                _FakeResult_0<List<_i8.CompletedSeriesData>>(
          this,
          Invocation.method(
            #getCompletedSeries,
            [allenamentoId],
          ),
        )),
      ) as _i4.Future<_i2.Result<List<_i8.CompletedSeriesData>>>);

  @override
  _i4.Future<_i2.Result<_i8.SaveCompletedSeriesResponse>> saveCompletedSeries(
    int? allenamentoId,
    List<_i8.SeriesData>? serie,
    String? requestId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #saveCompletedSeries,
          [
            allenamentoId,
            serie,
            requestId,
          ],
        ),
        returnValue:
            _i4.Future<_i2.Result<_i8.SaveCompletedSeriesResponse>>.value(
                _FakeResult_0<_i8.SaveCompletedSeriesResponse>(
          this,
          Invocation.method(
            #saveCompletedSeries,
            [
              allenamentoId,
              serie,
              requestId,
            ],
          ),
        )),
      ) as _i4.Future<_i2.Result<_i8.SaveCompletedSeriesResponse>>);

  @override
  _i4.Future<_i2.Result<_i8.CompleteWorkoutResponse>> completeWorkout(
    int? allenamentoId,
    int? durataTotale, {
    String? note,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #completeWorkout,
          [
            allenamentoId,
            durataTotale,
          ],
          {#note: note},
        ),
        returnValue: _i4.Future<_i2.Result<_i8.CompleteWorkoutResponse>>.value(
            _FakeResult_0<_i8.CompleteWorkoutResponse>(
          this,
          Invocation.method(
            #completeWorkout,
            [
              allenamentoId,
              durataTotale,
            ],
            {#note: note},
          ),
        )),
      ) as _i4.Future<_i2.Result<_i8.CompleteWorkoutResponse>>);

  @override
  _i4.Future<_i2.Result<List<_i9.WorkoutHistory>>> getWorkoutHistory(
          int? userId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getWorkoutHistory,
          [userId],
        ),
        returnValue: _i4.Future<_i2.Result<List<_i9.WorkoutHistory>>>.value(
            _FakeResult_0<List<_i9.WorkoutHistory>>(
          this,
          Invocation.method(
            #getWorkoutHistory,
            [userId],
          ),
        )),
      ) as _i4.Future<_i2.Result<List<_i9.WorkoutHistory>>>);

  @override
  _i4.Future<_i2.Result<List<_i8.CompletedSeriesData>>> getWorkoutSeriesDetail(
          int? allenamentoId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getWorkoutSeriesDetail,
          [allenamentoId],
        ),
        returnValue:
            _i4.Future<_i2.Result<List<_i8.CompletedSeriesData>>>.value(
                _FakeResult_0<List<_i8.CompletedSeriesData>>(
          this,
          Invocation.method(
            #getWorkoutSeriesDetail,
            [allenamentoId],
          ),
        )),
      ) as _i4.Future<_i2.Result<List<_i8.CompletedSeriesData>>>);

  @override
  _i4.Future<_i2.Result<bool>> deleteCompletedSeries(String? seriesId) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteCompletedSeries,
          [seriesId],
        ),
        returnValue: _i4.Future<_i2.Result<bool>>.value(_FakeResult_0<bool>(
          this,
          Invocation.method(
            #deleteCompletedSeries,
            [seriesId],
          ),
        )),
      ) as _i4.Future<_i2.Result<bool>>);

  @override
  _i4.Future<_i2.Result<bool>> updateCompletedSeries(
    String? seriesId,
    double? weight,
    int? reps, {
    int? recoveryTime,
    String? notes,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #updateCompletedSeries,
          [
            seriesId,
            weight,
            reps,
          ],
          {
            #recoveryTime: recoveryTime,
            #notes: notes,
          },
        ),
        returnValue: _i4.Future<_i2.Result<bool>>.value(_FakeResult_0<bool>(
          this,
          Invocation.method(
            #updateCompletedSeries,
            [
              seriesId,
              weight,
              reps,
            ],
            {
              #recoveryTime: recoveryTime,
              #notes: notes,
            },
          ),
        )),
      ) as _i4.Future<_i2.Result<bool>>);

  @override
  _i4.Future<_i2.Result<bool>> deleteWorkout(int? workoutId) =>
      (super.noSuchMethod(
        Invocation.method(
          #deleteWorkout,
          [workoutId],
        ),
        returnValue: _i4.Future<_i2.Result<bool>>.value(_FakeResult_0<bool>(
          this,
          Invocation.method(
            #deleteWorkout,
            [workoutId],
          ),
        )),
      ) as _i4.Future<_i2.Result<bool>>);

  @override
  _i4.Future<_i2.Result<_i9.UserStats>> getUserStats(int? userId) =>
      (super.noSuchMethod(
        Invocation.method(
          #getUserStats,
          [userId],
        ),
        returnValue: _i4.Future<_i2.Result<_i9.UserStats>>.value(
            _FakeResult_0<_i9.UserStats>(
          this,
          Invocation.method(
            #getUserStats,
            [userId],
          ),
        )),
      ) as _i4.Future<_i2.Result<_i9.UserStats>>);

  @override
  _i4.Future<_i2.Result<_i9.PeriodStats>> getPeriodStats(String? period) =>
      (super.noSuchMethod(
        Invocation.method(
          #getPeriodStats,
          [period],
        ),
        returnValue: _i4.Future<_i2.Result<_i9.PeriodStats>>.value(
            _FakeResult_0<_i9.PeriodStats>(
          this,
          Invocation.method(
            #getPeriodStats,
            [period],
          ),
        )),
      ) as _i4.Future<_i2.Result<_i9.PeriodStats>>);
}
