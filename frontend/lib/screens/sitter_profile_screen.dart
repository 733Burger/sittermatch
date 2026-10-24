import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';
import 'jobs_dashboard_screen.dart';
import 'messages_screen.dart';
import '../services/sitter_service.dart';
import '../utils/profile_completion.dart';
import '../widgets/homeowner/profile/profile_gate_banner.dart';
import 'sitter_home_screen.dart';

class SitterProfileScreen extends StatefulWidget {
  const SitterProfileScreen({super.key});

  @override
  State<SitterProfileScreen> createState() => _SitterProfileScreenState();
}

class _SitterProfileScreenState extends State<SitterProfileScreen> {
  final _formKey = GlobalKey<FormState>();

    final SitterService _sitterService = SitterService();
    String _sitterName = '';
    String _sitterEmail = '';
    String _sitterPhone = '';

    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _phoneController = TextEditingController();
    final TextEditingController _aboutController = TextEditingController();

    final TextEditingController _currentPwCtrl = TextEditingController();
    final TextEditingController _newPwCtrl = TextEditingController();
    final TextEditingController _confirmPwCtrl = TextEditingController();

    static const List<String> _petOptions = [
      'large dog', 'small dog', 'cat', 'bird', 'reptile', 'fish', 'exotic',
    ];
    final Set<String> _selectedPets = {};

    static const Map<String, String> _serviceCodes = {
      'Stay Over Night': 'STAY_OVER_NIGHT',
      'Walk Pet': 'WALK_PET',
      'Feed Pet': 'FEED_PET',
    };

  static const Map<String, IconData> _serviceIcons = {
    'Stay Over Night': Icons.nights_stay_outlined,
    'Walk Pet': Icons.directions_walk,
    'Feed Pet': Icons.restaurant_outlined,
  };

  // Service options state & pricing controllers
  final Map<String, bool> _selectedServices = {
    'Stay Over Night': true,
    'Walk Pet': false,
    'Feed Pet': false,
  };

  final TextEditingController _overnightRateCtrl = TextEditingController();
  final TextEditingController _walkRateCtrl = TextEditingController();
  final TextEditingController _walkDurationCtrl = TextEditingController();
  final TextEditingController _feedRateCtrl = TextEditingController();

  List<Map<String, dynamic>> _sitterReviews = [];

  double get _averageRating => _sitterReviews.isEmpty
      ? 0
      : _sitterReviews.fold<double>(0, (sum, r) => sum + (r['rating'] as double)) /
          _sitterReviews.length;

  // What the saved profile still needs before the rest of the app unlocks.
  List<String> _missing = [];
  bool get _profileComplete => _missing.isEmpty;

  Future<void> _refreshMissing() async {
    final missing = await missingProfileItems();
    if (!mounted) return;
    final justFinished = !_profileComplete && missing.isEmpty;
    setState(() => _missing = missing);
    if (justFinished) _showSnack('Profile complete. You can now use the whole app.');
  }

  void _showGateMessage() {
    _showSnack('Finish your profile first. Still needed: ${describeMissing(_missing)}.');
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadReviews();
    _refreshMissing();
  }

  // Reviews homeowners wrote about this sitter, once an admin has approved them.
  Future<void> _loadReviews() async {
    final userId = await AuthService().getUserId();
    if (!mounted || userId == null) return;
    try {
      final reviews = await ReviewService.fetchSitterReviews(userId);
      if (!mounted) return;
      setState(() {
        _sitterReviews = reviews
            .map((r) => <String, dynamic>{
                  'ownerName': r.reviewerName,
                  'rating': r.rating.toDouble(),
                  'comment': r.comment,
                  'date': r.dateLabel,
                })
            .toList();
      });
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    }
  }

  String _fmt(num? n) {
  if (n == null) return '';
  return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
}

Future<void> _loadProfile() async {
  final userId = await AuthService().getUserId();
  if (!mounted) return;
  if (userId == null) {
    _showSnack('User session expired. Please log in again.');
    return;
  }

  final result = await _sitterService.getSitterDetails(sitterId: userId);
  if (!mounted) return;
  if (result['success'] != true) {
    _showSnack(result['message']?.toString() ?? 'Could not load profile');
    return;
  }

  setState(() {
    _sitterName = (result['name'] ?? '').toString();
    _sitterEmail = (result['email'] ?? '').toString();
    _sitterPhone = (result['phone'] ?? '').toString();
    _nameController.text = _sitterName;
    _emailController.text = _sitterEmail;
    _phoneController.text = _sitterPhone;
    _aboutController.text = (result['experience'] ?? '').toString();

    _selectedPets
      ..clear()
      ..addAll(((result['petPreferences'] as List?) ?? [])
          .map((e) => e.toString().toLowerCase()));

    final services = (result['services'] as List?) ?? [];
    if (services.isNotEmpty) {
      for (final k in _selectedServices.keys) {
        _selectedServices[k] = false;
      }
      for (final s in services) {
        final code = s['serviceType']?.toString();
        final price = _fmt(s['price'] as num?);
        if (code == 'STAY_OVER_NIGHT') {
          _selectedServices['Stay Over Night'] = true;
          _overnightRateCtrl.text = price;
        } else if (code == 'WALK_PET') {
          _selectedServices['Walk Pet'] = true;
          _walkRateCtrl.text = price;
          _walkDurationCtrl.text = _fmt(s['durationMinutes'] as num?);
        } else if (code == 'FEED_PET') {
          _selectedServices['Feed Pet'] = true;
          _feedRateCtrl.text = price;
        }
      }
    }
  });
}

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    _overnightRateCtrl.dispose();
    _walkRateCtrl.dispose();
    _walkDurationCtrl.dispose();
    _feedRateCtrl.dispose();
    super.dispose();

  }

  // ---------- Helpers ----------

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleService(String key) {
    final count = _selectedServices.values.where((v) => v).length;
    if (_selectedServices[key]! && count == 1) {
      _showSnack('At least one service type must be selected.');
      return;
    }
    setState(() {
      _selectedServices[key] = !_selectedServices[key]!;
    });
  }

  String? _validatePrice(String? value) {
    final n = double.tryParse((value ?? '').trim());
    if (n == null || n <= 0) return 'Enter a price';
    return null;
  }

  String? _validateMinutes(String? value) {
    final n = int.tryParse((value ?? '').trim());
    if (n == null || n <= 0) return 'Enter minutes';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPets.isEmpty) {
      _showSnack('Select at least one pet type.');
      return;
    }
    FocusScope.of(context).unfocus();

    final userId = await AuthService().getUserId();
    if (!mounted) return;
    if (userId == null) {
      _showSnack('User session expired. Please log in again.');
      return;
    }

    final services = <Map<String, dynamic>>[
      if (_selectedServices['Stay Over Night']!)
        {
          'serviceType': _serviceCodes['Stay Over Night'],
          'price': double.parse(_overnightRateCtrl.text.trim()),
        },
      if (_selectedServices['Walk Pet']!)
        {
          'serviceType': _serviceCodes['Walk Pet'],
          'price': double.parse(_walkRateCtrl.text.trim()),
          'durationMinutes': int.parse(_walkDurationCtrl.text.trim()),
        },
      if (_selectedServices['Feed Pet']!)
        {
          'serviceType': _serviceCodes['Feed Pet'],
          'price': double.parse(_feedRateCtrl.text.trim()),
        },
    ];

    final result = await _sitterService.saveSitterProfile(
      sitterId: userId,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      experience: _aboutController.text.trim(),
      services: services,
      petPreferences: _selectedPets.map((p) => p.toUpperCase()).toList(),
    );
    if (!mounted) return;

    if (result['success'] != true) {
      _showSnack(result['message']?.toString() ?? 'Save failed.');
      return;
    }

    // The app uses the email as its session key, so keep it in sync.
    final newEmail = (result['email'] ?? '').toString();
    if (newEmail.isNotEmpty && newEmail != _sitterEmail) {
      final auth = AuthService();
      final role = await auth.getUserRole();
      await auth.saveSession(newEmail, role ?? '');
      if (!mounted) return;
    }

    setState(() {
      _sitterName = (result['name'] ?? '').toString();
      _sitterEmail = newEmail;
      _sitterPhone = (result['phone'] ?? '').toString();
    });
    _showSnack('Details saved.');
    _refreshMissing();
  }

  Future<void> _showChangePasswordDialog() async {
    _currentPwCtrl.clear();
    _newPwCtrl.clear();
    _confirmPwCtrl.clear();
    bool hideCurrent = true;
    bool hideNew = true;
    bool saving = false;
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Change password', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _currentPwCtrl,
                  obscureText: hideCurrent,
                  decoration: _fieldDecoration(hint: 'Current password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(hideCurrent ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.darkText),
                      onPressed: () => setDialogState(() => hideCurrent = !hideCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPwCtrl,
                  obscureText: hideNew,
                  decoration: _fieldDecoration(hint: 'New password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(hideNew ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.darkText),
                      onPressed: () => setDialogState(() => hideNew = !hideNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPwCtrl,
                  obscureText: hideNew, // follows the New password toggle
                  decoration: _fieldDecoration(hint: 'Confirm new password'),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
              onPressed: saving
                  ? null
                  : () async {
                      final current = _currentPwCtrl.text;
                      final next = _newPwCtrl.text;

                      String? problem;
                      if (current.isEmpty || next.isEmpty || _confirmPwCtrl.text.isEmpty) {
                        problem = 'Fill in all password fields.';
                      } else if (next.length < 8) {
                        problem = 'New password must be at least 8 characters.';
                      } else if (next != _confirmPwCtrl.text) {
                        problem = 'New passwords do not match.';
                      }
                      if (problem != null) {
                        setDialogState(() => error = problem);
                        return;
                      }

                      final userId = await AuthService().getUserId();
                      if (!ctx.mounted) return;
                      if (userId == null) {
                        setDialogState(() => error = 'User session expired. Please log in again.');
                        return;
                      }

                      setDialogState(() {
                        saving = true;
                        error = null;
                      });
                      final result = await _sitterService.changePassword(
                        userId: userId,
                        currentPassword: current,
                        newPassword: next,
                      );
                      if (!ctx.mounted) return;

                      if (result['success'] == true) {
                        Navigator.pop(ctx);
                        if (mounted) _showSnack('Password updated.');
                      } else {
                        setDialogState(() {
                          saving = false;
                          error = result['message']?.toString() ?? 'Could not update password.';
                        });
                      }
                    },
              child: const Text('Update password'),
            ),
          ],
        ),
      ),
    );

    _currentPwCtrl.clear();
    _newPwCtrl.clear();
    _confirmPwCtrl.clear();
  }
  

  void _handleBottomNavTap(int index) {
    if (index != 3 && !_profileComplete) {
      _showGateMessage();
      return;
    }
    switch (index) {
      case 0:
        // Home is the first screen in the stack after login, unless a new sitter was sent
        // straight here to finish their profile.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SitterHomeScreen()));
        }
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const JobsDashboardScreen()),
        );
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MessagesScreen()),
        );
        break;
      case 3:
        break; // already on Profile
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    );
  }

  /// Label shown above a field (bigger and never overlaps the text box).
  Widget _fieldLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
          children: [
            if (required)
              const TextSpan(text: ' *', style: TextStyle(color: AppColors.primaryRust)),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    String? hint,
    IconData? icon,
    String? prefixText,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.primaryRust),
      prefixText: prefixText,
      suffixText: suffixText,
      filled: true,
      fillColor: AppColors.expandButtonBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryRust, width: 1.5),
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.lightRustBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryRust,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _stars(double score, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final remaining = score - i;
        IconData icon;
        if (remaining >= 1) {
          icon = Icons.star_rounded;
        } else if (remaining >= 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, color: AppColors.primaryRust, size: size);
      }),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _profileComplete,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _showGateMessage();
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.pets, color: AppColors.primaryRust),
        title: const Text(
          'Sitter Profile',
          style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_profileComplete) ...[
              ProfileGateBanner(missing: _missing),
              const SizedBox(height: 16),
            ],
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildPersonalCard(),          // new
            const SizedBox(height: 16),
            _buildAboutCard(),
            const SizedBox(height: 16),
            _buildPetPreferencesCard(),    // new
            const SizedBox(height: 16),
            _buildServicesCard(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _save,
                child: const Text(
                  'Save details',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildReviewsCard(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        currentIndex: 3,
        selectedItemColor: AppColors.primaryRust,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: _handleBottomNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'JOBS'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'MESSAGES'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, size: 52, color: Colors.grey),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _showSnack('Photo upload is coming soon.'),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRust,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _sitterName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          _tag('SITTER'),
          const SizedBox(height: 10),
          if (_sitterReviews.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: AppColors.primaryRust, size: 18),
                const SizedBox(width: 4),
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  ' (${_sitterReviews.length} reviews)',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.mail_outline, _sitterEmail.isEmpty ? 'No email on file' : _sitterEmail),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.phone_outlined, _sitterPhone.isEmpty ? 'No phone on file' : _sitterPhone),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryRust, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.darkText)),
        ),
      ],
    );
  }

 Widget _buildPersonalCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
        ),
        const SizedBox(height: 2),
        const Text(
          'Saved with the "Save details" button below.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        _fieldLabel('Full name', required: true),
        TextFormField(
          controller: _nameController,
          maxLength: 100,
          decoration: _fieldDecoration(icon: Icons.person_outline).copyWith(counterText: ''),
          validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Email', required: true),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _fieldDecoration(icon: Icons.mail_outline),
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.isEmpty) return 'Email is required';
            if (!t.contains('@')) return 'Enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _fieldLabel('Phone number', required: true),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 20,
          decoration: _fieldDecoration(icon: Icons.phone_outlined).copyWith(counterText: ''),
          validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
        ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showChangePasswordDialog,
                    icon: const Icon(Icons.lock_outline, size: 18, color: AppColors.primaryRust),
                    label: const Text(
                      'Change password',
                      style: TextStyle(color: AppColors.darkText, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
      ],
    ),
  );
}

Widget _buildPetPreferencesCard() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: _cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pet preferences',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
        ),
        const SizedBox(height: 2),
        const Text(
          'Select the animals you are happy to look after. At least one is required.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _petOptions.map((pet) {
            final isSelected = _selectedPets.contains(pet);
            return ChoiceChip(
              label: Text(pet),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppColors.primaryRust,
              backgroundColor: AppColors.expandButtonBg,
              side: BorderSide.none,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.darkText,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              onSelected: (_) => setState(() {
                if (isSelected) {
                  _selectedPets.remove(pet);
                } else {
                  _selectedPets.add(pet);
                }
              }),
            );
          }).toList(),
        ),
      ],
    ),
  );
}




  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About & experience',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _aboutController,
            maxLines: 4,
            decoration: _fieldDecoration(
              hint: 'Share your background, skills and pet experience...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services offered & pricing',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 2),
          const Text(
            'Select one or more. At least one is required.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedServices.keys.map((service) {
              final isSelected = _selectedServices[service]!;
              return ChoiceChip(
                avatar: Icon(
                  _serviceIcons[service],
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.primaryRust,
                ),
                label: Text(service),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: AppColors.primaryRust,
                backgroundColor: AppColors.expandButtonBg,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.darkText,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (_) => _toggleService(service),
              );
            }).toList(),
          ),

          // Pricing inputs for each selected service
          if (_selectedServices['Stay Over Night']!)
            _buildServiceBlock(
              icon: Icons.nights_stay_outlined,
              title: 'Stay over night',
              fields: [
                _fieldLabel('Price per night', required: true),
                TextFormField(
                  controller: _overnightRateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration(hint: '0', prefixText: 'R '),
                  validator: _validatePrice,
                ),
              ],
            ),
          if (_selectedServices['Walk Pet']!)
            _buildServiceBlock(
              icon: Icons.directions_walk,
              title: 'Walk Pet',
              fields: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Price per walk', required: true),
                          TextFormField(
                            controller: _walkRateCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _fieldDecoration(hint: '0', prefixText: 'R '),
                            validator: _validatePrice,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Walk length', required: true),
                          TextFormField(
                            controller: _walkDurationCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _fieldDecoration(hint: '0', suffixText: 'min'),
                            validator: _validateMinutes,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          if (_selectedServices['Feed Pet']!)
            _buildServiceBlock(
              icon: Icons.restaurant_outlined,
              title: 'Feed Pet',
              fields: [
                _fieldLabel('Price per feeding visit', required: true),
                TextFormField(
                  controller: _feedRateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration(hint: '0', prefixText: 'R '),
                  validator: _validatePrice,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildServiceBlock({
    required IconData icon,
    required String title,
    required List<Widget> fields,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryRust, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...fields,
        ],
      ),
    );
  }

  Widget _buildReviewsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating & client reviews',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 12),
          if (_sitterReviews.isEmpty)
            const Text(
              'No reviews yet. Homeowners can review you after a stay.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            )
          else ...[
            Row(
              children: [
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _stars(_averageRating, size: 18),
                    const SizedBox(height: 2),
                    Text(
                      '${_sitterReviews.length} reviews',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            ..._sitterReviews.map(_buildReviewTile),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTile(Map<String, dynamic> review) {
    final String name = review['ownerName'] as String;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.lightRustBg,
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryRust,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.primaryRust, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${review['rating']}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  review['comment'] as String,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  review['date'] as String,
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}