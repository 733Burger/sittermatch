import 'package:flutter/material.dart';

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
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _isEdit ? 'Edit pet' : 'Add a pet',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () => widget.onMessage('Pet photo upload is coming soon.'),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.lightRustBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: AppColors.primaryRust),
                      SizedBox(height: 4),
                      Text(
                        'Add photo',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primaryRust,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              maxLength: 255,
              decoration: profileFieldDecoration('Pet name *')
                  .copyWith(errorText: _nameError, counterText: ''),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _breedController,
              maxLength: 255,
              decoration: profileFieldDecoration('Breed *')
                  .copyWith(errorText: _breedError, counterText: ''),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedSpecies,
              isExpanded: true,
              dropdownColor: Colors.white,
              decoration: profileFieldDecoration('Type of pet *').copyWith(errorText: _speciesError),
              items: petTypes
                  .map((type) => DropdownMenuItem(value: type, child: Text(petTypeLabel(type))))
                  .toList(),
              onChanged: (value) => setState(() => _selectedSpecies = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: profileFieldDecoration('Age (years) *').copyWith(errorText: _ageError),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _careController,
              maxLines: 2,
              maxLength: 255,
              decoration: profileFieldDecoration('Care notes').copyWith(counterText: ''),
            ),
            const SizedBox(height: 12),
            const Text(
              'Behaviour scores and reviews are added by sitters after a stay.',
              style: TextStyle(fontSize: 11, color: Colors.black54),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 12),
              Text(_saveError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
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
          child: _saving ? profileButtonSpinner : Text(_isEdit ? 'Save changes' : 'Add pet'),
        ),
      ],
    );
  }
}
