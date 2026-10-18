
import 'package:flutter/material.dart';
import 'package:voyage_flutter/features/auth/services/auth_service.dart';
import 'package:voyage_flutter/features/auth/services/auth_validators.dart';

const Color _registerPurple = Color(0xFF6D4AFF);
const Color _registerDarkPurple = Color(0xFF38216D);
const Color _registerBackground = Color(0xFFF8F7FC);
const Color _registerText = Color(0xFF28213B);
const Color _registerMuted = Color(0xFF77738A);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _authService.registerUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _registerBackground,
      appBar: AppBar(
        backgroundColor: _registerBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: _registerText,
          ),
        ),
        title: const Text(
          'Create account',
          style: TextStyle(
            color: _registerText,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 850;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 36 : 22,
                  vertical: 24,
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
            const SizedBox(height: 26),
            _buildRegistrationForm(),
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
          flex: 10,
          child: _buildBrandHeader(compact: false),
        ),
        const SizedBox(width: 42),
        Expanded(
          flex: 9,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFECE8F5),
              ),
              boxShadow: [
                BoxShadow(
                  color: _registerDarkPurple.withValues(alpha: 0.06),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRegistrationForm(),
                const SizedBox(height: 20),
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
      padding: EdgeInsets.all(compact ? 24 : 32),
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
            color: _registerPurple.withValues(alpha: 0.18),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.23),
                  ),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Voyage',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 25,
                  letterSpacing: -0.8,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 24 : 36),
          const Text(
            'YOUR JOURNEY STARTS HERE',
            style: TextStyle(
              color: Color(0xFFDCD2FF),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Make room for\nnew adventures.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 29 : 37,
              height: 1.14,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Create your account to organize trips, '
                'plan itineraries, and keep every journey '
                'in one place.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.83),
              fontSize: 13,
              height: 1.7,
            ),
          ),
          SizedBox(height: compact ? 22 : 34),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.17),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.public_rounded,
                  color: Colors.white,
                  size: 29,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'One account. Endless journeys.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Your next adventure awaits.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Join Voyage',
            style: TextStyle(
              color: _registerText,
              fontWeight: FontWeight.w800,
              fontSize: 27,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set up your account and start planning.',
            style: TextStyle(
              color: _registerMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 23),

          _fieldLabel('Full name'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: _inputDecoration(
              hint: 'Enter your full name',
              icon: Icons.person_outline_rounded,
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: AuthValidators.validateName,
          ),

          const SizedBox(height: 17),
          _fieldLabel('Email address'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            decoration: _inputDecoration(
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: AuthValidators.validateEmail,
          ),

          const SizedBox(height: 17),
          _fieldLabel('Password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            decoration: _inputDecoration(
              hint: 'Create a password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              onToggleVisibility: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: AuthValidators.validatePassword,
          ),

          const SizedBox(height: 17),
          _fieldLabel('Confirm password'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: _inputDecoration(
              hint: 'Enter your password again',
              icon: Icons.verified_user_outlined,
              obscure: _obscureConfirmPassword,
              onToggleVisibility: () {
                setState(() {
                  _obscureConfirmPassword =
                  !_obscureConfirmPassword;
                });
              },
            ),
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _register(),
            validator: (value) {
              return AuthValidators.validateConfirmPassword(
                value,
                password: _passwordController.text,
              );
            },
          ),

          const SizedBox(height: 25),
          SizedBox(
            height: 53,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _register,
              style: FilledButton.styleFrom(
                backgroundColor: _registerPurple,
                foregroundColor: Colors.white,
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
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create my account',
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

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: _registerText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleVisibility,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: _registerPurple,
        size: 21,
      ),
      suffixIcon: onToggleVisibility == null
          ? null
          : IconButton(
        tooltip: obscure ? 'Show password' : 'Hide password',
        onPressed: onToggleVisibility,
        icon: Icon(
          obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: _registerMuted,
        ),
      ),
      filled: true,
      fillColor: const Color(0xFFFAF9FD),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 17,
      ),
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
          color: _registerPurple,
          width: 1.6,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Color(0xFFE7E2F1),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 13),
              child: Text(
                'TRAVEL STARTS WITH A PLAN',
                style: TextStyle(
                  color: _registerMuted,
                  fontSize: 9,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Color(0xFFE7E2F1),
              ),
            ),
          ],
        ),
        SizedBox(height: 18),
        Text(
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
