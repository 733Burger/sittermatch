import 'package:flutter/material.dart';

import '../../../services/auth_services.dart';
import '../../../theme/app_colors.dart';
import '../profile/profile_styles.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key, required this.onMessage});

  final void Function(String message) onMessage;

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  static const int _minPasswordLength = 8;

  final TextEditingController _currentController = TextEditingController();
  final TextEditingController _newController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _saving = false;
  String? _errorText;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentController.text;
    final next = _newController.text;

    if (current.isEmpty || next.isEmpty || _confirmController.text.isEmpty) {
      setState(() => _errorText = 'Fill in all three fields.');
      return;
    }
    if (next.length < _minPasswordLength) {
      setState(() => _errorText = 'New password must be at least $_minPasswordLength characters.');
      return;
    }
    if (next != _confirmController.text) {
      setState(() => _errorText = 'New passwords do not match.');
      return;
    }

    final userId = await AuthService().getUserId();
    if (!mounted) return;
    if (userId == null) {
      setState(() => _errorText = 'Session expired. Please log in again.');
      return;
    }

    setState(() {
      _saving = true;
      _errorText = null;
    });

    final result = await AuthService().changePassword(
      userId: userId,
      currentPassword: current,
      newPassword: next,
    );
    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(context);
      widget.onMessage('Password updated.');
    } else {
      setState(() {
        _saving = false;
        _errorText = result['message']?.toString() ?? 'Could not update password.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final longEnough = _newController.text.length >= _minPasswordLength;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: MediaQuery.viewInsetsOf(context),
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DialogHeader(
                  icon: Icons.lock_outline,
                  title: 'Change password',
                  subtitle: 'Choose a new password with at least 8 characters.',
                ),
                const SizedBox(height: 20),
                const ProfileFieldLabel('Current password'),
                TextField(
                  controller: _currentController,
                  enabled: !_saving,
                  obscureText: _hideCurrent,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                  decoration: _passwordDecoration(
                    hidden: _hideCurrent,
                    onToggle: () => setState(() => _hideCurrent = !_hideCurrent),
                  ),
                ),
                const SizedBox(height: 16),
                const ProfileFieldLabel('New password'),
                TextField(
                  controller: _newController,
                  enabled: !_saving,
                  obscureText: _hideNew,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  onChanged: (_) => setState(() {}),
                  decoration: _passwordDecoration(
                    hidden: _hideNew,
                    onToggle: () => setState(() => _hideNew = !_hideNew),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  longEnough ? 'Long enough to save.' : 'At least 8 characters.',
                  style: TextStyle(
                    fontSize: 12,
                    color: _newController.text.isEmpty
                        ? Colors.black45
                        : longEnough
                            ? AppColors.primaryRust
                            : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                const ProfileFieldLabel('Confirm new password'),
                TextField(
                  controller: _confirmController,
                  enabled: !_saving,
                  obscureText: _hideConfirm,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: _saving ? null : (_) => _submit(),
                  decoration: _passwordDecoration(
                    hidden: _hideConfirm,
                    onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
                  ),
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 14),
                  _DialogError(message: _errorText!),
                ],
                const SizedBox(height: 18),
                ProfileSaveButton(
                  label: 'Update password',
                  saving: _saving,
                  onPressed: _saving ? null : _submit,
                ),
                Center(
                  child: TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _passwordDecoration({
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return profileFieldDecoration(null).copyWith(
      suffixIcon: IconButton(
        onPressed: _saving ? null : onToggle,
        icon: Icon(
          hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: AppColors.primaryRust,
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.lightRustBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryRust, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DialogError extends StatelessWidget {
  const _DialogError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFFB42318), fontSize: 12, height: 1.35),
      ),
    );
  }
}
