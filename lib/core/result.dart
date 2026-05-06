/// Generic sealed class for handling operations that can succeed or fail.
/// Enforces safe error handling without throwing uncaught exceptions.
sealed class Result<T, E extends Exception> {
  const Result();

  /// Transform the result using pattern matching or fold
  R fold<R>(
    R Function(T value) onSuccess,
    R Function(E exception) onFailure,
  ) {
    return switch (this) {
      Success<T, E>(:final value) => onSuccess(value),
      Failure<T, E>(:final exception) => onFailure(exception),
    };
  }
}

/// Represents a successful operation containing a value of type [T].
final class Success<T, E extends Exception> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

/// Represents a failed operation containing an exception of type [E].
final class Failure<T, E extends Exception> extends Result<T, E> {
  final E exception;
  const Failure(this.exception);
}
