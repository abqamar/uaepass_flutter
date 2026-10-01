import 'package:flutter/material.dart';

import '../auth/uae_pass_auth_page.dart';
import '../auth/uae_pass_auth_result.dart';
import 'uae_pass_config.dart';

class UaePassFlutter {
  const UaePassFlutter({required this.config});

  final UaePassConfig config;

  Future<UaePassAuthResult> authenticate(BuildContext context) async {
    config.validate();

    final result = await Navigator.of(context).push<UaePassAuthResult>(
      MaterialPageRoute<UaePassAuthResult>(
        fullscreenDialog: true,
        builder: (_) => UaePassAuthPage(config: config),
      ),
    );

    return result ?? const UaePassAuthResult.cancelled();
  }
}
