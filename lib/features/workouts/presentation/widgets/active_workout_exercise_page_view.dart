import 'package:flutter/material.dart';

import '../../models/exercise_group_models.dart';
import '../../models/active_workout_models.dart' as models;

class ActiveWorkoutExercisePageView extends StatelessWidget {
  final PageController controller;
  final List<ExerciseGroup> groups;
  final Map<int, List<models.CompletedSeriesData>> completedSeries;
  final ValueChanged<int> onPageChanged;
  final Widget Function(ExerciseGroup group, Map<int, List<models.CompletedSeriesData>> completedSeries) itemBuilder;

  const ActiveWorkoutExercisePageView({
    super.key,
    required this.controller,
    required this.groups,
    required this.completedSeries,
    required this.onPageChanged,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      onPageChanged: onPageChanged,
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return itemBuilder(group, completedSeries);
      },
    );
  }
}
