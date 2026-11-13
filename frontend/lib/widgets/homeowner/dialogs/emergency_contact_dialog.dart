import 'package:flutter/material.dart';

import '../../../services/verification_check_service.dart';
import '../../../utils/sa_phone.dart';
import '../profile/profile_styles.dart';

class EmergencyContactDialog extends StatefulWidget {
  const EmergencyContactDialog({
    super.key,
    required this.initialName,
    required this.initialPhone,
    required this.email,
    required this.checkService,
    required this.onSaved,
    required this.onMessage,
  });

  final String initialName;
  final String initialPhone;
  final String email;
  final VerificationCheckService checkService;
  final VoidCallback onSaved;
  final void Function(String message) onMessage;

  @override
  State<EmergencyContactDialog> createState() => _EmergencyContactDialogState();
}

class _EmergencyContactDialogState extends State<EmergencyContactDialog> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _phone = TextEditingController(text: SaPhoneInputFormatter.format(widget.initialPhone));
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.email.isEmpty) {
      Navigator.pop(context);
      widget.onMessage('Please log in to save this contact.');
      return;
    }

    final name = _name.text.trim();
    final phone = SaPhoneInputFormatter.digitsOf(_phone.text);
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _errorText = 'Fill in both the name and phone number.');
      return;
    }
    if (!saPhoneRegex.hasMatch(phone)) {
      setState(() => _errorText = 'Enter a valid 10-digit SA number, e.g. 063 111 1111');
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final result = await widget.checkService.submitEmergencyCheck(
        email: widget.email,
        name: name,
        phoneNumber: phone,
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
          icon: Icons.contact_phone_outlined,
          title: 'Emergency contact',
          subtitle: 'Someone sitters can call while you are away.',
        ),
        const SizedBox(height: 20),
        const ProfileFieldLabel('Contact name'),
        TextField(
          controller: _name,
          enabled: !_submitting,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: profileFieldDecoration(null, hint: 'e.g. Thandi Mokoena'),
        ),
        const SizedBox(height: 16),
        const ProfileFieldLabel('Phone number'),
        TextField(
          controller: _phone,
          enabled: !_submitting,
          keyboardType: TextInputType.phone,
          inputFormatters: [SaPhoneInputFormatter()],
          textInputAction: TextInputAction.done,
          onSubmitted: _submitting ? null : (_) => _submit(),
          decoration: profileFieldDecoration(null, hint: 'e.g. 063 111 1111'),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 14),
          ProfileDialogError(message: _errorText!),
        ],
        const SizedBox(height: 18),
        ProfileSaveButton(
          label: 'Save contact',
          saving: _submitting,
          onPressed: _submitting ? null : _submit,
        ),
        ProfileDialogCancelButton(enabled: !_submitting),
      ],
    );
  }
}
