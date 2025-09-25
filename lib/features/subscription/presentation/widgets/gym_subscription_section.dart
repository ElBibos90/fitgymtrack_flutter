// lib/features/subscription/presentation/widgets/gym_subscription_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/gym_subscription.dart';
import '../../bloc/gym_subscription_bloc.dart';

/// Widget per mostrare l'abbonamento palestra
class GymSubscriptionSection extends StatelessWidget {
  final int userId;

  const GymSubscriptionSection({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    // Carica l'abbonamento quando il widget viene costruito
    context.read<GymSubscriptionBloc>().add(LoadGymSubscriptionEvent(userId: userId));
    
    return BlocBuilder<GymSubscriptionBloc, GymSubscriptionState>(
      builder: (context, state) {
        if (state is GymSubscriptionLoading) {
          return _buildLoadingState();
        }

        if (state is GymSubscriptionNotFound) {
          return _buildNoSubscriptionState();
        }

        if (state is GymSubscriptionLoaded) {
          return _buildSubscriptionCard(context, state.subscription);
        }

        if (state is GymSubscriptionError) {
          return _buildErrorState(state.message);
        }

        return _buildLoadingState();
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20.w,
            height: 20.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Caricamento abbonamento palestra...',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionState() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange[600],
            size: 20.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Nessun abbonamento attivo. Contatta la tua palestra.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 20.w,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Errore nel caricamento abbonamento: $message',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.red[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, GymSubscription subscription) {
    final sub = subscription;
    final isExpired = sub.isExpired;
    final isActive = sub.isValid;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive 
              ? [Colors.green[400]!, Colors.green[600]!]
              : [Colors.red[400]!, Colors.red[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: (isActive ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icona e stato
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: Colors.white,
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.gymName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      sub.formattedPlanName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  isActive ? 'ATTIVO' : 'SCADUTO',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Dettagli abbonamento
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.calendar_today,
                  label: 'Scadenza',
                  value: sub.formattedDaysRemaining,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  icon: Icons.euro,
                  label: 'Prezzo',
                  value: sub.formattedPrice,
                ),
              ),
            ],
          ),
          
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: 14.w,
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
