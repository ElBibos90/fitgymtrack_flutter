// lib/test/simple_workout_test_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/dependency_injection.dart';
import '../core/services/session_service.dart';
import '../features/workouts/bloc/active_workout_bloc.dart';
import '../features/workouts/bloc/workout_bloc.dart';
import '../features/subscription/bloc/subscription_bloc.dart';
import '../features/workouts/presentation/screens/bloc_active_workout_screen.dart';

/// Schermata semplificata per testare funzionalità con repository reali
class SimpleWorkoutTestScreen extends StatefulWidget {
  const SimpleWorkoutTestScreen({super.key});

  @override
  State<SimpleWorkoutTestScreen> createState() => _SimpleWorkoutTestScreenState();
}

class _SimpleWorkoutTestScreenState extends State<SimpleWorkoutTestScreen> {
  bool _isLoading = false;
  String _statusMessage = "Ready to test real repositories";
  final List<String> _testResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Test Repository Reali',
          style: TextStyle(fontSize: 18.sp),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.science,
                          color: Colors.blue[600],
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Test Mode: Repository Reali',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.blue[700],
                      ),
                    ),
                    if (_isLoading) ...[
                      SizedBox(height: 12.h),
                      LinearProgressIndicator(
                        backgroundColor: Colors.blue[100],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Test buttons
              Text(
                'Tests Disponibili:',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),

              SizedBox(height: 16.h),

              // Workout Plans Test
              _buildTestButton(
                title: 'Test Caricamento Schede',
                description: 'Carica le schede reali dell\'utente',
                icon: Icons.fitness_center,
                color: Colors.green,
                onPressed: _testWorkoutPlans,
              ),

              SizedBox(height: 12.h),

              // Subscription Test
              _buildTestButton(
                title: 'Test Abbonamento',
                description: 'Verifica stato abbonamento reale',
                icon: Icons.card_membership,
                color: Colors.purple,
                onPressed: _testSubscription,
              ),

              SizedBox(height: 12.h),

              // BLoC Active Workout Test
              _buildTestButton(
                title: 'Test BLoC Allenamento',
                description: 'Apri schermata test BLoC reale',
                icon: Icons.play_circle,
                color: Colors.orange,
                onPressed: _testBlocActiveWorkout,
              ),

              SizedBox(height: 20.h),

              // Test results
              if (_testResults.isNotEmpty) ...[
                Text(
                  'Risultati Test:',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8.h),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ListView.builder(
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 2.h),
                          child: Text(
                            '${index + 1}. ${_testResults[index]}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[700],
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.all(16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white.withValues(alpha:0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16.sp),
          ],
        ),
      ),
    );
  }

  Future<void> _testWorkoutPlans() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Testing real workout plans...";
    });

    try {
      _addTestResult("Iniziando test caricamento schede reali...");

      // 🔧 FIX: Ottieni userId dalla sessione
      final sessionService = getIt.get<SessionService>();
      final userId = await sessionService.getCurrentUserId();

      if (userId == null) {
        _addTestResult("ERRORE: Utente non loggato");
        setState(() {
          _statusMessage = "Errore: Utente non loggato";
        });
        return;
      }

      _addTestResult("UserId ottenuto: $userId");

      // Usa il WorkoutBloc per caricare le schede
      final workoutBloc = context.read<WorkoutBloc>();

      // 🔧 FIX: Trigger caricamento con userId
      workoutBloc.loadWorkoutPlans(userId);
      _addTestResult("Comando caricamento inviato al WorkoutBloc per utente $userId");

      // Simula un po' di attesa per vedere il risultato
      await Future.delayed(const Duration(seconds: 2));

      _addTestResult("Test completato - controlla la schermata Allenamenti per i risultati");

      setState(() {
        _statusMessage = "Test schede completato";
      });

    } catch (e) {
      _addTestResult("ERRORE: $e");
      setState(() {
        _statusMessage = "Test fallito: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testSubscription() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Testing real subscription...";
    });

    try {
      _addTestResult("Iniziando test abbonamento reale...");

      // Usa il SubscriptionBloc per caricare l'abbonamento
      final subscriptionBloc = context.read<SubscriptionBloc>();

      // Trigger caricamento
      subscriptionBloc.add(const LoadSubscriptionEvent());
      _addTestResult("Comando caricamento inviato al SubscriptionBloc");

      await Future.delayed(const Duration(seconds: 2));

      _addTestResult("Test completato - controlla la schermata Abbonamento per i risultati");

      setState(() {
        _statusMessage = "Test abbonamento completato";
      });

    } catch (e) {
      _addTestResult("ERRORE: $e");
      setState(() {
        _statusMessage = "Test fallito: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testBlocActiveWorkout() async {
    setState(() {
      _statusMessage = "Aprendo test BLoC allenamento...";
    });

    try {
      _addTestResult("Aprendo schermata test BLoC con repository reali...");

      // Naviga alla schermata di test BLoC
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BlocProvider.value(
            value: getIt<ActiveWorkoutBloc>(),
            child: const BlocActiveWorkoutScreen(schedaId: 1),
          ),
        ),
      );

      _addTestResult("Schermata test BLoC aperta");

    } catch (e) {
      _addTestResult("ERRORE nell'aprire test BLoC: $e");
      setState(() {
        _statusMessage = "Errore nell'aprire test BLoC";
      });
    }
  }

  void _addTestResult(String result) {
    setState(() {
      _testResults.add("${DateTime.now().toLocal().toString().substring(11, 19)} - $result");
    });
  }
}