import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';



class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showBackButton;
  final bool showGymLogo; // Deprecato - ora sempre "FitGymTrack"
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
      title: Text(
        title, // Sempre mostra il titolo (FitGymTrack)
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
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

  // Metodi rimossi - ora il logo va nel banner di benvenuto

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}