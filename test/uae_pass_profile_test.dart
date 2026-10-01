import 'package:flutter_test/flutter_test.dart';
import 'package:uaepass_flutter/uaepass_flutter.dart';

void main() {
  test('parses UAE PASS profile and keeps raw attributes', () {
    final profile = UaePassProfile.fromJson(<String, dynamic>{
      'uuid': '123',
      'userType': 'SOP3',
      'fullnameEN': 'Test User',
      'firstnameEN': 'Test',
      'lastnameEN': 'User',
      'email': 'test@example.com',
      'idn': '784000000000000',
      'futureAttribute': 'future-value',
    });

    expect(profile.uuid, '123');
    expect(profile.fullnameEN, 'Test User');
    expect(profile.displayNameEnglish, 'Test User');
    expect(profile.raw['futureAttribute'], 'future-value');
  });
}
