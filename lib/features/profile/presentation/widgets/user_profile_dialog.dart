// lib/features/profile/presentation/widgets/user_profile_dialog.dart
// 🔧 FIXED: Enum property names corrected

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../bloc/profile_bloc.dart';
import '../../models/user_profile_models.dart';

/// 👤 Dialog per visualizzare e modificare il profilo utente
class UserProfileDialog extends StatefulWidget {
  const UserProfileDialog({super.key});

  @override
  State<UserProfileDialog> createState() => _UserProfileDialogState();
}

class _UserProfileDialogState extends State<UserProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers per i form
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();
  final _preferencesController = TextEditingController();
  final _injuriesController = TextEditingController();

  // Valori selezionati
  Gender? _selectedGender;
  ExperienceLevel _selectedExperience = ExperienceLevel.beginner;
  FitnessGoal? _selectedGoal;

  bool _isEditing = false;
  UserProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _notesController.dispose();
    _preferencesController.dispose();
    _injuriesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileBloc>().add(const LoadUserProfile());
    }
  }

  void _populateControllers(UserProfile profile) {
    _currentProfile = profile;
    _heightController.text = profile.height?.toString() ?? '';
    _weightController.text = profile.weight?.toString() ?? '';
    _ageController.text = profile.age?.toString() ?? '';
    _notesController.text = profile.notes ?? '';
    _preferencesController.text = profile.preferences ?? '';
    _injuriesController.text = profile.injuries ?? '';

    _selectedGender = profile.gender != null ? Gender.fromString(profile.gender!) : null;
    _selectedExperience = ExperienceLevel.fromString(profile.experienceLevel);
    _selectedGoal = profile.fitnessGoals != null ? FitnessGoal.fromString(profile.fitnessGoals!) : null;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    final availableHeight = mediaQuery.size.height -
        mediaQuery.viewInsets.bottom -
        mediaQuery.viewPadding.top -
        mediaQuery.viewPadding.bottom;

    return BlocListener<ProfileBloc, ProfileState>(
      listener: _handleProfileState,
      child: Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: 20.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (availableHeight * 0.9).clamp(400.h, 800.h),
            minHeight: 300.h,
            maxWidth: 500.w,
          ),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isDarkMode),
                SizedBox(height: 16.h),
                Flexible(
                  child: BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      if (state is ProfileLoading) {
                        return _buildLoadingContent();
                      } else if (state is ProfileLoaded) {
                        if (_currentProfile == null) {
                          _populateControllers(state.profile);
                        }
                        return _buildProfileContent(isDarkMode, state.profile);
                      } else if (state is ProfileError) {
                        return _buildErrorContent(state.message);
                      }
                      return _buildLoadingContent();
                    },
                  ),
                ),
                _buildActions(isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleProfileState(BuildContext context, ProfileState state) {
    if (state is ProfileUpdateSuccess) {
      CustomSnackbar.show(
        context,
        message: state.message,
        isSuccess: true,
      );
      setState(() {
        _isEditing = false;
      });
    } else if (state is ProfileError) {
      CustomSnackbar.show(
        context,
        message: state.message,
        isSuccess: false,
      );
    }
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: AppColors.indigo600.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            Icons.person_rounded,
            color: AppColors.indigo600,
            size: 18.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditing ? 'Modifica Profilo' : 'Il Tuo Profilo',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              Text(
                _isEditing ? 'Aggiorna le tue informazioni' : 'Le tue informazioni personali',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        if (_currentProfile != null && !_isEditing)
          IconButton(
            onPressed: () => setState(() => _isEditing = true),
            icon: Icon(
              Icons.edit,
              color: AppColors.indigo600,
              size: 20.sp,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.close,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Caricamento profilo...'),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Errore',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProfile,
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(bool isDarkMode, UserProfile profile) {
    if (_isEditing) {
      return _buildEditForm(isDarkMode);
    } else {
      return _buildReadOnlyView(isDarkMode, profile);
    }
  }

  Widget _buildReadOnlyView(bool isDarkMode, UserProfile profile) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress Card
          _buildProgressCard(isDarkMode, profile),
          SizedBox(height: 16.h),

          // Basic Info
          _buildInfoSection(
            'Informazioni Base',
            [
              if (profile.height != null) _buildInfoRow('Altezza', '${profile.height} cm'),
              if (profile.weight != null) _buildInfoRow('Peso', '${profile.weight?.toStringAsFixed(1)} kg'),
              if (profile.age != null) _buildInfoRow('Età', '${profile.age} anni'),
              // 🔧 FIX: Use .displayName (consistent with existing code)
              if (profile.gender != null) _buildInfoRow('Genere', Gender.fromString(profile.gender!).displayName),
              if (profile.bmi != null) _buildInfoRow('BMI', '${profile.bmi!.toStringAsFixed(1)} (${profile.bmiCategory})'),
            ],
            isDarkMode,
          ),

          SizedBox(height: 16.h),

          // Fitness Info
          _buildInfoSection(
            'Fitness',
            [
              // 🔧 FIX: Use .displayName (consistent with existing code)
              _buildInfoRow('Esperienza', ExperienceLevel.fromString(profile.experienceLevel).displayName),
              if (profile.fitnessGoals != null)
              // 🔧 FIX: Use .displayName (consistent with existing code)
                _buildInfoRow('Obiettivi', FitnessGoal.fromString(profile.fitnessGoals!).displayName),
            ],
            isDarkMode,
          ),

          if (profile.preferences != null || profile.injuries != null || profile.notes != null) ...[
            SizedBox(height: 16.h),
            _buildInfoSection(
              'Note',
              [
                if (profile.preferences != null) _buildInfoRow('Preferenze', profile.preferences!),
                if (profile.injuries != null) _buildInfoRow('Infortuni', profile.injuries!),
                if (profile.notes != null) _buildInfoRow('Note', profile.notes!),
              ],
              isDarkMode,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard(bool isDarkMode, UserProfile profile) {
    final completeness = profile.completenessPercentage;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.indigo600.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.indigo600.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40.w,
            height: 40.w,
            child: CircularProgressIndicator(
              value: completeness / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.indigo600),
              strokeWidth: 3,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profilo completato al $completeness%',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.indigo600,
                  ),
                ),
                if (!profile.isComplete)
                  Text(
                    'Completa per personalizzare l\'app',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children, bool isDarkMode) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(bool isDarkMode) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Basic Info
            Row(
              children: [
                Expanded(child: _buildHeightField(isDarkMode)),
                SizedBox(width: 12.w),
                Expanded(child: _buildWeightField(isDarkMode)),
              ],
            ),
            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(child: _buildAgeField(isDarkMode)),
                SizedBox(width: 12.w),
                Expanded(child: _buildGenderField(isDarkMode)),
              ],
            ),
            SizedBox(height: 12.h),

            // Fitness Info
            _buildExperienceField(isDarkMode),
            SizedBox(height: 12.h),
            _buildGoalField(isDarkMode),
            SizedBox(height: 12.h),

            // Notes
            _buildPreferencesField(isDarkMode),
            SizedBox(height: 12.h),
            _buildInjuriesField(isDarkMode),
            SizedBox(height: 12.h),
            _buildNotesField(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeightField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Altezza (cm)',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 4.h),
        TextFormField(
          controller: _heightController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '175',
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
          style: TextStyle(fontSize: 14.sp),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final height = int.tryParse(value);
              if (height == null || height < 100 || height > 250) {
                return 'Altezza non valida';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildWeightField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Peso (kg)',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 4.h),
        TextFormField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          decoration: InputDecoration(
            hintText: '70.5',
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
          style: TextStyle(fontSize: 14.sp),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final weight = double.tryParse(value);
              if (weight == null || weight < 30 || weight > 250) {
                return 'Peso non valido';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAgeField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Età',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 4.h),
        TextFormField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '25',
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
          style: TextStyle(fontSize: 14.sp),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final age = int.tryParse(value);
              if (age == null || age < 16 || age > 100) {
                return 'Età non valida';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGenderField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Genere',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 4.h),
        DropdownButtonFormField<Gender>(
          value: _selectedGender,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
          items: Gender.values.map((gender) {
            return DropdownMenuItem(
              value: gender,
              // 🔧 FIX: Use .displayName (consistent with existing code)
              child: Text(gender.displayName),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedGender = value),
        ),
      ],
    );
  }

  Widget _buildExperienceField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Livello Esperienza',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 4.h),
        DropdownButtonFormField<ExperienceLevel>(
          value: _selectedExperience,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
          items: ExperienceLevel.values.map((level) {
            return DropdownMenuItem(
              value: level,
              // 🔧 FIX: Use .displayName (consistent with existing code)
              child: Text(level.displayName),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedExperience = value!),
        ),
      ],
    );
  }

  Widget _buildGoalField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Obiettivo Fitness',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 4.h),
        DropdownButtonFormField<FitnessGoal>(
          value: _selectedGoal,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
          items: FitnessGoal.values.map((goal) {
            return DropdownMenuItem(
              value: goal,
              // 🔧 FIX: Use .displayName (consistent with existing code)
              child: Text(goal.displayName),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedGoal = value),
        ),
      ],
    );
  }

  Widget _buildPreferencesField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferenze Allenamento',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 4.h),
        TextFormField(
          controller: _preferencesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Es. Preferisco allenarmi al mattino...',
            contentPadding: EdgeInsets.all(12.w),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
          style: TextStyle(fontSize: 14.sp),
        ),
      ],
    );
  }

  Widget _buildInjuriesField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Infortuni / Limitazioni',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 4.h),
        TextFormField(
          controller: _injuriesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Es. Problema al ginocchio destro...',
            contentPadding: EdgeInsets.all(12.w),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
          style: TextStyle(fontSize: 14.sp),
        ),
      ],
    );
  }

  Widget _buildNotesField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note Personali',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(height: 4.h),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Aggiungi note personali...',
            contentPadding: EdgeInsets.all(12.w),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
            filled: true,
            fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
          ),
          style: TextStyle(fontSize: 14.sp),
        ),
      ],
    );
  }

  Widget _buildActions(bool isDarkMode) {
    if (!_isEditing) {
      return Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Chiudi',
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => setState(() => _isEditing = false),
            child: Text(
              'Annulla',
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              final isLoading = state is ProfileUpdating;
              return ElevatedButton(
                onPressed: isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo600,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  'Salva',
                  style: TextStyle(fontSize: 14.sp),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    if (_currentProfile == null) return;

    final updatedProfile = _currentProfile!.copyWith(
      height: _heightController.text.isNotEmpty ? int.parse(_heightController.text) : null,
      weight: _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
      age: _ageController.text.isNotEmpty ? int.parse(_ageController.text) : null,
      gender: _selectedGender?.value,
      experienceLevel: _selectedExperience.value,
      fitnessGoals: _selectedGoal?.value,
      preferences: _preferencesController.text.isNotEmpty ? _preferencesController.text : null,
      injuries: _injuriesController.text.isNotEmpty ? _injuriesController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    context.read<ProfileBloc>().add(UpdateUserProfile(profile: updatedProfile));
  }
}