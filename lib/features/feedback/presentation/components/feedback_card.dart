// lib/features/feedback/presentation/components/feedback_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../models/feedback_models.dart' as feedback_models;

class FeedbackCard extends StatelessWidget {
  final feedback_models.Feedback feedback;
  final bool isAdmin;
  final VoidCallback? onTap;
  final Function(feedback_models.FeedbackStatus)? onStatusChange;
  final VoidCallback? onEditNotes;

  const FeedbackCard({
    super.key,
    required this.feedback,
    this.isAdmin = false,
    this.onTap,
    this.onStatusChange,
    this.onEditNotes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 8.h,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: _getStatusColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              SizedBox(height: 12.h),
              _buildContent(context),
              SizedBox(height: 12.h),
              _buildFooter(context),
              if (isAdmin && (feedback.adminNotes?.isNotEmpty ?? false)) ...[
                SizedBox(height: 12.h),
                _buildAdminNotes(context),
              ],
              if (isAdmin) ...[
                SizedBox(height: 12.h),
                _buildAdminActions(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Icona tipo feedback
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: _getTypeColor().withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            feedback.type.icon,
            style: TextStyle(fontSize: 20.sp),
          ),
        ),
        SizedBox(width: 12.w),

        // Titolo e tipo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feedback.title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Text(
                    feedback.type.label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _getTypeColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getSeverityColor().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      feedback.severity.label,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: _getSeverityColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Badge stato
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8.w,
            vertical: 4.h,
          ),
          decoration: BoxDecoration(
            color: _getStatusColor(),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            feedback.status.label,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          feedback.description,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),

        // Email se presente
        if (feedback.email?.isNotEmpty ?? false) ...[
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                Icons.email_outlined,
                size: 16.sp,
                color: Colors.grey[600],
              ),
              SizedBox(width: 4.w),
              Text(
                feedback.email!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],

        // Foto se presenti
        if (feedback.attachments?.isNotEmpty ?? false) ...[
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(
                Icons.photo,
                size: 16.sp,
                color: Colors.grey[600],
              ),
              SizedBox(width: 4.w),
              Text(
                '${feedback.attachments!.length} ${feedback.attachments!.length == 1 ? 'foto' : 'foto'}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        // Info utente
        if (feedback.username?.isNotEmpty ?? false) ...[
          Icon(
            Icons.person_outline,
            size: 16.sp,
            color: Colors.grey[600],
          ),
          SizedBox(width: 4.w),
          Text(
            feedback.username!,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(width: 16.w),
        ],

        // Data creazione
        Icon(
          Icons.access_time,
          size: 16.sp,
          color: Colors.grey[600],
        ),
        SizedBox(width: 4.w),
        Text(
          _formatDate(feedback.createdAt),
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),

        const Spacer(),

        // ID feedback
        Text(
          'ID: ${feedback.id ?? 'N/A'}',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildAdminNotes(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_outlined,
                size: 16.sp,
                color: Colors.blue,
              ),
              SizedBox(width: 4.w),
              Text(
                'Note Admin',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            feedback.adminNotes!,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Azioni Admin',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8.h),

          // Cambio stato
          Wrap(
            spacing: 8.w,
            children: feedback_models.FeedbackStatus.values.map((status) {
              final isCurrentStatus = feedback.status == status;
              return ChoiceChip(
                label: Text(
                  status.label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isCurrentStatus ? Colors.white : Colors.black87,
                  ),
                ),
                selected: isCurrentStatus,
                onSelected: isCurrentStatus
                    ? null
                    : (selected) {
                  if (selected && onStatusChange != null) {
                    onStatusChange!(status);
                  }
                },
                selectedColor: _getStatusColor(),
              );
            }).toList(),
          ),

          // Pulsante modifica note
          SizedBox(height: 8.h),
          TextButton.icon(
            onPressed: onEditNotes,
            icon: Icon(
              Icons.edit_note,
              size: 16.sp,
            ),
            label: Text(
              'Modifica Note',
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (feedback.type) {
      case feedback_models.FeedbackType.bug:
        return Colors.red;
      case feedback_models.FeedbackType.feature:
        return Colors.purple;
      case feedback_models.FeedbackType.suggestion:
        return Colors.blue;
      case feedback_models.FeedbackType.complaint:
        return Colors.orange;
      case feedback_models.FeedbackType.compliment:
        return Colors.green;
      case feedback_models.FeedbackType.other:
        return Colors.grey;
    }
  }

  Color _getSeverityColor() {
    switch (feedback.severity) {
      case feedback_models.FeedbackSeverity.low:
        return Colors.green;
      case feedback_models.FeedbackSeverity.medium:
        return Colors.orange;
      case feedback_models.FeedbackSeverity.high:
        return Colors.red;
      case feedback_models.FeedbackSeverity.critical:
        return Colors.red.shade800;
    }
  }

  Color _getStatusColor() {
    switch (feedback.status) {
      case feedback_models.FeedbackStatus.new_:
        return Colors.blue;
      case feedback_models.FeedbackStatus.inProgress:
        return Colors.orange;
      case feedback_models.FeedbackStatus.closed:
        return Colors.green;
      case feedback_models.FeedbackStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Data sconosciuta';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Oggi ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Ieri ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} giorni fa';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
