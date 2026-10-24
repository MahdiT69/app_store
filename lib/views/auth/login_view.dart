import 'package:app_store/controllers/auth_session.dart';
import 'package:flutter/material.dart';

import 'package:app_store/controllers/auth_controller.dart';

const kDark = Color(0xFF16161A);
const kCard = Color(0xFF1E1E23);
const kBorder = Color(0xFF2C2C33);
const kGold = Color(0xFFD4A94D);
const kTextMuted = Color(0xFF9A9AA5);

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final AuthController _authController = AuthController();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _authController.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      debugPrint("Login success: ${result['user']}");
      AuthSession.instance.setUser(result['user']);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() => _errorMessage = result['message']);
    }
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      floatingLabelStyle: const TextStyle(color: kGold),
      labelStyle: const TextStyle(color: kTextMuted),
      prefixIcon: Icon(icon, color: kTextMuted),
      filled: true,
      fillColor: kDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kGold, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 520,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // LEFT CARD — logo / branding
                  Expanded(
                    flex: 4,
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: kCard.withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(24),
                        ),
                        border: Border.all(
                          color: kGold.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset('images/logo.png', height: 180),
                          const SizedBox(height: 20),
                          const Text(
                            "SHOPYME",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              letterSpacing: 1.6,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Gear that keeps your\nwork moving.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // RIGHT CARD — login form
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 48,
                      ),
                      decoration: BoxDecoration(
                        color: kCard,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(24),
                        ),
                        border: Border.all(color: kBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.close,
                                  size: 25,
                                  color: kGold,
                                ),
                                hoverColor: const Color.fromARGB(
                                  255,
                                  224,
                                  11,
                                  11,
                                ).withValues(alpha: 0.5),
                              ),
                            ),
                            const Text(
                              "Welcome back",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Sign in to continue to your account",
                              style: TextStyle(fontSize: 14, color: kTextMuted),
                            ),
                            const SizedBox(height: 32),

                            TextField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _fieldDecoration(
                                "Username",
                                Icons.person_outline,
                              ),
                            ),
                            const SizedBox(height: 18),

                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration:
                                  _fieldDecoration(
                                    "Password",
                                    Icons.lock_outline,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: kTextMuted,
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        );
                                      },
                                    ),
                                  ),
                              onSubmitted: (_) => _handleLogin(),
                            ),

                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: _errorMessage != null
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 14),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.redAccent.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: Colors.redAccent,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMessage!,
                                                style: const TextStyle(
                                                  color: Colors.redAccent,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            const SizedBox(height: 28),

                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kGold,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: kDark,
                                          strokeWidth: 2.4,
                                        ),
                                      )
                                    : const Text(
                                        "Login",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: kDark,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
