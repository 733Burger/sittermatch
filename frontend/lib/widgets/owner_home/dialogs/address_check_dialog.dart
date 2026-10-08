import 'package:flutter/material.dart';

import '../../../services/home_services.dart';

class AddressCheckDialog extends StatefulWidget {
  const AddressCheckDialog({
    super.key,
    required this.initialAddress,
    required this.email,
    required this.homeService,
    required this.onSaved,
    required this.onMessage,
  });

  final String initialAddress;
  final String email;
  final HomeService homeService;
  final VoidCallback onSaved;
  final void Function(String message) onMessage;

  @override
  State<AddressCheckDialog> createState() => _AddressCheckDialogState();
}

class _AddressCheckDialogState extends State<AddressCheckDialog> {
  late final TextEditingController _controller;
  bool _submitting = false;

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
    setState(() => _submitting = true);

    try {
      final result = await widget.homeService.submitResidenceCheck(
        email: widget.email,
        address: address,
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
      title: const Text('Home Address Verification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Confirm or enter your home physical address:'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            enabled: !_submitting,
            decoration: const InputDecoration(
              labelText: 'Home Address',
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
          child: const Text('Save & Confirm'),
        ),
      ],
    );
  }
}
