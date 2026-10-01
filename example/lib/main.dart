import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uaepass_flutter/uaepass_flutter.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final UaePassFlutter _uaePass = UaePassFlutter(
    config: UaePassConfig(
      clientId: 'YOUR_CLIENT_ID',
      clientSecret: 'YOUR_CLIENT_SECRET',
      redirectUri: 'YOUR_REGISTERED_REDIRECT_URI',
      appScheme: 'abqamaruaepass',
      environment: UaePassEnvironment.staging,
      locale: 'en',
      onLog: kDebugMode ? debugPrint : null,
    ),
  );

  bool _loading = false;
  String _result = 'Not authenticated';

  @override
  void dispose() {
    _uaePass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loading) return;

    setState(() => _loading = true);

    final result = await _uaePass.login(context);

    if (!mounted) return;

    setState(() {
      _loading = false;

      if (result.isSuccess) {
        final profile = result.profile!;
        _result = <String>[
          'Authenticated',
          'UUID: ${profile.uuid ?? '-'}',
          'Name: ${profile.fullnameEN ?? '-'}',
          'Email: ${profile.email ?? '-'}',
          'Mobile: ${profile.mobile ?? '-'}',
        ].join('\n');
      } else if (result.isCancelled) {
        _result = 'Authentication cancelled';
      } else {
        _result =
            'Failed: ${result.errorDescription ?? result.error ?? 'Unknown error'}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('uaepass_flutter 0.0.1')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login with UAE PASS'),
              ),
              const SizedBox(height: 24),
              Text(
                _result,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
