import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/uae_pass_access_token.dart';
import '../core/uae_pass_config.dart';
import '../core/uae_pass_environment.dart';
import '../core/uae_pass_exception.dart';
import '../profile/uae_pass_profile.dart';

class UaePassApiClient {
  UaePassApiClient({
    required this.config,
    http.Client? httpClient,
  })  : _httpClient = httpClient ?? http.Client(),
        _ownsClient = httpClient == null;

  final UaePassConfig config;
  final http.Client _httpClient;
  final bool _ownsClient;

  Future<UaePassAccessToken> exchangeAuthorizationCode(
    String authorizationCode,
  ) async {
    config.validateForDirectTokenExchange();

    if (authorizationCode.trim().isEmpty) {
      throw const UaePassException(
        'Authorization code cannot be empty.',
        code: 'missing_authorization_code',
      );
    }

    final uri = Uri.parse(config.environment.tokenEndpoint).replace(
      queryParameters: <String, String>{
        'grant_type': 'authorization_code',
        'redirect_uri': config.redirectUri,
        'code': authorizationCode,
      },
    );

    final basicCredentials = base64Encode(
      utf8.encode('${config.clientId}:${config.clientSecret!}'),
    );

    _log('Exchanging authorization code for access token.');

    try {
      // UAE PASS currently documents the token call as POST with query
      // parameters, HTTP Basic authentication, and multipart/form-data.
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(<String, String>{
          'Authorization': 'Basic $basicCredentials',
          'Accept': 'application/json',
        });

      final streamed =
          await _httpClient.send(request).timeout(config.networkTimeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(config.networkTimeout);

      final json = _decodeJsonObject(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _serverException(
          response.statusCode,
          json,
          fallbackMessage: 'UAE PASS token request failed.',
        );
      }

      final token = UaePassAccessToken.fromJson(json);
      _log('Access token received successfully.');
      return token;
    } on TimeoutException catch (e) {
      throw UaePassException(
        'UAE PASS token request timed out.',
        code: 'token_timeout',
        cause: e,
      );
    } on UaePassException {
      rethrow;
    } catch (e) {
      throw UaePassException(
        'Unable to obtain UAE PASS access token.',
        code: 'token_request_failed',
        cause: e,
      );
    }
  }

  Future<UaePassProfile> getUserProfile(String accessToken) async {
    if (accessToken.trim().isEmpty) {
      throw const UaePassException(
        'Access token cannot be empty.',
        code: 'missing_access_token',
      );
    }

    final uri = Uri.parse(config.environment.userInfoEndpoint);
    _log('Requesting UAE PASS user profile.');

    try {
      final response = await _httpClient.get(
        uri,
        headers: <String, String>{
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
      ).timeout(config.networkTimeout);

      final json = _decodeJsonObject(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _serverException(
          response.statusCode,
          json,
          fallbackMessage: 'UAE PASS user-info request failed.',
        );
      }

      final profile = UaePassProfile.fromJson(json);
      _log('UAE PASS user profile received successfully.');
      return profile;
    } on TimeoutException catch (e) {
      throw UaePassException(
        'UAE PASS user-info request timed out.',
        code: 'userinfo_timeout',
        cause: e,
      );
    } on UaePassException {
      rethrow;
    } catch (e) {
      throw UaePassException(
        'Unable to retrieve UAE PASS user profile.',
        code: 'userinfo_request_failed',
        cause: e,
      );
    }
  }

  Map<String, dynamic> _decodeJsonObject(http.Response response) {
    if (response.body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // The server may return HTML/plain text for some transport/proxy errors.
    }

    return <String, dynamic>{
      'error_description': response.body.trim(),
    };
  }

  UaePassException _serverException(
    int statusCode,
    Map<String, dynamic> json, {
    required String fallbackMessage,
  }) {
    final code = json['error']?.toString();
    final description = json['error_description']?.toString();

    return UaePassException(
      description?.trim().isNotEmpty == true ? description! : fallbackMessage,
      code: code,
      statusCode: statusCode,
    );
  }

  void _log(String message) {
    config.onLog?.call('[uaepass_flutter] $message');
  }

  void dispose() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }
}
