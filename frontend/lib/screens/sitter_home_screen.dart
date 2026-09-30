import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../theme/app_colors.dart';
import 'role_select_screen.dart';
import 'bookings_dashboard_screen.dart';
import 'direct_chat_screen.dart';

class SitterHomeScreen extends StatefulWidget {
  const SitterHomeScreen({super.key});

  @override
  State<SitterHomeScreen> createState() => _SitterHomeScreenState();
}

class _SitterHomeScreenState extends State<SitterHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _email = '';

  String? _idPhotoPath;
  String? _sapsCertPath;
  String _homeAddress = '';

  // 'completed', 'pending' or 'incomplete'. Replace with DB checks later.
  String _idCheckStatus = 'incomplete';
  String _sapsCheckStatus = 'incomplete';
  String _addressCheckStatus = 'incomplete';

  @override
  void initState() {
    super.initState();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    final email = await AuthService().getUserEmail();
    if (!mounted) return;
    setState(() => _email = email ?? '');
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
    await AuthService().clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
      (route) => false,
    );
  }

  // ---------- Dialogs ----------

  void _openUploadDialog({
    required String title,
    required String description,
    required bool alreadyUploaded,
    required VoidCallback onUploaded,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(description),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                setState(onUploaded);
                Navigator.pop(ctx);
                _showSnack('Uploaded successfully! Status set to Pending.');
              },
              icon: const Icon(Icons.upload_file),
              label: Text(alreadyUploaded ? 'Replace Upload' : 'Upload'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _openIdentityCheckDialog() {
    _openUploadDialog(
      title: 'Identity / SA ID Verification',
      description: 'Upload a clear photo of your South African ID Document or Card.',
      alreadyUploaded: _idPhotoPath != null,
      onUploaded: () {
        _idPhotoPath = 'uploads/id_card_sitter.png';
        _idCheckStatus = 'pending';
      },
    );
  }

  void _openSapsCheckDialog() {
    _openUploadDialog(
      title: 'SAPS Police Clearance',
      description: 'Upload your SAPS police clearance certificate (issued within the last 6 months).',
      alreadyUploaded: _sapsCertPath != null,
      onUploaded: () {
        _sapsCertPath = 'uploads/saps_certificate.pdf';
        _sapsCheckStatus = 'pending';
      },
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
            onPressed: () {
              setState(() {
                _homeAddress = controller.text;
                _addressCheckStatus = 'pending';
              });
              Navigator.pop(ctx);
              _showSnack('Home address saved! Status set to Pending.');
            },
            child: const Text('Save & Confirm'),
          ),
        ],
      ),
    );
  }

  void _openSubmitDetailsModal() {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Verification Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add an optional message or note for the Admin review team:'),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Please check my updated proof of residence...',
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
            onPressed: () {
              Navigator.pop(ctx);
              _comingSoon('Admin Verification Review');
            },
            child: const Text('Submit to Admin'),
          ),
        ],
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Sit & Stay',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: Colors.black),
            tooltip: 'Security & Trust',
            onPressed: () => _comingSoon('Security & Trust'),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.background,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primaryRust),
              accountName: const Text('Sitter'),
              accountEmail: Text(_email),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppColors.primaryRust),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () => _comingSoon('Profile'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('My Bookings'),
              onTap: () => _open(const BookingsDashboardScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () => _comingSoon('Settings'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
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
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildCheckTile(
                    title: 'Identity / SA ID Verification',
                    subtitle: _idPhotoPath == null ? 'No ID uploaded' : 'ID uploaded',
                    status: _idCheckStatus,
                    onTap: _openIdentityCheckDialog,
                  ),
                  _buildCheckTile(
                    title: 'SAPS Police Clearance',
                    subtitle: _sapsCertPath == null ? 'No certificate uploaded' : 'Certificate uploaded',
                    status: _sapsCheckStatus,
                    onTap: _openSapsCheckDialog,
                  ),
                  _buildCheckTile(
                    title: 'Home Address / Proof of Residence',
                    subtitle: _homeAddress.isEmpty ? 'No address added' : _homeAddress,
                    status: _addressCheckStatus,
                    onTap: _openAddressCheckDialog,
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
                      onPressed: _openSubmitDetailsModal,
                      child: const Text(
                        'Submit Documents / Details',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
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
        onTap: (index) {
          switch (index) {
            case 1:
              _open(const BookingsDashboardScreen());
              break;
            case 2:
              _open(const DirectChatScreen());
              break;
            case 3:
              _comingSoon('Profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'BOOKINGS'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'MESSAGES'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
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

    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Completed';
        break;
      case 'pending':
        statusColor = Colors.amber.shade800;
        statusText = 'Pending Review';
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