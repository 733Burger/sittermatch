import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../theme/app_colors.dart';
import 'jobs_dashboard_screen.dart';
import 'messages_screen.dart';

class SitterProfileScreen extends StatefulWidget {
  const SitterProfileScreen({super.key});

  @override
  State<SitterProfileScreen> createState() => _SitterProfileScreenState();
}

class _SitterProfileScreenState extends State<SitterProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Read-only sitter information
  final String _sitterName = 'Sarah Jenkins'; // TODO: load from the backend
  String _sitterEmail = '';
  final String _sitterPhone = '+27 83 987 6543'; // TODO: load from the backend

  final TextEditingController _aboutController = TextEditingController(
    text: 'Experienced pet sitter with 5+ years caring for dogs and cats. Certified in pet first aid.',
  );

  static const Map<String, IconData> _serviceIcons = {
    'Stay Over Night': Icons.nights_stay_outlined,
    'Walk Dog': Icons.directions_walk,
    'Feed Dog': Icons.restaurant_outlined,
  };

  // Service options state & pricing controllers
  final Map<String, bool> _selectedServices = {
    'Stay Over Night': true,
    'Walk Dog': false,
    'Feed Dog': true,
  };

  final TextEditingController _overnightRateCtrl = TextEditingController(text: '350');
  final TextEditingController _walkRateCtrl = TextEditingController(text: '120');
  final TextEditingController _walkDurationCtrl = TextEditingController(text: '45');
  final TextEditingController _feedRateCtrl = TextEditingController(text: '90');

  final List<Map<String, dynamic>> _sitterReviews = [
    {
      'ownerName': 'Joshua Stevens',
      'rating': 5.0,
      'comment': 'Sarah was brilliant with Buster! Sent daily updates and kept everything clean.',
      'date': 'Sep 2026',
    },
    {
      'ownerName': 'Claire Vance',
      'rating': 4.8,
      'comment': 'Punctual and great with feeding schedules. Will hire again!',
      'date': 'Aug 2026',
    },
  ];

  double get _averageRating => _sitterReviews.isEmpty
      ? 0
      : _sitterReviews.fold<double>(0, (sum, r) => sum + (r['rating'] as double)) /
          _sitterReviews.length;

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final email = await AuthService().getUserEmail();
    if (!mounted) return;
    setState(() => _sitterEmail = email ?? '');
  }

  @override
  void dispose() {
    _aboutController.dispose();
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // TODO: send the about text, services and rates to the backend.
    _showSnack('Profile saved.');
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Home is the first screen in the stack after login.
        Navigator.of(context).popUntil((route) => route.isFirst);
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
            _buildHeaderCard(),
            const SizedBox(height: 16),
            _buildAboutCard(),
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
                  'Save profile',
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
          _buildInfoRow(Icons.phone_outlined, _sitterPhone),
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
          if (_selectedServices['Walk Dog']!)
            _buildServiceBlock(
              icon: Icons.directions_walk,
              title: 'Walk dog',
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
          if (_selectedServices['Feed Dog']!)
            _buildServiceBlock(
              icon: Icons.restaurant_outlined,
              title: 'Feed dog',
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