import 'package:flutter/material.dart';
import '../config/app_config.dart';

extension ContextExtensions on BuildContext {
  // ============================================================================
  // THEME SHORTCUTS
  // ============================================================================

  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  // ============================================================================
  // MEDIA QUERY SHORTCUTS
  // ============================================================================

  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => MediaQuery.of(this).size;
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  EdgeInsets get padding => MediaQuery.of(this).padding;
  EdgeInsets get viewInsets => MediaQuery.of(this).viewInsets;

  // ============================================================================
  // RESPONSIVE HELPERS
  // ============================================================================

  bool get isMobile => AppConfig.isMobile(this);
  bool get isTablet => AppConfig.isTablet(this);
  bool get isDesktop => AppConfig.isDesktop(this);

  EdgeInsets get responsivePadding => AppConfig.getResponsivePadding(this);

  // ============================================================================
  // NAVIGATION SHORTCUTS
  // ============================================================================

  NavigatorState get navigator => Navigator.of(this);

  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  Future<T?> push<T>(Route<T> route) => Navigator.of(this).push(route);

  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      Navigator.of(this).pushNamed(routeName, arguments: arguments);

  Future<T?> pushReplacementNamed<T, TO>(String routeName, {Object? arguments}) =>
      Navigator.of(this).pushReplacementNamed(routeName, arguments: arguments);

  // ============================================================================
  // SNACKBAR HELPERS
  // ============================================================================

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void hideSnackBar() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }

  // ============================================================================
  // DIALOG HELPERS
  // ============================================================================

  Future<T?> showCustomDialog<T>(Widget dialog) {
    return showDialog<T>(
      context: this,
      builder: (_) => dialog,
    );
  }

  Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String confirmText = 'Conferma',
    String cancelText = 'Annulla',
  }) {
    return showDialog<bool>(
      context: this,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(this).pop(false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.of(this).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}