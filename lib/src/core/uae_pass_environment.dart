enum UaePassEnvironment {
  staging,
  production,
}

extension UaePassEnvironmentX on UaePassEnvironment {
  String get authorizationEndpoint => switch (this) {
        UaePassEnvironment.staging =>
          'https://stg-id.uaepass.ae/idshub/authorize',
        UaePassEnvironment.production =>
          'https://id.uaepass.ae/idshub/authorize',
      };

  String get tokenEndpoint => switch (this) {
        UaePassEnvironment.staging => 'https://stg-id.uaepass.ae/idshub/token',
        UaePassEnvironment.production => 'https://id.uaepass.ae/idshub/token',
      };

  String get userInfoEndpoint => switch (this) {
        UaePassEnvironment.staging =>
          'https://stg-id.uaepass.ae/idshub/userinfo',
        UaePassEnvironment.production =>
          'https://id.uaepass.ae/idshub/userinfo',
      };

  String get logoutEndpoint => switch (this) {
        UaePassEnvironment.staging => 'https://stg-id.uaepass.ae/idshub/logout',
        UaePassEnvironment.production => 'https://id.uaepass.ae/idshub/logout',
      };

  String get mobileAppScheme => switch (this) {
        UaePassEnvironment.staging => 'uaepassstg',
        UaePassEnvironment.production => 'uaepass',
      };

  String get androidPackageName => switch (this) {
        UaePassEnvironment.staging => 'ae.uaepass.mainapp.stg',
        UaePassEnvironment.production => 'ae.uaepass.mainapp',
      };
}
