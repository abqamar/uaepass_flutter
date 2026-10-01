class UaePassException implements Exception {
  const UaePassException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => cause == null
      ? 'UaePassException: $message'
      : 'UaePassException: $message ($cause)';
}
