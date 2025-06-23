// lib/features/home/presentation/widgets/recent_activity_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/loading_shimmer_widgets.dart';
import '../../../../shared/widgets/error_handling_widgets.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../workouts/bloc/workout_history_bloc.dart';
import '../../../stats/models/user_stats_models.dart';

/// Sezione attività recente con dati reali
class RecentActivitySection extends StatelessWidget {
  const RecentActivitySection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            'Attività Recente',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: 12.h),

        BlocBuilder<WorkoutHistoryBloc, WorkoutHistoryState>(
          builder: (context, state) {
            return BlocStateHandler<WorkoutHistoryState>(
              state: state,
              isLoading: (state) => state is WorkoutHistoryLoading,
              isSuccess: (state) => state is WorkoutHistoryLoaded,
              isError: (state) => state is WorkoutHistoryError,
              getErrorMessage: (state) => state is WorkoutHistoryError
                  ? NetworkErrorHandler.getReadableMessage(state.exception ?? Exception(state.message))
                  : 'Errore nel caricamento degli allenamenti',
              loadingBuilder: () => const ShimmerRecentActivity(),
              successBuilder: () {
                final loadedState = state as WorkoutHistoryLoaded;
                final recentWorkouts = loadedState.workoutHistory.take(3).toList();

                if (recentWorkouts.isEmpty) {
                  return _buildEmptyState(isDarkMode);
                }

                return Column(
                  children: recentWorkouts.map((workout) {
                    return _buildActivityItem(
                      context: context,
                      title: workout.schedaNome,
                      subtitle: _formatWorkoutTime(workout.dataAllenamento),
                      icon: Icons.fitness_center,
                      iconColor: Colors.green,
                      isDarkMode: isDarkMode,
                    );
                  }).toList(),
                );
              },
              errorBuilder: (errorMessage) => InlineErrorWidget(
                message: errorMessage,
                onRetry: () => _retryLoadWorkouts(context),
                icon: Icons.refresh,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDarkMode,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: isDarkMode ? Border.all(color: Colors.grey.shade800, width: 0.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: iconColor, size: 16.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            size: 20.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: isDarkMode
            ? Border.all(color: Colors.grey.shade800, width: 0.5)
            : null,
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 40.sp,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 8.h),
          Text(
            'Nessun allenamento registrato',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Inizia il tuo primo workout!',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      height: 120.h,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  String _formatWorkoutTime(String dataAllenamento) {
    try {
      final dateTime = DateTime.parse(dataAllenamento);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} giorn${difference.inDays == 1 ? 'o' : 'i'} fa';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} or${difference.inHours == 1 ? 'a' : 'e'} fa';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minut${difference.inMinutes == 1 ? 'o' : 'i'} fa';
      } else {
        return 'Adesso';
      }
    } catch (e) {
      return 'Data non valida';
    }
  }

  void _retryLoadWorkouts(BuildContext context) {
    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;

    if (authState is AuthAuthenticated) {
      final userId = authState.user.id;
      context.read<WorkoutHistoryBloc>().add(GetWorkoutHistory(userId: userId));
    } else if (authState is AuthLoginSuccess) {
      final userId = authState.user.id;
      context.read<WorkoutHistoryBloc>().add(GetWorkoutHistory(userId: userId));
    } else {
      print('[CONSOLE] [recent_activity] ⚠️ Cannot retry: user not authenticated (${authState.runtimeType})');
    }
  }
}