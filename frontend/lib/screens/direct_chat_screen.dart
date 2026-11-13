import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/booking_model.dart';
import '../services/auth_services.dart';
import '../services/booking_service.dart';
import '../services/message_service.dart';
import '../theme/app_colors.dart';
import 'homeowner_detail_screen.dart';
import 'sitter_detail_screen.dart';

/// One service in the booking offer, with its price.
class _OfferItem {
  final String service;
  final String unit; // 'night', 'visit' or 'walk'
  final int? quantity; // e.g. 3 nights. null for per-visit / per-walk services.
  final double originalPrice;
  double price;

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

  // The open booking between these two people (null = no card shown).
  BookingOffer? _offer;
  bool _offerBusy = false;

  bool get _showOffer =>
      _offer != null && const {'REQUESTED', 'ACCEPTED', 'CONFIRMED', 'ONGOING'}.contains(_offer!.status);
  bool get _offerOpen => _offer?.status == 'REQUESTED';

  List<_OfferItem> get _offerItems {
    final o = _offer;
    if (o == null) return [];
    return [
      if (o.pricePerNight != null)
        _OfferItem(service: 'Stay over night', unit: 'night', quantity: o.nights, originalPrice: o.pricePerNight!),
      if (o.pricePerVisit != null)
        _OfferItem(service: 'Drop-in visit (feed pets)', unit: 'visit', originalPrice: o.pricePerVisit!),
      if (o.pricePerWalk != null)
        _OfferItem(service: 'Walk dog', unit: 'walk', originalPrice: o.pricePerWalk!),
    ];
  }

  String _money(num v) => 'R${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(2)}';

  Future<void> _loadOffer() async {
    final s = _sitterId, h = _homeownerId;
    if (s == null || h == null) return;
    try {
      final offer = await BookingService.fetchBookingBetween(sitterId: s, homeownerId: h);
      if (mounted) setState(() => _offer = offer);
    } catch (e) {
      debugPrint('Error loading booking offer: $e');
    }
  }

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
      _loadOffer();
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
  bool get _canOpenPartnerProfile => _myRole.isNotEmpty && widget.partnerId != null;

  // Homeowners open the sitter's profile; sitters open the homeowner's.
  void _openSitterDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _isHomeowner
            ? SitterDetailScreen(sitterId: widget.partnerId!)
            : HomeownerDetailScreen(homeownerId: widget.partnerId!, homeownerName: widget.partnerName),
      ),
    );
  }

  double? get _total {
    final fixed = _offerItems.where((i) => i.quantity != null).toList();
    if (fixed.isEmpty) return null;
    return fixed.fold<double>(0, (sum, i) => sum + i.price * i.quantity!);
  }

  String _quantityLabel(_OfferItem item) {
    final qty = item.quantity;
    if (qty == null) return 'per ${item.unit}';
    return '$qty ${qty == 1 ? item.unit : '${item.unit}s'}';
  }

  // Accepting gives this sitter the booking and removes other sitters' offers on it.
  // Declining removes only this sitter's offer; the booking stays open.
  Future<void> _answerOffer({required bool accept}) async {
    final o = _offer;
    final sitterId = o?.sitterId ?? _sitterId;
    if (o == null || sitterId == null || _offerBusy) return;
    setState(() => _offerBusy = true);
    try {
      if (accept) {
        await BookingService.acceptOffer(o.id, sitterId);
      } else {
        await BookingService.declineOffer(o.id, sitterId);
      }
      await _loadOffer();
      _showSnack(accept ? 'Booking accepted.' : 'Booking ignored.');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _offerBusy = false);
    }
  }

  void _acceptOffer() => _answerOffer(accept: true);
  void _declineOffer() => _answerOffer(accept: false);

  Future<void> _savePrice(_OfferItem item, double value) async {
    final o = _offer;
    if (o == null) return;
    try {
      final updated = await BookingService.updatePrices(
        o.id,
        sitterId: o.sitterId ?? _sitterId,
        pricePerNight: item.unit == 'night' ? value : null,
        pricePerVisit: item.unit == 'visit' ? value : null,
        pricePerWalk: item.unit == 'walk' ? value : null,
      );
      if (!mounted) return;
      setState(() => _offer = updated);
      _showSnack('Price updated to ${_money(value)} / ${item.unit}.');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
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
                '${item.service} · currently ${_money(item.price)} / ${item.unit}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                final value = double.tryParse(controller.text.trim().replaceAll(',', '.'));
                if (value == null || value <= 0) {
                  setDialogState(() => error = 'Enter a price above R0');
                  return;
                }
                Navigator.pop(ctx);
                _savePrice(item, value);
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

    final showOffer = _showOffer;
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

  // Same look as the job cards and booking details: status pill, title, a grey details panel
  // with labelled rows, then the prices and two solid buttons.
  Widget _buildOfferCard() {
    final canEdit = _isHomeowner && _offerOpen;
    final pets = _offerPets;
    final notes = _offerNotes;

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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.send_outlined, color: AppColors.primaryRust, size: 12),
                SizedBox(width: 4),
                Text('BOOKING OFFER',
                    style: TextStyle(color: AppColors.primaryRust, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _offer!.bookingType,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildOfferDetailRow(Icons.calendar_today_outlined, 'DATES', _offerDateLine),
                if (pets != null) ...[
                  const SizedBox(height: 10),
                  _buildOfferDetailRow(Icons.pets, 'PETS', pets),
                ],
                if (notes != null) ...[
                  const SizedBox(height: 10),
                  _buildOfferDetailRow(Icons.sticky_note_2_outlined, 'NOTES', notes, maxLines: 3),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildPriceBlock(canEdit),
          const SizedBox(height: 14),
          _buildOfferActions(),
        ],
      ),
    );
  }

  // The offer's notes end with a "Pets: a, b" line added when the booking was made.
  List<String> get _offerNoteLines => _offer!.notes
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  String? get _offerPets {
    for (final line in _offerNoteLines) {
      if (line.startsWith('Pets:')) return line.substring('Pets:'.length).trim();
    }
    return null;
  }

  String? get _offerNotes {
    final notes = _offerNoteLines.where((line) => !line.startsWith('Pets:')).join(' ');
    return notes.isEmpty ? null : notes;
  }

  // "Mon 1 Dec – Wed 3 Dec · 2 nights".
  String get _offerDateLine {
    final o = _offer!;
    if (o.start == null || o.end == null) return 'Dates unconfirmed';
    final format = DateFormat('EEE d MMM');
    return '${format.format(o.start!)} – ${format.format(o.end!)} · ${o.nights} ${o.nights == 1 ? 'night' : 'nights'}';
  }

  Widget _buildOfferDetailRow(IconData icon, String label, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppColors.primaryRust),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Each service with its price (and a pencil for the homeowner), then the total.
  Widget _buildPriceBlock(bool canEdit) {
    final total = _total;
    final hasPerUseItems = _offerItems.any((i) => i.quantity == null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('PRICES',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
        for (final item in _offerItems) _buildPriceRow(item, canEdit),
        if (total != null) ...[
          const SizedBox(height: 4),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text('Total',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkText)),
              ),
              Text(
                _money(total),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryRust),
              ),
            ],
          ),
        ],
        if (hasPerUseItems || canEdit) ...[
          const SizedBox(height: 6),
          Text(
            [
              if (hasPerUseItems) 'Walks and visits are charged each time, not in the total.',
              if (canEdit) 'Tap the pencil to change a price.',
            ].join(' '),
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceRow(_OfferItem item, bool canEdit) {
    final changed = item.price != item.originalPrice;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.service,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkText)),
                Text(_quantityLabel(item), style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (changed)
                Text(
                  _money(item.originalPrice),
                  style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough),
                ),
              Text(
                '${_money(item.price)} / ${item.unit}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryRust),
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
    if (!_offerOpen) {
      return _buildOfferStatus(Icons.check_circle, 'Booking accepted');
    }

    // The sitter has sent the offer; only the homeowner can accept or ignore it.
    if (!_isHomeowner) {
      return _buildOfferStatus(Icons.hourglass_empty, 'Waiting for the homeowner to review prices and accept.');
    }

    return Row(
      children: [
        Expanded(
          child: _buildOfferButton(
            label: 'Ignore Booking',
            icon: Icons.block,
            color: Colors.red,
            onPressed: _offerBusy ? null : _declineOffer,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildOfferButton(
            label: 'Accept Booking',
            icon: Icons.check_circle_outline,
            color: AppColors.primaryRust,
            onPressed: _offerBusy ? null : _acceptOffer,
          ),
        ),
      ],
    );
  }

  Widget _buildOfferStatus(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryRust, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: AppColors.primaryRust, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // Same card button as the jobs and bookings dashboards: solid fill, 12px text.
  Widget _buildOfferButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, color: Colors.white, size: 16),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  // ---------- Messages ----------

  Widget _buildReceivedMessage(DirectMessage msg) => _buildBubble(msg, mine: false);

  Widget _buildSentMessage(DirectMessage msg) => _buildBubble(msg, mine: true);

  // A chat bubble that hugs its text, up to 75% of the screen, with the tail corner
  // on the sender's side and the time underneath.
  Widget _buildBubble(DirectMessage msg, {required bool mine}) {
    const radius = Radius.circular(18);
    const tail = Radius.circular(4);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.75;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mine ? AppColors.primaryRust : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: radius,
                  topRight: radius,
                  bottomLeft: mine ? radius : tail,
                  bottomRight: mine ? tail : radius,
                ),
                boxShadow: mine
                    ? null
                    : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: mine ? Colors.white : AppColors.darkText,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Text(
              mine ? formatChatTime(msg.sentAt) : '$_partnerFirstName • ${formatChatTime(msg.sentAt)}',
              style: const TextStyle(fontSize: 10, color: Colors.black45),
            ),
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