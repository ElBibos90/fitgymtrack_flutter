// lib/shared/widgets/plateau_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/workouts/models/plateau_models.dart';
import '../../features/workouts/bloc/plateau_bloc.dart';

/// 🎯 STEP 6: Widget Flutter per visualizzare i plateau
/// Traduzioni Flutter dei componenti Compose esistenti

/// Indicatore principale per segnalare un plateau
class PlateauIndicator extends StatefulWidget {
  final PlateauInfo plateauInfo;
  final VoidCallback? onDismiss;
  final Function(ProgressionSuggestion)? onApplySuggestion;

  const PlateauIndicator({
    super.key,
    required this.plateauInfo,
    this.onDismiss,
    this.onApplySuggestion,
  });

  @override
  State<PlateauIndicator> createState() => _PlateauIndicatorState();
}

class _PlateauIndicatorState extends State<PlateauIndicator>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _plateauColor {
    final colorHex = widget.plateauInfo.colorHex;
    return Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _plateauColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _plateauColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _plateauColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(colorScheme),
                if (_isExpanded) _buildExpandedContent(colorScheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            // Icona warning animata
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: _plateauColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.trending_flat,
                color: _plateauColor,
                size: 20.sp,
              ),
            ),

            SizedBox(width: 12.w),

            // Informazioni plateau
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚡ Plateau Rilevato',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: _plateauColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Stessi valori per ${widget.plateauInfo.sessionsInPlateau} allenamenti',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _plateauColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // Controlli
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: _plateauColor,
                    size: 20.sp,
                  ),
                  padding: EdgeInsets.all(4.w),
                  constraints: BoxConstraints(
                    minWidth: 32.w,
                    minHeight: 32.w,
                  ),
                ),
                IconButton(
                  onPressed: widget.onDismiss,
                  icon: Icon(
                    Icons.close,
                    color: _plateauColor.withOpacity(0.7),
                    size: 18.sp,
                  ),
                  padding: EdgeInsets.all(4.w),
                  constraints: BoxConstraints(
                    minWidth: 32.w,
                    minHeight: 32.w,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Divider
          Container(
            height: 1,
            margin: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  _plateauColor.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Informazioni attuali
          _buildCurrentInfo(),

          SizedBox(height: 16.h),

          // Suggerimenti
          _buildSuggestions(),
        ],
      ),
    );
  }

  Widget _buildCurrentInfo() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _plateauColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          // Peso attuale
          Expanded(
            child: _buildValueItem(
              'Peso Attuale',
              '${widget.plateauInfo.currentWeight.toStringAsFixed(1)} kg',
              Icons.fitness_center,
            ),
          ),

          SizedBox(width: 16.w),

          // Ripetizioni attuali
          Expanded(
            child: _buildValueItem(
              'Ripetizioni Attuali',
              widget.plateauInfo.currentReps.toString(),
              Icons.repeat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: _plateauColor,
          size: 16.sp,
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: _plateauColor.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: _plateauColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '💡 Suggerimenti per Progredire:',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: _plateauColor,
          ),
        ),

        SizedBox(height: 8.h),

        ...widget.plateauInfo.suggestions.take(2).map((suggestion) =>
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _buildSuggestionCard(suggestion),
            ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(ProgressionSuggestion suggestion) {
    final confidenceColor = Color(
      int.parse(suggestion.confidenceColorHex.substring(1), radix: 16) + 0xFF000000,
    );

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: _plateauColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getSuggestionIcon(suggestion.type),
            color: _plateauColor,
            size: 18.sp,
          ),

          SizedBox(width: 8.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.description,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Text(
                      'Confidenza: ',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      suggestion.confidenceText,
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: confidenceColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSuggestionIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.increaseWeight:
        return Icons.arrow_upward;
      case SuggestionType.increaseReps:
        return Icons.add;
      case SuggestionType.advancedTechnique:
        return Icons.psychology;
      case SuggestionType.reduceRest:
        return Icons.timer;
      case SuggestionType.changeTempo:
        return Icons.speed;
    }
  }
}

/// Badge discreto per indicare plateau
class PlateauBadge extends StatelessWidget {
  final VoidCallback? onTap;

  const PlateauBadge({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: const Color(0xFFFF5722).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.trending_flat,
              color: Colors.white,
              size: 12.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              'Plateau',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog dettagliato per plateau singolo
class PlateauDetailDialog extends StatelessWidget {
  final PlateauInfo plateauInfo;

  const PlateauDetailDialog({
    super.key,
    required this.plateauInfo,
  });

  Color get _plateauColor {
    final colorHex = plateauInfo.colorHex;
    return Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        Icons.trending_flat,
        color: _plateauColor,
        size: 32.sp,
      ),
      title: Text(
        'Plateau Rilevato!',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome esercizio
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _plateauColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                plateauInfo.exerciseName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: _plateauColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: 16.h),

            // Descrizione
            Text(
              'Hai usato gli stessi valori per ${plateauInfo.sessionsInPlateau} allenamenti consecutivi. È il momento di progredire!',
              style: TextStyle(fontSize: 14.sp),
            ),

            SizedBox(height: 16.h),

            // Valori attuali
            _buildCurrentValues(),

            SizedBox(height: 16.h),

            // Suggerimenti
            _buildSuggestionsList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Indietro'),
        ),
      ],
    );
  }

  Widget _buildCurrentValues() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Valori attuali:',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Icon(Icons.fitness_center, size: 16.sp, color: _plateauColor),
            SizedBox(width: 8.w),
            Text(
              'Peso: ${plateauInfo.currentWeight.toStringAsFixed(1)} kg',
              style: TextStyle(fontSize: 13.sp),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Icon(Icons.repeat, size: 16.sp, color: _plateauColor),
            SizedBox(width: 8.w),
            Text(
              'Ripetizioni: ${plateauInfo.currentReps}',
              style: TextStyle(fontSize: 13.sp),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggerimenti per progredire:',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        ...plateauInfo.suggestions.take(3).map((suggestion) =>
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: _plateauColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      suggestion.description,
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                ],
              ),
            ),
        ),
        if (plateauInfo.suggestions.length > 3)
          Text(
            '• E altri ${plateauInfo.suggestions.length - 3} suggerimenti...',
            style: TextStyle(
              fontSize: 13.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Dialog per plateau di gruppo (superset/circuit)
class GroupPlateauDialog extends StatelessWidget {
  final GroupPlateauAnalysis groupAnalysis;

  const GroupPlateauDialog({
    super.key,
    required this.groupAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(
        Icons.trending_flat,
        color: const Color(0xFFFF5722),
        size: 32.sp,
      ),
      title: Text(
        'Plateau nel ${_getGroupTypeText()}',
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informazioni gruppo
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                children: [
                  Text(
                    groupAnalysis.groupName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF5722),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${groupAnalysis.exercisesInPlateau}/${groupAnalysis.totalExercises} esercizi in plateau (${groupAnalysis.plateauPercentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFFFF5722),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Lista plateau
            Text(
              'Esercizi in plateau:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8.h),

            ...groupAnalysis.plateauList.map((plateau) =>
                _buildPlateauItem(plateau, colorScheme),
            ),

            SizedBox(height: 16.h),

            // Suggerimento generale
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '💪 Considera di variare i carichi e le ripetizioni per superare questi plateau!',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Indietro'),
        ),
      ],
    );
  }

  Widget _buildPlateauItem(PlateauInfo plateau, ColorScheme colorScheme) {
    final plateauColor = Color(
      int.parse(plateau.colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: plateauColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: plateauColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome esercizio
          Text(
            plateau.exerciseName,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: plateauColor,
            ),
          ),

          SizedBox(height: 6.h),

          // Valori attuali
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peso: ${plateau.currentWeight.toStringAsFixed(1)} kg',
                style: TextStyle(fontSize: 11.sp),
              ),
              Text(
                'Reps: ${plateau.currentReps}',
                style: TextStyle(fontSize: 11.sp),
              ),
            ],
          ),

          SizedBox(height: 6.h),

          // Miglior suggerimento
          if (plateau.bestSuggestion != null)
            Text(
              '💡 ${plateau.bestSuggestion!.description}',
              style: TextStyle(
                fontSize: 11.sp,
                color: colorScheme.onSurfaceVariant,
              ),
            ),

          SizedBox(height: 4.h),

          // Indicatore sessioni
          Text(
            '${plateau.sessionsInPlateau} allenamenti con stessi valori',
            style: TextStyle(
              fontSize: 10.sp,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _getGroupTypeText() {
    switch (groupAnalysis.groupType) {
      case 'superset':
        return 'Superset';
      case 'circuit':
        return 'Circuit';
      default:
        return 'Gruppo';
    }
  }
}

/// Widget per mostrare statistiche plateau
class PlateauStatisticsCard extends StatelessWidget {
  final PlateauStatistics statistics;

  const PlateauStatisticsCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.all(16.w),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Statistiche Plateau',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),

            SizedBox(height: 16.h),

            // Statistiche principali
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Plateau Rilevati',
                    statistics.totalPlateauDetected.toString(),
                    Icons.trending_flat,
                    colorScheme,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Percentuale',
                    '${statistics.globalPlateauPercentage.toStringAsFixed(1)}%',
                    Icons.pie_chart,
                    colorScheme,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Tipo più comune
            if (statistics.mostCommonPlateauType != null)
              _buildInfoRow(
                'Tipo più comune:',
                _getPlateauTypeDescription(statistics.mostCommonPlateauType!),
                colorScheme,
              ),

            // Suggerimento più comune
            if (statistics.mostCommonSuggestionType != null)
              _buildInfoRow(
                'Suggerimento più comune:',
                _getSuggestionTypeDescription(statistics.mostCommonSuggestionType!),
                colorScheme,
              ),

            // Media sessioni
            _buildInfoRow(
              'Media sessioni in plateau:',
              statistics.averageSessionsInPlateau.toStringAsFixed(1),
              colorScheme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Column(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 24.sp,
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _getPlateauTypeDescription(PlateauType type) {
    switch (type) {
      case PlateauType.lightWeight:
        return 'Peso Leggero';
      case PlateauType.heavyWeight:
        return 'Peso Pesante';
      case PlateauType.lowReps:
        return 'Poche Ripetizioni';
      case PlateauType.highReps:
        return 'Molte Ripetizioni';
      case PlateauType.moderate:
        return 'Valori Moderati';
    }
  }

  String _getSuggestionTypeDescription(SuggestionType type) {
    switch (type) {
      case SuggestionType.increaseWeight:
        return 'Aumenta Peso';
      case SuggestionType.increaseReps:
        return 'Aumenta Ripetizioni';
      case SuggestionType.advancedTechnique:
        return 'Tecniche Avanzate';
      case SuggestionType.reduceRest:
        return 'Riduci Recupero';
      case SuggestionType.changeTempo:
        return 'Cambia Tempo';
    }
  }
}