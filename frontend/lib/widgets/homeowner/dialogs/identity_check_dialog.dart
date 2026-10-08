import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/home_services.dart';

class IdentityCheckDialog extends StatefulWidget {
  const IdentityCheckDialog({
    super.key,
    required this.email,
    required this.homeService,
    required this.hasSelectedPhoto,
    required this.onUploaded,
    required this.onMessage,
  });

  final String email;
  final HomeService homeService;
  final bool hasSelectedPhoto;
  final void Function(String photoPath) onUploaded;
  final void Function(String message) onMessage;

  @override
  State<IdentityCheckDialog> createState() => _IdentityCheckDialogState();
}

class _IdentityCheckDialogState extends State<IdentityCheckDialog> {
  bool _submitting = false;

  Future<void> _pickAndSubmit(ImageSource source) async {
    if (widget.email.isEmpty) {
      Navigator.pop(context);
      widget.onMessage('Please log in to upload your ID.');
      return;
    }

    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (!mounted) return;

      if (photo == null) {
        setState(() => _submitting = false);
        return;
      }

      final bytes = await photo.readAsBytes();
      final result = await widget.homeService.submitIdentityCheck(
        email: widget.email,
        bytes: bytes,
        filename: photo.name.isEmpty ? 'id-photo.jpg' : photo.name,
      );

      // The dialog may have been dismissed while uploading; the result is
      // still reported to the screen.
      if (mounted) Navigator.pop(context);

      if (result['success'] == true) {
        widget.onUploaded(photo.path);
      } else {
        widget.onMessage(result['message']?.toString() ?? 'Upload failed.');
      }
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      widget.onMessage('Upload failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Identity / SA ID Verification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Upload a clear photo of your South African ID Document or Card.',
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed:
                _submitting ? null : () => _pickAndSubmit(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: Text(
              widget.hasSelectedPhoto
                  ? 'Change Selected Photo'
                  : 'Select from Gallery',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed:
                _submitting ? null : () => _pickAndSubmit(ImageSource.camera),
            icon: const Icon(Icons.photo_camera),
            label: Text(
              widget.hasSelectedPhoto ? 'Replace with camera' : 'Take a Photo',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}