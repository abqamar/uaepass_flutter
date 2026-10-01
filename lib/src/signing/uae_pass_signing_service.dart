import 'dart:typed_data';

import 'uae_pass_signing_models.dart';

/// Extension point reserved for a future UAE PASS digital-signing module.
///
/// Version 0.0.1 intentionally does not implement signing API calls. Keeping
/// this interface separate from authentication allows single-document and
/// multi-document signing to be added later without breaking the login API.
abstract interface class UaePassSigningService {
  Future<UaePassSigningSession> createSigningSession(
    UaePassSigningRequest request,
  );

  Future<UaePassSigningStatus> getSigningStatus(String processId);

  Future<Uint8List> downloadSignedDocument(String documentId);

  Future<void> deleteSigningProcess(String processId);
}
