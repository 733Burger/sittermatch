import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/pet_model.dart';
import '../../../services/auth_services.dart';
import '../../../services/profile_service.dart';
import '../../../theme/app_colors.dart';
import '../profile/profile_styles.dart';

class PetFormDialog extends StatefulWidget {
  const PetFormDialog({
    super.key,
    this.pet,
    required this.profileService,
    required this.onSaved,
    required this.onMessage,
  });

  final PetModel? pet;
  final ProfileService profileService;
  final Future<void> Function() onSaved;
  final void Function(String message) onMessage;

  @override
  State<PetFormDialog> createState() => _PetFormDialogState();
}

class _PetFormDialogState extends State<PetFormDialog> {
  static const int _minPetAge = 0;
  static const int _maxPetAge = 20;

  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _ageController;
  late final TextEditingController _careController;

  String? _selectedSpecies;
  String? _nameError;
  String? _breedError;
  String? _speciesError;
  String? _ageError;
  String? _saveError;
  bool _saving = false;

  bool get _isEdit => widget.pet != null;

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    _nameController = TextEditingController(text: pet?.name ?? '');
    _breedController = TextEditingController(text: pet?.breed ?? '');
    _ageController = TextEditingController(text: pet == null ? '' : '${pet.age}');
    _careController = TextEditingController(text: pet?.careNotes ?? '');
    final species = pet?.species.toUpperCase();
    _selectedSpecies = species != null && petTypes.contains(species) ? species : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageController.dispose();
    _careController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final breed = _breedController.text.trim();
    final species = _selectedSpecies ?? '';
    final age = int.tryParse(_ageController.text.trim());
    final ageOk = age != null && age >= _minPetAge && age <= _maxPetAge;

    if (name.isEmpty || breed.isEmpty || species.isEmpty || !ageOk) {
      setState(() {
        _nameError = name.isEmpty ? 'Required' : null;
        _breedError = breed.isEmpty ? 'Required' : null;
        _speciesError = species.isEmpty ? 'Required' : null;
        _ageError = ageOk ? null : 'Enter an age from $_minPetAge to $_maxPetAge';
      });
      return;
    }

    final homeownerId = await AuthService().getUserId();
    if (!mounted) return;
    if (homeownerId == null) {
      setState(() => _saveError = 'Session expired. Please log in again.');
      return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
      _nameError = null;
      _breedError = null;
      _speciesError = null;
      _ageError = null;
    });

    final result = _isEdit
        ? await widget.profileService.updatePet(
            homeownerId: homeownerId,
            petId: widget.pet!.id!,
            name: name,
            species: species,
            breed: breed,
            age: age,
            careNotes: _careController.text.trim(),
          )
        : await widget.profileService.addPet(
            homeownerId: homeownerId,
            name: name,
            species: species,
            breed: breed,
            age: age,
            careNotes: _careController.text.trim(),
          );
    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.pop(context);
      await widget.onSaved();
      widget.onMessage(_isEdit ? 'Pet details updated.' : '$name added as a pet.');
    } else {
      setState(() {
        _saving = false;
        _saveError = result['message']?.toString() ?? 'Could not add pet.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      padding: viewInsets,
      child: Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 420,
            maxHeight: MediaQuery.sizeOf(context).height - viewInsets.vertical - 48,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.lightRustBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.pets, color: AppColors.primaryRust, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEdit ? 'Edit pet' : 'Add a pet',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isEdit
                                ? 'Update the details sitters will see.'
                                : 'Tell sitters who they will be looking after.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _saving
                      ? null
                      : () => widget.onMessage('Pet photo upload is coming soon.'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightRustBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: AppColors.primaryRust, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add photo',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkText,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Photo upload is coming soon.',
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const ProfileFieldLabel('Pet name'),
                TextField(
                  controller: _nameController,
                  enabled: !_saving,
                  maxLength: 255,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: profileFieldDecoration(
                    null,
                    hint: 'e.g. Daisy')
                    .copyWith(errorText: _nameError, counterText: ''),
                ),
                const SizedBox(height: 16),
                const ProfileFieldLabel('Breed'),
                TextField(
                  controller: _breedController,
                  enabled: !_saving,
                  maxLength: 255,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: profileFieldDecoration(
                    null,
                    hint: 'e.g. Jack Russel')
                    .copyWith(errorText: _breedError, counterText: ''),
                ),
                const SizedBox(height: 16),
                const ProfileFieldLabel('Type of pet'),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSpecies,
                  isExpanded: true,
                  hint: const Text(
                    'Select a type',
                    style: TextStyle(color: Colors.black38, fontSize: 14),
                  ),
                  decoration: profileFieldDecoration(null).copyWith(errorText: _speciesError),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  items: [
                    for (final type in petTypes)
                      DropdownMenuItem(value: type, child: Text(petTypeLabel(type))),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                            _selectedSpecies = value;
                            _speciesError = null;
                          }),
                ),
                const SizedBox(height: 16),
                const ProfileFieldLabel('Age (years)'),
                TextField(
                  controller: _ageController,
                  enabled: !_saving,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  textInputAction: TextInputAction.next,
                  decoration: profileFieldDecoration(
                    null,
                    hint: 'e.g. 3',
                  ).copyWith(errorText: _ageError),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Care notes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Optional. Includes feeding, medication, or routines.',
                  style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _careController,
                  enabled: !_saving,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 255,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: profileFieldDecoration(
                    null,
                    hint: 'e.g. Needs medication with dinner.',
                  ).copyWith(counterText: ''),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Behaviour scores and reviews are added by sitters after a stay.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECEC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _saveError!,
                      style: const TextStyle(color: Color(0xFFB42318), fontSize: 12, height: 1.35),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                ProfileSaveButton(
                  label: _isEdit ? 'Save changes' : 'Add pet',
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
}
