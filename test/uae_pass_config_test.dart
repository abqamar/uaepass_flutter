import 'package:flutter_test/flutter_test.dart';
import 'package:uaepass_flutter/uaepass_flutter.dart';

void main() {
  test('valid configuration passes validation', () {
    const config = UaePassConfig(
      clientId: 'client-id',
      clientSecret: 'client-secret',
      redirectUri: 'https://example.com/uaepass/callback',
      appScheme: 'abqamaruaepass',
    );

    expect(config.validate, returnsNormally);
  });

  test('invalid callback scheme is rejected', () {
    const config = UaePassConfig(
      clientId: 'client-id',
      clientSecret: 'client-secret',
      redirectUri: 'https://example.com/uaepass/callback',
      appScheme: 'not a valid scheme',
    );

    expect(config.validate, throwsArgumentError);
  });
}
