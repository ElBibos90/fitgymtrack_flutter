// lib/shared/widgets/muscle_badge.dart

import 'package:flutter/material.dart';
import '../../features/exercises/models/muscle_group.dart';
import '../../features/exercises/models/secondary_muscle.dart';

/// 🎯 Widget per visualizzare badge dei muscoli (primario + secondari)
/// 
/// Esempio uso:
/// ```dart
/// MuscleBadge(
///   primaryMuscle: MuscleGroup(id: 1, name: 'Quadricipiti', parentCategory: 'Gambe'),
///   secondaryMuscles: [
///     SecondaryMuscle(id: 2, name: 'Glutei', activationLevel: 'high'),
///     SecondaryMuscle(id: 3, name: 'Femorali', activationLevel: 'medium'),
///   ],
/// )
/// ```
class MuscleBadge extends StatelessWidget {
  final MuscleGroup? primaryMuscle;
  final List<SecondaryMuscle>? secondaryMuscles;
  final bool compact; // Se true, mostra versione compatta
  final bool showActivationLevel; // Se true, mostra livello attivazione
  final double maxWidth; // Larghezza massima del widget

  const MuscleBadge({
    super.key,
    this.primaryMuscle,
    this.secondaryMuscles,
    this.compact = false,
    this.showActivationLevel = true,
    this.maxWidth = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    if (primaryMuscle == null && (secondaryMuscles == null || secondaryMuscles!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: compact ? _buildCompactView(context) : _buildExpandedView(context),
    );
  }

  /// Versione compatta: un'unica riga con badge piccoli
  Widget _buildCompactView(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (primaryMuscle != null)
          _buildPrimaryBadge(context, primaryMuscle!, compact: true),
        
        if (secondaryMuscles != null && secondaryMuscles!.isNotEmpty)
          ...secondaryMuscles!.map((muscle) => 
            _buildSecondaryBadge(context, muscle, compact: true)
          ),
      ],
    );
  }

  /// Versione espansa: badge primario più grande, secondari sotto
  Widget _buildExpandedView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge primario
        if (primaryMuscle != null) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center,
                size: 14,
                color: _getCategoryColor(primaryMuscle!.parentCategory),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: _buildPrimaryBadge(context, primaryMuscle!, compact: false),
              ),
            ],
          ),
          if (secondaryMuscles != null && secondaryMuscles!.isNotEmpty)
            const SizedBox(height: 6),
        ],

        // Badge secondari
        if (secondaryMuscles != null && secondaryMuscles!.isNotEmpty)
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: secondaryMuscles!.map((muscle) => 
              _buildSecondaryBadge(context, muscle, compact: false)
            ).toList(),
          ),
      ],
    );
  }

  /// Badge per muscolo primario
  Widget _buildPrimaryBadge(BuildContext context, MuscleGroup muscle, {required bool compact}) {
    final color = _getCategoryColor(muscle.parentCategory);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(
          color: color,
          width: compact ? 1 : 1.5,
        ),
      ),
      child: Text(
        muscle.name,
        style: TextStyle(
          fontSize: compact ? 11 : 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Badge per muscolo secondario
  Widget _buildSecondaryBadge(BuildContext context, SecondaryMuscle muscle, {required bool compact}) {
    final color = _getActivationColor(muscle.activationLevel);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 6,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+ ',
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
          Text(
            muscle.name,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.9),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (showActivationLevel && !compact) ...[
            const SizedBox(width: 3),
            Text(
              '(${_getActivationLabel(muscle.activationLevel)})',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Ottiene il colore in base alla categoria muscolare
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'gambe':
        return Colors.blue;
      case 'petto':
        return Colors.red;
      case 'schiena':
        return Colors.green;
      case 'spalle':
        return Colors.orange;
      case 'braccia':
        return Colors.purple;
      case 'core':
        return Colors.teal;
      case 'cardio':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  /// Ottiene il colore in base al livello di attivazione
  Color _getActivationColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return Colors.red.shade700;
      case 'medium':
        return Colors.orange.shade700;
      case 'low':
        return Colors.grey.shade600;
      default:
        return Colors.grey;
    }
  }

  /// Ottiene l'etichetta abbreviata per il livello di attivazione
  String _getActivationLabel(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return 'A'; // Alta
      case 'medium':
        return 'M'; // Media
      case 'low':
        return 'B'; // Bassa
      default:
        return '?';
    }
  }
}

/// Widget semplificato per mostrare solo il nome del muscolo primario
/// (fallback quando il nuovo sistema non è disponibile)
class SimpleMuscleText extends StatelessWidget {
  final String muscleName;
  final bool showIcon;

  const SimpleMuscleText({
    super.key,
    required this.muscleName,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          const Icon(Icons.fitness_center, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
        ],
        Text(
          muscleName,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}


