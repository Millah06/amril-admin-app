import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../components/bootom_bar.dart';
import '../components/flush_bar_message.dart';
import '../components/pin_entry.dart';
import '../constraints/constants.dart';
import '../core/theme/app_theme.dart';
import '../features/sheel_screen.dart';
import '../screens/main/home.dart';
import '../services/auth.dart';
import '../services/brain.dart';

/// Admin sign-in. Rebuilt to the quality of amril-app's auth screens (§7):
/// branded header, validated fields, show/hide password, loading + error
/// states. Auth logic is unchanged — [Authentication.signUp] signs the admin in
/// with Firebase and marks setup done, then we land on [ShellScreen].
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await Authentication().signUp(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const ShellScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      FlushBarMessage.showFlushBar(
        context: context,
        title: 'Sign-in failed',
        message: _authMessage(e),
        icon: const Icon(Icons.error_outline, color: kErrorIconColor, size: 30),
      );
    } catch (e) {
      if (!mounted) return;
      FlushBarMessage.showFlushBar(
        context: context,
        title: 'Sign-in failed',
        message: e.toString().replaceAll('Exception: ', ''),
        icon: const Icon(Icons.error_outline, color: kErrorIconColor, size: 30),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again in a moment.';
      default:
        return e.message ?? 'Could not sign in. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand mark
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.shield_moon_rounded,
                        color: AppTheme.primary, size: 38),
                  ),
                  const SizedBox(height: 20),
                  Text('Amril Admin',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text('Sign in to the control panel',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary, fontSize: 14)),
                  const SizedBox(height: 32),

                  // Email
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Email is required';
                      if (!t.contains('@') || !t.contains('.')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    onFieldSubmitted: (_) => _loading ? null : _signIn(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: FaIcon(
                            _obscure
                                ? FontAwesomeIcons.eyeSlash
                                : FontAwesomeIcons.eye,
                            size: 18,
                            color: AppTheme.textSecondary),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Password is required'
                        : null,
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signIn,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            )
                          : Text('Sign In',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Authorized personnel only.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Passcode lock screen. Kept for the biometric/PIN re-lock flow. NOTE: the old
/// version had an INVERTED check (it let you in when the passcode was WRONG) and
/// bound the email + passcode fields to the same controller — both fixed here.
class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  bool _obscure = true;
  final TextEditingController _controller = TextEditingController();

  Color _buttonColor = const Color(0x3321DEED);
  Color _textColor = Colors.white60;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _auth(Future<bool> canAuth) async {
    final LocalAuthentication auth = LocalAuthentication();
    if (await canAuth) {
      final result = await auth.authenticate(
        localizedReason: 'Use Fingerprint to login',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!mounted) return;
      if (result) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => Home()), (route) => false);
      } else {
        _biometricError();
      }
    } else {
      _biometricError();
    }
  }

  void _biometricError() {
    FlushBarMessage.showFlushBar(
      context: context,
      message: 'Your device doesn\'t support this method, use passcode instead.',
      title: 'Ops',
      icon: const Icon(Icons.error_outline, color: kErrorIconColor, size: 30),
    );
  }

  void _submitPasscode(Brain pov) {
    if (_controller.text.length != 6) return;
    // FIXED: enter on MATCH (was inverted — previously entered on mismatch).
    if (pov.localPasscode == _controller.text) {
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => BottomBar()), (route) => false);
    } else {
      FlushBarMessage.showFlushBar(
        context: context,
        message: 'Incorrect PassCode',
        title: 'Ops',
        icon: const Icon(Icons.error_outline, color: kErrorIconColor, size: 30),
      );
      _controller.clear();
      setState(() {
        _buttonColor = const Color(0x3321DEED);
        _textColor = Colors.white60;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<Brain>(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 30, left: 15, right: 15),
              child: Column(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipOval(
                      child: Image.asset('images/profile.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(pov.user,
                      style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black38),
                    child: TextFormField(
                      controller: _controller,
                      readOnly: true,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700),
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.security),
                        hintText: '6-digit PassCode',
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: FaIcon(
                              _obscure
                                  ? FontAwesomeIcons.eyeSlash
                                  : FontAwesomeIcons.eye,
                              size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                onTap: () {},
                child: Text('Forgot PassCode?',
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        color: kButtonColor,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.underline)),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () => _submitPasscode(pov),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _buttonColor,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 100),
                    side: BorderSide.none),
                child: Text('Login Now',
                    style: GoogleFonts.inter(
                        color: _textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 18)),
              ),
            ),
            CustomPinKeyboard(
              onKeyTap: (digit) {
                if (_controller.text.length < 6) {
                  _controller.text += digit;
                }
                if (_controller.text.length == 6) {
                  setState(() {
                    _buttonColor = const Color(0xFF21D3ED);
                    _textColor = Colors.black;
                  });
                }
              },
              onBackspace: () {
                if (_controller.text.isNotEmpty) {
                  _controller.text = _controller.text
                      .substring(0, _controller.text.length - 1);
                  setState(() {
                    _buttonColor = const Color(0x3321DEED);
                    _textColor = Colors.white60;
                  });
                }
              },
              onBiometric: () => _auth(pov.canAuthenticate()),
            ),
          ],
        ),
      ),
    );
  }
}
