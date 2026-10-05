import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../theme/app_colors.dart';
import 'bookings_dashboard_screen.dart';
import 'direct_chat_screen.dart';
import 'jobs_dashboard_screen.dart';
import 'owner_profile_screen.dart';
import 'sitter_profile_screen.dart';
import 'owner_home_screen.dart';

/// One row in the conversation list.
class _Conversation {
  final String name;
  final String lastMessage;
  final String time; // e.g. '10:30 AM', 'Yesterday', 'Mon'
  final int unread;
  final String? imageUrl;
  final String? bookingLabel; // e.g. 'Camps Bay Stay · Oct 12–18'

  const _Conversation({
    required this.name,
    required this.lastMessage,
    required this.time,
    this.unread = 0,
    this.imageUrl,
    this.bookingLabel,
  });
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  // Sample conversations so the layout can be seen.
  // Set to false once real conversations come from the backend.
  static const bool _useSampleData = true;

  // Homeowners see their conversations with sitters...
  static const List<_Conversation> _sampleForOwner = [
    _Conversation(
      name: 'Lerato Khumalo',
      lastMessage: 'Hello, I reviewed Luke and Josh care sheet',
      time: '10:30 AM',
      unread: 2,
      imageUrl: 'https://i.pravatar.cc/150?img=44',
      bookingLabel: 'Camps Bay Stay · Oct 12–18',
    ),
    _Conversation(
      name: 'Michael Tau',
      lastMessage: 'Perfect, I can confirm the dates tomorrow.',
      time: 'Yesterday',
      imageUrl: 'https://i.pravatar.cc/150?img=12',
    ),
    _Conversation(
      name: 'Sarah Jenkins',
      lastMessage: 'You: Thanks again for looking after Buster!',
      time: 'Mon',
      imageUrl: 'https://i.pravatar.cc/150?img=5',
      bookingLabel: 'Sea Point Apartment · Sep 5–9',
    ),
  ];

  // ...and sitters see their conversations with homeowners.
  static const List<_Conversation> _sampleForSitter = [
    _Conversation(
      name: 'Joshua Stevens',
      lastMessage: 'Hi Sarah, are you free from 24 to 27 Nov?',
      time: '9:12 AM',
      unread: 1,
      bookingLabel: 'Camps Bay Stay · Nov 24–27',
    ),
    _Conversation(
      name: 'Claire Vance',
      lastMessage: 'You: Happy to do two walks a day.',
      time: 'Yesterday',
    ),
    _Conversation(
      name: 'Thandi Mokoena',
      lastMessage: 'Thank you for the update photos!',
      time: 'Tue',
      bookingLabel: 'Claremont Cottage · Sep 20–22',
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  bool _isSitter = false;
  bool _unreadOnly = false;
  String _query = '';
  List<_Conversation> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final role = await AuthService().getUserRole();
    if (!mounted) return;
    final isSitter = (role ?? '').toUpperCase() == 'SITTER';
    setState(() {
      _isSitter = isSitter;
      // TODO: load the real conversations from the backend.
      _conversations = _useSampleData
          ? (isSitter ? _sampleForSitter : _sampleForOwner)
          : <_Conversation>[];
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------- Helpers ----------

  int get _unreadCount => _conversations.where((c) => c.unread > 0).length;

  List<_Conversation> get _visible {
    final q = _query.trim().toLowerCase();
    return _conversations.where((c) {
      if (_unreadOnly && c.unread == 0) return false;
      if (q.isNotEmpty && !c.name.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  void _openChat() {
    // TODO: pass the selected conversation once DirectChatScreen accepts one.
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DirectChatScreen()),
    );
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OwnerHomeScreen()),
         );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                _isSitter ? const JobsDashboardScreen() : const BookingsDashboardScreen(),
          ),
        );
        break;
      case 2:
        break; // already on Messages
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                _isSitter ? const SitterProfileScreen() : const OwnerProfileScreen(),
          ),
        );
        break;
    }
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.pets, color: AppColors.primaryRust),
        title: const Text(
          'Messages',
          style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRust))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSearchField(),
                const SizedBox(height: 12),
                _buildFilterPills(),
                const SizedBox(height: 16),
                if (visible.isEmpty)
                  _buildEmptyState()
                else
                  ...visible.map(_buildConversationTile),
                const SizedBox(height: 24),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        currentIndex: 2,
        selectedItemColor: AppColors.primaryRust,
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: _handleBottomNavTap,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'HOME'),
          BottomNavigationBarItem(
            icon: Icon(_isSitter ? Icons.work_outline : Icons.calendar_today),
            label: _isSitter ? 'JOBS' : 'BOOKINGS',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'MESSAGES',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      decoration: InputDecoration(
        hintText: 'Search conversations...',
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: AppColors.primaryRust),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryRust, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    return Row(
      children: [
        _buildPill('ALL (${_conversations.length})', !_unreadOnly, () {
          setState(() => _unreadOnly = false);
        }),
        const SizedBox(width: 8),
        _buildPill('UNREAD ($_unreadCount)', _unreadOnly, () {
          setState(() => _unreadOnly = !_unreadOnly);
        }),
      ],
    );
  }

  Widget _buildPill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRust : AppColors.expandButtonBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.darkText.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final noConversations = _conversations.isEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.lightRustBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.primaryRust,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            noConversations ? 'No conversations yet' : 'No matching conversations',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            noConversations
                ? (_isSitter
                    ? 'When a homeowner messages you, the conversation will show up here.'
                    : 'Message a sitter from their profile and the conversation will show up here.')
                : 'Try a different name or clear the filter.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.person, color: Colors.grey, size: 28),
    );
  }

  Widget _buildConversationTile(_Conversation convo) {
    final hasUnread = convo.unread > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _openChat,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: convo.imageUrl != null
                      ? Image.network(
                          convo.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _avatarPlaceholder(),
                        )
                      : _avatarPlaceholder(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            convo.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          convo.time,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            color: hasUnread ? AppColors.primaryRust : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            convo.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                              color: hasUnread ? Colors.black87 : Colors.black54,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryRust,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${convo.unread}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (convo.bookingLabel != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.lightRustBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.event_note_outlined,
                              color: AppColors.primaryRust,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                convo.bookingLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primaryRust,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}