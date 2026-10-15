import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../services/message_service.dart';
import '../theme/app_colors.dart';
import 'sitter_detail_screen.dart';

/// One service in the booking offer, with its price.
class _OfferItem {
  final String service;
  final String unit; // 'night', 'visit' or 'walk'
  final int? quantity; // e.g. 3 nights. null for per-visit / per-walk services.
  final int originalPrice;
  int price;

  _OfferItem({
    required this.service,
    required this.unit,
    this.quantity,
    required this.originalPrice,
  }) : price = originalPrice;
}

class DirectChatScreen extends StatefulWidget {
  /// The user id of the person you are chatting with: the sitter if you are
  /// a homeowner, or the homeowner if you are a sitter.
  final int? partnerId;
  final String? partnerName;

  const DirectChatScreen({super.key, this.partnerId, this.partnerName});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  // Shows the sample booking offer card at the top of every chat.
  // TODO: set to false (or remove) once booking offers come from the backend.
  static const bool _showSampleOffer = true;

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;

  bool _loading = true;
  bool _sending = false;
  String? _error;
  int? _myId;
  String _myRole = '';
  List<DirectMessage> _messages = [];

  bool get _isHomeowner => _myRole == 'HOMEOWNER';

  // 'pending', 'accepted' or 'declined'
  String _offerStatus = 'pending';

  // Sample booking offer. TODO: replace with the real booking from the backend.
  final String _stayTitle = 'Camps Bay Stay';
  final String _dates = 'Nov 24 – 27';
  final int _nights = 3;
  final String _petsSummary = 'Bella & Milo (dogs), Cleo (cat)';
  final List<_OfferItem> _offerItems = [
    _OfferItem(service: 'Stay over night', unit: 'night', quantity: 3, originalPrice: 320),
    _OfferItem(service: 'Walk dog', unit: 'walk', originalPrice: 120),
  ];

  // The sitter and homeowner ids for this conversation.
  int? get _sitterId => _myRole == 'SITTER' ? _myId : widget.partnerId;
  int? get _homeownerId => _myRole == 'SITTER' ? widget.partnerId : _myId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final id = await AuthService().getUserId();
    final role = await AuthService().getUserRole();
    if (!mounted) return;

    _myId = id;
    _myRole = (role ?? '').toUpperCase();

    if (widget.partnerId == null || _myId == null) {
      setState(() => _loading = false);
      return;
    }

    await _loadMessages();

    // Check for new messages every few seconds while the chat is open.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _loadMessages(silent: true),
    );
  }

  // ---------- Messages: loading and sending ----------

  Future<void> _loadMessages({bool silent = false}) async {
    final sitterId = _sitterId;
    final homeownerId = _homeownerId;
    if (sitterId == null || homeownerId == null) return;

    try {
      final messages = await MessageService.fetchThread(
        sitterId: sitterId,
        homeownerId: homeownerId,
        viewerRole: _myRole,
      );
      if (!mounted) return;

      final hasNew = messages.length != _messages.length;
      setState(() {
        _messages = messages;
        _loading = false;
        _error = null;
      });
      if (hasNew) _scrollToBottom();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _error = 'Could not load messages. Check your connection and try again.';
      });
    }
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    final sitterId = _sitterId;
    final homeownerId = _homeownerId;
    if (text.isEmpty || _sending || sitterId == null || homeownerId == null) return;

    setState(() => _sending = true);
    try {
      final sent = await MessageService.sendMessage(
        sitterId: sitterId,
        homeownerId: homeownerId,
        sentBy: _myRole,
        message: text,
      );
      if (!mounted) return;

      _inputController.clear();
      setState(() {
        _messages = [..._messages, sent];
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ---------- Helpers ----------

  bool _isMine(DirectMessage msg) => msg.sentBy == _myRole;

  String get _partnerFirstName {
    final name = (widget.partnerName ?? '').trim();
    return name.isEmpty ? 'Them' : name.split(' ').first;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // Homeowners can open the sitter's profile from the chat header.
  bool get _canOpenPartnerProfile => _isHomeowner && widget.partnerId != null;

  void _openSitterDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SitterDetailScreen(sitterId: widget.partnerId!),
      ),
    );
  }

  int? get _total {
    final fixed = _offerItems.where((i) => i.quantity != null).toList();
    if (fixed.isEmpty) return null;
    return fixed.fold<int>(0, (sum, i) => sum + i.price * i.quantity!);
  }

  String _quantityLabel(_OfferItem item) {
    final qty = item.quantity;
    if (qty == null) return 'per ${item.unit}';
    return '$qty ${qty == 1 ? item.unit : '${item.unit}s'}';
  }

  void _acceptOffer() {
    setState(() => _offerStatus = 'accepted');
    // TODO: send the acceptance to the backend.
    _showSnack('Booking accepted.');
  }

  void _declineOffer() {
    setState(() => _offerStatus = 'declined');
    // TODO: send the decline to the backend.
    _showSnack('Offer declined.');
  }

  // The homeowner can change the price per night, per visit or per walk.
  void _editPrice(_OfferItem item) {
    final controller = TextEditingController(text: '${item.price}');
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Change price per ${item.unit}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.service} · currently R${item.price} / ${item.unit}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'New price',
                  prefixText: 'R ',
                  suffixText: '/ ${item.unit}',
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value <= 0) {
                  setDialogState(() => error = 'Enter a price above R0');
                  return;
                }
                setState(() => item.price = value);
                // TODO: send the updated price to the backend.
                Navigator.pop(ctx);
                _showSnack('Price updated to R$value / ${item.unit}.');
              },
              child: const Text('Save price'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Build ----------

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
        title: const Text('Direct Chat', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: AppColors.darkText), onPressed: () {}),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(radius: 14, backgroundColor: AppColors.primaryRust, child: Icon(Icons.person, color: Colors.white, size: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildContactHeader(),
          Expanded(child: _buildThread()),
          _buildBottomInputArea(),
        ],
      ),
    );
  }

  // The profile bar shows who you are chatting with.
  // Homeowners can tap it to open the sitter's details.
  Widget _buildContactHeader() {
    final partnerName = widget.partnerName ?? 'Conversation';
    final canOpen = _canOpenPartnerProfile;
    final roleLabel = _myRole.isEmpty ? '' : (_myRole == 'SITTER' ? 'Homeowner' : 'Sitter');

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: canOpen ? _openSitterDetails : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partnerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (roleLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(roleLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    ],
                  ],
                ),
              ),
              if (canOpen) const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThread() {
    if (widget.partnerId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            "Open a conversation from Messages, or tap Message on a sitter's card.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      );
    }

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
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadMessages();
                },
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

    const showOffer = _showSampleOffer;
    if (_messages.isEmpty && !showOffer) {
      return const Center(
        child: Text(
          'No messages yet. Say hello!',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (showOffer ? 1 : 0),
      itemBuilder: (context, index) {
        if (showOffer && index == 0) return _buildOfferCard();
        final msg = _messages[index - (showOffer ? 1 : 0)];
        return _isMine(msg) ? _buildSentMessage(msg) : _buildReceivedMessage(msg);
      },
    );
  }

  // ---------- Booking offer ----------

  Widget _buildOfferCard() {
    final canEdit = _isHomeowner && _offerStatus == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BOOKING OFFER',
            style: TextStyle(
              color: AppColors.primaryRust,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _stayTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.calendar_today_outlined, '$_dates · $_nights nights'),
          const SizedBox(height: 4),
          _buildInfoRow(Icons.pets, _petsSummary),
          const SizedBox(height: 14),
          _buildPriceBlock(canEdit),
          const SizedBox(height: 14),
          _buildOfferActions(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryRust, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBlock(bool canEdit) {
    const labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: Colors.black54,
    );
    final total = _total;
    final hasPerUseItems = _offerItems.any((i) => i.quantity == null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(child: Text('SERVICE', style: labelStyle)),
              Text('PRICE', style: labelStyle),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          ..._offerItems.map((item) => _buildPriceRow(item, canEdit)),
          if (total != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Text('Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                Text(
                  'R$total',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryRust),
                ),
              ],
            ),
          ],
          if (hasPerUseItems) ...[
            const SizedBox(height: 8),
            const Text(
              'Per-walk and per-visit prices are charged each time and are not in the total.',
              style: TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
          if (canEdit) ...[
            const SizedBox(height: 8),
            const Text(
              'Tap the pencil to change a price.',
              style: TextStyle(fontSize: 10, color: AppColors.primaryRust, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(_OfferItem item, bool canEdit) {
    final changed = item.price != item.originalPrice;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.primaryRust, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.service, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text(_quantityLabel(item), style: const TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (changed)
                Text(
                  'R${item.originalPrice}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                'R${item.price} / ${item.unit}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryRust),
              ),
            ],
          ),
          if (canEdit)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Change price',
              icon: const Icon(Icons.edit_outlined, color: AppColors.primaryRust, size: 18),
              onPressed: () => _editPrice(item),
            ),
        ],
      ),
    );
  }

  Widget _buildOfferActions() {
    if (_offerStatus != 'pending') {
      final accepted = _offerStatus == 'accepted';
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.lightRustBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              accepted ? Icons.check_circle : Icons.cancel_outlined,
              color: AppColors.primaryRust,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              accepted ? 'Booking accepted' : 'Offer declined',
              style: const TextStyle(
                color: AppColors.primaryRust,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _acceptOffer,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRust,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
            label: const Text(
              'Accept booking',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextButton(
            onPressed: _declineOffer,
            child: const Text(
              'Ignore / Decline',
              style: TextStyle(color: AppColors.primaryRust, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Messages ----------

  Widget _buildReceivedMessage(DirectMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 40, bottom: 4),
            child: Text(
              '$_partnerFirstName • ${formatChatTime(msg.sentAt)}',
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, size: 16, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomRight: Radius.circular(12))),
                  child: Text(msg.text, style: const TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentMessage(DirectMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 40, bottom: 4),
            child: Text(
              'You • ${formatChatTime(msg.sentAt)}',
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: AppColors.primaryRust, borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomLeft: Radius.circular(12))),
                  child: Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(radius: 14, backgroundColor: Colors.black87, child: Text('ME', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputArea() {
    final enabled = widget.partnerId != null && _myId != null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.black87, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade300)),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        enabled: enabled,
                        maxLength: 255,
                        textInputAction: TextInputAction.send,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _send(),
                        buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Icon(Icons.mic_none, color: Colors.black54, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: enabled ? _send : null,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: enabled ? AppColors.primaryRust : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}