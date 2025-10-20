// lib/features/templates/presentation/widgets/template_rating_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../models/template_models.dart';

class TemplateRatingWidget extends StatefulWidget {
  final WorkoutTemplate template;
  final Function(int rating, String? review) onRatingSubmitted;
  final VoidCallback? onRatingSuccess; // 🔧 FIX: Callback per successo

  const TemplateRatingWidget({
    super.key,
    required this.template,
    required this.onRatingSubmitted,
    this.onRatingSuccess, // 🔧 FIX: Callback opzionale
  });

  @override
  State<TemplateRatingWidget> createState() => TemplateRatingWidgetState();
}

class TemplateRatingWidgetState extends State<TemplateRatingWidget> {
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  /// 🔧 FIX: Metodo pubblico per resettare lo stato di loading
  void resetLoadingState() {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Se l'utente ha già valutato, mostra la sua valutazione
    if (widget.template.userRating != null) {
      _selectedRating = widget.template.userRating!.rating;
      _reviewController.text = widget.template.userRating!.review ?? '';
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.cardBackgroundDark : AppColors.cardBackgroundLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating attuale
          _buildCurrentRating(),
          
          SizedBox(height: 16.h),
          
          // Form per nuovo rating
          _buildRatingForm(),
          
          SizedBox(height: 16.h),
          
          // Recensioni recenti
          _buildRecentReviews(),
        ],
      ),
    );
  }

  Widget _buildCurrentRating() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      children: [
        Icon(
          Icons.star,
          size: 20.sp,
          color: AppColors.warning,
        ),
        SizedBox(width: 8.w),
        Text(
          widget.template.ratingFormatted,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(width: 16.w),
        Text(
          '${widget.template.usageCount} utilizzi',
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.template.userRating != null ? 'La tua valutazione' : 'Valuta questo template',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        
        // Stelle per rating
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedRating = index + 1;
                });
              },
              child: Icon(
                index < _selectedRating ? Icons.star : Icons.star_border,
                size: 32.sp,
                color: AppColors.warning,
              ),
            );
          }),
        ),
        
        SizedBox(height: 16.h),
        
        // Campo recensione
        TextField(
          controller: _reviewController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Scrivi una recensione (opzionale)...',
            hintStyle: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.white60 : AppColors.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          ),
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode ? Colors.white : AppColors.textPrimary,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        // Pulsante submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedRating > 0 && !_isSubmitting ? _submitRating : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.template.userRating != null ? 'Aggiorna Valutazione' : 'Invia Valutazione',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentReviews() {
    if (widget.template.recentReviews == null || widget.template.recentReviews!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recensioni recenti',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 12.h),
        ...widget.template.recentReviews!.map((review) => _buildReviewItem(review)),
      ],
    );
  }

  Widget _buildReviewItem(TemplateReview review) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColors.borderColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Stelle rating
              ...List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  size: 16.sp,
                  color: AppColors.warning,
                );
              }),
              SizedBox(width: 8.w),
              Text(
                review.userName,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(review.createdAt),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (review.review != null && review.review!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              review.review!,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}g fa';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h fa';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m fa';
      } else {
        return 'Ora';
      }
    } catch (e) {
      return dateString;
    }
  }

  void _submitRating() {
    if (_selectedRating == 0) return;

    setState(() {
      _isSubmitting = true;
    });

    // 🔧 FIX: Invia la valutazione
    widget.onRatingSubmitted(_selectedRating, _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim());

    // 🔧 FIX: Chiama il callback per notificare il successo
    if (widget.onRatingSuccess != null) {
      // Aspetta un po' per permettere al BLoC di processare
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onRatingSuccess!();
      });
    }
  }
}
