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
      redirectUri: 'YOUR_REGISTERED_HTTPS_REDIRECT_URI',
      appScheme: 'abqamaruaepass',
      environment: UaePassEnvironment.staging,
      onLog: debugPrint,
    ),
  );

  String _result = 'Not authenticated';

  Future<void> _login() async {
    final result = await _uaePass.authenticate(context);

    if (!mounted) return;

    setState(() {
      _result = result.isSuccess
          ? 'Authorization code: ${result.authorizationCode}'
          : 'Status: ${result.status.name} - ${result.errorDescription ?? result.error ?? ''}';
    });

    // Recommended next step:
    // Send result.authorizationCode to YOUR backend.
    // The backend exchanges it for a UAE PASS token using the client secret.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('uaepass_flutter example')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: _login,
              child: const Text('Login with UAE PASS'),
            ),
            const SizedBox(height: 20),
            Text(_result),
          ],
        ),
      ),
    );
  }
}
