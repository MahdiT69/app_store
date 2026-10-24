import 'package:flutter/material.dart';
import 'package:app_store/controllers/user_controller.dart';
import 'package:app_store/controllers/auth_session.dart';
import 'package:app_store/utils/toast.dart';

const kDark = Color(0xFF16161A);
const kCard = Color(0xFF1E1E23);
const kBorder = Color(0xFF2C2C33);
const kGold = Color(0xFFD4A94D);
const kTextMuted = Color(0xFF9A9AA5);

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  final UserController _userController = UserController();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSavingProfile = false;
  bool _isSavingPassword = false;
  bool _obscurePassword = true;

  String get _userId => AuthSession.instance.currentUser?['id_user']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final result = await _userController.fetchUser(_userId);
    if (result['success'] == true) {
      final user = result['user'];
      _fullNameController.text = user.fullName ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phone ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    final result = await _userController.updateProfile(
      _userId,
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (mounted) {
      setState(() => _isSavingProfile = false);
      if (result['success'] == true) {
        AppToast.show(context, message: "Profile updated successfully.");
      } else {
        AppToast.show(
          context,
          message: result['message'] ?? "Update failed",
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _savePassword() async {
    if (_newPasswordController.text.trim().isEmpty) {
      AppToast.show(
        context,
        message: "Enter a new password first.",
        type: ToastType.error,
      );
      return;
    }

    setState(() => _isSavingPassword = true);
    final result = await _userController.changePassword(
      _userId,
      _newPasswordController.text.trim(),
    );
    if (mounted) {
      setState(() => _isSavingPassword = false);
      if (result['success'] == true) {
        _newPasswordController.clear();
        AppToast.show(context, message: "Password changed successfully.");
      } else {
        AppToast.show(
          context,
          message: result['message'] ?? "Update failed",
          type: ToastType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      floatingLabelStyle: const TextStyle(color: kGold),
      labelStyle: const TextStyle(color: kTextMuted),
      prefixIcon: Icon(icon, color: kTextMuted),
      filled: true,
      fillColor: kDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kGold, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 560,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(color: kGold),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header row with title + close button (replaces AppBar)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
                      child: Row(
                        children: [
                          const Text(
                            "My Account",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: kTextMuted),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProfileHeader(),
                            const SizedBox(height: 28),
                            _sectionCard(
                              title: "Profile information",
                              children: [
                                TextField(
                                  controller: _fullNameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _fieldDecoration(
                                    "Full name",
                                    Icons.person_outline,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // TextField(
                                //   controller: _emailController,
                                //   keyboardType: TextInputType.emailAddress,
                                //   style: const TextStyle(color: Colors.white),
                                //   decoration: _fieldDecoration(
                                //     "Email address",
                                //     Icons.email_outlined,
                                //   ),
                                // ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _fieldDecoration(
                                    "Phone number",
                                    Icons.phone_outlined,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isSavingProfile
                                        ? null
                                        : _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kGold,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: _isSavingProfile
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: kDark,
                                            ),
                                          )
                                        : const Text(
                                            "Save changes",
                                            style: TextStyle(
                                              color: kDark,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _sectionCard(
                              title: "Change password",
                              children: [
                                TextField(
                                  controller: _newPasswordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _fieldDecoration(
                                    "New password",
                                    Icons.lock_outline,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: kTextMuted,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: _isSavingPassword
                                        ? null
                                        : _savePassword,
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: kGold),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: _isSavingPassword
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: kGold,
                                            ),
                                          )
                                        : const Text(
                                            "Update password",
                                            style: TextStyle(
                                              color: kGold,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
          child: const Icon(Icons.person, color: kDark, size: 42),
        ),
        const SizedBox(height: 12),
        Text(
          AuthSession.instance.username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
