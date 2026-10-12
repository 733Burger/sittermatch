import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/chat_model.dart';
import '../services/auth_services.dart';
import '../services/chat_service.dart';
import 'sitter_detail_screen.dart';

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
  const DirectChatScreen({super.key});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  late Future<List<ChatMessage>> _chatFuture;

  bool _isHomeowner = false;

  String _offerStatus = 'pending';

  final String _stayTitle = 'Camps Bay Stay';
  final String _dates = 'Nov 24 – 27';
  final int _nights = 3;
  final String _petsSummary = 'Bella & Milo (dogs), Cleo (cat)';
  final List<_OfferItem> _offerItems = [
    _OfferItem(service: 'Stay over night', unit: 'night', quantity: 3, originalPrice: 320),
    _OfferItem(service: 'Walk dog', unit: 'walk', originalPrice: 120),
  ];

  @override
  void initState() {
    super.initState();
    _chatFuture = ChatService.getChatThread();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AuthService().getUserRole();
    if (!mounted) return;
    setState(() => _isHomeowner = (role ?? '').toUpperCase() == 'HOMEOWNER');
  }

  void _openSitterDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SitterDetailScreen(sitterId: 2),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
          Expanded(
            child: FutureBuilder<List<ChatMessage>>(
              future: _chatFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryRust));
                }
                if (snapshot.hasError) return const Center(child: Text('Failed to load chat.'));

                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageRouter(msg);
                  },
                );
              },
            ),
          ),
          _buildBottomInputArea(),
        ],
      ),
    );
  }

  // The whole profile bar opens the sitter's details.
  Widget _buildContactHeader() {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: _openSitterDetails,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=44'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.primaryRust,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
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
                    const Row(
                      children: [
                        Text('Lerato Khumalo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(width: 4),
                        Icon(Icons.verified_outlined, color: AppColors.primaryRust, size: 14),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Active Sitter • Camps Bay', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageRouter(ChatMessage msg) {
    switch (msg.type) {
      case ChatMessageType.system:
        return _buildOfferCard(); // one simple card for the booking and its price
      case ChatMessageType.quote:
        return const SizedBox.shrink(); // merged into the offer card
      case ChatMessageType.recieved:
        return _buildReceivedMessage(msg);
      case ChatMessageType.sent:
        return _buildSentMessage(msg);
      case ChatMessageType.oversight:
        return const SizedBox.shrink();
    }
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

  Widget _buildReceivedMessage(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 48, bottom: 4),
            child: Text('Lerato • ${msg.timeStamp}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const CircleAvatar(radius: 14, backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=44')),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomRight: Radius.circular(12))),
                  child: Text(msg.text ?? '', style: const TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentMessage(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 48, bottom: 4),
            child: Text('You • ${msg.timeStamp}', style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: AppColors.primaryRust, borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12), bottomLeft: Radius.circular(12))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(msg.text ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Read', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          SizedBox(width: 4),
                          Icon(Icons.done_all, color: Colors.white70, size: 12),
                        ],
                      )
                    ],
                  ),
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
                child: const Row(
                  children: [
                    Expanded(
                      child: TextField(decoration: InputDecoration(hintText: 'Type a message...', hintStyle: TextStyle(fontSize: 14), border: InputBorder.none)),
                    ),
                    Icon(Icons.mic_none, color: Colors.black54, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: AppColors.primaryRust, shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}