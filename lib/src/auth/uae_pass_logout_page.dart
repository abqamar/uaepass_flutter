import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class UaePassLogoutPage extends StatefulWidget {
  const UaePassLogoutPage({
    super.key,
    required this.logoutUrl,
    required this.redirectUri,
    this.onLog,
    this.clearCookies = true,
  });

  final String logoutUrl;
  final String redirectUri;
  final void Function(String message)? onLog;
  final bool clearCookies;

  @override
  State<UaePassLogoutPage> createState() => _UaePassLogoutPageState();
}

class _UaePassLogoutPageState extends State<UaePassLogoutPage> {
  InAppWebViewController? webViewController;

  bool _isLoading = true;
  bool _completed = false;

  Uri get _redirectUri => Uri.parse(widget.redirectUri);

  @override
  void initState() {
    super.initState();

    _prepareLogout();
  }

  Future<void> _prepareLogout() async {
    try {
      if (widget.clearCookies) {
        await CookieManager.instance().deleteAllCookies();

        await WebStorageManager.instance().deleteAllData();

        _log(
          'WebView cookies and storage cleared.',
        );
      }
    } catch (e) {
      _log(
        'Unable to clear WebView session: $e',
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  bool _isLogoutRedirect(Uri uri) {
    final expected = _redirectUri;

    return uri.scheme.toLowerCase() == expected.scheme.toLowerCase() &&
        uri.host.toLowerCase() == expected.host.toLowerCase() &&
        _effectivePort(uri) == _effectivePort(expected) &&
        _normalizePath(uri.path) == _normalizePath(expected.path);
  }

  Future<NavigationActionPolicy> _handleNavigation(
    NavigationAction action,
  ) async {
    final webUri = action.request.url;

    if (webUri == null) {
      return NavigationActionPolicy.ALLOW;
    }

    final uri = Uri.tryParse(
      webUri.toString(),
    );

    if (uri == null) {
      return NavigationActionPolicy.ALLOW;
    }

    _log(
      'Logout navigation: '
      '${uri.scheme}://${uri.host}${uri.path}',
    );

    if (_isLogoutRedirect(uri)) {
      _completeLogout();

      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  }

  void _completeLogout() {
    if (_completed || !mounted) {
      return;
    }

    _completed = true;

    _log(
      'UAE PASS logout completed.',
    );

    Navigator.of(context).pop(true);
  }

  void _cancelLogout() {
    if (_completed || !mounted) {
      return;
    }

    _completed = true;

    Navigator.of(context).pop(false);
  }

  int _effectivePort(Uri uri) {
    if (uri.hasPort) {
      return uri.port;
    }

    if (uri.scheme.toLowerCase() == 'https') {
      return 443;
    }

    if (uri.scheme.toLowerCase() == 'http') {
      return 80;
    }

    return 0;
  }

  String _normalizePath(String path) {
    if (path.isEmpty || path == '/') {
      return '/';
    }

    return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
  }

  void _log(String message) {
    widget.onLog?.call(
      '[uaepass_flutter] $message',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
        didPop,
        result,
      ) {
        if (!didPop) {
          _cancelLogout();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'UAE PASS',
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.close,
            ),
            onPressed: _cancelLogout,
          ),
        ),
        body: Stack(
          children: [
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(
                  widget.logoutUrl,
                ),
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                useShouldOverrideUrlLoading: true,
                supportMultipleWindows: false,
                clearCache: false,
              ),
              onWebViewCreated: (
                controller,
              ) {
                webViewController = controller;

                _log(
                  'Logout WebView created.',
                );
              },
              shouldOverrideUrlLoading: (
                controller,
                action,
              ) {
                return _handleNavigation(
                  action,
                );
              },
              onLoadStart: (
                controller,
                url,
              ) {
                if (mounted) {
                  setState(() {
                    _isLoading = true;
                  });
                }

                if (url == null) {
                  return;
                }

                final uri = Uri.tryParse(
                  url.toString(),
                );

                if (uri != null && _isLogoutRedirect(uri)) {
                  _completeLogout();
                }
              },
              onLoadStop: (
                controller,
                url,
              ) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }

                if (url == null) {
                  return;
                }

                final uri = Uri.tryParse(
                  url.toString(),
                );

                if (uri != null && _isLogoutRedirect(uri)) {
                  _completeLogout();
                }
              },
              onUpdateVisitedHistory: (
                controller,
                url,
                isReload,
              ) {
                if (url == null) {
                  return;
                }

                final uri = Uri.tryParse(
                  url.toString(),
                );

                if (uri != null && _isLogoutRedirect(uri)) {
                  _completeLogout();
                }
              },
              onReceivedError: (
                controller,
                request,
                error,
              ) {
                _log(
                  'Logout WebView error: '
                  '${error.description}',
                );
              },
            ),
            if (_isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
              ),
          ],
        ),
      ),
    );
  }
}
