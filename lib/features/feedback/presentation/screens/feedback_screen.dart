// lib/features/feedback/presentation/screens/feedback_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../core/utils/device_info_helper.dart';
import '../../models/feedback_models.dart';
import '../bloc/feedback_bloc.dart';
import '../bloc/feedback_event.dart';
import '../bloc/feedback_state.dart';
import '../components/attachment_picker_widget.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FeedbackBloc(
        feedbackRepository: getIt.get(),
      ),
      child: const _FeedbackScreenContent(),
    );
  }
}

class _FeedbackScreenContent extends StatefulWidget {
  const _FeedbackScreenContent();

  @override
  State<_FeedbackScreenContent> createState() => _FeedbackScreenContentState();
}

class _FeedbackScreenContentState extends State<_FeedbackScreenContent> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _emailController = TextEditingController();

  FeedbackType _selectedType = FeedbackType.suggestion;
  FeedbackSeverity _selectedSeverity = FeedbackSeverity.medium;
  List<File> _attachments = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invia Feedback'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: BlocConsumer<FeedbackBloc, FeedbackState>(
        listener: (context, state) {
          if (state is FeedbackSubmitted) {
            // Feedback inviato con successo - pulisci il form
            _titleController.clear();
            _descriptionController.clear();
            _emailController.clear();
            setState(() {
              _selectedType = FeedbackType.suggestion;
              _selectedSeverity = FeedbackSeverity.medium;
              _attachments.clear();
            });
            _showSuccessDialog(context, state.response);
          } else if (state is FeedbackError) {
            // Errore nell'invio
            _showErrorSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              _buildBody(context, state),
              if (state is FeedbackSubmitting)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, FeedbackState state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 24.h),
            _buildFeedbackTypeSection(),
            SizedBox(height: 20.h),
            _buildSeveritySection(),
            SizedBox(height: 20.h),
            _buildTitleField(),
            SizedBox(height: 16.h),
            _buildDescriptionField(),
            SizedBox(height: 16.h),
            _buildEmailField(),
            SizedBox(height: 20.h),
            AttachmentPickerWidget(
              attachments: _attachments,
              onAttachmentsChanged: (attachments) {
                setState(() {
                  _attachments = attachments;
                });
              },
            ),
            SizedBox(height: 32.h),
            _buildSubmitButton(context, state),
            SizedBox(height: 16.h),
            if (state is FeedbackSubmitted) _buildSuccessMessage(state),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.indigo600.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.indigo600.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.feedback_outlined,
                color: AppColors.indigo600,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                'Il tuo feedback è importante',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.indigo600,
                  fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Aiutaci a migliorare l\'app condividendo le tue idee, segnalando problemi o lasciando suggerimenti.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo di feedback',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: FeedbackType.values.map((type) {
            final isSelected = _selectedType == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = type;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.indigo600
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.indigo600
                        : Theme.of(context).colorScheme.outline,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      type.icon,
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      type.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSeveritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priorità',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: FeedbackSeverity.values.map((severity) {
            final isSelected = _selectedSeverity == severity;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSeverity = severity;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(right: 8.w),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _getSeverityColor(severity)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: _getSeverityColor(severity),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    severity.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : _getSeverityColor(severity),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Titolo *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            hintText: 'Inserisci un titolo per il tuo feedback',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Il titolo è obbligatorio';
            }
            if (value.trim().length < 5) {
              return 'Il titolo deve essere di almeno 5 caratteri';
            }
            return null;
          },
          maxLength: 100,
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descrizione *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: 'Descrivi dettagliatamente il tuo feedback',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          maxLines: 5,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La descrizione è obbligatoria';
            }
            if (value.trim().length < 10) {
              return 'La descrizione deve essere di almeno 10 caratteri';
            }
            return null;
          },
          maxLength: 500,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email (opzionale)',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'La tua email per eventuali comunicazioni',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Inserisci un indirizzo email valido';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context, FeedbackState state) {
    final isLoading = state is FeedbackSubmitting;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _submitFeedback(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.indigo600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
          height: 20.h,
          width: 20.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          'Invia Feedback',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage(FeedbackSubmitted state) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Feedback inviato con successo!\nID: ${state.response.feedbackId}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(FeedbackSeverity severity) {
    switch (severity) {
      case FeedbackSeverity.low:
        return Colors.green;
      case FeedbackSeverity.medium:
        return Colors.orange;
      case FeedbackSeverity.high:
        return Colors.red;
      case FeedbackSeverity.critical:
        return Colors.red.shade800;
    }
  }

  // ============================================================================
  // ✅ FIX 1: RIMUOVI DOPPIA NAVIGAZIONE - PROBLEMA SCHERMATA NERA
  // ============================================================================
  void _showSuccessDialog(BuildContext context, FeedbackResponse response) {
    final attachmentInfo = response.attachmentsCount != null && response.attachmentsCount! > 0
        ? '\n\nAllegati caricati: ${response.attachmentsCount}'
        : '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Feedback Inviato'),
        content: Text(
          'Grazie per il tuo feedback! Lo abbiamo ricevuto e lo esamineremo al più presto.\n\nID: ${response.feedbackId}$attachmentInfo',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ✅ Solo chiudi dialog, NON navigare indietro
              // ❌ RIMOSSO: Navigator.of(context).pop(); // Questa causava la schermata nera
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // ============================================================================
  // ✅ FIX 2: ABILITA INVIO ALLEGATI - RIMOSSO MESSAGGIO CHE LI DISABILITAVA
  // ============================================================================
  Future<void> _submitFeedback(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // ✅ RIMOSSO il messaggio che disabilitava gli allegati
    // Era questo codice che impediva l'upload:
    /*
    if (_attachments.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nota: Gli allegati sono selezionati ma l\'upload non è ancora implementato...'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    */

    // ✅ Raccoglie info dispositivo reali
    final deviceInfo = await DeviceInfoHelper.getDeviceInfoJson();

    final request = FeedbackRequest(
      type: _selectedType,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      severity: _selectedSeverity,
      deviceInfo: deviceInfo, // ✅ Usa le info reali del dispositivo
    );

    // ✅ NUOVO: Invia con allegati se presenti
    context.read<FeedbackBloc>().add(SubmitFeedback(
      request: request,
      attachments: _attachments.isNotEmpty ? _attachments : null,
    ));
  }
}