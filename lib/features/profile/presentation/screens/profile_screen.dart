// lib/features/profile/presentation/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../models/user_profile_models.dart';

/// Schermata del profilo utente (FASE 2 - Basic Implementation)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isEditing = false;

  // Controllers per i form
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _notesController = TextEditingController();

  // Valori selezionati
  String? _selectedGender;
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

  void _loadProfile() {
    setState(() {
      _isLoading = true;
    });

    // TODO: Implementare caricamento reale dal BLoC/Repository
    // Per ora usiamo dati mock per la FASE 2
    Future.delayed(const Duration(seconds: 1), () {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        setState(() {
          _userProfile = _createMockProfile(authState.user.id);
          _populateControllers();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  UserProfile _createMockProfile(int userId) {
    // Mock profile per la FASE 2 - in futuro verrà dal repository
    return UserProfile(
      userId: userId,
      height: 175,
      weight: 70.5,
      age: 28,
      gender: 'male',
      experienceLevel: 'intermediate',
      fitnessGoals: 'muscle_gain',
      preferences: 'Preferisco allenamenti al mattino',
      notes: 'Problema al ginocchio sinistro - attenzione agli squat',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    );
  }

  void _populateControllers() {
    if (_userProfile == null) return;

    _heightController.text = _userProfile!.height?.toString() ?? '';
    _weightController.text = _userProfile!.weight?.toString() ?? '';
    _ageController.text = _userProfile!.age?.toString() ?? '';
    _notesController.text = _userProfile!.notes ?? '';

    _selectedGender = _userProfile!.gender;
    _selectedExperience = ExperienceLevel.fromString(_userProfile!.experienceLevel);
    if (_userProfile!.fitnessGoals != null) {
      _selectedGoal = FitnessGoal.fromString(_userProfile!.fitnessGoals!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profilo'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _userProfile == null
          ? _buildEmptyState(isDarkMode)
          : _buildProfileContent(isDarkMode),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Profilo'),
      centerTitle: true,
      actions: [
        if (_userProfile != null)
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _populateControllers(); // Reset se annulla
                }
              });
            },
            tooltip: _isEditing ? 'Annulla' : 'Modifica',
          ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80.sp,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 20.h),
          Text(
            'Profilo non trovato',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Completa il tuo profilo per personalizzare l\'esperienza',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30.h),
          ElevatedButton(
            onPressed: _createProfile,
            child: const Text('Crea Profilo'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(bool isDarkMode) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Header con statistiche
          _buildProfileHeader(isDarkMode),

          SizedBox(height: 20.h),

          // Informazioni di base
          _buildBasicInfoSection(isDarkMode),

          SizedBox(height: 20.h),

          // Fitness info
          _buildFitnessInfoSection(isDarkMode),

          if (_userProfile!.notes != null && _userProfile!.notes!.isNotEmpty) ...[
            SizedBox(height: 20.h),
            _buildNotesSection(isDarkMode),
          ],

          if (_isEditing) ...[
            SizedBox(height: 30.h),
            _buildSaveButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileHeader(bool isDarkMode) {
    final completeness = _userProfile!.completenessPercentage;

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

  Widget _buildBasicInfoSection(bool isDarkMode) {
    return _buildSection(
      title: 'Informazioni di Base',
      icon: Icons.person_outline,
      isDarkMode: isDarkMode,
      children: [
        _buildInfoRow(
          'Altezza',
          _isEditing
              ? _buildTextField(_heightController, 'cm', TextInputType.number)
              : '${_userProfile!.height ?? 'Non specificata'} cm',
          Icons.height,
          isDarkMode,
        ),
        _buildInfoRow(
          'Peso',
          _isEditing
              ? _buildTextField(_weightController, 'kg', const TextInputType.numberWithOptions(decimal: true))
              : '${_userProfile!.weight ?? 'Non specificato'} kg',
          Icons.monitor_weight,
          isDarkMode,
        ),
        _buildInfoRow(
          'Età',
          _isEditing
              ? _buildTextField(_ageController, 'anni', TextInputType.number)
              : '${_userProfile!.age ?? 'Non specificata'} anni',
          Icons.cake,
          isDarkMode,
        ),
        _buildInfoRow(
          'Genere',
          _isEditing
              ? _buildGenderDropdown(isDarkMode)
              : Gender.fromString(_userProfile!.gender ?? '').displayName,
          Icons.wc,
          isDarkMode,
        ),
        if (_userProfile!.bmi != null) ...[
          _buildInfoRow(
            'BMI',
            '${_userProfile!.bmi!.toStringAsFixed(1)} (${_userProfile!.bmiCategory})',
            Icons.insights,
            isDarkMode,
          ),
        ],
      ],
    );
  }

  Widget _buildFitnessInfoSection(bool isDarkMode) {
    return _buildSection(
      title: 'Informazioni Fitness',
      icon: Icons.fitness_center,
      isDarkMode: isDarkMode,
      children: [
        _buildInfoRow(
          'Livello',
          _isEditing
              ? _buildExperienceDropdown(isDarkMode)
              : _selectedExperience.displayName,
          Icons.bar_chart,
          isDarkMode,
        ),
        _buildInfoRow(
          'Obiettivo',
          _isEditing
              ? _buildGoalDropdown(isDarkMode)
              : _selectedGoal?.displayName ?? 'Non specificato',
          Icons.flag,
          isDarkMode,
        ),
      ],
    );
  }

  Widget _buildNotesSection(bool isDarkMode) {
    return _buildSection(
      title: 'Note e Preferenze',
      icon: Icons.note,
      isDarkMode: isDarkMode,
      children: [
        _isEditing
            ? TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Note, infortuni, preferenze...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        )
            : Text(
          _userProfile!.notes!,
          style: TextStyle(
            fontSize: 14.sp,
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
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
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: isDarkMode
            ? Border.all(color: Colors.grey.shade700, width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
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
                  color: isDarkMode ? Colors.white : Colors.black,
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
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          SizedBox(width: 12.w),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: value is Widget
                ? value
                : Text(
              value.toString(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String suffix, TextInputType type) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        suffixText: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
    );
  }

  Widget _buildGenderDropdown(bool isDarkMode) {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
      items: Gender.values.map((gender) {
        return DropdownMenuItem(
          value: gender.value,
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: Row(
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

  void _createProfile() {
    // TODO: Implementare creazione profilo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funzionalità in arrivo nella FASE 3'),
      ),
    );
  }

  void _saveProfile() {
    // TODO: Implementare salvataggio profilo
    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modifiche salvate (simulato per FASE 2)'),
        backgroundColor: Colors.green,
      ),
    );
  }
}