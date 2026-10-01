import 'dart:typed_data';

/// Public models reserved for the document-signing module.
///
/// UAE PASS requires authentication before document signing. The package keeps
/// signing behind a backend abstraction so client secrets and signing
/// credentials do not need to be embedded in a mobile application.
class UaePassSigningRequest {
  const UaePassSigningRequest({
    required this.documentBytes,
    required this.fileName,
    this.page = 'last',
    this.x = 100,
    this.y = 110,
    this.width = 400,
    this.height = 150,
    this.locale = 'en_US',
  });

  final Uint8List documentBytes;
  final String fileName;
  final String page;
  final double x;
  final double y;
  final double width;
  final double height;
  final String locale;
}

class UaePassSigningSession {
  const UaePassSigningSession({
    required this.processId,
    required this.signingUrl,
    this.documentId,
  });

  final String processId;
  final Uri signingUrl;
  final String? documentId;
}

enum UaePassSigningStatus {
  pending,
  completed,
  failed,
  cancelled,
}

class UaePassSigningResult {
  const UaePassSigningResult({
    required this.status,
    this.processId,
    this.documentId,
    this.signedDocument,
    this.message,
  });

  final UaePassSigningStatus status;
  final String? processId;
  final String? documentId;
  final Uint8List? signedDocument;
  final String? message;
}
