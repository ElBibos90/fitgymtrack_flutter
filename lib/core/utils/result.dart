// lib/core/utils/result.dart

/// Result pattern simile a quello di Kotlin per gestire successo/errore
/// Usato nei repository per wrappare le risposte API
sealed class Result<T> {
  const Result();

  /// Crea un Result di successo
  static Result<T> success<T>(T data) => Success(data);

  /// Crea un Result di errore
  static Result<T> failure<T>(Exception exception, {String? message}) =>
      Failure(exception, message: message);

  /// Crea un Result da una funzione che può lanciare eccezioni
  static Result<T> tryCall<T>(T Function() operation) {
    try {
      return Success(operation());
    } catch (e) {
      return Failure(
        e is Exception ? e : Exception(e.toString()),
        message: e.toString(),
      );
    }
  }

  /// Crea un Result asincrono da una Future che può lanciare eccezioni
  static Future<Result<T>> tryCallAsync<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      return Success(result);
    } catch (e) {
      return Failure(
        e is Exception ? e : Exception(e.toString()),
        message: e.toString(),
      );
    }
  }
}

/// Rappresenta un risultato di successo
final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Rappresenta un risultato di errore
final class Failure<T> extends Result<T> {
  const Failure(this.exception, {this.message});

  final Exception exception;
  final String? message;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure<T> &&
        other.exception == exception &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(exception, message);

  @override
  String toString() => 'Failure($exception${message != null ? ', $message' : ''})';
}

/// Estensioni per il Result pattern
extension ResultExtensions<T> on Result<T> {
  /// Restituisce true se il risultato è un successo
  bool get isSuccess => this is Success<T>;

  /// Restituisce true se il risultato è un errore
  bool get isFailure => this is Failure<T>;

  /// Restituisce i dati se il risultato è un successo, null altrimenti
  T? get dataOrNull => switch (this) {
    Success<T>(data: final data) => data,
    Failure<T>() => null,
  };

  /// Restituisce l'eccezione se il risultato è un errore, null altrimenti
  Exception? get exceptionOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(exception: final exception) => exception,
  };

  /// Fold pattern - esegue onSuccess o onFailure in base al risultato
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Exception exception, String? message) onFailure,
  }) {
    return switch (this) {
      Success<T>(data: final data) => onSuccess(data),
      Failure<T>(exception: final exception, message: final message) => onFailure(exception, message),
    };
  }

  /// Map - trasforma i dati se il risultato è un successo
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final data) => Success(transform(data)),
      Failure<T>(exception: final exception, message: final message) => Failure(exception, message: message),
    };
  }

  /// FlatMap - trasforma i dati e può restituire un altro Result
  Result<R> flatMap<R>(Result<R> Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final data) => transform(data),
      Failure<T>(exception: final exception, message: final message) => Failure(exception, message: message),
    };
  }

  /// GetOrElse - restituisce i dati o un valore di default
  T getOrElse(T defaultValue) {
    return switch (this) {
      Success<T>(data: final data) => data,
      Failure<T>() => defaultValue,
    };
  }

  /// GetOrThrow - restituisce i dati o lancia l'eccezione
  T getOrThrow() {
    return switch (this) {
      Success<T>(data: final data) => data,
      Failure<T>(exception: final exception) => throw exception,
    };
  }
}