import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/booking_draft_model.dart';
import '../services/booking_service.dart';

class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  late Future<BookingDraftModel> _draftFuture;
  final TextEditingController _instructionsController = TextEditingController(text: "Armed response callout procedure attached, Bella takes joint tablet morning");

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
        title: const Text('Booking Flow', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
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
            child: Column(
              children: [
                _buildProgressHeader(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDatesCard(draft),
                      const SizedBox(height: 16),
                      _buildPetsCard(draft),
                      const SizedBox(height: 16),
                      _buildSecurityCard(),
                      const SizedBox(height: 16),
                      _buildFeeCard(draft),
                      const SizedBox(height: 24),
                      _buildDispatchFooter(draft),
                    ],
                  ),
                ),
              ],
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BOOKING REQUEST SETUP', style: TextStyle(color: AppColors.primaryRust, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              Text('Step 2 of 3', style: TextStyle(color: AppColors.darkText, fontSize: 12)),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(flex: 2, child: Container(height: 3, color: AppColors.primaryRust)),
            Expanded(flex: 1, child: Container(height: 3, color: Colors.grey.shade300)),
          ],
        )
      ],
    );
  }

  Widget _buildDatesCard(BookingDraftModel draft) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_today, color: AppColors.primaryRust, size: 18),
                  SizedBox(width: 8),
                  Text('Stay Dates & Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Text('Edit', style: TextStyle(color: AppColors.primaryRust, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 26.0),
            child: Text('Cape Town & Surrounds (SAST)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CHECK-IN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(draft.checkInDate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Text('From 09:00\nAM', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      const Icon(Icons.arrow_forward, color: AppColors.primaryRust, size: 16),
                      Text('${draft.nights} Nights', style: const TextStyle(color: AppColors.primaryRust, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('CHECK-OUT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(draft.checkOutDate, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Text('Until 04:00 PM', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPetsCard(BookingDraftModel draft) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pets, color: AppColors.primaryRust, size: 18),
              SizedBox(width: 8),
              Text('Who Needs Care?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 26.0),
            child: Text('Tap to select your registered household companions', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5),
            itemCount: draft.companions.length,
            itemBuilder: (context, index) {
              final pet = draft.companions[index];
              return GestureDetector(
                onTap: () => setState(() => pet.isSelected = !pet.isSelected),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pet.isSelected ? AppColors.primaryRust : AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.pets, color: pet.isSelected ? Colors.white : Colors.grey, size: 16),
                          Icon(pet.isSelected ? Icons.check_circle : Icons.add_circle_outline, color: pet.isSelected ? Colors.white : Colors.grey, size: 16),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pet.category, style: TextStyle(color: pet.isSelected ? Colors.white : AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(pet.details, style: TextStyle(color: pet.isSelected ? Colors.white70 : Colors.grey, fontSize: 10)),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primaryRust, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Special Instructions & House Security', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _instructionsController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user, color: AppColors.primaryRust, size: 14),
                  SizedBox(width: 4),
                  Text('ADT / FIDELITY LINKED', style: TextStyle(color: AppColors.primaryRust, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
              Text('72 / 400 chars', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFeeCard(BookingDraftModel draft) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.receipt_long, color: AppColors.primaryRust, size: 18),
                  SizedBox(width: 8),
                  Text('Transparent Fee\nBreakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(4)),
                child: const Text('ZAR\nGUARANTEED', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 16),
          _buildFeeRow('Base Sitting Rate (${draft.nights} nights × R320)', draft.baseRate),
          const SizedBox(height: 8),
          _buildFeeRow('Multi-pet Care Fee (2 additional)', draft.multiPetFee),
          const SizedBox(height: 8),
          _buildFeeRow('Trust & Security Protection Guarantee', draft.trustFee, isHighlight: true),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Held securely in trust until stay\ncompletion', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('R ${draft.estimatedTotal.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.primaryRust, fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('ZAR INCL. VAT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, double amount, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: TextStyle(color: isHighlight ? AppColors.primaryRust : AppColors.darkText, fontSize: 12))),
        Text('R ${amount.toStringAsFixed(2)}', style: TextStyle(color: isHighlight ? AppColors.primaryRust : AppColors.darkText, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDispatchFooter(BookingDraftModel draft) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('DISPATCH BOOKING BROADCAST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            Row(
              children: [
                Icon(Icons.circle, color: AppColors.primaryRust, size: 8),
                SizedBox(width: 4),
                Text('14 Sitters Active Near You', style: TextStyle(color: AppColors.primaryRust, fontSize: 10)),
              ],
            )
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            // Executes the POST request using the data from the screen
            onPressed: () async => await BookingService.dispatchBooking(draft, _instructionsController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRust,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.radar, color: Colors.white),
                SizedBox(width: 12),
                Column(
                  children: [
                    Text('Send to Both (Saved & Nearby)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Maximum reach & fastest verified confirmation', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
                SizedBox(width: 12),
                Icon(Icons.send, color: Colors.white),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.bookmark, color: AppColors.primaryRust, size: 16),
                    SizedBox(height: 4),
                    Text('Saved Sitters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('Notify Page 11 Shortlist', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified, color: AppColors.primaryRust, size: 16),
                    SizedBox(height: 4),
                    Text('Nearby Verified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('SAPS Vetted in Radius', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}