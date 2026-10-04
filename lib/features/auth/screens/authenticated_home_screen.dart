import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/auth/services/auth_service.dart';
import 'package:voyage_flutter/screens/itinerary_screen.dart';

class AuthenticatedHomeScreen extends StatefulWidget {
  const AuthenticatedHomeScreen({
    required this.user,
    required this.authService,
    super.key,
  });

  final firebase_auth.User user;
  final AuthService authService;

  @override
  State<AuthenticatedHomeScreen> createState() =>
      _AuthenticatedHomeScreenState();
}

class _AuthenticatedHomeScreenState extends State<AuthenticatedHomeScreen> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _profileStream;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _profileStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots();
  }

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() => _isLoggingOut = true);
    try {
      await widget.authService.logoutUser();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(AuthService.errorMessage(error))),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voyage Home'),
        actions: [
          TextButton.icon(
            onPressed: _isLoggingOut ? null : _logout,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Welcome,', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _profileStream,
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final storedName = data?['name'];
                  final name = storedName is String && storedName.isNotEmpty
                      ? storedName
                      : widget.user.displayName;

                  return Column(
                    children: [
                      if (name != null && name.isNotEmpty)
                        Text(
                          name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      Text(widget.user.email ?? 'Email unavailable'),
                      if (snapshot.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Profile name could not be loaded.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const ItineraryScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.event_note),
                label: const Text('Open existing itinerary'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
