import 'uae_pass_environment.dart';

typedef UaePassLogCallback = void Function(String message);

class UaePassConfig {
  const UaePassConfig({
    required this.clientId,
    required this.redirectUri,
    required this.appScheme,
    this.environment = UaePassEnvironment.staging,
    this.scope = 'urn:uae:digitalid:profile:general',
    this.locale = 'en',
    this.resumeHost = 'resume_authn',
    this.authenticationTimeout = const Duration(minutes: 3),
    this.onLog,
  });

  final String clientId;

  /// HTTPS redirect URI registered with UAE PASS.
  final String redirectUri;

  /// Unique custom scheme owned by the consuming application.
  /// Example: `abqamaruaepass`.
  final String appScheme;

  final UaePassEnvironment environment;
  final String scope;

  /// UAE PASS supports `en` and `ar` for the authentication UI.
  final String locale;

  /// Host used when UAE PASS returns control to the app.
  /// Callback format: appScheme://resume_authn?url=...
  final String resumeHost;

  final Duration authenticationTimeout;
  final UaePassLogCallback? onLog;

  void validate() {
    if (clientId.trim().isEmpty) {
      throw ArgumentError.value(clientId, 'clientId', 'Cannot be empty.');
    }

    final redirect = Uri.tryParse(redirectUri);
    if (redirect == null || !redirect.hasScheme) {
      throw ArgumentError.value(
        redirectUri,
        'redirectUri',
        'Must be a valid URI registered with UAE PASS.',
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

    if (locale != 'en' && locale != 'ar') {
      throw ArgumentError.value(locale, 'locale', 'Use en or ar.');
    }
  }
}
