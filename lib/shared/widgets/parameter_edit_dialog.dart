// lib/shared/widgets/parameter_edit_dialog.dart
// ✏️ Dialog per Editare Peso e Ripetizioni durante l'allenamento

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

/// ✏️ Parameter Edit Dialog - Modifica peso e ripetizioni
/// ✅ Touch-friendly con pulsanti + e -
/// ✅ Input diretto per valori precisi
/// ✅ Design coerente con l'app
class ParameterEditDialog extends StatefulWidget {
  final double initialWeight;
  final int initialReps;
  final String exerciseName;
  final bool isIsometric; // Per mostrare "Secondi" invece di "Ripetizioni"
  final Function(double weight, int reps) onSave;

  const ParameterEditDialog({
    super.key,
    required this.initialWeight,
    required this.initialReps,
    required this.exerciseName,
    this.isIsometric = false,
    required this.onSave,
  });

  @override
  State<ParameterEditDialog> createState() => _ParameterEditDialogState();
}

class _ParameterEditDialogState extends State<ParameterEditDialog>
    with TickerProviderStateMixin {

  late double _currentWeight;
  late int _currentReps;

  late TextEditingController _weightController;
  late TextEditingController _repsController;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _currentWeight = widget.initialWeight;
    _currentReps = widget.initialReps;

    _weightController = TextEditingController(text: _currentWeight.toStringAsFixed(1));
    _repsController = TextEditingController(text: _currentReps.toString());

    _initializeAnimations();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  void _updateWeight(double delta) {
    setState(() {
      _currentWeight = (_currentWeight + delta).clamp(0.0, 999.9);
      _weightController.text = _currentWeight.toStringAsFixed(1);
    });

    HapticFeedback.lightImpact();
  }

  void _updateReps(int delta) {
    setState(() {
      _currentReps = (_currentReps + delta).clamp(1, 999);
      _repsController.text = _currentReps.toString();
    });

    HapticFeedback.lightImpact();
  }

  void _onWeightChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed != null && parsed >= 0 && parsed <= 999.9) {
      setState(() {
        _currentWeight = parsed;
      });
    }
  }

  void _onRepsChanged(String value) {
    final parsed = int.tryParse(value);
    if (parsed != null && parsed >= 1 && parsed <= 999) {
      setState(() {
        _currentReps = parsed;
      });
    }
  }

  void _save() {
    widget.onSave(_currentWeight, _currentReps);
    Navigator.of(context).pop();
  }

  void _cancel() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: colorScheme.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modifica Parametri',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          widget.exerciseName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: colorScheme.onSurface.withValues(alpha:0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // 🔧 FIX: Layout verticale per evitare overflow
              Column(
                children: [
                  // Weight Control
                  _buildCompactParameterControl(
                    label: 'Peso',
                    value: _currentWeight.toStringAsFixed(1),
                    controller: _weightController,
                    onChanged: _onWeightChanged,
                    onIncrement: () => _updateWeight(0.5),
                    onDecrement: () => _updateWeight(-0.5),
                    icon: Icons.fitness_center,
                    color: colorScheme.primary,
                    unit: 'kg',
                  ),

                  SizedBox(height: 16.h),

                  // Reps/Seconds Control
                  _buildCompactParameterControl(
                    label: widget.isIsometric ? 'Secondi' : 'Ripetizioni',
                    value: _currentReps.toString(),
                    controller: _repsController,
                    onChanged: _onRepsChanged,
                    onIncrement: () => _updateReps(1),
                    onDecrement: () => _updateReps(-1),
                    icon: widget.isIsometric ? Icons.timer : Icons.repeat,
                    color: widget.isIsometric ? Colors.deepPurple : Colors.green,
                    unit: widget.isIsometric ? 'sec' : 'rep',
                  ),
                ],
              ),

              SizedBox(height: 24.h),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _cancel,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Annulla',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: colorScheme.onSurface.withValues(alpha:0.7),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Salva',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔧 Nuovo metodo compatto per evitare overflow
  Widget _buildCompactParameterControl({
    required String label,
    required String value,
    required TextEditingController controller,
    required Function(String) onChanged,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required IconData icon,
    required Color color,
    required String unit,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withValues(alpha:0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label with icon
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Control row - Layout orizzontale compatto
          Row(
            children: [
              // Decrement button
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: IconButton(
                  onPressed: onDecrement,
                  icon: Icon(
                    Icons.remove,
                    color: color,
                    size: 16.sp,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),

              SizedBox(width: 8.w),

              // Text input - più compatto
              Expanded(
                child: Container(
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: color.withValues(alpha:0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 8.h,
                      ),
                      suffixText: unit,
                      suffixStyle: TextStyle(
                        fontSize: 10.sp,
                        color: color.withValues(alpha:0.6),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 8.w),

              // Increment button
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: color.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: IconButton(
                  onPressed: onIncrement,
                  icon: Icon(
                    Icons.add,
                    color: color,
                    size: 16.sp,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}