import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../services/message_service.dart';
import '../theme/app_colors.dart';
import 'bookings_dashboard_screen.dart';
import 'direct_chat_screen.dart';
import 'jobs_dashboard_screen.dart';
import 'owner_profile_screen.dart';
import 'sitter_profile_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  bool _isSitter = false;
  bool _unreadOnly = false;
  String _query = '';
  List<Conversation> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------- Data ----------

  Future<void> _loadData({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final role = (await AuthService().getUserRole() ?? '').toUpperCase();
      final userId = await AuthService().getUserId();
      if (!mounted) return;

      if (userId == null) {
        setState(() {
          _loading = false;
          _error = 'Please log in again to see your messages.';
        });
        return;
      }

      final conversations = await MessageService.fetchConversations(
        userId: userId,
        role: role,
      );
      if (!mounted) return;

      setState(() {
        _isSitter = role == 'SITTER';
        _conversations = conversations;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your messages. Check your connection and try again.';
      });
    }
  }

  // ---------- Helpers ----------

  int get _unreadCount => _conversations.where((c) => c.unread > 0).length;

  List<Conversation> get _visible {
    final q = _query.trim().toLowerCase();
    return _conversations.where((c) {
      if (_unreadOnly && c.unread == 0) return false;
      if (q.isNotEmpty && !c.partnerName.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  Future<void> _openChat(Conversation convo) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(
          partnerId: convo.partnerId,
          partnerName: convo.partnerName,
        ),
      ),
    );
    // Refresh so unread counts and previews are up to date.
    if (mounted) _loadData(showSpinner: false);
  }

  void _handleBottomNavTap(int index) {
    switch (index) {
      case 0:
        // Home is the first screen in the stack after login.
        Navigator.of(context).popUntil((route) => route.isFirst);
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
      body: _buildBody(),
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

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryRust));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final visible = _visible;

    return RefreshIndicator(
      color: AppColors.primaryRust,
      onRefresh: () => _loadData(showSpinner: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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

  Widget _buildConversationTile(Conversation convo) {
    final hasUnread = convo.unread > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openChat(convo),
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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person, color: Colors.grey, size: 28),
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
                            convo.partnerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatChatTime(convo.lastSentAt),
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