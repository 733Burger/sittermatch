import 'package:flutter/material.dart';

import '../../../services/places_service.dart';
import '../../../theme/app_colors.dart';
import 'profile_styles.dart';

class ProfileAddressCard extends StatelessWidget {
  const ProfileAddressCard({
    super.key,
    required this.formKey,
    required this.addressController,
    required this.requirementsController,
    required this.searching,
    required this.suggestions,
    required this.notice,
    required this.saving,
    required this.onChanged,
    required this.onAddressChanged,
    required this.onAddressTap,
    required this.onSelectSuggestion,
    required this.addressValidator,
    required this.onAddressSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController addressController;
  final TextEditingController requirementsController;
  final bool searching;
  final List<PlaceSuggestion> suggestions;
  final String? notice;
  final bool saving;
  final VoidCallback onChanged;
  final ValueChanged<String> onAddressChanged;
  final VoidCallback onAddressTap;
  final ValueChanged<PlaceSuggestion> onSelectSuggestion;
  final FormFieldValidator<String> addressValidator;
  final VoidCallback onAddressSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: profileCardDecoration(),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Address details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Search for your home and choose it from the list. Saving stores the address and its map location.',
              style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
            ),
            const SizedBox(height: 20),
            const ProfileFieldLabel('Address'),
            TextFormField(
              controller: addressController,
              onChanged: onAddressChanged,
              onTap: onAddressTap,
              decoration: profileFieldDecoration(
                null,
                icon: Icons.location_on_outlined,
                hint: 'Start typing your home address',
              ),
              validator: addressValidator,
            ),
            if (searching)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: AppColors.primaryRust,
                  backgroundColor: AppColors.lightRustBg,
                ),
              ),
            if (suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < suggestions.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
                      InkWell(
                        onTap: () => onSelectSuggestion(suggestions[i]),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.place_outlined,
                                size: 18,
                                color: AppColors.primaryRust,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  suggestions[i].description,
                                  style: const TextStyle(fontSize: 13, color: AppColors.darkText),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if (notice != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  notice!,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            const SizedBox(height: 20),
            const ProfileFieldLabel('House sitting notes'),
            _HouseNotesField(
              controller: requirementsController,
              onPresenceChanged: onChanged,
            ),
            const SizedBox(height: 16),
            ProfileSaveButton(
              label: 'Save address details',
              saving: saving,
              onPressed: saving ? null : onAddressSave,
            ),
          ],
        ),
      ),
    );
  }
}

class _HouseNotesField extends StatefulWidget {
  const _HouseNotesField({
    required this.controller,
    required this.onPresenceChanged,
  });

  final TextEditingController controller;
  final VoidCallback onPresenceChanged;

  @override
  State<_HouseNotesField> createState() => _HouseNotesFieldState();
}

class _HouseNotesFieldState extends State<_HouseNotesField> {
  late bool _hasNotes;

  @override
  void initState() {
    super.initState();
    _hasNotes = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant _HouseNotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _hasNotes = widget.controller.text.trim().isNotEmpty;
  }

  void _onChanged(String value) {
    final hasNotes = value.trim().isNotEmpty;
    if (hasNotes == _hasNotes) return;
    _hasNotes = hasNotes;
    widget.onPresenceChanged();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      onChanged: _onChanged,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      minLines: 1,
      maxLines: 8,
      decoration: profileFieldDecoration(
        null,
        icon: Icons.note_alt_outlined,
        hint: 'e.g. Feed the dogs twice a day and lock the gate at 8 PM.',
      ),
      validator: (val) =>
          val == null || val.trim().isEmpty ? 'House sitting notes are required' : null,
    );
  }
}
