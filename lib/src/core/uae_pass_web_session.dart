import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class UaePassWebSession {
  UaePassWebSession._();

  static Future<void> clear({
    void Function(String message)? onLog,
  }) async {
    void log(String message) {
      onLog?.call(
        '[uaepass_flutter] $message',
      );
    }

    try {
      log('Clearing UAE PASS WebView session.');

      // ----------------------------------------------------
      // Cookies
      // ----------------------------------------------------

      final cookieManager = CookieManager.instance();

      await cookieManager.deleteAllCookies();

      log('WebView cookies cleared.');

      // ----------------------------------------------------
      // HTML localStorage / sessionStorage etc.
      // ----------------------------------------------------

      try {
        await WebStorageManager.instance().deleteAllData();

        log('WebView storage cleared.');
      } catch (e) {
        log(
          'Unable to clear WebView storage: $e',
        );
      }

      // ----------------------------------------------------
      // WebView resource cache
      // ----------------------------------------------------

      try {
        await InAppWebViewController.clearAllCache(
          includeDiskFiles: true,
        );

        log('WebView cache cleared.');
      } catch (e) {
        log(
          'Unable to clear WebView cache: $e',
        );
      }

      // ----------------------------------------------------
      // Android session cookies
      // ----------------------------------------------------

      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await cookieManager.removeSessionCookies();

          log(
            'Android session cookies cleared.',
          );
        } catch (e) {
          log(
            'Unable to clear session cookies: $e',
          );
        }
      }

      log(
        'UAE PASS WebView session cleared.',
      );
    } catch (e) {
      log(
        'WebView cleanup warning: $e',
      );
    }
  }
}
