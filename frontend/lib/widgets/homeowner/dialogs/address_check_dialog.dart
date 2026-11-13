import 'package:flutter/material.dart';

import '../../../services/verification_check_service.dart';
import '../profile/profile_styles.dart';

class AddressCheckDialog extends StatefulWidget {
  const AddressCheckDialog({
    super.key,
    required this.initialAddress,
    required this.email,
    required this.checkService,
    required this.onSaved,
    required this.onMessage,
  });

  final String initialAddress;
  final String email;
  final VerificationCheckService checkService;
  final VoidCallback onSaved;
  final void Function(String message) onMessage;

  @override
  State<AddressCheckDialog> createState() => _AddressCheckDialogState();
}

class _AddressCheckDialogState extends State<AddressCheckDialog> {
  late final TextEditingController _controller;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.email.isEmpty) {
      Navigator.pop(context);
      widget.onMessage('Please log in to save your address.');
      return;
    }

    final address = _controller.text.trim();
    if (address.isEmpty) {
      setState(() => _errorText = 'Enter your home address.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final result = await widget.checkService.submitResidenceCheck(
        email: widget.email,
        address: address,
      );
      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pop(context);
        widget.onSaved();
      } else {
        setState(() {
          _submitting = false;
          _errorText = result['message']?.toString() ?? 'Save failed.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = 'Save failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileDialogShell(
      children: [
        const ProfileDialogHeader(
          icon: Icons.home_outlined,
          title: 'Home address',
          subtitle: 'Confirm or enter the physical address of your home.',
        ),
        const SizedBox(height: 20),
        const ProfileFieldLabel('Home address'),
        TextField(
          controller: _controller,
          enabled: !_submitting,
          minLines: 1,
          maxLines: 3,
          keyboardType: TextInputType.streetAddress,
          textCapitalization: TextCapitalization.words,
          decoration: profileFieldDecoration(null, hint: 'e.g. 12 Oak Street, Rondebosch'),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 14),
          ProfileDialogError(message: _errorText!),
        ],
        const SizedBox(height: 18),
        ProfileSaveButton(
          label: 'Save & confirm',
          saving: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
        ProfileDialogCancelButton(enabled: !_submitting),
      ],
    );
  }
}
