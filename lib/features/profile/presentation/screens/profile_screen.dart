// lib/features/profile/presentation/screens/profile_screen.dart
// ✅ VERSIONE REALE - Salvataggio database funzionante!

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../models/user_profile_models.dart';
import '../../bloc/profile_bloc.dart';

/// ✅ Schermata del profilo utente - VERSIONE REALE con salvataggio DB
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  bool _isEditing = false;

  // Controllers per i form
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();

  // Valori selezionati
  Gender? _selectedGender;
  ExperienceLevel _selectedExperience = ExperienceLevel.beginner;
  FitnessGoal? _selectedGoal;

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
    super.dispose();
  }

  /// ✅ Carica il profilo reale dal database
  void _loadProfile() {
    print('[CONSOLE] [profile_screen] 📡 Loading real profile from database...');
    context.read<ProfileBloc>().add(const LoadUserProfile());
  }

  /// ✅ Popola i controller con i dati reali
  void _populateControllers(UserProfile profile) {
    _userProfile = profile;

    _heightController.text = profile.height?.toString() ?? '';
    _weightController.text = profile.weight?.toString() ?? '';
    _ageController.text = profile.age?.toString() ?? '';
    _notesController.text = profile.notes ?? '';

    _selectedGender = profile.gender != null ? Gender.fromString(profile.gender!) : null;
    _selectedExperience = ExperienceLevel.fromString(profile.experienceLevel);
    _selectedGoal = profile.fitnessGoals != null ? FitnessGoal.fromString(profile.fitnessGoals!) : null;

    print('[CONSOLE] [profile_screen] ✅ Controllers populated with real data');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: _handleProfileState,
      builder: (context, state) {
        // Determina il profile corrente per l'AppBar
        UserProfile? currentProfile;
        if (state is ProfileLoaded) {
          currentProfile = state.profile;
        } else if (state is ProfileUpdating) {
          currentProfile = state.currentProfile;
        }

        return Scaffold(
          backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
          appBar: _buildAppBar(isDarkMode, profile: currentProfile),
          body: _buildBody(context, state, isDarkMode),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProfileState state, bool isDarkMode) {
    if (state is ProfileLoading) {
      return _buildLoadingState();
    } else if (state is ProfileError) {
      return _buildErrorState(state.message);
    } else if (state is ProfileLoaded) {
      // ✅ Popola i controller quando carica i dati reali
      if (_userProfile?.userId != state.profile.userId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _populateControllers(state.profile);
        });
      }
      return _buildProfileContent(isDarkMode, state.profile);
    } else if (state is ProfileUpdating) {
      return _buildProfileContent(isDarkMode, state.currentProfile, isUpdating: true);
    }

    return _buildEmptyState();
  }

  /// ✅ Gestisce gli stati del ProfileBloc
  void _handleProfileState(BuildContext context, ProfileState state) {
    if (state is ProfileUpdateSuccess) {
      print('[CONSOLE] [profile_screen] ✅ Profile updated successfully!');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      setState(() {
        _isEditing = false;
      });

      // Aggiorna i controller con i nuovi dati
      _populateControllers(state.profile);

    } else if (state is ProfileError && state.message.contains('aggiornamento')) {
      print('[CONSOLE] [profile_screen] ❌ Profile update failed: ${state.message}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode, {UserProfile? profile}) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: isDarkMode ? Colors.white : AppColors.textPrimary,
        ),
        onPressed: () {
          print('[CONSOLE] [profile_screen] ⬅️ Navigating back to dashboard');
          // ✅ FIX: Usa context.go invece di Navigator.pop() per evitare errori di stack
          context.go('/dashboard');
        },
      ),
      title: Text(
        'Profilo',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : AppColors.textPrimary,
        ),
      ),
      actions: [
        if (profile != null && !_isEditing)
          IconButton(
            icon: Icon(
              Icons.edit,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
            onPressed: () {
              print('[CONSOLE] [profile_screen] ✏️ Entering edit mode');
              setState(() {
                _isEditing = true;
              });
            },
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Caricamento profilo...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            'Errore nel caricamento',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _loadProfile,
            child: const Text('Riprova'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            'Nessun profilo trovato',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _createProfile,
            child: const Text('Crea Profilo'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(bool isDarkMode, UserProfile profile, {bool isUpdating = false}) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Header con statistiche
          _buildProfileHeader(isDarkMode, profile),

          SizedBox(height: 20.h),

          // Informazioni di base
          _buildBasicInfoSection(isDarkMode, profile),

          SizedBox(height: 20.h),

          // Fitness info
          _buildFitnessInfoSection(isDarkMode, profile),

          if (profile.notes != null && profile.notes!.isNotEmpty) ...[
            SizedBox(height: 20.h),
            _buildNotesSection(isDarkMode, profile),
          ],

          if (_isEditing) ...[
            SizedBox(height: 30.h),
            _buildSaveButton(isUpdating),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDarkMode, UserProfile profile) {
    final completeness = profile.completenessPercentage;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          // Avatar e nome
          Row(
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Icon(
                  Icons.person,
                  size: 30.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        final userName = authState is AuthAuthenticated
                            ? authState.user.username.isNotEmpty
                            ? authState.user.username
                            : authState.user.email?.split('@').first ?? 'Utente'
                            : 'Utente';

                        return Text(
                          userName,
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    Text(
                      _selectedExperience.displayName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Barra completezza
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completezza Profilo',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    '$completeness%',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              LinearProgressIndicator(
                value: completeness / 100,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(bool isDarkMode, UserProfile profile) {
    return _buildSection(
      title: 'Informazioni di Base',
      icon: Icons.person_outline,
      isDarkMode: isDarkMode,
      children: [
        _buildInfoRow(
          'Altezza',
          _isEditing
              ? _buildTextField(_heightController, 'cm', TextInputType.number)
              : '${profile.height ?? 'Non specificata'} cm',
          Icons.height,
          isDarkMode,
        ),
        _buildInfoRow(
          'Peso',
          _isEditing
              ? _buildTextField(_weightController, 'kg', const TextInputType.numberWithOptions(decimal: true))
              : '${profile.weight ?? 'Non specificato'} kg',
          Icons.monitor_weight,
          isDarkMode,
        ),
        _buildInfoRow(
          'Età',
          _isEditing
              ? _buildTextField(_ageController, 'anni', TextInputType.number)
              : '${profile.age ?? 'Non specificata'} anni',
          Icons.cake,
          isDarkMode,
        ),
        _buildInfoRow(
          'Genere',
          _isEditing ? _buildGenderDropdown(isDarkMode) : (_selectedGender?.displayName ?? 'Non specificato'),
          Icons.person,
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildFitnessInfoSection(bool isDarkMode, UserProfile profile) {
    return _buildSection(
      title: 'Informazioni Fitness',
      icon: Icons.fitness_center,
      isDarkMode: isDarkMode,
      children: [
        _buildInfoRow(
          'Livello di Esperienza',
          _isEditing ? _buildExperienceDropdown(isDarkMode) : _selectedExperience.displayName,
          Icons.trending_up,
          isDarkMode,
        ),
        _buildInfoRow(
          'Obiettivo Principale',
          _isEditing ? _buildGoalDropdown(isDarkMode) : (_selectedGoal?.displayName ?? 'Non specificato'),
          Icons.flag,
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildNotesSection(bool isDarkMode, UserProfile profile) {
    return _buildSection(
      title: 'Note Personali',
      icon: Icons.notes,
      isDarkMode: isDarkMode,
      children: [
        _isEditing
            ? _buildTextArea(_notesController, 'Aggiungi note personali...', isDarkMode)
            : Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            profile.notes ?? 'Nessuna nota',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required bool isDarkMode,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value, IconData icon, bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: isDarkMode ? Colors.white54 : AppColors.textSecondary,
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDarkMode ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: value is Widget ? value : Text(
              value.toString(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String suffix, TextInputType inputType) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        suffixText: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        isDense: true,
      ),
      style: TextStyle(fontSize: 14.sp),
    );
  }

  Widget _buildTextArea(TextEditingController controller, String hint, bool isDarkMode) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        contentPadding: EdgeInsets.all(12.w),
        filled: true,
        fillColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
      ),
      style: TextStyle(fontSize: 14.sp),
    );
  }

  Widget _buildGenderDropdown(bool isDarkMode) {
    return DropdownButtonFormField<Gender>(
      value: _selectedGender,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        isDense: true,
      ),
      items: Gender.values.map((gender) {
        return DropdownMenuItem(
          value: gender,
          child: Text('${gender.icon} ${gender.displayName}'),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
        });
      },
    );
  }

  Widget _buildExperienceDropdown(bool isDarkMode) {
    return DropdownButtonFormField<ExperienceLevel>(
      value: _selectedExperience,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        isDense: true,
      ),
      items: ExperienceLevel.values.map((level) {
        return DropdownMenuItem(
          value: level,
          child: Text(level.displayName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedExperience = value!;
        });
      },
    );
  }

  Widget _buildGoalDropdown(bool isDarkMode) {
    return DropdownButtonFormField<FitnessGoal>(
      value: _selectedGoal,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        isDense: true,
      ),
      items: FitnessGoal.values.map((goal) {
        return DropdownMenuItem(
          value: goal,
          child: Text(goal.displayName),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedGoal = value;
        });
      },
    );
  }

  Widget _buildSaveButton(bool isUpdating) {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: isUpdating ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: isUpdating
            ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20.w,
              height: 20.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'Salvataggio...',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'Salva Modifiche',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Crea un nuovo profilo
  void _createProfile() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      print('[CONSOLE] [profile_screen] 🆕 Creating default profile for user ${authState.user.id}');
      context.read<ProfileBloc>().add(CreateDefaultProfile(userId: authState.user.id));
    }
  }

  /// ✅ Salva le modifiche reali nel database!
  void _saveProfile() {
    if (_userProfile == null) {
      print('[CONSOLE] [profile_screen] ❌ Cannot save: _userProfile is null');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Errore: profilo non caricato'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('[CONSOLE] [profile_screen] 💾 Saving profile changes to database...');

    final updatedProfile = _userProfile!.copyWith(
      height: _heightController.text.isNotEmpty ? int.tryParse(_heightController.text) : null,
      weight: _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null,
      age: _ageController.text.isNotEmpty ? int.tryParse(_ageController.text) : null,
      gender: _selectedGender?.value,
      experienceLevel: _selectedExperience.value,
      fitnessGoals: _selectedGoal?.value,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    print('[CONSOLE] [profile_screen] 📤 Sending updated profile to ProfileBloc...');

    // ✅ Invia al ProfileBloc per salvare nel database reale!
    context.read<ProfileBloc>().add(UpdateUserProfile(profile: updatedProfile));
  }
}