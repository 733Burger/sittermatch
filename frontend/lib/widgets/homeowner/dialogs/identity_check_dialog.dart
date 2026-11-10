import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/home_services.dart';
import '../../../theme/app_colors.dart';
import '../profile/profile_styles.dart';

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
  String? _errorText;

  Future<void> _pickAndSubmit(ImageSource source) async {
    if (widget.email.isEmpty) {
      Navigator.pop(context);
      widget.onMessage('Please log in to upload your ID.');
      return;
    }

    if (_submitting) return;
    setState(() {
      _submitting = true;
      _errorText = null;
    });

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
      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pop(context);
        widget.onUploaded(photo.path);
      } else {
        setState(() {
          _submitting = false;
          _errorText = result['message']?.toString() ?? 'Upload failed.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorText = 'Upload failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileDialogShell(
      children: [
        const ProfileDialogHeader(
          icon: Icons.badge_outlined,
          title: 'Identity verification',
          subtitle: 'Upload a clear photo of your South African ID document or card.',
        ),
        const SizedBox(height: 20),
        _PhotoOption(
          icon: Icons.photo_library_outlined,
          title: widget.hasSelectedPhoto ? 'Change selected photo' : 'Choose from gallery',
          subtitle: 'Pick an existing photo of your ID.',
          enabled: !_submitting,
          onTap: () => _pickAndSubmit(ImageSource.gallery),
        ),
        const SizedBox(height: 10),
        _PhotoOption(
          icon: Icons.photo_camera_outlined,
          title: widget.hasSelectedPhoto ? 'Replace with camera' : 'Take a photo',
          subtitle: 'Use your camera to capture your ID.',
          enabled: !_submitting,
          onTap: () => _pickAndSubmit(ImageSource.camera),
        ),
        if (_submitting) ...[
          const SizedBox(height: 14),
          const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryRust),
              ),
              SizedBox(width: 10),
              Text('Uploading…', style: TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ],
        if (_errorText != null) ...[
          const SizedBox(height: 14),
          ProfileDialogError(message: _errorText!),
        ],
        const SizedBox(height: 8),
        ProfileDialogCancelButton(enabled: !_submitting),
      ],
    );
  }
}

class _PhotoOption extends StatelessWidget {
  const _PhotoOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: AppColors.lightRustBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryRust, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.primaryRust),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
