import 'dart:typed_data';

import 'uae_pass_signing_models.dart';

/// Abstraction for future UAE PASS signing support.
///
/// Recommended implementation: the consuming application's backend talks to
/// UAE PASS signing APIs, while this Flutter package handles the mobile UX.
/// This avoids placing signing/client secrets in the APK/IPA.
abstract interface class UaePassSigningBackend {
  Future<UaePassSigningSession> createSigningSession(
    UaePassSigningRequest request,
  );

  Future<UaePassSigningStatus> getSigningStatus(String processId);

  Future<Uint8List> downloadSignedDocument(String documentId);

  Future<void> deleteSigningProcess(String processId);
}
