# uaepass_flutter

`uaepass_flutter` is an **unofficial** reusable Flutter package for UAE PASS authentication.

Version **0.0.1** supports the complete client-side authentication flow:

1. Detect whether the UAE PASS mobile app is available.
2. Start UAE PASS OAuth authorization in an embedded WebView.
3. If UAE PASS is installed, use the on-device authentication flow and hand the user to the UAE PASS app.
4. If UAE PASS is not installed, keep the user inside the embedded WebView.
5. Receive and validate the OAuth authorization code.
6. Exchange the authorization code for an access token.
7. Call UAE PASS User Info and return a typed user profile.

The package is intentionally structured so UAE PASS **document signing** can be added later without redesigning authentication.

> This is not an official UAE PASS SDK. Always validate your final staging/production configuration and approved use case with the UAE PASS onboarding team.

## Package identity

- Flutter package: `uaepass_flutter`
- Version: `0.0.1`
- Example Android application ID: `com.abqamar.uaepass_flutter`
- Example iOS bundle identifier: `com.abqamar.uaepass_flutter`
- Example custom callback scheme: `abqamaruaepass`

A normal Flutter package does not itself own an Android application ID or iOS bundle ID. The identifiers above are used for the example/integration convention. In a consuming application, use the bundle/application ID approved for that UAE PASS client.

## Important security note

This version supports direct token exchange from Flutter because some applications require the complete flow on-device.

That means `clientSecret` is supplied to the Flutter package. A secret embedded in an APK/IPA cannot be considered confidential because a determined user can extract it from the application binary.

UAE PASS documentation describes token and User Info requests as back-channel requests. Confirm that direct mobile token exchange is acceptable for your approved UAE PASS mobile use case before production release.

The package keeps the authorization-only API available so token exchange can be moved to a backend later without changing the app-to-app authentication implementation.

---

# Installation

For a local package:

```yaml
dependencies:
  uaepass_flutter:
    path: ../uaepass_flutter
```

Then:

```bash
flutter pub get
```

## Dependencies used internally

The package is a normal Flutter package, not a custom native plugin. It uses established packages for platform capabilities:

- `flutter_inappwebview` — embedded UAE PASS authentication browser
- `flutter_device_apps` — exact UAE PASS Android package detection
- `url_launcher` — UAE PASS app handoff
- `app_links` — app-to-app callback handling
- `http` — access-token and User Info API calls

---

# Flow

## UAE PASS installed

```text
Your Flutter app
      |
      v
Embedded UAE PASS authorization WebView
      |
      | acr_values = mobileondevice
      v
UAE PASS deep-link generated
      |
      v
uaepass:// or uaepassstg://
      |
      v
UAE PASS mobile app
      |
      | user confirms authentication
      v
abqamaruaepass://resume_authn?url=...
      |
      v
Existing embedded WebView resumes callback URL
      |
      v
OAuth redirect URI + authorization code
      |
      v
/token
      |
      v
Access token
      |
      v
/userinfo
      |
      v
UaePassProfile
```

The package does not try to replace the UAE PASS-defined WebView bootstrap. UAE PASS's documented mobile flow starts authorization in an embedded WebView and then hands the generated custom-scheme URL to the UAE PASS app.

## UAE PASS not installed

```text
Your Flutter app
      |
      v
Embedded UAE PASS authorization WebView
      |
      | acr_values = authentication:level:low
      v
User enters UAE PASS identifier
      |
      v
User approves on another UAE PASS-enabled device
      |
      v
OAuth redirect URI + authorization code
      |
      v
/token -> /userinfo -> profile
```

If app detection produces a false positive but the OS cannot open UAE PASS, the package automatically retries using the embedded WebView fallback flow.

---

# Configuration

## Android

Edit the consuming application's:

```text
android/app/src/main/AndroidManifest.xml
```

Make sure Internet permission exists:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

Add UAE PASS visibility under the root `<manifest>` element, **outside** `<application>`:

```xml
<queries>
    <package android:name="ae.uaepass.mainapp" />
    <package android:name="ae.uaepass.mainapp.stg" />

    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="uaepass" />
    </intent>

    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="uaepassstg" />
    </intent>

    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="mobileid" />
    </intent>
</queries>
```

Your `MainActivity` should use `singleTask` and contain the callback filter:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTask"
    android:theme="@style/LaunchTheme"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:windowSoftInputMode="adjustResize">

    <meta-data
        android:name="io.flutter.embedding.android.NormalTheme"
        android:resource="@style/NormalTheme" />

    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>

    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />

        <data
            android:scheme="abqamaruaepass"
            android:host="resume_authn" />
    </intent-filter>
</activity>
```

The value:

```text
abqamaruaepass
```

must exactly match `UaePassConfig.appScheme`.

For the sample identity requested for this package:

```text
applicationId = com.abqamar.uaepass_flutter
```

Your actual consuming application should use the application ID approved for its UAE PASS client.

### Verify the installed APK configuration

In Android Studio, open `AndroidManifest.xml` and inspect **Merged Manifest**. Confirm the callback scheme and `<queries>` entries are present in the final build variant.

---

## iOS

Edit:

```text
ios/Runner/Info.plist
```

Add UAE PASS schemes that the application is allowed to query:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>uaepass</string>
    <string>uaepassstg</string>
    <string>mobileid</string>
</array>
```

Register your application's callback scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.abqamar.uaepass_flutter</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>abqamaruaepass</string>
        </array>
    </dict>
</array>
```

For the example identity:

```text
PRODUCT_BUNDLE_IDENTIFIER = com.abqamar.uaepass_flutter
```

Again, the consuming app should use the actual identifier approved for its UAE PASS integration.

---

# Initialize once with GetX

If your app uses GetX, create one `UaePassFlutter` instance in `main.dart` and register it permanently.

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uaepass_flutter/uaepass_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put<UaePassFlutter>(
    UaePassFlutter(
      config: UaePassConfig(
        clientId: 'YOUR_CLIENT_ID',
        clientSecret: 'YOUR_CLIENT_SECRET',
        redirectUri: 'YOUR_REGISTERED_REDIRECT_URI',
        appScheme: 'abqamaruaepass',
        environment: UaePassEnvironment.staging,
        locale: 'en',
        onLog: kDebugMode ? debugPrint : null,
      ),
    ),
    permanent: true,
  );

  runApp(const MyApp());
}
```

For production change only the environment after using your production credentials/registered redirect URI:

```dart
environment: UaePassEnvironment.production,
```

---

# Login from a GetX controller

```dart
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uaepass_flutter/uaepass_flutter.dart';

class LoginController extends GetxController {
  final UaePassFlutter _uaePass = Get.find<UaePassFlutter>();

  final isUaePassLoading = false.obs;

  Future<void> loginWithUaePass() async {
    if (isUaePassLoading.value) return;

    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;

    try {
      isUaePassLoading.value = true;

      final result = await _uaePass.login(context);

      if (result.isCancelled) {
        debugPrint('UAE PASS login cancelled');
        return;
      }

      if (!result.isSuccess) {
        debugPrint(
          'UAE PASS failed: ${result.error} - ${result.errorDescription}',
        );
        return;
      }

      final accessToken = result.accessToken!;
      final profile = result.profile!;

      debugPrint('UAE PASS login completed');
      debugPrint('UUID: ${profile.uuid}');
      debugPrint('Name EN: ${profile.fullnameEN}');
      debugPrint('Name AR: ${profile.fullnameAR}');
      debugPrint('Mobile: ${profile.mobile}');
      debugPrint('Email: ${profile.email}');
      debugPrint('Emirates ID: ${profile.idn}');

      // Store/use accessToken and profile according to your app flow.
      // Do not print the access token in production logs.
      useAuthenticatedUaePassUser(accessToken, profile);
    } finally {
      isUaePassLoading.value = false;
    }
  }

  void useAuthenticatedUaePassUser(
    String accessToken,
    UaePassProfile profile,
  ) {
    // Your application logic.
  }
}
```

The high-level method:

```dart
await _uaePass.login(context);
```

performs:

```text
authorize -> access token -> user info
```

and returns everything in one `UaePassLoginResult`.

---

# Result model

```dart
final result = await uaePass.login(context);

if (result.isSuccess) {
  result.authorizationCode;
  result.token;
  result.accessToken;
  result.profile;
}
```

`UaePassProfile` includes common UAE PASS profile fields:

```dart
profile.sub
profile.uuid
profile.userType
profile.fullnameEN
profile.fullnameAR
profile.firstnameEN
profile.firstnameAR
profile.lastnameEN
profile.lastnameAR
profile.nationalityEN
profile.nationalityAR
profile.gender
profile.mobile
profile.email
profile.idType
profile.idn
profile.spuuid
profile.titleEN
profile.titleAR
profile.profileType
profile.unifiedId
profile.acr
profile.amr
```

UAE PASS can return different attributes depending on the user's profile type and scopes enabled for your client. Therefore the full response is also retained:

```dart
profile.raw
```

---

# Low-level APIs

If you need more control, each step is public.

## Authorization only

```dart
final auth = await uaePass.authorize(context);

if (auth.isSuccess) {
  print(auth.authorizationCode);
}
```

`authenticate(context)` is also available as an alias for authorization-only behavior.

## Exchange authorization code

```dart
final token = await uaePass.exchangeAuthorizationCode(
  auth.authorizationCode!,
);
```

## Get profile

```dart
final profile = await uaePass.getUserProfile(
  token.accessToken,
);
```

---

# App-installed detection

On Android, the package first checks the environment-specific UAE PASS package ID, matching UAE PASS mobile integration guidance. It then falls back to URL-scheme detection. On iOS, it uses URL-scheme detection.

Staging:

```text
uaepassstg://
```

Production:

```text
uaepass://
```

It also checks the generic `mobileid://` scheme used by the documented mobile protocol.

If your application already has a stronger native/package-installed detector, inject it:

```dart
UaePassConfig(
  // ...
  appInstalledResolver: (environment) async {
    // Return true only when the correct UAE PASS app is installed.
    return true;
  },
)
```

You can force the embedded WebView flow for testing:

```dart
preferUaePassApp: false,
```

---

# Staging and production endpoints

The package currently maps UAE PASS environments to:

### Staging

```text
Authorization: https://stg-id.uaepass.ae/idshub/authorize
Token:         https://stg-id.uaepass.ae/idshub/token
User Info:     https://stg-id.uaepass.ae/idshub/userinfo
Logout:        https://stg-id.uaepass.ae/idshub/logout
```

### Production

```text
Authorization: https://id.uaepass.ae/idshub/authorize
Token:         https://id.uaepass.ae/idshub/token
User Info:     https://id.uaepass.ae/idshub/userinfo
Logout:        https://id.uaepass.ae/idshub/logout
```

---

# Visitor profile scopes

The default scope is:

```text
urn:uae:digitalid:profile:general
```

If UAE PASS has approved visitor profile attributes for your client, configure the additional scopes provided by UAE PASS, for example:

```dart
scope: [
  'urn:uae:digitalid:profile:general',
  'urn:uae:digitalid:profile:general:profileType',
  'urn:uae:digitalid:profile:general:unifiedId',
].join(' '),
```

Only request scopes enabled for your UAE PASS client.

---

# Debug logging

Enable package lifecycle logs during integration:

```dart
onLog: debugPrint,
```

Typical sequence when the app is installed:

```text
[uaepass_flutter] UAE PASS app detected. Using on-device app authentication flow.
[uaepass_flutter] Authorization URL prepared.
[uaepass_flutter] WebView navigation: https://stg-id.uaepass.ae/...
[uaepass_flutter] WebView navigation: uaepassstg://...
[uaepass_flutter] Opening the UAE PASS mobile application.
[uaepass_flutter] UAE PASS mobile application opened. Waiting for callback.
[uaepass_flutter] App callback received: abqamaruaepass://resume_authn
[uaepass_flutter] Resuming UAE PASS authorization in the existing WebView.
[uaepass_flutter] Authorization code received successfully.
[uaepass_flutter] Exchanging authorization code for access token.
[uaepass_flutter] Access token received successfully.
[uaepass_flutter] Requesting UAE PASS user profile.
[uaepass_flutter] UAE PASS user profile received successfully.
```

The logger intentionally does **not** log the client secret, access token, authorization code, or URL query parameters.

---

# Troubleshooting physical devices

If tapping UAE PASS does not open the UAE PASS app:

1. Confirm the correct UAE PASS environment app is installed.
2. Confirm Android `<queries>` or iOS `LSApplicationQueriesSchemes` are present.
3. Confirm `appScheme` exactly matches the Android/iOS callback scheme.
4. On Android inspect the **Merged Manifest**, not only the source manifest.
5. Confirm `MainActivity` uses `android:launchMode="singleTask"`.
6. Confirm staging credentials are used with staging endpoints/app and production credentials with production.
7. Enable `onLog: debugPrint` and identify where the flow stops.

Android examples:

```bash
adb shell pm path ae.uaepass.mainapp
adb shell pm path ae.uaepass.mainapp.stg
adb shell am start -W -a android.intent.action.VIEW -d "abqamaruaepass://resume_authn?url=https%3A%2F%2Fexample.com"
```

---

# Digital signing roadmap

Version `0.0.1` does not make UAE PASS signing API calls yet, but the public package layout already contains:

```text
lib/src/signing/
  uae_pass_signing_models.dart
  uae_pass_signing_service.dart
```

The authentication client is intentionally independent from signing, allowing future support for:

- single-document signing
- multiple-document signing
- signer process creation
- signature position configuration
- signing status
- signed-document download
- process cleanup
- LTV-related flows

without breaking the current login API.

A future API can therefore be added alongside authentication, for example:

```dart
final login = await uaePass.login(context);

// Future version:
// final signed = await uaePass.signing.signDocument(...);
```

---

# Official UAE PASS references

- Mobile application requirements: https://docs.uaepass.ae/feature-guides/authentication/mobile-application/requirements
- Mobile application API flow: https://docs.uaepass.ae/feature-guides/authentication/mobile-application/guide/api
- Authentication endpoints: https://docs.uaepass.ae/feature-guides/authentication/web-application/endpoints
- Access token: https://docs.uaepass.ae/feature-guides/authentication/web-application/2.-obtaining-the-access-token
- User information: https://docs.uaepass.ae/feature-guides/authentication/web-application/3.-obtaining-authenticated-user-information-from-the-access-token
- Attributes: https://docs.uaepass.ae/resources/attributes-list

---

# Disclaimer

`uaepass_flutter` is an independent integration package and is not affiliated with, endorsed by, or an official SDK of UAE PASS. UAE PASS documentation and onboarding requirements remain authoritative.
