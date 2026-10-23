import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:voyage_flutter/core/constants/app_constants.dart';
import 'package:voyage_flutter/features/auth/screens/auth_gate.dart';
import 'package:voyage_flutter/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const VoyageApp());
}

class VoyageApp extends StatefulWidget {
  const VoyageApp({super.key});

  @override
  State<VoyageApp> createState() => _VoyageAppState();
}

class _VoyageAppState extends State<VoyageApp> {
  late final Future<FirebaseApp> _firebaseInitialization;

  @override
  void initState() {
    super.initState();
    _firebaseInitialization = _initializeFirebase();
  }

  Future<FirebaseApp> _initializeFirebase() async {
    try {
      final app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      debugPrint('Firebase project: ${app.options.projectId}');

      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('trips')
            .doc('test')
            .get();

        debugPrint('Firestore test successful.');
        debugPrint('Document exists: ${snapshot.exists}');
        debugPrint('Document data: ${snapshot.data()}');
      } catch (error, stackTrace) {
        debugPrint('Firestore test FAILED: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      return app;
    } on Object catch (error, stackTrace) {
      debugPrint('Firebase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,

      // Global purple-and-white theme.
      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D4AFF),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color(0xFFF8F7FC),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F7FC),
          foregroundColor: Color(0xFF241B35),
          elevation: 0,
          centerTitle: false,
        ),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFECE8F5)),
          ),
          clipBehavior: Clip.antiAlias,
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE4DEEF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE4DEEF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF6D4AFF), width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
          ),
        ),

        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF6D4AFF),
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6D4AFF),
            minimumSize: const Size(0, 50),
            side: const BorderSide(color: Color(0xFFD8CEF8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF6D4AFF)),
        ),

        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Color(0xFF6D4AFF),
        ),
      ),

      home: FutureBuilder<FirebaseApp>(
        future: _firebaseInitialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return const _FirebaseConfigurationScreen();
          }

          return const AuthGate();
        },
      ),
    );
  }
}

class _FirebaseConfigurationScreen extends StatelessWidget {
  const _FirebaseConfigurationScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECE6FF),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.cloud_off_outlined,
                      size: 44,
                      color: Color(0xFF6D4AFF),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Firebase could not be initialized.',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF241B35),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Configure this app with FlutterFire CLI, '
                    'then restart Voyage.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
