import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../models/saved_sitter_model.dart';
import '../services/saved_sitter_service.dart';
import '../services/auth_services.dart';
import 'direct_chat_screen.dart';
import 'bookings_dashboard_screen.dart';
import 'booking_flow_screen.dart';
import 'messages_screen.dart';
import 'owner_profile_screen.dart';
import 'sitter_detail_screen.dart';

class SavedSittersScreen extends StatefulWidget {
  const SavedSittersScreen({super.key});

  @override
  State<SavedSittersScreen> createState() => _SavedSittersScreenState();
}

class _SavedSittersScreenState extends State<SavedSittersScreen> {
  final SavedSitterService _savedSitterService = SavedSitterService();
  final AuthService _authService = AuthService();

  final Set<int> _removedIds = {};
  List<SavedSitterModel> _sitters = [];
  bool _isLoading = true;
  bool _sortByRating = false;

  List<SavedSitterModel> get _visibleSitters {
    if (!_sortByRating) return _sitters;
    return [..._sitters]..sort((a, b) => b.rating.compareTo(a.rating));
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);

    try {
      final savedSitters = await _savedSitterService.fetchSavedSitters();
      if (!mounted) return;

      if (savedSitters['success'] != true) {
        setState(() {
          _sitters = [];
          _isLoading = false;
        });
        _showSnack(savedSitters['message']?.toString() ?? 'Could not load saved sitters');
        return;
      }

      setState(() {
        _sitters = SavedSitterModel.listFromJson(savedSitters['sitters']);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Could not load saved sitters');
    }
  }

  Future<void> _unsaveSitter(SavedSitterModel sitter) async {
    final savedSitterIndex = _sitters.indexWhere((item) => item.id == sitter.id);
    if (savedSitterIndex == -1) return;

    setState(() => _sitters.removeAt(savedSitterIndex));
    _removedIds.add(sitter.id);

    try {
      final homeownerId = await _authService.getUserId();
      if (!mounted) return;

      if (homeownerId == null) {
        setState(() => _sitters.insert(savedSitterIndex, sitter));
        _removedIds.remove(sitter.id);
        _showSnack('User session expired. Please log in again.');
        return;
      }

      final result = await _savedSitterService.toggleSavedSitter(
        homeownerId: homeownerId,
        sitterId: sitter.id,
        isCurrentlySaved: true,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSnack(
          '${sitter.name} removed from Saved Sitters.',
          action: SnackBarAction(
            label: 'UNDO',
            textColor: AppColors.lightRustBg,
            onPressed: () => _resaveSitter(sitter, homeownerId, savedSitterIndex),
          ),
        );
      } else {
        setState(() => _sitters.insert(savedSitterIndex, sitter));
        _removedIds.remove(sitter.id);
        _showSnack('Failed to remove sitter. Please try again.');
      }
    } catch (e) {
      debugPrint('Error unsaving sitter: $e');
      if (!mounted) return;
      setState(() => _sitters.insert(savedSitterIndex, sitter));
      _removedIds.remove(sitter.id);
      _showSnack('Network error occurred.');
    }
  }

  Future<void> _resaveSitter(SavedSitterModel sitter, int homeownerId, int index) async {
    try {
      final result = await _savedSitterService.toggleSavedSitter(
        homeownerId: homeownerId,
        sitterId: sitter.id,
        isCurrentlySaved: false,
      );
      if (!mounted) return;

      if (result['success'] == true) {
        setState(() => _sitters.insert(index.clamp(0, _sitters.length), sitter));
        _removedIds.remove(sitter.id);
      } else {
        _showSnack('Could not restore ${sitter.name}. Please try again.');
      }
    } catch (e) {
      debugPrint('Error re-saving sitter: $e');
      if (!mounted) return;
      _showSnack('Network error occurred.');
    }
  }

  // A sitter un-bookmarked on their profile drops off this list, and off the home page's bookmarks.
  Future<void> _openSitter(SavedSitterModel sitter) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SitterDetailScreen(sitterId: sitter.id)),
    );
    if (!mounted || saved != false) return;
    setState(() => _sitters.removeWhere((item) => item.id == sitter.id));
    _removedIds.add(sitter.id);
  }

  void _showSnack(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), action: action));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
        onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.pop(context, _removedIds);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.maybePop(context, _removedIds),
          ),
          title: const Row(
            children: [
              Icon(Icons.pets, color: AppColors.primaryRust),
              SizedBox(width: 8),
              Text('Saved Sitters', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircleAvatar(radius: 14, backgroundColor: Colors.black87, child: Icon(Icons.person, color: Colors.white, size: 16)),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRust))
            : RefreshIndicator(
                color: AppColors.primaryRust,
                onRefresh: () => _loadData(silent: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeader(_sitters.length),
                    const SizedBox(height: 16),
                    _buildFilters(),
                    const SizedBox(height: 16),
                    if (_sitters.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No saved sitters yet.\nTap the bookmark on a sitter to save them here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54, height: 1.4),
                          ),
                        ),
                      )
                    else
                      ..._visibleSitters.map((sitter) => _buildSitterCard(sitter)),
                    _buildSecurityFooter(),
                  ],
                ),
              ),
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildHeader(int savedCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Saved sitters',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lightRustBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$savedCount saved',
                  style: const TextStyle(
                    color: AppColors.primaryRust,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Your shortlist of sitters you want to book again.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        _buildFilterChip('All Active', selected: !_sortByRating, onTap: () => setState(() => _sortByRating = false)),
        const SizedBox(width: 8),
        _buildFilterChip('High Rating', selected: _sortByRating, onTap: () => setState(() => _sortByRating = true)),
      ],
    );
  }

  Widget _buildFilterChip(String label, {required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.black87 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSitterCard(SavedSitterModel sitter) {
    final initial = sitter.name.trim().isEmpty
        ? '?'
        : sitter.name.trim()[0].toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _openSitter(sitter),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.lightRustBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: AppColors.primaryRust,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  sitter.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: AppColors.primaryRust, size: 14),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  sitter.location,
                                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.primaryRust, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${sitter.rating.toStringAsFixed(1)} (${sitter.reviewCount})',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DirectChatScreen(partnerId: sitter.id, partnerName: sitter.name),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 16),
                        label: const Text('Message', style: TextStyle(color: Colors.white, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BookingFlowScreen(sitterId: sitter.id)),
                          );
                        },
                        icon: const Icon(Icons.calendar_month, color: Colors.white, size: 16),
                        label: const Text('Book', style: TextStyle(color: Colors.white, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRust,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.bookmark, color: AppColors.primaryRust),
                        tooltip: 'Remove from saved',
                        onPressed: () => _unsaveSitter(sitter),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.primaryRust, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pre-Screened Security Standard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text('All saved sitters undergo continuous bi-monthly South African Police Service criminal record validation and home conduct reference audits.', style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      elevation: 0,
      currentIndex: 0,
      selectedItemColor: AppColors.primaryRust,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      onTap: (index) {
        if (index == 0) {
          Navigator.maybePop(context, _removedIds);
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BookingsDashboardScreen()),
            result: _removedIds,
          );
        } else if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const MessagesScreen()));
        } else if (index == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const OwnerProfileScreen()));
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'HOME'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'BOOKINGS'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'MESSAGES'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
      ],
    );
  }
}