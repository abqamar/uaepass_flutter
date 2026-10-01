import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../uaepass_flutter.dart';
import '../auth/uae_pass_auth_page.dart';
import '../auth/uae_pass_logout_page.dart';
import 'uae_pass_web_session.dart';
import '../network/uae_pass_api_client.dart';

class UaePassFlutter {
  UaePassFlutter({
    required this.config,
    http.Client? httpClient,
  }) : _apiClient = UaePassApiClient(
          config: config,
          httpClient: httpClient,
        ) {
    config.validate();
  }

  final UaePassConfig config;
  final UaePassApiClient _apiClient;

  /// Full UAE PASS login flow:
  ///
  /// 1. Authorize user.
  /// 2. If UAE PASS app is installed, hand authentication to the app.
  /// 3. Otherwise remain in the embedded WebView.
  /// 4. Receive authorization code.
  /// 5. Exchange code for access token.
  /// 6. Retrieve the UAE PASS profile.
  Future<UaePassLoginResult> login(
    BuildContext context, {
    bool clearPreviousSession = true,
  }) async {
    try {
      config.validateForDirectTokenExchange();

      // =====================================================
      // IMPORTANT
      //
      // Every authentication should start from a known
      // WebView state.
      //
      // This prevents old OAuth sessions/callbacks/cookies
      // from interfering with the next login.
      // =====================================================

      if (clearPreviousSession) {
        await UaePassWebSession.clear(
          onLog: config.onLog,
        );
      }

      _log(
        'Starting fresh UAE PASS authentication.',
      );

      final authResult = await authorize(context);

      if (authResult.isCancelled) {
        return UaePassLoginResult.cancelled(
          error: authResult.error,
          errorDescription: authResult.errorDescription,
        );
      }

      if (!authResult.isSuccess || authResult.authorizationCode == null) {
        return UaePassLoginResult.failed(
          error: authResult.error ?? 'authorization_failed',
          errorDescription: authResult.errorDescription ?? 'UAE PASS authorization failed.',
        );
      }

      final token = await exchangeAuthorizationCode(
        authResult.authorizationCode!,
      );

      final profile = await getUserProfile(
        token.accessToken,
      );

      return UaePassLoginResult.success(
        authorizationCode: authResult.authorizationCode!,
        state: authResult.state!,
        token: token,
        profile: profile,
      );
    } on UaePassException catch (e) {
      _log(
        'Login failed: ${e.message}',
      );

      return UaePassLoginResult.failed(
        error: e.code ?? 'uaepass_error',
        errorDescription: e.message,
      );
    } catch (e) {
      _log(
        'Unexpected login error: $e',
      );

      return UaePassLoginResult.failed(
        error: 'unexpected_error',
        errorDescription: e.toString(),
      );
    }
  }

  Future<bool> logout(
    BuildContext context, {
    bool clearCookies = true,
  }) async {
    try {
      final logoutUri = Uri.parse(
        config.environment.logoutEndpoint,
      ).replace(
        queryParameters: {
          'redirect_uri': config.redirectUri,
        },
      );

      _log(
        'Starting UAE PASS logout.',
      );

      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          fullscreenDialog: true,
          builder: (_) => UaePassLogoutPage(
            logoutUrl: logoutUri.toString(),
            redirectUri: config.redirectUri,
            clearCookies: clearCookies,
            onLog: config.onLog,
          ),
        ),
      );

      if (result == true) {
        _log(
          'UAE PASS logout successful.',
        );

        return true;
      }

      _log(
        'UAE PASS logout cancelled.',
      );

      return false;
    } catch (e) {
      _log(
        'UAE PASS logout failed: $e',
      );

      return false;
    }
  }

  /// Authorization-only flow. Useful if an application later decides to move
  /// token exchange to its backend without changing the mobile handoff logic.
  Future<UaePassAuthResult> authorize(BuildContext context) async {
    config.validate();

    final result = await Navigator.of(context).push<UaePassAuthResult>(
      MaterialPageRoute<UaePassAuthResult>(
        fullscreenDialog: true,
        builder: (_) => UaePassAuthPage(config: config),
      ),
    );

    return result ?? const UaePassAuthResult.cancelled();
  }

  /// Backward-friendly alias for authorization-only behavior.
  Future<UaePassAuthResult> authenticate(BuildContext context) {
    return authorize(context);
  }

  Future<UaePassAccessToken> exchangeAuthorizationCode(
    String authorizationCode,
  ) {
    return _apiClient.exchangeAuthorizationCode(authorizationCode);
  }

  Future<UaePassProfile> getUserProfile(String accessToken) {
    return _apiClient.getUserProfile(accessToken);
  }

  void dispose() {
    _apiClient.dispose();
  }

  void _log(String message) {
    config.onLog?.call('[uaepass_flutter] $message');
  }
}
