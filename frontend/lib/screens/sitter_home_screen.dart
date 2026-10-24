import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_services.dart';
import '../services/sitter_service.dart';
import '../theme/app_colors.dart';
import '../utils/profile_completion.dart';
import 'bookings_dashboard_screen.dart';
import 'direct_chat_screen.dart';
import 'jobs_dashboard_screen.dart';
import 'messages_screen.dart';
import 'owner_home_screen.dart';
import 'owner_profile_screen.dart';
import 'sitter_profile_screen.dart';

class SitterHomeScreen extends StatefulWidget {
  const SitterHomeScreen({super.key});

  @override
  State<SitterHomeScreen> createState() => _SitterHomeScreenState();
}

class _SitterHomeScreenState extends State<SitterHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();

  String _email = '';
  String _userRole = 'SITTER'; 
  int? _sitterId; 

  // Backend verification state
  String _idCheckStatus = 'incomplete';
  String _addressCheckStatus = 'incomplete';
  String _emergencyCheckStatus = 'incomplete';

  String _homeAddress = '';
  String _emergencyName = '';
  String _emergencyPhone = '';
  bool _hasIdPhoto = false;

  @override
  void initState() {
    super.initState();
    _requireCompleteProfile();
    _loadUserData();
    _loadSitterId();
  }

  // New sitters fill in their profile before they can use the rest of the app.
  Future<void> _requireCompleteProfile() async {
    final missing = await missingProfileItems();
    if (!mounted || missing.isEmpty) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SitterProfileScreen()),
      (route) => false,
    );
  }

  Future<void> _loadSitterId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _sitterId = prefs.getInt('userId');
    });
  }

  Future<void> _loadUserData() async {
    final email = await _authService.getUserEmail();
    final role = await _authService.getUserRole();
    if (!mounted) return;
    setState(() {
      _email = email ?? '';
      _userRole = (role ?? 'SITTER').toUpperCase();
    });
    
    // Fetch live data from MySQL as soon as we have the email
    if (_email.isNotEmpty) {
      _fetchVerificationStatus();
    }
  }

  Future<void> _fetchVerificationStatus() async {
    try {
      final data = await SitterService.getVerificationChecks(_email);
      if (data['success'] == true && mounted) {
        setState(() {
          _idCheckStatus = data['idCheck']['status'] ?? 'incomplete';
          _addressCheckStatus = data['residenceCheck']['status'] ?? 'incomplete';
          _emergencyCheckStatus = data['emergencyCheck']['status'] ?? 'incomplete';

          _homeAddress = data['residenceCheck']['subtitle'] == 'No address provided' 
              ? '' 
              : data['residenceCheck']['subtitle'];
          
          _emergencyName = data['emergencyContactName'] ?? '';
          _emergencyPhone = data['emergencyContactPhone'] ?? '';
          _hasIdPhoto = _idCheckStatus != 'incomplete';
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch verifications: $e");
    }
  }

  void _closeDrawerIfOpen() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.pop(context);
  }

  void _open(Widget screen) {
    _closeDrawerIfOpen();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _comingSoon(String title) {
    _closeDrawerIfOpen();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title is coming soon')),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signOut() async {
    await _authService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // Dialogs connected to Backend 

  void _openIdentityCheckDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Identity / SA ID Verification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Upload a clear photo of your South African ID Document or Card.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  // Pushing a dummy byte array to the backend since we are in the emulator
                  await SitterService.submitIdentityCheck(
                    email: _email,
                    imageBytes: [137, 80, 78, 71, 13, 10, 26, 10], // Dummy PNG header
                  );
                  _showSnack('ID photo uploaded to database!');
                  _fetchVerificationStatus(); // Refresh UI
                } catch (e) {
                  _showSnack('Error: $e');
                }
              },
              icon: const Icon(Icons.upload_file),
              label: Text(_hasIdPhoto ? 'Replace Upload' : 'Upload ID'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _openEmergencyCheckDialog() {
    final nameController = TextEditingController(text: _emergencyName);
    final phoneController = TextEditingController(text: _emergencyPhone);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a trusted contact in case of emergency:'),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SitterService.submitEmergencyCheck(
                  email: _email,
                  name: nameController.text,
                  phoneNumber: phoneController.text,
                );
                _showSnack('Emergency contact saved to database!');
                _fetchVerificationStatus();
              } catch (e) {
                _showSnack('Error: $e');
              }
            },
            child: const Text('Save & Confirm'),
          ),
        ],
      ),
    );
  }

  void _openAddressCheckDialog() {
    final controller = TextEditingController(text: _homeAddress);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Home Address / Proof of Residence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirm or enter your home physical address:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Home Address',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await SitterService.submitResidenceCheck(
                  email: _email,
                  address: controller.text,
                );
                _showSnack('Address saved to database!');
                _fetchVerificationStatus();
              } catch (e) {
                _showSnack('Error: $e');
              }
            },
            child: const Text('Save & Confirm'),
          ),
        ],
      ),
    );
  }

  // Navigation Routing

  void _handleBottomNavTap(int index) {
    final isSitter = _userRole == 'SITTER';

    switch (index) {
      case 0:
        if (!isSitter) _open(const OwnerHomeScreen());
        break;
      case 1:
        _open(isSitter ? const JobsDashboardScreen() : const BookingsDashboardScreen());
        break;
      case 2:
        _open(const MessagesScreen());
        break;
      case 3:
        _open(isSitter ? const SitterProfileScreen() : const OwnerProfileScreen());
        break;
    }
  }

  // Build 

  @override
  Widget build(BuildContext context) {
    final bool isSitter = _userRole == 'SITTER';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Row(
          children: [
            Icon(Icons.pets, color: AppColors.primaryRust),
            SizedBox(width: 8),
            Text('Sit & Stay', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primaryRust),
              accountName: Text(isSitter ? 'Sitter' : 'Homeowner'),
              accountEmail: Text(_email),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppColors.primaryRust),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () => _open(isSitter ? const SitterProfileScreen() : const OwnerProfileScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onTap: _signOut,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complete Your\nSitter Profile',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, height: 1.1),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.primaryRust, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Complete your outstanding checks to start receiving bookings.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildCheckTile(
                    title: 'Identity / SA ID Verification',
                    subtitle: _hasIdPhoto ? 'ID uploaded' : 'No ID uploaded',
                    status: _idCheckStatus,
                    onTap: _openIdentityCheckDialog,
                  ),
                  _buildCheckTile(
                    title: 'Home Address / Proof of Residence',
                    subtitle: _homeAddress.isEmpty ? 'No address added' : _homeAddress,
                    status: _addressCheckStatus,
                    onTap: _openAddressCheckDialog,
                  ),
                  _buildCheckTile(
                    title: 'Emergency Contact',
                    subtitle: _emergencyName.isEmpty ? 'No emergency contact' : '$_emergencyName • $_emergencyPhone',
                    status: _emergencyCheckStatus,
                    onTap: _openEmergencyCheckDialog,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                         _fetchVerificationStatus();
                         _showSnack('Status synced with database.');
                      },
                      child: const Text('Refresh Status', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        currentIndex: 0,
        selectedItemColor: AppColors.primaryRust,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: _handleBottomNavTap,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'HOME'),
          BottomNavigationBarItem(
            icon: Icon(isSitter ? Icons.work_outline : Icons.calendar_today),
            label: isSitter ? 'JOBS' : 'BOOKINGS',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'MESSAGES'),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
        ],
      ),
    );
  }

  Widget _buildCheckTile({
    required String title,
    required String subtitle,
    required String status,
    required VoidCallback onTap,
  }) {
    Color statusColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approved';
        break;
      case 'pending':
        statusColor = Colors.amber.shade800;
        statusText = 'Pending Review';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Update Required';
        break;
      case 'incomplete':
      default:
        statusColor = Colors.red;
        statusText = 'Incomplete';
        break;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              statusText,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}