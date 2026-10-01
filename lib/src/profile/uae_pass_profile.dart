class UaePassProfile {
  UaePassProfile({
    required Map<String, dynamic> raw,
    this.sub,
    this.uuid,
    this.userType,
    this.fullnameEN,
    this.fullnameAR,
    this.firstnameEN,
    this.firstnameAR,
    this.lastnameEN,
    this.lastnameAR,
    this.nationalityEN,
    this.nationalityAR,
    this.gender,
    this.mobile,
    this.email,
    this.idType,
    this.idn,
    this.spuuid,
    this.titleEN,
    this.titleAR,
    this.profileType,
    this.unifiedId,
    this.acr,
    this.amr = const <String>[],
  }) : raw = Map<String, dynamic>.unmodifiable(raw);

  final String? sub;
  final String? uuid;
  final String? userType;
  final String? fullnameEN;
  final String? fullnameAR;
  String? firstnameEN;
  String? firstnameAR;
  String? lastnameEN;
  String? lastnameAR;
  final String? nationalityEN;
  final String? nationalityAR;
  final String? gender;
  final String? mobile;
  final String? email;
  final String? idType;
  final String? idn;
  final String? spuuid;
  final String? titleEN;
  final String? titleAR;

  /// Used by visitor-profile integrations when enabled for the client.
  final String? profileType;

  /// Used by visitor-profile integrations when enabled for the client.
  final String? unifiedId;

  final String? acr;
  final List<String> amr;

  /// Full server response retained for attributes UAE PASS enables later or
  /// attributes specific to the consuming application's approved scopes.
  final Map<String, dynamic> raw;

  factory UaePassProfile.fromJson(Map<String, dynamic> json) {
    return UaePassProfile(
      raw: json,
      sub: _string(json['sub']),
      uuid: _string(json['uuid']),
      userType: _string(json['userType']),
      fullnameEN: _string(json['fullnameEN']),
      fullnameAR: _string(json['fullnameAR']),
      firstnameEN: _string(json['firstnameEN']),
      firstnameAR: _string(json['firstnameAR']),
      lastnameEN: _string(json['lastnameEN']),
      lastnameAR: _string(json['lastnameAR']),
      nationalityEN: _string(json['nationalityEN']),
      nationalityAR: _string(json['nationalityAR']),
      gender: _string(json['gender']),
      mobile: _string(json['mobile']),
      email: _string(json['email']),
      idType: _string(json['idType']),
      idn: _string(json['idn']),
      spuuid: _string(json['spuuid'] ?? json['spuuid1']),
      titleEN: _string(json['titleEN']),
      titleAR: _string(json['titleAR']),
      profileType: _string(json['profileType']),
      unifiedId: _string(json['unifiedId'] ?? json['unifiedID']),
      acr: _string(json['acr']),
      amr: _stringList(json['amr']),
    );
  }

  String? get displayNameEnglish => fullnameEN?.trim().isNotEmpty == true ? fullnameEN!.trim() : [firstnameEN, lastnameEN].where((value) => value?.trim().isNotEmpty == true).map((value) => value!.trim()).join(' ').trim().nullIfEmpty;

  String? get displayNameArabic => fullnameAR?.trim().isNotEmpty == true ? fullnameAR!.trim() : [firstnameAR, lastnameAR].where((value) => value?.trim().isNotEmpty == true).map((value) => value!.trim()).join(' ').trim().nullIfEmpty;

  static String? _string(dynamic value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) return null;
    return text;
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return List<String>.unmodifiable(
      value.map((item) => item?.toString()).whereType<String>().where((item) => item.isNotEmpty),
    );
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
