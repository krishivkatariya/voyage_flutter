
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/auth/screens/register_screen.dart';
import 'package:voyage_flutter/features/auth/services/auth_service.dart';
import 'package:voyage_flutter/features/auth/services/auth_validators.dart';

const Color _loginPurple = Color(0xFF6D4AFF);
const Color _loginDarkPurple = Color(0xFF38216D);
const Color _loginBackground = Color(0xFFF8F7FC);
const Color _loginText = Color(0xFF28213B);
const Color _loginMuted = Color(0xFF77738A);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _authService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(AuthService.errorMessage(error)),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _openRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _loginBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 850;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 36 : 22,
                  vertical: 28,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1080,
                  ),
                  child: isWide
                      ? _buildWideLayout()
                      : _buildMobileLayout(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 440,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBrandHeader(compact: true),
            const SizedBox(height: 28),
            _buildLoginForm(),
            const SizedBox(height: 22),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 11,
          child: _buildBrandHeader(compact: false),
        ),
        const SizedBox(width: 48),
        Expanded(
          flex: 9,
          child: Container(
            padding: const EdgeInsets.all(34),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFECE8F5),
              ),
              boxShadow: [
                BoxShadow(
                  color: _loginDarkPurple.withValues(alpha: 0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLoginForm(),
                const SizedBox(height: 22),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandHeader({required bool compact}) {
    return Container(
      padding: EdgeInsets.all(compact ? 25 : 34),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7655F5),
            Color(0xFF5734C9),
            Color(0xFF39216F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _loginPurple.withValues(alpha: 0.19),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.23),
                  ),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 13),
              const Text(
                'Voyage',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 30 : 40),
          const Text(
            'YOUR NEXT ADVENTURE',
            style: TextStyle(
              color: Color(0xFFDCD2FF),
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'The world is\nwaiting for you.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 31 : 39,
              height: 1.13,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Plan unforgettable journeys, organize your '
                'itinerary, and make every trip count.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.83),
              fontSize: 14,
              height: 1.7,
            ),
          ),
          SizedBox(height: compact ? 25 : 38),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.17),
              ),
            ),
            child: Row(
              children: [
                _travelIcon(Icons.flight_takeoff_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your journey begins here',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Dream it. Plan it. Experience it.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.76),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 30),
            const Row(
              children: [
                Icon(
                  Icons.public_rounded,
                  color: Color(0xFFDCD2FF),
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  'Made for travelers and explorers',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _travelIcon(IconData icon) {
    return Container(
      width: 43,
      height: 43,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 23,
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              color: _loginText,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Sign in to continue your journey.',
            style: TextStyle(
              color: _loginMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Email address',
            style: TextStyle(
              color: _loginText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 9),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'you@example.com',
              prefixIcon: const Icon(
                Icons.mail_outline_rounded,
                color: _loginPurple,
                size: 21,
              ),
              filled: true,
              fillColor: const Color(0xFFFAF9FD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFE7E2F1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFE7E2F1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: _loginPurple,
                  width: 1.6,
                ),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: AuthValidators.validateEmail,
          ),
          const SizedBox(height: 20),
          const Text(
            'Password',
            style: TextStyle(
              color: _loginText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 9),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              hintText: 'Enter your password',
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: _loginPurple,
                size: 21,
              ),
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Show password'
                    : 'Hide password',
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _loginMuted,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFFAF9FD),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFE7E2F1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: Color(0xFFE7E2F1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(
                  color: _loginPurple,
                  width: 1.6,
                ),
              ),
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            validator: AuthValidators.validatePassword,
          ),
          const SizedBox(height: 27),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _login,
              style: FilledButton.styleFrom(
                backgroundColor: _loginPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _loginPurple.withValues(
                  alpha: 0.55,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sign in',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 9),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Divider(color: Color(0xFFE7E2F1)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13),
              child: Text(
                'NEW TO VOYAGE?',
                style: TextStyle(
                  color: _loginMuted.withValues(alpha: 0.9),
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Expanded(
              child: Divider(color: Color(0xFFE7E2F1)),
            ),
          ],
        ),
        const SizedBox(height: 13),
        SizedBox(
          width: double.infinity,
          height: 49,
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : _openRegistration,
            style: OutlinedButton.styleFrom(
              foregroundColor: _loginPurple,
              side: const BorderSide(
                color: Color(0xFFDCD2FF),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Create an account',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'YOUR NEXT ADVENTURE STARTS HERE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFAAA4BA),
            fontSize: 9,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
