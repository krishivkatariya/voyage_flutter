import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/auth/screens/authenticated_home_screen.dart';
import 'package:voyage_flutter/features/auth/screens/login_screen.dart';
import 'package:voyage_flutter/features/auth/services/auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _authService;
  late final Stream<firebase_auth.User?> _authStateChanges;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _authStateChanges = _authService.authStateChanges;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<firebase_auth.User?>(
      stream: _authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not check your sign-in status. '
                  '${AuthService.errorMessage(snapshot.error!)}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return AuthenticatedHomeScreen(user: user, authService: _authService);
      },
    );
  }
}
