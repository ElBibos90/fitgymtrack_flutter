// lib/shared/widgets/dual_notes_widget.dart
// 🔥 FASE 6: Note Duali - Widget collapsible per note trainer/utente/sistema
// Data: 18 Ottobre 2025

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/workout_design_system.dart';

class DualNotesWidget extends StatefulWidget {
  final String? trainerNote;
  final String? userNote;
  final String? systemNote;
  final Function(String) onUserNoteChanged;
  final bool isLoading;

  const DualNotesWidget({
    super.key,
    this.trainerNote,
    this.userNote,
    this.systemNote,
    required this.onUserNoteChanged,
    this.isLoading = false,
  });

  @override
  State<DualNotesWidget> createState() => _DualNotesWidgetState();
}

class _DualNotesWidgetState extends State<DualNotesWidget> {
  bool _isExpanded = false;
  final TextEditingController _userNoteController = TextEditingController();
  final FocusNode _userNoteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _userNoteController.text = widget.userNote ?? '';
  }

  @override
  void didUpdateWidget(DualNotesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userNote != oldWidget.userNote) {
      _userNoteController.text = widget.userNote ?? '';
    }
  }

  @override
  void dispose() {
    _userNoteController.dispose();
    _userNoteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyNote = widget.trainerNote != null || 
                      widget.userNote != null || 
                      widget.systemNote != null;

    return Column(
      children: [
        // Pulsante collapsible
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: WorkoutDesignSystem.gray100,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: WorkoutDesignSystem.gray200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 20.sp,
                  color: WorkoutDesignSystem.primary600,
                ),
                SizedBox(width: 8.w),
                Text(
                  'NOTE',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: WorkoutDesignSystem.gray900,
                  ),
                ),
                SizedBox(width: 8.w),
                if (hasAnyNote) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: WorkoutDesignSystem.primary600,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '1',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20.sp,
                  color: WorkoutDesignSystem.gray900,
                ),
              ],
            ),
          ),
        ),

        // Popup note (se espanso)
        if (_isExpanded) ...[
          SizedBox(height: 8.h),
          _buildNotesPopup(),
        ],
      ],
    );
  }

  Widget _buildNotesPopup() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: WorkoutDesignSystem.gray100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: WorkoutDesignSystem.gray200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Note Trainer
          if (widget.trainerNote != null) ...[
            _buildNoteSection(
              icon: Icons.fitness_center,
              label: 'Trainer',
              note: widget.trainerNote!,
              isEditable: false,
            ),
            SizedBox(height: 12.h),
          ],

          // Note Utente
          _buildNoteSection(
            icon: Icons.person,
            label: 'Tua nota',
            note: widget.userNote ?? '',
            isEditable: true,
            controller: _userNoteController,
            focusNode: _userNoteFocus,
          ),

          // Note Sistema
          if (widget.systemNote != null) ...[
            SizedBox(height: 12.h),
            _buildNoteSection(
              icon: Icons.settings,
              label: 'Sistema',
              note: widget.systemNote!,
              isEditable: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteSection({
    required IconData icon,
    required String label,
    required String note,
    required bool isEditable,
    TextEditingController? controller,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: WorkoutDesignSystem.primary600,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: WorkoutDesignSystem.gray900,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),
        if (isEditable) ...[
          TextField(
            controller: controller,
            focusNode: focusNode,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Aggiungi una nota...',
              hintStyle: TextStyle(
                fontSize: 12.sp,
                color: WorkoutDesignSystem.gray400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.r),
                borderSide: BorderSide(
                  color: WorkoutDesignSystem.gray200,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6.r),
                borderSide: BorderSide(
                  color: WorkoutDesignSystem.primary600,
                  width: 2,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 8.h,
              ),
            ),
            style: TextStyle(
              fontSize: 12.sp,
              color: WorkoutDesignSystem.gray900,
            ),
            onChanged: (value) {
              widget.onUserNoteChanged(value);
            },
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: WorkoutDesignSystem.gray100,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: WorkoutDesignSystem.gray200,
              ),
            ),
            child: Text(
              note,
              style: TextStyle(
                fontSize: 12.sp,
                color: WorkoutDesignSystem.gray900,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
