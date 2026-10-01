import 'package:flutter_test/flutter_test.dart';
import 'package:uaepass_flutter/uaepass_flutter.dart';

void main() {
  test('parses access token response', () {
    final token = UaePassAccessToken.fromJson(<String, dynamic>{
      'access_token': 'token-value',
      'token_type': 'Bearer',
      'expires_in': 3600,
      'scope': 'urn:uae:digitalid:profile:general',
    });

    expect(token.accessToken, 'token-value');
    expect(token.tokenType, 'Bearer');
    expect(token.expiresIn, 3600);
  });
}
