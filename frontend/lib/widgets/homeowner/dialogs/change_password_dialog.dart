import 'package:flutter/material.dart';

import '../../../services/auth_services.dart';
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
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Change password',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentController,
              obscureText: _hideCurrent,
              decoration: profileFieldDecoration('Current password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _hideCurrent ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _hideCurrent = !_hideCurrent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newController,
              obscureText: _hideNew,
              decoration: profileFieldDecoration('New password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _hideNew ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _hideNew = !_hideNew),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmController,
              obscureText: _hideNew,
              decoration: profileFieldDecoration('Confirm new password'),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(_errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
          ),
          onPressed: _saving ? null : _submit,
          child: _saving ? profileButtonSpinner : const Text('Update password'),
        ),
      ],
    );
  }
}
