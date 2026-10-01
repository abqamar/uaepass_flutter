import 'dart:async';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/uae_pass_config.dart';
import '../core/uae_pass_environment.dart';
import '../core/uae_pass_exception.dart';
import 'uae_pass_auth_result.dart';

class UaePassAuthPage extends StatefulWidget {
  const UaePassAuthPage({
    super.key,
    required this.config,
  });

  final UaePassConfig config;

  @override
  State<UaePassAuthPage> createState() => _UaePassAuthPageState();
}

class _UaePassAuthPageState extends State<UaePassAuthPage> {
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _linkSubscription;
  Timer? _timeoutTimer;
  InAppWebViewController? _webViewController;

  late final String _state;
  Uri? _authorizationUri;

  bool _isLoading = true;
  bool _completed = false;
  bool _useMobileAppFlow = false;
  String? _errorMessage;

  UaePassConfig get config => widget.config;
  late final String _attemptId;

  @override
  void initState() {
    super.initState();
    _attemptId = DateTime.now().millisecondsSinceEpoch.toString();
    _state = _secureState();
    _listenForAppCallbacks();
    _startTimeout();
    _prepareAuthentication();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();

    _linkSubscription?.cancel();
    _linkSubscription = null;

    _webViewController = null;

    super.dispose();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(config.authenticationTimeout, () {
      if (_completed || !mounted) return;
      _finish(
        const UaePassAuthResult.failed(
          error: 'authentication_timeout',
          errorDescription: 'UAE PASS authentication timed out.',
        ),
      );
    });
  }

  Future<void> _prepareAuthentication() async {
    try {
      config.validate();

      final installed = config.preferUaePassApp ? await _isUaePassInstalled() : false;

      _useMobileAppFlow = installed;
      _log(
        installed ? 'UAE PASS app detected. Using on-device app authentication flow.' : 'UAE PASS app not detected. Using embedded WebView authentication flow.',
      );

      _authorizationUri = _buildAuthorizationUri(
        useMobileAppFlow: _useMobileAppFlow,
      );

      _log('Authorization URL prepared.');

      if (mounted) setState(() {});
    } catch (e) {
      _fail('Unable to prepare UAE PASS authentication.', e);
    }
  }

  Uri _buildAuthorizationUri({required bool useMobileAppFlow}) {
    final acr = useMobileAppFlow ? 'urn:digitalid:authentication:flow:mobileondevice' : 'urn:safelayer:tws:policies:authentication:level:low';

    return Uri.parse(config.environment.authorizationEndpoint).replace(
      queryParameters: <String, String>{
        'response_type': 'code',
        'client_id': config.clientId,
        'scope': config.scope,
        'state': _state,
        'redirect_uri': config.redirectUri,
        'acr_values': acr,
        'ui_locales': config.locale,
      },
    );
  }

  Future<bool> _isUaePassInstalled() async {
    final resolver = config.appInstalledResolver;
    if (resolver != null) {
      return resolver(config.environment);
    }

    // UAE PASS documentation recommends checking the Android package ID. We
    // do that first on Android rather than relying only on a URL-scheme probe.
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final app = await FlutterDeviceApps.getApp(
          config.environment.androidPackageName,
          includeIcon: false,
        );
        if (app != null) return true;
      } catch (e) {
        _log('Android package check failed; trying URL schemes. $e');
      }
    }

    // iOS uses scheme discovery, and Android also gets this as a safe fallback.
    // The consuming Android app must expose schemes/packages through <queries>;
    // iOS must list schemes in LSApplicationQueriesSchemes.
    final candidates = <Uri>[
      Uri.parse('${config.environment.mobileAppScheme}://'),
      Uri.parse('mobileid://'),
    ];

    for (final candidate in candidates) {
      try {
        if (await canLaunchUrl(candidate)) return true;
      } catch (_) {
        // Try the next candidate. Missing platform visibility configuration
        // should result in the safe embedded-WebView fallback.
      }
    }

    return false;
  }

  void _listenForAppCallbacks() {
    _log(
      'Starting UAE PASS '
      'callback listener...',
    );

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _log(
          'Deep link received by app_links.',
        );

        _processAppCallback(uri);
      },
      onError: (Object error) {
        _log(
          'Deep-link listener error: $error',
        );
      },
    );
  }

  Future<void> _processAppCallback(
    Uri uri,
  ) async {
    if (_completed) {
      return;
    }

    _log(
      'Incoming app link: '
      '${uri.scheme}://${uri.host}${uri.path}',
    );

    if (uri.scheme.toLowerCase() != config.appScheme.toLowerCase()) {
      _log(
        'Ignoring callback with scheme: '
        '${uri.scheme}',
      );

      return;
    }

    final expectedPath = '/${config.resumeHost.toLowerCase()}';

    final isResume = uri.host.toLowerCase() == config.resumeHost.toLowerCase() || uri.path.toLowerCase() == expectedPath;

    if (!isResume) {
      _log(
        'Callback does not match '
        'resume_authn.',
      );

      return;
    }

    final originalUrl = uri.queryParameters['url'];

    if (originalUrl == null || originalUrl.isEmpty) {
      _fail(
        'UAE PASS callback did not '
        'contain the resume URL.',
      );

      return;
    }

    final originalUri = Uri.tryParse(originalUrl);

    if (originalUri == null || !originalUri.hasScheme) {
      _fail(
        'UAE PASS returned an invalid '
        'resume URL.',
      );

      return;
    }

    _log(
      'UAE PASS callback received.',
    );

    _log(
      'Resuming authentication '
      'inside WebView.',
    );

    final controller = _webViewController;

    if (controller == null) {
      _authorizationUri = originalUri;

      if (mounted) {
        setState(() {});
      }

      return;
    }

    await controller.loadUrl(
      urlRequest: URLRequest(
        url: WebUri(
          originalUri.toString(),
        ),
      ),
    );
  }

  Future<NavigationActionPolicy> _handleNavigation(
    NavigationAction action,
  ) async {
    final webUri = action.request.url;
    if (webUri == null) return NavigationActionPolicy.ALLOW;

    final uri = Uri.tryParse(webUri.toString());
    if (uri == null) return NavigationActionPolicy.ALLOW;

    final handled = await _handleObservedUri(uri);
    return handled ? NavigationActionPolicy.CANCEL : NavigationActionPolicy.ALLOW;
  }

  Future<bool> _handleObservedUri(Uri uri) async {
    if (_completed) return true;

    _logNavigation(uri);

    if (_isRedirectUri(uri)) {
      _completeFromRedirect(uri);
      return true;
    }

    if (_isUaePassMobileUri(uri)) {
      if (!_useMobileAppFlow) {
        // Browser fallback should not normally produce the mobile deep link,
        // but allow it if it does rather than leaving the WebView on an
        // unsupported custom scheme.
        _log('UAE PASS mobile link received while in WebView fallback.');
      }

      await _openUaePassApp(uri);
      return true;
    }

    return false;
  }

  void _logNavigation(Uri uri) {
    // Do not log query parameters because they can contain callback data or
    // authorization codes. Only log the route shape.
    _log('WebView navigation: ${uri.scheme}://${uri.host}${uri.path}');
  }

  bool _isRedirectUri(Uri uri) {
    final redirect = config.redirectUriParsed;

    return uri.scheme.toLowerCase() == redirect.scheme.toLowerCase() && uri.host.toLowerCase() == redirect.host.toLowerCase() && _effectivePort(uri) == _effectivePort(redirect) && _normalizePath(uri.path) == _normalizePath(redirect.path);
  }

  int _effectivePort(Uri uri) {
    if (uri.hasPort) return uri.port;
    return uri.scheme.toLowerCase() == 'https' ? 443 : 80;
  }

  bool _isUaePassMobileUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'mobileid' || scheme == 'uaepass' || scheme == 'uaepassstg';
  }

  Future<void> _openUaePassApp(
    Uri originalUri,
  ) async {
    try {
      final successUrl = _queryValueIgnoreCase(
        originalUri,
        'successURL',
      );

      final failureUrl = _queryValueIgnoreCase(
        originalUri,
        'failureURL',
      );

      if (successUrl == null || successUrl.isEmpty || failureUrl == null || failureUrl.isEmpty) {
        throw const UaePassException(
          'UAE PASS mobile URL is missing '
          'successURL or failureURL.',
          code: 'missing_mobile_callback',
        );
      }

      // -----------------------------------------------------
      // IMPORTANT:
      //
      // UAE PASS documented callback format:
      //
      // yourapp:///resume_authn?url=<original-url>
      //
      // Notice THREE slashes.
      // -----------------------------------------------------

      final successCallback = '${config.appScheme}:///${config.resumeHost}'
          '?url=${Uri.encodeQueryComponent(successUrl)}';

      final failureCallback = '${config.appScheme}:///${config.resumeHost}'
          '?url=${Uri.encodeQueryComponent(failureUrl)}';

      _log(
        'Success callback prepared: '
        '${config.appScheme}:///${config.resumeHost}',
      );

      _log(
        'Failure callback prepared: '
        '${config.appScheme}:///${config.resumeHost}',
      );

      final parameters = Map<String, String>.from(
        originalUri.queryParameters,
      );

      _replaceQueryValueIgnoreCase(
        parameters,
        key: 'successURL',
        value: successCallback,
      );

      _replaceQueryValueIgnoreCase(
        parameters,
        key: 'failureURL',
        value: failureCallback,
      );

      // -----------------------------------------------------
      // Force the correct UAE PASS scheme.
      //
      // staging    -> uaepassstg://
      // production -> uaepass://
      // -----------------------------------------------------

      final modifiedUri = originalUri.replace(
        scheme: config.environment.mobileAppScheme,
        queryParameters: parameters,
      );

      _log(
        'Opening UAE PASS '
        '(${config.environment.name})',
      );

      _log(
        'UAE PASS URI scheme: '
        '${modifiedUri.scheme}',
      );

      final launched = await launchUrl(
        modifiedUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw const UaePassException(
          'The UAE PASS application '
          'could not be opened.',
          code: 'uaepass_launch_failed',
        );
      }

      _log(
        'UAE PASS opened. '
        'Waiting for callback...',
      );
    } catch (e) {
      _log(
        'Unable to open UAE PASS: $e',
      );

      await _fallbackToBrowserFlow();
    }
  }

  Future<void> _fallbackToBrowserFlow() async {
    if (_completed) return;

    _useMobileAppFlow = false;
    final browserUri = _buildAuthorizationUri(useMobileAppFlow: false);
    _authorizationUri = browserUri;

    _log('Falling back to UAE PASS authentication in the embedded WebView.');

    final controller = _webViewController;
    if (controller != null) {
      await controller.loadUrl(
        urlRequest: URLRequest(url: WebUri(browserUri.toString())),
      );
    } else if (mounted) {
      setState(() {});
    }
  }

  String? _queryValueIgnoreCase(Uri uri, String key) {
    final expected = key.toLowerCase();
    for (final entry in uri.queryParameters.entries) {
      if (entry.key.toLowerCase() == expected) return entry.value;
    }
    return null;
  }

  void _replaceQueryValueIgnoreCase(
    Map<String, String> parameters, {
    required String key,
    required String value,
  }) {
    final expected = key.toLowerCase();
    String? existingKey;

    for (final candidate in parameters.keys) {
      if (candidate.toLowerCase() == expected) {
        existingKey = candidate;
        break;
      }
    }

    parameters[existingKey ?? key] = value;
  }

  void _completeFromRedirect(Uri uri) {
    if (_completed) return;

    final returnedState = uri.queryParameters['state'];
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];
    final description = uri.queryParameters['error_description'];

    if (error != null) {
      final normalized = error.toLowerCase();
      final cancelled = normalized.contains('cancel') || normalized == 'access_denied';

      _finish(
        cancelled
            ? UaePassAuthResult.cancelled(
                error: error,
                errorDescription: description,
              )
            : UaePassAuthResult.failed(
                error: error,
                errorDescription: description,
              ),
      );
      return;
    }

    if (returnedState == null || returnedState != _state) {
      _finish(
        const UaePassAuthResult.failed(
          error: 'invalid_state',
          errorDescription: 'OAuth state validation failed.',
        ),
      );
      return;
    }

    if (code == null || code.isEmpty) {
      _finish(
        const UaePassAuthResult.failed(
          error: 'missing_code',
          errorDescription: 'Authorization code was not returned.',
        ),
      );
      return;
    }

    _log('Authorization code received successfully.');

    _finish(
      UaePassAuthResult.success(
        authorizationCode: code,
        state: returnedState,
      ),
    );
  }

  void _finish(UaePassAuthResult result) {
    if (_completed || !mounted) return;
    _completed = true;
    _timeoutTimer?.cancel();
    Navigator.of(context).pop(result);
  }

  void _fail(String message, [Object? error]) {
    _log(error == null ? message : '$message $error');

    if (!mounted || _completed) return;

    setState(() {
      _errorMessage = error == null ? message : '$message\n$error';
      _isLoading = false;
    });
  }

  void _log(String message) {
    config.onLog?.call(
      '[uaepass_flutter]'
      '[$_attemptId] '
      '$message',
    );
  }

  String _normalizePath(String path) {
    if (path.isEmpty || path == '/') return '/';
    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  String _secureState() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  Widget build(BuildContext context) {
    final uri = _authorizationUri;

    return Scaffold(
      appBar: AppBar(
        title: const Text('UAE PASS'),
      ),
      body: _errorMessage != null
          ? _ErrorView(
              message: _errorMessage!,
              onRetry: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _startTimeout();
                _prepareAuthentication();
              },
              onClose: () => _finish(
                UaePassAuthResult.failed(
                  error: 'authentication_error',
                  errorDescription: _errorMessage,
                ),
              ),
            )
          : uri == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri(uri.toString()),
                      ),
                      initialSettings: InAppWebViewSettings(
                        javaScriptEnabled: true,
                        useShouldOverrideUrlLoading: true,
                        mediaPlaybackRequiresUserGesture: true,
                        supportMultipleWindows: false,
                      ),
                      onWebViewCreated: (controller) {
                        _webViewController = controller;
                      },
                      shouldOverrideUrlLoading: (controller, action) {
                        return _handleNavigation(action);
                      },
                      onLoadStart: (_, webUri) async {
                        if (mounted) setState(() => _isLoading = true);
                        if (webUri != null) {
                          final uri = Uri.tryParse(webUri.toString());
                          if (uri != null && _isRedirectUri(uri)) {
                            _completeFromRedirect(uri);
                          }
                        }
                      },
                      onUpdateVisitedHistory: (_, webUri, __) {
                        if (webUri == null) return;
                        final uri = Uri.tryParse(webUri.toString());
                        if (uri != null && _isRedirectUri(uri)) {
                          _completeFromRedirect(uri);
                        }
                      },
                      onLoadStop: (_, __) {
                        if (mounted) setState(() => _isLoading = false);
                      },
                      onReceivedError: (_, request, error) {
                        // Custom-scheme handoff can appear as a WebView error on
                        // some OS/WebView versions. Do not turn it into a user
                        // error; the navigation delegate performs the handoff.
                        _log(
                          'WebView notice for ${request.url}: ${error.description}',
                        );
                      },
                    ),
                    if (_isLoading) const LinearProgressIndicator(minHeight: 2),
                  ],
                ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onClose,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onClose,
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
