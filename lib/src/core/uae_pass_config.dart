import 'uae_pass_environment.dart';

typedef UaePassLogCallback = void Function(String message);
typedef UaePassAppInstalledResolver = Future<bool> Function(
  UaePassEnvironment environment,
);

class UaePassConfig {
  const UaePassConfig({
    required this.clientId,
    this.clientSecret,
    required this.redirectUri,
    required this.appScheme,
    this.environment = UaePassEnvironment.staging,
    this.scope = 'urn:uae:digitalid:profile:general',
    this.locale = 'en',
    this.resumeHost = 'resume_authn',
    this.authenticationTimeout = const Duration(minutes: 3),
    this.networkTimeout = const Duration(seconds: 45),
    this.preferUaePassApp = true,
    this.onLog,
    this.appInstalledResolver,
  });

  /// UAE PASS client ID issued for the approved mobile channel/use case.
  final String clientId;

  /// UAE PASS client secret.
  ///
  /// IMPORTANT: Mobile binaries cannot securely hide embedded secrets. The
  /// package supports direct token exchange because some integrations require
  /// a Flutter-only flow, but production use should be aligned with UAE PASS
  /// onboarding/security requirements.
  final String? clientSecret;

  /// Exact redirect URI registered with UAE PASS.
  final String redirectUri;

  /// Unique custom URI scheme owned by the consuming app.
  /// Example: `abqamaruaepass`.
  final String appScheme;

  final UaePassEnvironment environment;

  /// Default profile scope. Additional approved scopes can be appended using
  /// spaces, for example visitor profile scopes.
  final String scope;

  /// UAE PASS authentication UI locale: `en` or `ar`.
  final String locale;

  /// Host used for app-to-app return callbacks.
  /// Callback format: `appScheme://resume_authn?url=...`.
  final String resumeHost;

  final Duration authenticationTimeout;
  final Duration networkTimeout;

  /// If true, the package checks whether the UAE PASS app is available and
  /// uses the on-device flow when possible. If false, it always uses the
  /// browser-style embedded WebView flow.
  final bool preferUaePassApp;

  final UaePassLogCallback? onLog;

  /// Optional custom app-installed check. Useful if the consuming app already
  /// has a native/package detector. When omitted, Android package lookup is
  /// attempted first and URL-scheme discovery is used as fallback.
  final UaePassAppInstalledResolver? appInstalledResolver;

  Uri get redirectUriParsed => Uri.parse(redirectUri);

  void validateForDirectTokenExchange() {
    validate();

    final secret = clientSecret;
    if (secret == null || secret.trim().isEmpty) {
      throw ArgumentError.value(
        secret,
        'clientSecret',
        'Cannot be empty when access-token exchange is performed in Flutter.',
      );
    }
  }

  void validate() {
    if (clientId.trim().isEmpty) {
      throw ArgumentError.value(clientId, 'clientId', 'Cannot be empty.');
    }

    final redirect = Uri.tryParse(redirectUri);
    if (redirect == null || !redirect.hasScheme || redirect.host.isEmpty) {
      throw ArgumentError.value(
        redirectUri,
        'redirectUri',
        'Must be a valid registered absolute URI.',
      );
    }

    final schemePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*$');
    if (!schemePattern.hasMatch(appScheme)) {
      throw ArgumentError.value(
        appScheme,
        'appScheme',
        'Must be a valid custom URI scheme.',
      );
    }

    if (resumeHost.trim().isEmpty) {
      throw ArgumentError.value(resumeHost, 'resumeHost', 'Cannot be empty.');
    }

    if (scope.trim().isEmpty) {
      throw ArgumentError.value(scope, 'scope', 'Cannot be empty.');
    }

    if (locale != 'en' && locale != 'ar') {
      throw ArgumentError.value(locale, 'locale', 'Use en or ar.');
    }

    if (authenticationTimeout <= Duration.zero) {
      throw ArgumentError.value(
        authenticationTimeout,
        'authenticationTimeout',
        'Must be greater than zero.',
      );
    }

    if (networkTimeout <= Duration.zero) {
      throw ArgumentError.value(
        networkTimeout,
        'networkTimeout',
        'Must be greater than zero.',
      );
    }
  }
}
