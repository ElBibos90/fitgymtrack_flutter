import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../bloc/workout_bloc.dart';
import '../../models/workout_plan_models.dart';
import '../../../exercises/services/image_service.dart';

class WorkoutDetailsScreen extends StatelessWidget {
  final int workoutId;
  const WorkoutDetailsScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<WorkoutBloc>()..loadWorkoutPlanDetails(workoutId),
      child: BlocListener<WorkoutBloc, WorkoutState>(
        listener: (context, state) {
          if (state is WorkoutPlanDeleted) {
            CustomSnackbar.show(
              context,
              message: 'Scheda eliminata con successo',
              isSuccess: true,
            );
          } else if (state is WorkoutError) {
            CustomSnackbar.show(
              context,
              message: state.message,
              isSuccess: false,
            );
          }
        },
        child: BlocBuilder<WorkoutBloc, WorkoutState>(
        builder: (context, state) {
          if (state is WorkoutLoading || state is WorkoutLoadingWithMessage) {
            return const LoadingOverlay(isLoading: true, child: SizedBox());
          }
          if (state is WorkoutError) {
            return Scaffold(
              appBar: AppBar(title: const Text('Dettagli Scheda')),
              body: Center(child: Text(state.message)),
            );
          }
          if (state is WorkoutPlanDetailsLoaded) {
            final plan = state.workoutPlan;
            return Scaffold(
              appBar: AppBar(
                title: Text(plan.nome),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => context.push('/workouts/edit/${plan.id}'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Elimina Scheda'),
                          content: Text('Sei sicuro di voler eliminare la scheda "${plan.nome}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Annulla'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                              child: const Text('Elimina'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        context.read<WorkoutBloc>().deleteWorkout(plan.id);
                        context.go('/workouts');
                      }
                    },
                  ),
                ],
              ),
              body: Padding(
                padding: EdgeInsets.all(AppConfig.spacingM.w),
                child: ListView(
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plan.nome, style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
                            if (plan.dataCreazione != null) ...[
                              SizedBox(height: 4.h),
                              Text('Creata il ${_formatDate(plan.dataCreazione!)}', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                            ],
                            if (plan.descrizione != null && plan.descrizione!.isNotEmpty) ...[
                              SizedBox(height: 8.h),
                              Text(plan.descrizione!, style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary)),
                            ],
                            SizedBox(height: 12.h),
                            Wrap(
                              spacing: 8.w,
                              children: [
                                _buildStatChip(Icons.fitness_center, '${plan.esercizi.length} Esercizi'),
                                _buildStatChip(Icons.timer, '${_calculateEstimatedDuration(plan)} min'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text('Esercizi', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8.h),
                    ...plan.esercizi.map((ex) => _buildExerciseTile(ex)).toList(),
                    SizedBox(height: 32.h),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/workouts/${plan.id}/start'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Inizia Allenamento'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.indigo600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox();
        },
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.indigo600.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConfig.radiusS),
        border: Border.all(color: AppColors.indigo600.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: AppColors.indigo600),
          SizedBox(width: 4.w),
          Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppColors.indigo600)),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(WorkoutExercise ex) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Immagine esercizio
                if (ex.immagineNome != null) ...[
                  Container(
                    width: 80.w,
                    height: 80.w,
                    margin: EdgeInsets.only(right: 12.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.indigo600.withValues(alpha: 0.3),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.r),
                      child: ImageService.buildGifImage(
                        imageUrl: ImageService.getImageUrl(ex.immagineNome),
                        width: 80.w,
                        height: 80.w,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex.nome, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      if (ex.gruppoMuscolare != null) ...[
                        SizedBox(height: 2.h),
                        Text('Muscolo: ${ex.gruppoMuscolare}', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                      ],
                      if (ex.attrezzatura != null) ...[
                        SizedBox(height: 2.h),
                        Text('Attrezzatura: ${ex.attrezzatura}', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Wrap(
              spacing: 8.w,
              children: [
                _buildExerciseStat('Serie', ex.serie.toString()),
                _buildExerciseStat('Ripetizioni', ex.ripetizioni.toString()),
                _buildExerciseStat('Peso', '${ex.peso} kg'),
                if (ex.tempoRecupero > 0)
                  _buildExerciseStat('Recupero', '${ex.tempoRecupero}s'),
              ],
            ),
            if (ex.note != null && ex.note!.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text('Note: ${ex.note}', style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseStat(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.indigo600.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text('$label: $value', style: TextStyle(fontSize: 11.sp, color: AppColors.indigo600)),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  int _calculateEstimatedDuration(WorkoutPlan plan) {
    if (plan.esercizi.isEmpty) return 0;
    int totalSets = 0;
    for (final exercise in plan.esercizi) {
      totalSets += exercise.serie;
    }
    final setupTime = plan.esercizi.length * 2;
    final executionTime = totalSets * 1;
    final recoveryTime = totalSets * 1;
    return setupTime + executionTime + recoveryTime;
  }
} 