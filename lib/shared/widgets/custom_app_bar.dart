import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/config/app_config.dart';
import '../../core/di/dependency_injection.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/models/login_response.dart';
import '../../features/gym/services/gym_logo_service.dart';
import '../../features/gym/widgets/gym_logo_widget.dart';



class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showBackButton;
  final bool showGymLogo;
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.showBackButton = true,
    this.showGymLogo = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      title: showGymLogo 
        ? _buildGymLogoTitle(context)
        : Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface, // ✅ DINAMICO!
            ),
          ),
      centerTitle: centerTitle,
      backgroundColor: colorScheme.surface, // ✅ DINAMICO!
      surfaceTintColor: Colors.transparent, // ✅ RIMUOVE TINT
      elevation: 0,
      leading: leading ?? (showBackButton && Navigator.canPop(context)
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      )
          : null),
      actions: actions,
      iconTheme: IconThemeData(
        color: colorScheme.onSurface, // ✅ DINAMICO!
      ),
      actionsIconTheme: IconThemeData(
        color: colorScheme.onSurface, // ✅ DINAMICO!
      ),
    );
  }

  Widget _buildGymLogoTitle(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          return _buildLogoForAuthenticatedUser(context, authState.user);
        }
        
        // Fallback se non autenticato
        return Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        );
      },
    );
  }
  
  Widget _buildLogoForAuthenticatedUser(BuildContext context, User user) {
    final gymLogoService = getIt<GymLogoService>();
    
    // Verifica se l'utente dovrebbe mostrare un logo palestra
    if (!gymLogoService.shouldShowGymLogo(user)) {
      return Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      );
    }
    
    // Mostra logo con loading state
    return GymLogoWidgetWithLoading(
      gymLogoFuture: gymLogoService.getGymLogoForCurrentUser(user),
      width: 120.w,
      height: 32.h,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}