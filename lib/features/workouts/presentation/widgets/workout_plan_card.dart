// lib/features/workouts/presentation/widgets/workout_plan_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_card.dart';
import '../../../../core/config/app_config.dart';
import '../../models/workout_plan_models.dart';

class WorkoutPlanCard extends StatelessWidget {
  final WorkoutPlan workoutPlan;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onStartWorkout;
  final BuildContext parentContext;
  final bool canManageSchede;

  const WorkoutPlanCard({
    super.key,
    required this.workoutPlan,
    required this.parentContext,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onStartWorkout,
    this.canManageSchede = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomCard(
      onTap: onTap,
      elevation: AppConfig.elevationS,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con nome e data
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutPlan.nome,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface, // ✅ DINAMICO!
                      ),
                    ),
                    if (workoutPlan.dataCreazione != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        'Creata il ${_formatDate(workoutPlan.dataCreazione!)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.6), // ✅ DINAMICO!
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Menu actions (solo se l'utente può gestire le schede)
              if (canManageSchede)
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(context, value),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: AppColors.error),
                          const SizedBox(width: 8),
                          const Text('Elimina',
                              style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: colorScheme.onSurface
                        .withValues(alpha: 0.6), // ✅ DINAMICO!
                    size: 24.sp,
                  ),
                ),
            ],
          ),

          // Descrizione (se presente)
          if (workoutPlan.descrizione != null &&
              workoutPlan.descrizione!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              workoutPlan.descrizione!,
              style: TextStyle(
                fontSize: 14.sp,
                color:
                    colorScheme.onSurface.withValues(alpha: 0.7), // ✅ DINAMICO!
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          SizedBox(height: 12.h),

          // Statistiche esercizi
          Wrap(
            spacing: 8.w,
            children: [
              _buildStatChip(
                context,
                icon: Icons.fitness_center,
                label: '${workoutPlan.esercizi.length} Esercizi',
                color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
              ),
              _buildStatChip(
                context,
                icon: Icons.timer,
                label: '${_calculateEstimatedDuration()} min',
                color: AppColors.green600,
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onStartWorkout,
                  icon: const Icon(Icons.play_arrow, size: 20),
                  label: const Text('Inizia Allenamento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    foregroundColor:
                        isDark ? AppColors.backgroundDark : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConfig.radiusM),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                ),
              ),
              if (canManageSchede) ...[
                SizedBox(width: 12.w),
                OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                    side: BorderSide(
                        color: isDark
                            ? const Color(0xFF90CAF9)
                            : AppColors.indigo600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConfig.radiusM),
                    ),
                    padding:
                        EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                  ),
                  child: const Icon(Icons.edit, size: 20),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConfig.radiusS),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Gestione azioni del menu con conferma eliminazione
  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'details':
        onTap?.call();
        break;
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  int _calculateEstimatedDuration() {
    // Calcolo approssimativo:
    // - 2 minuti per esercizio setup
    // - 1 minuto per serie (assumendo 3 serie per esercizio)
    // - 1 minuto di recupero per serie
    if (workoutPlan.esercizi.isEmpty) return 0;

    int totalSets = 0;
    for (final exercise in workoutPlan.esercizi) {
      totalSets += exercise.serie;
    }

    // Setup time (2 min per esercizio) + execution time (1 min per serie) + recovery time (1 min per serie)
    final setupTime = workoutPlan.esercizi.length * 2;
    final executionTime = totalSets * 1;
    final recoveryTime = totalSets * 1;

    return setupTime + executionTime + recoveryTime;
  }
}
