// lib/features/feedback/presentation/components/attachment_picker_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../repository/feedback_repository.dart';

class AttachmentPickerWidget extends StatefulWidget {
  final List<File> attachments;
  final Function(List<File>) onAttachmentsChanged;
  final int maxAttachments;

  const AttachmentPickerWidget({
    super.key,
    required this.attachments,
    required this.onAttachmentsChanged,
    this.maxAttachments = 3,
  });

  @override
  State<AttachmentPickerWidget> createState() => _AttachmentPickerWidgetState();
}

class _AttachmentPickerWidgetState extends State<AttachmentPickerWidget> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto (opzionale)',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Funzionalità in sviluppo: puoi selezionare foto ma l\'upload non è ancora attivo',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Aggiungi foto per illustrare il tuo feedback (max ${widget.maxAttachments} immagini, 5MB ciascuna)',
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 12.h),

        // Pulsanti per aggiungere foto (solo camera e galleria)
        if (widget.attachments.length < widget.maxAttachments) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Scatta Foto'),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Dalla Galleria'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
        ],

        // Lista foto selezionate
        if (widget.attachments.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.indigo600.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.indigo600.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foto selezionate (${widget.attachments.length}/${widget.maxAttachments})',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.indigo600,
                  ),
                ),
                SizedBox(height: 8.h),
                ...widget.attachments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  return _buildAttachmentItem(file, index);
                }).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttachmentItem(File file, int index) {
    final fileName = file.path.split('/').last;
    final fileSize = file.lengthSync();

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Preview immagine
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.broken_image,
                    size: 20.sp,
                    color: Colors.grey[400],
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Info file
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  FeedbackRepository.formatFileSize(fileSize),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Pulsante rimuovi
          IconButton(
            onPressed: () => _removeAttachment(index),
            icon: Icon(
              Icons.close,
              size: 18.sp,
              color: Colors.red,
            ),
            constraints: BoxConstraints(
              minWidth: 32.w,
              minHeight: 32.w,
            ),
          ),
        ],
      ),
    );
  }

  void _pickFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        final file = File(photo.path);
        await _addAttachment(file);
      }
    } catch (e) {
      _showError('Errore nell\'apertura della fotocamera: $e');
    }
  }

  void _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        await _addAttachment(file);
      }
    } catch (e) {
      _showError('Errore nella selezione dell\'immagine: $e');
    }
  }

  Future<void> _addAttachment(File file) async {
    final fileName = file.path.split('/').last;

    // Verifica se il file è un'immagine supportata
    if (!_isImageFile(fileName)) {
      _showError('Solo immagini sono supportate: $fileName');
      return;
    }

    // Verifica dimensione
    final fileSize = await file.length();
    if (fileSize > FeedbackRepository.maxFileSize) {
      _showError('Immagine troppo grande: $fileName (max 5MB)');
      return;
    }

    // Verifica se non abbiamo raggiunto il limite
    if (widget.attachments.length >= widget.maxAttachments) {
      _showError('Limite massimo di ${widget.maxAttachments} foto raggiunto');
      return;
    }

    // Aggiungi alla lista
    final updatedAttachments = List<File>.from(widget.attachments);
    updatedAttachments.add(file);
    widget.onAttachmentsChanged(updatedAttachments);
  }

  void _removeAttachment(int index) {
    final updatedAttachments = List<File>.from(widget.attachments);
    updatedAttachments.removeAt(index);
    widget.onAttachmentsChanged(updatedAttachments);
  }

  bool _isImageFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif'].contains(extension);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}