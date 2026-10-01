class UaePassException implements Exception {
  const UaePassException(
    this.message, {
    this.code,
    this.statusCode,
    this.cause,
  });

  final String message;
  final String? code;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() {
    final parts = <String>['UaePassException'];
    if (code != null && code!.isNotEmpty) parts.add('[$code]');
    parts.add(message);
    if (statusCode != null) parts.add('(HTTP $statusCode)');
    return parts.join(' ');
  }
}
