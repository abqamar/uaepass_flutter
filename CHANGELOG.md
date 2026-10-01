# Changelog

## 0.0.1

Initial package release.

### Authentication
- UAE PASS staging and production environments.
- OAuth 2.0 authorization-code flow.
- Detects whether the UAE PASS mobile application can be launched.
- When UAE PASS is installed, uses the on-device authentication ACR and hands the flow to the UAE PASS app.
- When UAE PASS is not installed, keeps authentication inside an embedded in-app WebView.
- Handles custom-scheme callbacks and resumes the original UAE PASS callback URL in the same WebView.
- Validates OAuth `state`.
- Exchanges the authorization code for an access token.
- Retrieves the authenticated UAE PASS user profile.
- Exposes low-level `authorize`, `exchangeAuthorizationCode`, and `getUserProfile` methods in addition to high-level `login`.
- Supports detailed opt-in logging without logging the client secret or access token.

### Architecture
- Package name: `uaepass_flutter`.
- Example Android application ID / iOS bundle ID: `com.abqamar.uaepass_flutter`.
- Default sample app callback scheme: `abqamaruaepass`.
- Signing namespace and public models reserved for future UAE PASS document-signing integration.
