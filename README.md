# uaepass_flutter

Unofficial reusable Flutter package for UAE PASS mobile authentication, designed so digital-document signing can be added without redesigning the package API.

> This package is not an official UAE PASS SDK. Follow your UAE PASS onboarding team's configuration and current UAE PASS documentation.

## Naming

- Dart/Flutter package: `uaepass_flutter`
- Example Android applicationId: `com.abqamar.uaepass_flutter`
- Example iOS bundle identifier: `com.abqamar.uaepass_flutter`
- Recommended custom callback scheme: `abqamaruaepass`

Do not use the package/bundle identifier directly as the OAuth redirect URI unless UAE PASS has registered that exact URI. The OAuth `redirectUri` is normally the HTTPS URL registered during onboarding; `appScheme` is the mobile app-to-app callback scheme.

## Current scope

Version 0.0.1 implements the mobile authorization-code flow:

1. Opens the UAE PASS authorization endpoint in an embedded WebView.
2. Uses the UAE PASS on-device ACR when the UAE PASS app is installed.
3. Intercepts UAE PASS/mobile-ID custom-scheme navigation.
4. Rewrites `successURL` and `failureURL` to the consuming application's custom scheme.
5. Launches the UAE PASS application.
6. Receives `appScheme://resume_authn?url=...` through `app_links`.
7. Resumes the original URL in the same WebView.
8. Detects the registered OAuth redirect URI.
9. Validates OAuth `state`.
10. Returns the authorization code to the consuming app.

The mobile app should send the authorization code to its backend. Keep the UAE PASS client secret on the backend rather than embedding it in the APK/IPA.

## Usage

```dart
final uaePass = UaePassFlutter(
  config: UaePassConfig(
    clientId: 'YOUR_CLIENT_ID',
    redirectUri: 'https://your-domain.ae/uaepass/callback',
    appScheme: 'abqamaruaepass',
    environment: UaePassEnvironment.staging,
    onLog: debugPrint,
  ),
);

final result = await uaePass.authenticate(context);

if (result.isSuccess) {
  final code = result.authorizationCode!;
  // Send `code` to your backend immediately.
}
```

## Android configuration

In the consuming application's `android/app/src/main/AndroidManifest.xml`, add package visibility inside `<manifest>`:

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
</queries>
```

Add the callback filter to `MainActivity` and keep `launchMode="singleTask"`:

```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTask">

    <!-- existing launcher filter -->

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

The value `abqamaruaepass` must match `UaePassConfig.appScheme`.

## iOS configuration

Add UAE PASS schemes and your callback scheme to `ios/Runner/Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>uaepass</string>
    <string>uaepassstg</string>
</array>

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

## Digital signing roadmap

The package already reserves a `signing` module and exposes `UaePassSigningBackend` plus request/session/result models. The intended architecture is:

```text
Flutter app / uaepass_flutter
        |
        | authenticated user + document request
        v
Your backend
        |
        | signing credentials / access token
        v
UAE PASS signing APIs
        |
        +--> create document / signer process
        +--> signing UI
        +--> poll/get result
        +--> download signed document
        +--> delete process
        +--> optional LTV handling
```

This supports future single-document and multi-document signing without putting UAE PASS signing credentials inside the mobile application.

## Security notes

- Generate and validate OAuth `state` for each authentication attempt.
- Use the exact redirect URI registered with UAE PASS.
- Use a unique custom app scheme; do not reuse demo schemes.
- Do not store the UAE PASS client secret in Flutter source, assets, `.env`, or compile-time constants.
- Exchange the authorization code on your backend. UAE PASS authorization codes are short-lived, so send them to the backend immediately.

## Example bundle/application ID

When creating the example application locally, use:

```text
com.abqamar.uaepass_flutter
```
