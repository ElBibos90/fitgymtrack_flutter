import 'package:flutter/material.dart';

class WearActiveWorkoutScreen extends StatelessWidget {
  final String exerciseName;
  final int currentExerciseIndex;
  final int totalExercises;
  final Duration elapsedTime;
  final bool isPaused;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onPausePlay;
  final VoidCallback onStop;

  const WearActiveWorkoutScreen({
    Key? key,
    required this.exerciseName,
    required this.currentExerciseIndex,
    required this.totalExercises,
    required this.elapsedTime,
    required this.isPaused,
    required this.onNext,
    required this.onPrevious,
    required this.onPausePlay,
    required this.onStop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = totalExercises > 0 ? (currentExerciseIndex + 1) / totalExercises : 0.0;
    final timeStr = _formatDuration(elapsedTime);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                timeStr,
                style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                exerciseName,
                style: const TextStyle(fontSize: 18, color: Colors.white),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${currentExerciseIndex + 1}/$totalExercises esercizi',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                minHeight: 6,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                    onPressed: onPrevious,
                  ),
                  IconButton(
                    icon: Icon(
                      isPaused ? Icons.play_arrow : Icons.pause,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: onPausePlay,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 32),
                    onPressed: onNext,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
                icon: const Icon(Icons.stop),
                label: const Text('Stop'),
                onPressed: onStop,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    final hours = d.inHours > 0 ? '${twoDigits(d.inHours)}:' : '';
    return '${d.inHours > 0 ? twoDigits(d.inHours) + ':' : ''}$minutes:$seconds';
  }
} 