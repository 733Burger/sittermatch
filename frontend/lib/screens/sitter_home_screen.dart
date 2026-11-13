import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';

import '../models/booking_model.dart';
import '../models/homeowner_checks_model.dart';
import '../services/auth_services.dart';
import '../services/sitter_verification_service.dart';
import '../theme/app_colors.dart';
import '../utils/profile_completion.dart';
import '../widgets/homeowner/dialogs/address_check_dialog.dart';
import '../widgets/homeowner/dialogs/emergency_contact_dialog.dart';
import '../widgets/homeowner/dialogs/identity_check_dialog.dart';
import '../widgets/homeowner/homepage/verification_checks_card.dart';
import '../widgets/sitter/sitter_job_card.dart';
import 'bookings_dashboard_screen.dart';
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

class _SitterHomeScreenState extends State<SitterHomeScreen> with SitterJobActions {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();

  String _email = '';
  String _userRole = 'SITTER';

  final SitterVerificationService _checkService = SitterVerificationService();
  OwnerChecks _checks = const OwnerChecks();

  // Open bookings (no sitter chosen yet) this sitter hasn't offered on or declined.
  // Once they send an offer, the booking moves to their Jobs.
  late Future<List<BookingModel>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requireCompleteProfile();
    _loadUserData();
    reloadJobs();
  }

  @override
  void reloadJobs() {
    setState(() {
      _requestsFuture = fetchSitterBookings().then((all) => all.where(isOpenRequest).toList());
    });
  }

  Future<void> _refreshAll() async {
    reloadJobs();
    await Future.wait([_refreshChecks(), _requestsFuture.catchError((_) => <BookingModel>[])]);
  }

  // New sitters fill in their profile before they can use the rest of the app.
  Future<void> _requireCompleteProfile() async {
    final missing = await missingProfileItems();
    if (!mounted || missing.isEmpty) return;
    Navigator.of(context)
        .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const SitterProfileScreen()), (route) => false);
  }

  Future<void> _loadUserData() async {
    final email = await _authService.getUserEmail();
    final role = await _authService.getUserRole();
    if (!mounted) return;
    setState(() {
      _email = email ?? '';
      _userRole = (role ?? 'SITTER').toUpperCase();
    });

    if (_email.isNotEmpty) _refreshChecks();
  }

  // Fetches only the verification checks, so saving a check updates just the checklist card.
  Future<void> _refreshChecks() async {
    final result = await _checkService.fetchChecks();
    if (!mounted) return;

    if (result['success'] != true) {
      _showSnack(result['message']?.toString() ?? 'Could not load checks');
      return;
    }
    setState(() => _checks = OwnerChecks.fromJson(result));
  }

  void _closeDrawerIfOpen() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.pop(context);
  }

  // Reloads the open requests on return, e.g. after withdrawing an offer from Jobs.
  Future<void> _open(Widget screen) async {
    _closeDrawerIfOpen();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) reloadJobs();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signOut() async {
    await _authService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  // Dialogs (the same ones the homeowner home page uses)

  void _showMessageIfMounted(String message) {
    if (mounted) _showSnack(message);
  }

  void _openIdentityCheckDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => IdentityCheckDialog(
        email: _email,
        checkService: _checkService,
        onUploaded: () {
          if (!mounted) return;
          _showSnack('ID Photo uploaded successfully! Status set to Pending.');
          _refreshChecks();
        },
        onMessage: _showMessageIfMounted,
      ),
    );
  }

  void _openAddressCheckDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddressCheckDialog(
        initialAddress: _checks.addressCheck.status == CheckStatus.incomplete ? '' : _checks.addressCheck.subtitle,
        email: _email,
        checkService: _checkService,
        onSaved: () {
          if (!mounted) return;
          _showSnack('Home address saved! Status set to Pending.');
          _refreshChecks();
        },
        onMessage: _showMessageIfMounted,
      ),
    );
  }

  void _openEmergencyContactDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmergencyContactDialog(
        initialName: _checks.emergencyContactName,
        initialPhone: _checks.emergencyContactNumber,
        email: _email,
        checkService: _checkService,
        onSaved: () {
          if (!mounted) return;
          _showSnack('Emergency contact saved! Status set to Pending.');
          _refreshChecks();
        },
        onMessage: _showMessageIfMounted,
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
            Text(
              'Sit & Stay',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
            ),
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
      // Pull down to pick up new requests, or a check an admin has just approved or rejected.
      body: RefreshIndicator(
        color: AppColors.primaryRust,
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VerificationChecksCard(
                checks: _checks,
                onIdentityTap: _openIdentityCheckDialog,
                onAddressTap: _openAddressCheckDialog,
                onEmergencyContactTap: _openEmergencyContactDialog,
                readySubtitle: 'You’re ready to take bookings',
              ),

              // Same layout as "Available Sitters Nearby" on the homeowner home page.
              const SizedBox(height: 24),
              const Text('Open Requests Nearby', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildOpenRequests(),
            ],
          ),
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

  // The open requests, using the same card and buttons as Jobs.
  Widget _buildOpenRequests() {
    if (jobActionBusy) return _buildListMessage(null);

    return FutureBuilder<List<BookingModel>>(
      future: _requestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _buildListMessage(null);
        if (snapshot.hasError) {
          return _buildListMessage('Could not load open requests. Pull down to try again.');
        }
        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return _buildListMessage('No open requests within 40 km of your work area yet.');
        }
        // Cards stacked directly under the heading, like the sitter cards on the homeowner home page.
        return Column(children: requests.map(buildJobCard).toList());
      },
    );
  }

  // A spinner while loading (message null), or a line of grey text. No card, same as the
  // homeowner home page's "No sitters within 40 km" message.
  Widget _buildListMessage(String? message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: message == null
            ? const CircularProgressIndicator(color: AppColors.primaryRust)
            : Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
      ),
    );
  }
}
