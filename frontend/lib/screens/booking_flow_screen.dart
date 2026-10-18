import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../models/booking_draft_model.dart';
import '../services/booking_service.dart';
import 'saved_sitters_screen.dart';
import 'bookings_dashboard_screen.dart';
import 'direct_chat_screen.dart';
import 'owner_profile_screen.dart';

class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  late Future<BookingDraftModel> _draftFuture;
  final TextEditingController _instructionsController = TextEditingController(
    text: "Armed response callout procedure attached, Bella takes joint tablet morning",
  );

  // State for interactive Pickers
  DateTime _checkInDate = DateTime.now();
  DateTime _checkOutDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _checkInTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _checkOutTime = const TimeOfDay(hour: 16, minute: 0);

  // State for Services Menu
  bool _stayNight = true;
  bool _feedDog = false;
  bool _walkDog = false;

  // Submission state
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _draftFuture = BookingService.getBookingDraft();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  // Pickers Logic
  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkInDate : _checkOutDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRust,
              onPrimary: Colors.white,
              onSurface: AppColors.darkText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          if (_checkOutDate.isBefore(_checkInDate)) {
            _checkOutDate = _checkInDate.add(const Duration(days: 1));
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isCheckIn) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isCheckIn ? _checkInTime : _checkOutTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryRust,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInTime = picked;
        } else {
          _checkOutTime = picked;
        }
      });
    }
  }

  // Handle booking dispatch
  Future<void> _sendBooking(BookingDraftModel draft) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final startDateTime = DateTime(
        _checkInDate.year,
        _checkInDate.month,
        _checkInDate.day,
        _checkInTime.hour,
        _checkInTime.minute,
      );
      final endDateTime = DateTime(
        _checkOutDate.year,
        _checkOutDate.month,
        _checkOutDate.day,
        _checkOutTime.hour,
        _checkOutTime.minute,
      );

      String serviceType = 'Stay Night';
      if (_feedDog) serviceType = 'Drop-in Feeding';
      if (_walkDog) serviceType = _stayNight ? 'Stay Night & Walk' : 'Walk Dog';

      await BookingService.dispatchBooking(
        draft,
        _instructionsController.text,
        bookingType: serviceType,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking sent successfully! Status set to PENDING.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BookingsDashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Booking', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: AppColors.darkText), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(radius: 14, backgroundColor: AppColors.primaryRust, child: Icon(Icons.person, color: Colors.white, size: 16)),
          ),
        ],
      ),
      body: FutureBuilder<BookingDraftModel>(
        future: _draftFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryRust));
          }
          if (snapshot.hasError) return const Center(child: Text('Failed to load draft.'));

          final draft = snapshot.data!;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDatesCard(draft),
                  const SizedBox(height: 16),
                  _buildServicesCard(),
                  const SizedBox(height: 16),
                  _buildPetsCard(draft),
                  const SizedBox(height: 16),
                  _buildSecurityCard(),
                  const SizedBox(height: 24),
                  _buildDispatchFooter(draft),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: 1,
        selectedItemColor: AppColors.primaryRust,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SavedSittersScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BookingsDashboardScreen()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DirectChatScreen()));
          } else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const OwnerProfileScreen()));
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

  Widget _buildDatesCard(BookingDraftModel draft) {
    int nights = _checkOutDate.difference(_checkInDate).inDays;
    if (nights <= 0) nights = 1;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, color: AppColors.primaryRust, size: 18),
              SizedBox(width: 8),
              Text('Stay Dates & Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CHECK-IN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(DateFormat('dd MMM').format(_checkInDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _selectTime(context, true),
                          child: Text('From ${_checkInTime.format(context)}', style: const TextStyle(fontSize: 12, color: AppColors.primaryRust, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      const Icon(Icons.arrow_forward, color: AppColors.primaryRust, size: 16),
                      Text('$nights Nights', style: const TextStyle(color: AppColors.primaryRust, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('CHECK-OUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(DateFormat('dd MMM').format(_checkOutDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _selectTime(context, false),
                          child: Text('Until ${_checkOutTime.format(context)}', style: const TextStyle(fontSize: 12, color: AppColors.primaryRust, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildServicesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.design_services_outlined, color: AppColors.primaryRust, size: 18),
              SizedBox(width: 8),
              Text('Select Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
            ],
          ),
          const SizedBox(height: 16),
          _buildServiceOption(
            title: 'Stay Night',
            subtitle: 'Sitter stays at your home overnight (feeding included)',
            icon: Icons.nightlight_round,
            isSelected: _stayNight,
            onTap: () {
              setState(() {
                _stayNight = !_stayNight;
                if (_stayNight) _feedDog = false;
              });
            },
          ),
          const SizedBox(height: 8),
          _buildServiceOption(
            title: 'Drop-in Feeding Visit',
            subtitle: 'Sitter drops in just to feed your pets, no overnight stay',
            icon: Icons.restaurant,
            isSelected: _feedDog,
            onTap: () {
              setState(() {
                _feedDog = !_feedDog;
                if (_feedDog) _stayNight = false;
              });
            },
          ),
          const SizedBox(height: 8),
          _buildServiceOption(
            title: 'Walk Dog',
            subtitle: 'Sitter takes your dog out for a walk',
            icon: Icons.directions_walk,
            isSelected: _walkDog,
            onTap: () {
              setState(() {
                _walkDog = !_walkDog;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceOption({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRust : AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.darkText, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: isSelected ? Colors.white : AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 14)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: isSelected ? Colors.white70 : Colors.black54, fontSize: 11)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.white : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetsCard(BookingDraftModel draft) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pets, color: AppColors.primaryRust, size: 18),
              SizedBox(width: 8),
              Text('Pets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Tap to select your registered companions', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          for (final pet in draft.companions)
            _buildPetOption(
              title: pet.category,
              details: pet.details,
              isSelected: pet.isSelected,
              onTap: () => setState(() => pet.isSelected = !pet.isSelected),
            ),
        ],
      ),
    );
  }

  Widget _buildPetOption({
    required String title,
    required String details,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.lightRustBg : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primaryRust : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryRust : AppColors.lightRustBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pets,
                  color: isSelected ? Colors.white : AppColors.primaryRust,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppColors.primaryRust : Colors.grey.shade400,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.note_alt_outlined, color: AppColors.primaryRust, size: 18),
              SizedBox(width: 8),
              Text('Notes & Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkText)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _instructionsController,
            maxLines: 4,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              hintText: 'Add feeding times, security codes, or extra details...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchFooter(BookingDraftModel draft) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : () => _sendBooking(draft),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRust,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Send Booking',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                  ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}