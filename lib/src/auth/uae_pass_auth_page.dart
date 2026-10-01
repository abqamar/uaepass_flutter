import 'dart:async';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
  InAppWebViewController? _webViewController;

  late final String _state;
  Uri? _authorizationUri;
  bool _isLoading = true;
  bool _completed = false;
  String? _errorMessage;

  UaePassConfig get config => widget.config;

  @override
  void initState() {
    super.initState();
    _state = _secureState();
    _listenForAppCallbacks();
    _prepareAuthentication();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _prepareAuthentication() async {
    try {
      config.validate();

      final installed = await _isUaePassInstalled();
      _log('UAE PASS installed: $installed');

      final acr = installed
          ? 'urn:digitalid:authentication:flow:mobileondevice'
          : 'urn:safelayer:tws:policies:authentication:level:low';

      _authorizationUri = Uri.parse(
        config.environment.authorizationEndpoint,
      ).replace(
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

      _log('Authorization URL prepared.');

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _fail('Unable to prepare UAE PASS authentication.', e);
    }
  }

  Future<bool> _isUaePassInstalled() async {
    final scheme = config.environment.mobileAppScheme;
    return canLaunchUrl(Uri.parse('$scheme://'));
  }

  void _listenForAppCallbacks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) async {
        _log('App callback received: ${uri.scheme}://${uri.host}${uri.path}');

        if (uri.scheme.toLowerCase() != config.appScheme.toLowerCase()) {
          return;
        }

        final isResume = uri.host == config.resumeHost ||
            uri.path == '/${config.resumeHost}';

        if (!isResume) {
          return;
        }

        final originalUrl = uri.queryParameters['url'];
        if (originalUrl == null || originalUrl.isEmpty) {
          _fail('UAE PASS callback did not contain the resume URL.');
          return;
        }

        final originalUri = Uri.tryParse(originalUrl);
        if (originalUri == null) {
          _fail('UAE PASS returned an invalid resume URL.');
          return;
        }

        _log('Resuming authentication inside the same WebView.');

        await _webViewController?.loadUrl(
          urlRequest: URLRequest(url: WebUri(originalUri.toString())),
        );
      },
      onError: (Object error) {
        _fail('Deep-link listener failed.', error);
      },
    );
  }

  Future<NavigationActionPolicy> _handleNavigation(
    NavigationAction action,
  ) async {
    final webUri = action.request.url;
    if (webUri == null) {
      return NavigationActionPolicy.ALLOW;
    }

    final uri = Uri.tryParse(webUri.toString());
    if (uri == null) {
      return NavigationActionPolicy.ALLOW;
    }

    _log('WebView navigation: ${uri.scheme}://${uri.host}${uri.path}');

    if (_isRedirectUri(uri)) {
      _completeFromRedirect(uri);
      return NavigationActionPolicy.CANCEL;
    }

    if (_isUaePassMobileUri(uri)) {
      await _openUaePassApp(uri);
      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  }

  bool _isRedirectUri(Uri uri) {
    final redirect = Uri.parse(config.redirectUri);

    return uri.scheme.toLowerCase() == redirect.scheme.toLowerCase() &&
        uri.host.toLowerCase() == redirect.host.toLowerCase() &&
        _normalizePath(uri.path) == _normalizePath(redirect.path);
  }

  bool _isUaePassMobileUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();

    // UAE PASS documentation has used mobileid:// in the generic protocol
    // description and uaepass:// / uaepassstg:// in environment examples.
    return scheme == 'mobileid' ||
        scheme == 'uaepass' ||
        scheme == 'uaepassstg';
  }

  Future<void> _openUaePassApp(Uri originalUri) async {
    try {
      final successUrl = originalUri.queryParameters['successURL'];
      final failureUrl = originalUri.queryParameters['failureURL'];

      if (successUrl == null || failureUrl == null) {
        throw const UaePassException(
          'UAE PASS mobile URL is missing successURL or failureURL.',
        );
      }

      final successCallback = Uri(
        scheme: config.appScheme,
        host: config.resumeHost,
        queryParameters: <String, String>{'url': successUrl},
      );

      final failureCallback = Uri(
        scheme: config.appScheme,
        host: config.resumeHost,
        queryParameters: <String, String>{'url': failureUrl},
      );

      final parameters = Map<String, String>.from(originalUri.queryParameters)
        ..['successURL'] = successCallback.toString()
        ..['failureURL'] = failureCallback.toString();

      final modifiedUri = originalUri.replace(queryParameters: parameters);

      _log('Launching UAE PASS mobile application.');

      final launched = await launchUrl(
        modifiedUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw const UaePassException('Could not launch UAE PASS application.');
      }
    } catch (e) {
      _fail('Unable to launch UAE PASS application.', e);
    }
  }

  void _completeFromRedirect(Uri uri) {
    if (_completed) return;

    final returnedState = uri.queryParameters['state'];
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];
    final description = uri.queryParameters['error_description'];

    if (error != null) {
      final cancelled = error.toLowerCase().contains('cancel') ||
          error.toLowerCase() == 'access_denied';

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

    if (returnedState != _state) {
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

    _finish(
      UaePassAuthResult.success(
        authorizationCode: code,
        state: returnedState!,
      ),
    );
  }

  void _finish(UaePassAuthResult result) {
    if (_completed || !mounted) return;
    _completed = true;
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
    config.onLog?.call('[uaepass_flutter] $message');
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
                      ),
                      onWebViewCreated: (controller) {
                        _webViewController = controller;
                      },
                      shouldOverrideUrlLoading: (controller, action) {
                        return _handleNavigation(action);
                      },
                      onLoadStart: (_, __) {
                        if (mounted) {
                          setState(() => _isLoading = true);
                        }
                      },
                      onLoadStop: (_, __) {
                        if (mounted) {
                          setState(() => _isLoading = false);
                        }
                      },
                      onReceivedError: (_, request, error) {
                        _log(
                          'WebView error for ${request.url}: ${error.description}',
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
    required this.onClose,
  });

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onClose,
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
