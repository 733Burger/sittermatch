import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/verification_check_service.dart';
import '../../../theme/app_colors.dart';
import '../profile/profile_styles.dart';

class IdentityCheckDialog extends StatefulWidget {
  const IdentityCheckDialog({
    super.key,
    required this.email,
    required this.checkService,
    required this.onUploaded,
    required this.onMessage,
  });

  final String email;
  final VerificationCheckService checkService;
  final VoidCallback onUploaded;
  final void Function(String message) onMessage;

  @override
  State<IdentityCheckDialog> createState() => _IdentityCheckDialogState();
}

class _IdentityCheckDialogState extends State<IdentityCheckDialog> {
  final ImagePicker _picker = ImagePicker();

  Uint8List? _bytes;
  String _filename = 'id-photo.jpg';
  bool _picking = false;
  bool _submitting = false;
  String? _errorText;

  bool get _busy => _picking || _submitting;
  bool get _canUseCamera => _picker.supportsImageSource(ImageSource.camera);

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() {
      _picking = true;
      _errorText = null;
    });

    try {
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2000,
      );
      if (photo == null) return;

      final bytes = await photo.readAsBytes();
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _filename = photo.name.isEmpty ? 'id-photo.jpg' : photo.name;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorText = source == ImageSource.camera
          ? 'Could not open the camera.'
          : 'Could not open that photo.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _submit() async {
    final bytes = _bytes;
    if (bytes == null || _busy) return;

    if (widget.email.isEmpty) {
      Navigator.pop(context);
      widget.onMessage('Please log in to upload your ID.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      final result = await widget.checkService.submitIdentityCheck(
        email: widget.email,
        bytes: bytes,
        filename: _filename,
      );
      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pop(context);
        widget.onUploaded();
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
          subtitle: 'Upload a clear photo of your South African ID document or card, '
              'with all four corners showing.',
        ),
        const SizedBox(height: 20),
        _UploadBox(
          bytes: _bytes,
          loading: _picking,
          enabled: !_busy,
          onTap: () => _pick(ImageSource.gallery),
        ),
        if (_canUseCamera) ...[
          const SizedBox(height: 14),
          const _OrDivider(),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _busy ? null : () => _pick(ImageSource.camera),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.lightRustBg,
                foregroundColor: AppColors.primaryRust,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.photo_camera_outlined, size: 20),
              label: Text(
                _bytes == null ? 'Open camera & take photo' : 'Retake with camera',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
        if (_errorText != null) ...[
          const SizedBox(height: 14),
          ProfileDialogError(message: _errorText!),
        ],
        const SizedBox(height: 18),
        ProfileSaveButton(
          label: 'Continue',
          saving: _submitting,
          onPressed: _bytes == null || _busy ? null : _submit,
        ),
        ProfileDialogCancelButton(enabled: !_submitting),
      ],
    );
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.bytes,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final Uint8List? bytes;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = bytes;

    Widget content;
    if (loading) {
      content = const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryRust),
      );
    } else if (photo == null) {
      content = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, color: AppColors.primaryRust, size: 30),
          SizedBox(height: 8),
          Text(
            'Select photo',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText),
          ),
          SizedBox(height: 4),
          Text('JPG or PNG, up to 5 MB', style: TextStyle(fontSize: 12, color: Colors.black45)),
        ],
      );
    } else {
      content = Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(photo, fit: BoxFit.cover, gaplessPlayback: true),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      button: true,
      label: photo == null ? 'Select ID photo' : 'Change ID photo',
      child: Material(
        color: AppColors.expandButtonBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.primaryRust, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: SizedBox(height: 180, width: double.infinity, child: content),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: Colors.black45)),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300)),
      ],
    );
  }
}
