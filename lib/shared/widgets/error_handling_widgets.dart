// lib/shared/widgets/error_handling_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/app_colors.dart';

/// Tipi di errori gestiti
enum ErrorType {
  network,
  server,
  timeout,
  unauthorized,
  notFound,
  unknown,
}

/// Widget per gestire stati di errore con retry
class ErrorStateWidget extends StatelessWidget {
  final ErrorType errorType;
  final String? message;
  final String? title;
  final VoidCallback? onRetry;
  final Widget? icon;
  final bool showRetryButton;
  final String? retryButtonText;
  final EdgeInsets? padding;

  const ErrorStateWidget({
    super.key,
    required this.errorType,
    this.message,
    this.title,
    this.onRetry,
    this.icon,
    this.showRetryButton = true,
    this.retryButtonText,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final errorInfo = _getErrorInfo();

    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.all(20.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: errorInfo.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40.r),
            ),
            child: icon ?? Icon(
              errorInfo.icon,
              size: 40.sp,
              color: errorInfo.color,
            ),
          ),

          SizedBox(height: 20.h),

          // Title
          Text(
            title ?? errorInfo.title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8.h),

          // Message
          Text(
            message ?? errorInfo.message,
            style: TextStyle(
              fontSize: 14.sp,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          if (showRetryButton && onRetry != null) ...[
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh, size: 20.sp),
                label: Text(
                  retryButtonText ?? 'Riprova',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorInfo.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _ErrorInfo _getErrorInfo() {
    switch (errorType) {
      case ErrorType.network:
        return _ErrorInfo(
          icon: Icons.wifi_off,
          title: 'Nessuna Connessione',
          message: 'Controlla la tua connessione internet e riprova.',
          color: Colors.orange,
        );
      case ErrorType.server:
        return _ErrorInfo(
          icon: Icons.dns,
          title: 'Errore del Server',
          message: 'Il server è temporaneamente non disponibile.\nRiprova tra qualche minuto.',
          color: Colors.red,
        );
      case ErrorType.timeout:
        return _ErrorInfo(
          icon: Icons.access_time,
          title: 'Timeout',
          message: 'La richiesta sta impiegando troppo tempo.\nControllare la connessione.',
          color: Colors.amber,
        );
      case ErrorType.unauthorized:
        return _ErrorInfo(
          icon: Icons.lock_outline,
          title: 'Accesso Negato',
          message: 'Non hai i permessi per accedere a questa risorsa.\nEffettua nuovamente il login.',
          color: Colors.purple,
        );
      case ErrorType.notFound:
        return _ErrorInfo(
          icon: Icons.search_off,
          title: 'Non Trovato',
          message: 'La risorsa richiesta non è stata trovata.',
          color: Colors.blue,
        );
      case ErrorType.unknown:
      default:
        return _ErrorInfo(
          icon: Icons.error_outline,
          title: 'Qualcosa è Andato Storto',
          message: 'Si è verificato un errore imprevisto.\nRiprova o contatta il supporto.',
          color: Colors.grey,
        );
    }
  }
}

class _ErrorInfo {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _ErrorInfo({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });
}

/// Widget per errori compatti (inline)
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  final Color? color;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final errorColor = color ?? Colors.red;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: errorColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.error_outline,
            color: errorColor,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.sp,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  'Riprova',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Snackbar personalizzata per errori
class ErrorSnackbar {
  static void show(
      BuildContext context, {
        required String message,
        ErrorType errorType = ErrorType.unknown,
        VoidCallback? onRetry,
        Duration duration = const Duration(seconds: 4),
      }) {
    final errorInfo = _getErrorInfoForSnackbar(errorType);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              errorInfo.icon,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: errorInfo.color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        action: onRetry != null
            ? SnackBarAction(
          label: 'Riprova',
          textColor: Colors.white,
          onPressed: onRetry,
        )
            : null,
      ),
    );
  }

  static _ErrorInfo _getErrorInfoForSnackbar(ErrorType errorType) {
    switch (errorType) {
      case ErrorType.network:
        return _ErrorInfo(
          icon: Icons.wifi_off,
          title: 'Errore di Rete',
          message: 'Connessione non disponibile',
          color: Colors.orange.shade700,
        );
      case ErrorType.server:
        return _ErrorInfo(
          icon: Icons.dns,
          title: 'Errore Server',
          message: 'Server non disponibile',
          color: Colors.red.shade700,
        );
      case ErrorType.timeout:
        return _ErrorInfo(
          icon: Icons.access_time,
          title: 'Timeout',
          message: 'Richiesta scaduta',
          color: Colors.amber.shade700,
        );
      default:
        return _ErrorInfo(
          icon: Icons.error,
          title: 'Errore',
          message: 'Qualcosa è andato storto',
          color: Colors.grey.shade700,
        );
    }
  }
}

/// Widget per gestire stati di caricamento con errori
class AsyncStateWidget<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Widget Function(T data) dataBuilder;
  final Widget? loadingWidget;
  final Widget Function(Object error)? errorBuilder;
  final VoidCallback? onRetry;
  final String? emptyMessage;

  const AsyncStateWidget({
    super.key,
    required this.snapshot,
    required this.dataBuilder,
    this.loadingWidget,
    this.errorBuilder,
    this.onRetry,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return errorBuilder?.call(snapshot.error!) ??
          ErrorStateWidget(
            errorType: _determineErrorType(snapshot.error!),
            message: snapshot.error.toString(),
            onRetry: onRetry,
          );
    }

    if (!snapshot.hasData) {
      return Center(
        child: Text(
          emptyMessage ?? 'Nessun dato disponibile',
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return dataBuilder(snapshot.data!);
  }

  ErrorType _determineErrorType(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || errorString.contains('socket')) {
      return ErrorType.network;
    }
    if (errorString.contains('timeout')) {
      return ErrorType.timeout;
    }
    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return ErrorType.unauthorized;
    }
    if (errorString.contains('404') || errorString.contains('not found')) {
      return ErrorType.notFound;
    }
    if (errorString.contains('500') || errorString.contains('server')) {
      return ErrorType.server;
    }

    return ErrorType.unknown;
  }
}

/// Wrapper per gestire stati di loading/error in BLoC
class BlocStateHandler<T> extends StatelessWidget {
  final T state;
  final Widget Function() loadingBuilder;
  final Widget Function() successBuilder;
  final Widget Function(String error) errorBuilder;
  final bool Function(T state) isLoading;
  final bool Function(T state) isSuccess;
  final bool Function(T state) isError;
  final String Function(T state)? getErrorMessage;

  const BlocStateHandler({
    super.key,
    required this.state,
    required this.loadingBuilder,
    required this.successBuilder,
    required this.errorBuilder,
    required this.isLoading,
    required this.isSuccess,
    required this.isError,
    this.getErrorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading(state)) {
      return loadingBuilder();
    }

    if (isError(state)) {
      final errorMessage = getErrorMessage?.call(state) ?? 'Errore sconosciuto';
      return errorBuilder(errorMessage);
    }

    if (isSuccess(state)) {
      return successBuilder();
    }

    // Fallback per stati non gestiti
    return const SizedBox.shrink();
  }
}

/// Utility per gestire errori di rete comuni
class NetworkErrorHandler {
  static ErrorType getErrorTypeFromException(Object error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('socketerror') ||
        errorString.contains('network is unreachable') ||
        errorString.contains('no internet')) {
      return ErrorType.network;
    }

    if (errorString.contains('timeout') ||
        errorString.contains('deadline exceeded')) {
      return ErrorType.timeout;
    }

    if (errorString.contains('401') ||
        errorString.contains('unauthorized')) {
      return ErrorType.unauthorized;
    }

    if (errorString.contains('404') ||
        errorString.contains('not found')) {
      return ErrorType.notFound;
    }

    if (errorString.contains('500') ||
        errorString.contains('internal server error') ||
        errorString.contains('bad gateway')) {
      return ErrorType.server;
    }

    return ErrorType.unknown;
  }

  static String getReadableMessage(Object error) {
    final errorString = error.toString().toLowerCase();

    // FIX: Gestisci errori DioException specifici
    if (errorString.contains('dioexception')) {
      if (errorString.contains('bad response')) {
        if (errorString.contains('404') || errorString.contains('not found')) {
          return 'Nessun dato disponibile al momento.';
        }
        if (errorString.contains('500') || errorString.contains('internal server')) {
          return 'Problemi del server. Riprova tra un momento.';
        }
        if (errorString.contains('401') || errorString.contains('unauthorized')) {
          return 'Sessione scaduta. Rieffettua il login.';
        }
        return 'Errore di connessione. Controlla la rete e riprova.';
      }
      if (errorString.contains('connection')) {
        return 'Problemi di connessione. Controlla la tua rete.';
      }
      if (errorString.contains('timeout')) {
        return 'La richiesta sta impiegando troppo tempo.';
      }
    }

    // Gestione errori standard
    final errorType = getErrorTypeFromException(error);

    switch (errorType) {
      case ErrorType.network:
        return 'Problemi di connessione. Controlla la tua rete.';
      case ErrorType.timeout:
        return 'La richiesta sta impiegando troppo tempo.';
      case ErrorType.unauthorized:
        return 'Devi effettuare nuovamente il login.';
      case ErrorType.notFound:
        return 'Nessun allenamento trovato. Inizia il tuo primo workout!';
      case ErrorType.server:
        return 'Problemi del server. Riprova più tardi.';
      case ErrorType.unknown:
      default:
        return 'Errore temporaneo. Riprova tra un momento.';
    }
  }
}