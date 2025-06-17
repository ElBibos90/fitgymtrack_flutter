// lib/core/utils/result.dart


/// Pattern Result per gestire operazioni async in modo sicuro
/// Evita exceptions non gestite e fornisce un pattern consistente
class Result<T> {
  final T? _data;
  final Exception? _exception;
  final String? _message;
  final bool _isSuccess;

  const Result._({
    T? data,
    Exception? exception,
    String? message,
    required bool isSuccess,
  })  : _data = data,
        _exception = exception,
        _message = message,
        _isSuccess = isSuccess;

  /// Crea un Result di successo
  factory Result.success(T data) {
    return Result._(data: data, isSuccess: true);
  }

  /// Crea un Result di errore
  factory Result.error(String message, [Exception? exception]) {
    return Result._(
      message: message,
      exception: exception,
      isSuccess: false,
    );
  }

  /// Indica se l'operazione è andata a buon fine
  bool get isSuccess => _isSuccess;

  /// Indica se l'operazione è fallita
  bool get isFailure => !_isSuccess;

  /// I dati di successo (null se fallito)
  T? get data => _data;

  /// L'eccezione (null se successo)
  Exception? get exception => _exception;

  /// Il messaggio di errore (null se successo)
  String? get message => _message;

  /// Pattern matching per gestire successo/fallimento
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Exception? exception, String? message) onFailure,
  }) {
    if (_isSuccess && _data != null) {
      return onSuccess(_data as T);
    } else {
      return onFailure(_exception, _message);
    }
  }

  /// Trasforma i dati in caso di successo
  Result<R> map<R>(R Function(T data) transform) {
    if (_isSuccess && _data != null) {
      try {
        final transformedData = transform(_data as T);
        return Result.success(transformedData);
      } catch (e) {
        return Result.error(
          'Errore nella trasformazione dei dati: $e',
          e is Exception ? e : Exception(e.toString()),
        );
      }
    } else {
      return Result.error(_message ?? 'Operazione fallita', _exception);
    }
  }

  /// Concatena operazioni async in caso di successo
  Future<Result<R>> flatMap<R>(Future<Result<R>> Function(T data) transform) async {
    if (_isSuccess && _data != null) {
      try {
        return await transform(_data as T);
      } catch (e) {
        return Result.error(
          'Errore nella concatenazione: $e',
          e is Exception ? e : Exception(e.toString()),
        );
      }
    } else {
      return Result.error(_message ?? 'Operazione fallita', _exception);
    }
  }

  /// Helper per eseguire operazioni async con gestione errori automatica
  static Future<Result<T>> tryCallAsync<T>(Future<T> Function() operation) async {
    try {
      //print('[CONSOLE] [result]Executing async operation...');
      final result = await operation();
      //print('[CONSOLE] [result]Async operation completed successfully');
      return Result.success(result);
    } catch (e, stackTrace) {
      //print('[CONSOLE] [result]Async operation failed: $e');

      // Gestione di diversi tipi di eccezioni
      if (e is Exception) {
        return Result.error(e.toString(), e);
      } else {
        return Result.error(
          'Errore sconosciuto: $e',
          Exception(e.toString()),
        );
      }
    }
  }

  /// Helper per operazioni sincrone
  static Result<T> tryCall<T>(T Function() operation) {
    try {
      final result = operation();
      return Result.success(result);
    } catch (e) {
      //print('[CONSOLE] [result]Sync operation failed: $e');

      if (e is Exception) {
        return Result.error(e.toString(), e);
      } else {
        return Result.error(
          'Errore sconosciuto: $e',
          Exception(e.toString()),
        );
      }
    }
  }

  @override
  String toString() {
    if (_isSuccess) {
      return 'Result.success(data: $_data)';
    } else {
      return 'Result.error(message: $_message, exception: $_exception)';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Result<T> &&
        other._isSuccess == _isSuccess &&
        other._data == _data &&
        other._message == _message &&
        other._exception == _exception;
  }

  @override
  int get hashCode {
    return Object.hash(_isSuccess, _data, _message, _exception);
  }
}

/// Extension per Future<Result<T>> per operazioni più fluide
extension FutureResultExtensions<T> on Future<Result<T>> {
  /// Trasforma il risultato in caso di successo
  Future<Result<R>> mapAsync<R>(R Function(T data) transform) async {
    final result = await this;
    return result.map(transform);
  }

  /// Concatena operazioni async
  Future<Result<R>> flatMapAsync<R>(Future<Result<R>> Function(T data) transform) async {
    final result = await this;
    return result.flatMap(transform);
  }

  /// Gestisce il risultato con callbacks
  Future<R> foldAsync<R>({
    required R Function(T data) onSuccess,
    required R Function(Exception? exception, String? message) onFailure,
  }) async {
    final result = await this;
    return result.fold(onSuccess: onSuccess, onFailure: onFailure);
  }
}