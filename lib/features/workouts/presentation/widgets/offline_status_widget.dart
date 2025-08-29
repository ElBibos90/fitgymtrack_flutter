// lib/features/workouts/presentation/widgets/offline_status_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/active_workout_bloc.dart';

/// 🚀 Widget per mostrare lo stato offline e permettere la sincronizzazione
class OfflineStatusWidget extends StatefulWidget {
  const OfflineStatusWidget({super.key});

  @override
  State<OfflineStatusWidget> createState() => _OfflineStatusWidgetState();
}

class _OfflineStatusWidgetState extends State<OfflineStatusWidget> {
  Map<String, dynamic>? _offlineStats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOfflineStats();
  }

  Future<void> _loadOfflineStats() async {
    try {
      final bloc = context.read<ActiveWorkoutBloc>();
      final stats = await bloc.getOfflineStats();
      setState(() {
        _offlineStats = stats;
      });
    } catch (e) {
      // Ignora errori nel caricamento delle statistiche
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ActiveWorkoutBloc, ActiveWorkoutState>(
      listener: (context, state) {
        if (state is OfflineSyncInProgress) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is WorkoutSessionActive || state is ActiveWorkoutInitial) {
          setState(() {
            _isLoading = false;
          });
          _loadOfflineStats();
        }
      },
      child: BlocBuilder<ActiveWorkoutBloc, ActiveWorkoutState>(
        builder: (context, state) {
          // Mostra solo se ci sono dati offline o se siamo in modalità offline
          final bloc = context.read<ActiveWorkoutBloc>();
          final hasOfflineData = _offlineStats?['pending_series_count'] != null && 
                                _offlineStats!['pending_series_count'] > 0;
          final isOfflineMode = bloc.isOfflineMode;

          if (!hasOfflineData && !isOfflineMode) {
            return const SizedBox.shrink();
          }

          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOfflineMode ? Colors.orange.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOfflineMode ? Colors.orange.shade300 : Colors.blue.shade300,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      isOfflineMode ? Icons.wifi_off : Icons.cloud_upload,
                      color: isOfflineMode ? Colors.orange.shade700 : Colors.blue.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOfflineMode 
                          ? 'Modalità offline attiva'
                          : 'Dati in attesa di sincronizzazione',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isOfflineMode ? Colors.orange.shade700 : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_offlineStats != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Serie in attesa: ${_offlineStats!['pending_series_count']}',
                    style: TextStyle(
                      color: isOfflineMode ? Colors.orange.shade600 : Colors.blue.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (!isOfflineMode && hasOfflineData) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () {
                        context.read<ActiveWorkoutBloc>().syncOfflineData();
                      },
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync, size: 16),
                      label: Text(_isLoading ? 'Sincronizzazione...' : 'Sincronizza ora'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
