enum UaePassAuthStatus {
  success,
  cancelled,
  failed,
}

class UaePassAuthResult {
  const UaePassAuthResult._({
    required this.status,
    this.authorizationCode,
    this.state,
    this.error,
    this.errorDescription,
  });

  const UaePassAuthResult.success({
    required String authorizationCode,
    required String state,
  }) : this._(
          status: UaePassAuthStatus.success,
          authorizationCode: authorizationCode,
          state: state,
        );

  const UaePassAuthResult.cancelled({
    String? error,
    String? errorDescription,
  }) : this._(
          status: UaePassAuthStatus.cancelled,
          error: error,
          errorDescription: errorDescription,
        );

  const UaePassAuthResult.failed({
    String? error,
    String? errorDescription,
  }) : this._(
          status: UaePassAuthStatus.failed,
          error: error,
          errorDescription: errorDescription,
        );

  final UaePassAuthStatus status;
  final String? authorizationCode;
  final String? state;
  final String? error;
  final String? errorDescription;

  bool get isSuccess => status == UaePassAuthStatus.success;
  bool get isCancelled => status == UaePassAuthStatus.cancelled;
}
