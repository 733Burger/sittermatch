import 'package:flutter/material.dart';

import '../../../services/home_services.dart';

class EmergencyContactDialog extends StatefulWidget {
  const EmergencyContactDialog({
    super.key,
    required this.initialName,
    required this.initialPhone,
    required this.email,
    required this.homeService,
    required this.onSaved,
    required this.onMessage,
  });

  final String initialName;
  final String initialPhone;
  final String email;
  final HomeService homeService;
  final VoidCallback onSaved;
  final void Function(String message) onMessage;

  @override
  State<EmergencyContactDialog> createState() => _EmergencyContactDialogState();
}

class _EmergencyContactDialogState extends State<EmergencyContactDialog> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _phone = TextEditingController(text: widget.initialPhone);
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
    final phone = _phone.text.trim();
    setState(() => _submitting = true);

    try {
      final result = await widget.homeService.submitEmergencyCheck(
        email: widget.email,
        name: name,
        phoneNumber: phone,
      );
      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pop(context);
        widget.onSaved();
      } else {
        setState(() => _submitting = false);
        widget.onMessage(result['message']?.toString() ?? 'Save failed.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      widget.onMessage('Save failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Emergency Contact Details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter a person we can call while you are away:'),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            enabled: !_submitting,
            decoration: const InputDecoration(
              labelText: 'Contact Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            enabled: !_submitting,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
          ),
          onPressed: _submitting ? null : _submit,
          child: const Text('Save Contact'),
        ),
      ],
    );
  }
}