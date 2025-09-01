import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';

class AuthWrapper extends StatelessWidget {
  final Widget authenticatedChild;
  final Widget unauthenticatedChild;

  const AuthWrapper({
    super.key,
    required this.authenticatedChild,
    required this.unauthenticatedChild,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // 🔧 FIX: Gestione completa di tutti gli stati di autenticazione
        
        // 1. Stati autenticati - mostra il contenuto autenticato
        if (state is AuthAuthenticated || state is AuthLoginSuccess) {
          return authenticatedChild;
        }
        
        // 2. Stato di allenamento in sospeso - mostra SOLO il contenuto autenticato
        // Il dialogo verrà gestito SOLO nella homepage per evitare duplicati
        if (state is PendingWorkoutPrompt) {
          return authenticatedChild;
        }
        
        // 3. Stato iniziale - mostra il contenuto autenticato (utente già loggato)
        if (state is AuthInitial) {
          return authenticatedChild;
        }
        
        // 4. Altri stati (loading, error, etc.) - mostra il contenuto autenticato se disponibile
        // Questo evita di mostrare la login page quando non necessario
        if (state is AuthLoading || state is AuthError) {
          // Se siamo in loading o error, prova a mostrare il contenuto autenticato
          // per evitare di mostrare la login page inappropriatamente
          return authenticatedChild;
        }
        
        // 5. Stato non autenticato - mostra la login page
        return unauthenticatedChild;
      },
    );
  }

}

