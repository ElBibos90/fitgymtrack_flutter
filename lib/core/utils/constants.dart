class AppConstants {
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String resetPasswordRoute = '/reset-password';
  static const String dashboardRoute = '/dashboard';
  static const String profileRoute = '/profile';
  static const String workoutsRoute = '/workouts';
  static const String statsRoute = '/stats';

  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';

  static const String isFirstLaunchKey = 'is_first_launch';
  static const String selectedThemeKey = 'selected_theme';
  static const String lastSyncKey = 'last_sync';

  static const String networkErrorCode = 'NETWORK_ERROR';
  static const String authErrorCode = 'AUTH_ERROR';
  static const String validationErrorCode = 'VALIDATION_ERROR';
  static const String serverErrorCode = 'SERVER_ERROR';

  static const int maxExercisesPerWorkout = 20;
  static const int maxSetsPerExercise = 10;
  static const double minWeight = 0.5;
  static const double maxWeight = 500.0;
  static const int minReps = 1;
  static const int maxReps = 100;

  static const int maxSnackbarLines = 3;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  static const String emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
  static const String usernamePattern = r'^[a-zA-Z0-9_]+$';
  static const String namePattern = r'^[a-zA-ZÀ-ÿ\s\';
}