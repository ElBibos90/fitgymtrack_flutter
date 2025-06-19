// lib/shared/widgets/exercise_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../../core/config/app_config.dart';
import '../../features/exercises/models/exercises_response.dart';
import '../../features/subscription/bloc/subscription_bloc.dart';
import '../../features/subscription/presentation/widgets/subscription_widgets.dart';
import 'create_exercise_dialog.dart';

class ExerciseSelectionDialog extends StatefulWidget {
  final List<ExerciseItem> exercises;
  final List<int> selectedExerciseIds;
  final bool isLoading;
  final Function(ExerciseItem) onExerciseSelected;
  final VoidCallback onDismissRequest;
  final VoidCallback? onCreateExercise; // Callback per aprire il dialog di creazione esercizio
  final VoidCallback? onExercisesRefresh; // Callback per aggiornare la lista dopo creazione

  const ExerciseSelectionDialog({
    super.key,
    required this.exercises,
    required this.selectedExerciseIds,
    required this.isLoading,
    required this.onExerciseSelected,
    required this.onDismissRequest,
    this.onCreateExercise,
    this.onExercisesRefresh,
  });

  @override
  State<ExerciseSelectionDialog> createState() => _ExerciseSelectionDialogState();
}

class _ExerciseSelectionDialogState extends State<ExerciseSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedMuscleGroup;
  bool _showCreateDialog = false; // ✅ NUOVO: Stato per il dialog di creazione

  @override
  void initState() {
    super.initState();
    // Controlla i limiti degli esercizi personalizzati quando apre il dialog
    context.read<SubscriptionBloc>().add(const CheckResourceLimitsEvent('max_custom_exercises'));
  }

  List<ExerciseItem> get _filteredExercises {
    var filtered = widget.exercises;

    // Filtro per nome (ricerca)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((exercise) =>
          exercise.nome.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Filtro per gruppo muscolare
    if (_selectedMuscleGroup != null && _selectedMuscleGroup!.isNotEmpty) {
      filtered = filtered.where((exercise) =>
      exercise.gruppoMuscolare?.toLowerCase() == _selectedMuscleGroup!.toLowerCase()).toList();
    }

    return filtered;
  }

  List<String> get _availableMuscleGroups {
    final groups = widget.exercises
        .where((exercise) => exercise.gruppoMuscolare != null)
        .map((exercise) => exercise.gruppoMuscolare!)
        .toSet()
        .toList();
    groups.sort();
    return groups;
  }

  void _showCreateExerciseDialog() {
    setState(() {
      _showCreateDialog = true;
    });
  }

  // ✅ NUOVO: Gestione sicura della chiusura del dialog
  void _handleDismiss() {
    print('[CONSOLE] [exercise_selection_dialog]🔄 Dialog dismissing - cleanup');

    // Reset stati locali
    setState(() {
      _showCreateDialog = false;
      _searchQuery = '';
      _selectedMuscleGroup = null;
    });

    // Callback di dismissal (usa onDismissRequest che esiste davvero)
    widget.onDismissRequest();
  }

  void _showUpgradeDialog(BuildContext context, String resourceType, int maxAllowed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limite Raggiunto'),
        content: Text(
          resourceType == 'max_custom_exercises'
              ? 'Hai raggiunto il limite di $maxAllowed esercizi personalizzati disponibili con il piano Free. Passa al piano Premium per avere esercizi illimitati.'
              : 'Hai raggiunto un limite del tuo piano corrente. Passa al piano Premium per sbloccare funzionalità illimitate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Naviga alla schermata di abbonamento (sostituisci con il tuo routing)
              // Navigator.of(context).pushNamed('/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF90CAF9)
                  : AppColors.indigo600,
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
            ),
            child: const Text('Passa a Premium'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16.w),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppConfig.radiusL),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(context),
                _buildFilters(context),
                Expanded(child: _buildExercisesList(context)),
                _buildFooter(context),
              ],
            ),
          ),
        ),

        // ✅ NUOVO: Dialog di creazione esercizio
        if (_showCreateDialog)
          CreateExerciseDialog(
            onSuccess: () {
              print('[CONSOLE] [exercise_selection_dialog]✅ Exercise created successfully - refreshing');
              setState(() {
                _showCreateDialog = false;
              });
              // ✅ REFRESH MIGLIORATO: Aggiorna la lista degli esercizi
              if (widget.onExercisesRefresh != null) {
                // Usa Future.delayed per evitare refresh immediato che può causare problemi
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    widget.onExercisesRefresh!();
                  }
                });
              }
            },
            onDismiss: () {
              print('[CONSOLE] [exercise_selection_dialog]📱 Create dialog dismissed');
              setState(() {
                _showCreateDialog = false;
              });
            },
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppConfig.radiusL),
          topRight: Radius.circular(AppConfig.radiusL),
        ),
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Seleziona Esercizi',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          // Pulsante per creare nuovo esercizio
          if (widget.onCreateExercise != null)
            BlocBuilder<SubscriptionBloc, SubscriptionState>(
              builder: (context, subscriptionState) {
                return IconButton(
                  onPressed: () {
                    if (subscriptionState is SubscriptionLoaded) {
                      final exerciseLimits = subscriptionState.exerciseLimits;

                      // Se abbiamo i limiti e sono raggiunti, mostra il dialog di upgrade
                      if (exerciseLimits != null && exerciseLimits.limitReached) {
                        _showUpgradeDialog(context, 'max_custom_exercises', exerciseLimits.maxAllowed ?? 5);
                        return;
                      }

                      // Se il piano è premium o ci sono slot disponibili, permetti la creazione
                      final subscription = subscriptionState.subscription;
                      if (subscription.isPremium && !subscription.isExpired) {
                        _showCreateExerciseDialog();
                      } else if (exerciseLimits != null && exerciseLimits.remaining > 0) {
                        _showCreateExerciseDialog();
                      } else {
                        // Fallback: mostra comunque il dialog di upgrade
                        _showUpgradeDialog(context, 'max_custom_exercises', subscription.maxCustomExercises ?? 5);
                      }
                    } else {
                      // Se non abbiamo lo stato della subscription, prova comunque
                      _showCreateExerciseDialog();
                    }
                  },
                  icon: Icon(
                    Icons.add,
                    color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                  ),
                  tooltip: 'Crea nuovo esercizio',
                );
              },
            ),
          SizedBox(width: 8.w),
          IconButton(
            onPressed: _handleDismiss,
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          // Barra di ricerca
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cerca esercizi...',
              prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: Icon(Icons.clear, color: colorScheme.onSurface.withOpacity(0.6)),
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
          SizedBox(height: 12.h),
          // Filtro gruppo muscolare
          DropdownButtonFormField<String>(
            value: _selectedMuscleGroup,
            decoration: InputDecoration(
              labelText: 'Filtra per gruppo muscolare',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppConfig.radiusM),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: Text(
                  'Tutti i gruppi',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
              ..._availableMuscleGroups.map((group) => DropdownMenuItem<String>(
                value: group,
                child: Text(
                  group,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              )),
            ],
            onChanged: (value) {
              setState(() => _selectedMuscleGroup = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final filteredExercises = _filteredExercises;

    if (filteredExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64.sp,
              color: colorScheme.onSurface.withOpacity(0.4),
            ),
            SizedBox(height: 16.h),
            Text(
              'Nessun esercizio trovato',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Prova a modificare i filtri di ricerca'
                  : 'Non ci sono esercizi disponibili',
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.onCreateExercise != null) ...[
              SizedBox(height: 24.h),
              BlocBuilder<SubscriptionBloc, SubscriptionState>(
                builder: (context, subscriptionState) {
                  return ElevatedButton.icon(
                    onPressed: () {
                      if (subscriptionState is SubscriptionLoaded) {
                        final exerciseLimits = subscriptionState.exerciseLimits;

                        if (exerciseLimits != null && exerciseLimits.limitReached) {
                          _showUpgradeDialog(context, 'max_custom_exercises', exerciseLimits.maxAllowed ?? 5);
                          return;
                        }

                        final subscription = subscriptionState.subscription;
                        if (subscription.isPremium && !subscription.isExpired) {
                          _showCreateExerciseDialog();
                        } else if (exerciseLimits != null && exerciseLimits.remaining > 0) {
                          _showCreateExerciseDialog();
                        } else {
                          _showUpgradeDialog(context, 'max_custom_exercises', subscription.maxCustomExercises ?? 5);
                        }
                      } else {
                        _showCreateExerciseDialog();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Crea nuovo esercizio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF90CAF9)
                          : AppColors.indigo600,
                      foregroundColor: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.backgroundDark
                          : Colors.white,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = filteredExercises[index];
        final isSelected = widget.selectedExerciseIds.contains(exercise.id);

        return _buildExerciseItem(context, exercise, isSelected);
      },
    );
  }

  Widget _buildExerciseItem(BuildContext context, ExerciseItem exercise, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF90CAF9).withOpacity(0.1) : AppColors.indigo600.withOpacity(0.1))
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConfig.radiusM),
        border: Border.all(
          color: isSelected
              ? (isDark ? const Color(0xFF90CAF9) : AppColors.indigo600)
              : colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        title: Text(
          exercise.nome,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exercise.gruppoMuscolare != null) ...[
              SizedBox(height: 4.h),
              Text(
                exercise.gruppoMuscolare!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (exercise.attrezzatura != null) ...[
              SizedBox(height: 2.h),
              Text(
                exercise.attrezzatura!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: isSelected
            ? Icon(
          Icons.check_circle,
          color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
          size: 24.sp,
        )
            : Icon(
          Icons.add_circle_outline,
          color: colorScheme.onSurface.withOpacity(0.6),
          size: 24.sp,
        ),
        onTap: isSelected ? null : () {
          print('[CONSOLE] [exercise_selection_dialog]Selected exercise: ${exercise.nome}');
          widget.onExerciseSelected(exercise);
        },
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppConfig.radiusL),
          bottomRight: Radius.circular(AppConfig.radiusL),
        ),
        border: Border(
          top: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_filteredExercises.length} esercizi trovati',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                // Mostra informazioni sugli slot disponibili
                if (widget.onCreateExercise != null)
                  BlocBuilder<SubscriptionBloc, SubscriptionState>(
                    builder: (context, state) {
                      if (state is SubscriptionLoaded) {
                        final subscription = state.subscription;
                        if (subscription.isPremium && !subscription.isExpired) {
                          return Text(
                            'Esercizi personalizzati illimitati',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.green.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        } else {
                          final remaining = (subscription.maxCustomExercises ?? 5) - subscription.currentCustomExercises;
                          return Text(
                            '$remaining slot${remaining == 1 ? '' : 's'} rimanente${remaining == 1 ? '' : 'i'} per esercizi personalizzati',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: remaining > 0
                                  ? colorScheme.onSurface.withOpacity(0.6)
                                  : AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _handleDismiss,
            child: Text(
              'Chiudi',
              style: TextStyle(
                fontSize: 16.sp,
                color: isDark ? const Color(0xFF90CAF9) : AppColors.indigo600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}