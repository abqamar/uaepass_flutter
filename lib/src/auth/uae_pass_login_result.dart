import '../profile/uae_pass_profile.dart';
import 'uae_pass_access_token.dart';
import 'uae_pass_auth_result.dart';

class UaePassLoginResult {
  const UaePassLoginResult._({
    required this.status,
    this.authorizationCode,
    this.state,
    this.token,
    this.profile,
    this.error,
    this.errorDescription,
  });

  const UaePassLoginResult.success({
    required String authorizationCode,
    required String state,
    required UaePassAccessToken token,
    required UaePassProfile profile,
  }) : this._(
          status: UaePassAuthStatus.success,
          authorizationCode: authorizationCode,
          state: state,
          token: token,
          profile: profile,
        );

  const UaePassLoginResult.cancelled({
    String? error,
    String? errorDescription,
  }) : this._(
          status: UaePassAuthStatus.cancelled,
          error: error,
          errorDescription: errorDescription,
        );

  const UaePassLoginResult.failed({
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
  final UaePassAccessToken? token;
  final UaePassProfile? profile;
  final String? error;
  final String? errorDescription;

  bool get isSuccess => status == UaePassAuthStatus.success;
  bool get isCancelled => status == UaePassAuthStatus.cancelled;
  bool get isFailed => status == UaePassAuthStatus.failed;

  String? get accessToken => token?.accessToken;
}
