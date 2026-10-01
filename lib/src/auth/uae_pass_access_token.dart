class UaePassAccessToken {
  const UaePassAccessToken({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.scope,
    this.refreshToken,
    this.idToken,
  });

  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final String scope;
  final String? refreshToken;
  final String? idToken;

  factory UaePassAccessToken.fromJson(Map<String, dynamic> json) {
    final token = json['access_token']?.toString();
    if (token == null || token.isEmpty) {
      throw const FormatException(
          'UAE PASS response did not contain access_token.');
    }

    return UaePassAccessToken(
      accessToken: token,
      tokenType: json['token_type']?.toString() ?? 'Bearer',
      expiresIn: _asInt(json['expires_in']) ?? 0,
      scope: json['scope']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString(),
      idToken: json['id_token']?.toString(),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
