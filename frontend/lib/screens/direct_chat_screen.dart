import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import 'sitter_detail_screen.dart';

class DirectChatScreen extends StatefulWidget {
  const DirectChatScreen({super.key});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  late Future<List<ChatMessage>> _chatFuture;

  // Sample quote details: (requested service, sitter price).
  // TODO: replace with the real quote once it comes from the backend.
  static const List<(String, String)> _requestedServices = [
    ('Stay over night', 'R320 / night'),
  ];

  @override
  void initState() {
    super.initState();
    _chatFuture = ChatService.getChatThread();
  }

  void _openSitterDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SitterDetailScreen()),
    );
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
        return _buildSystemNotice();
      case ChatMessageType.quote:
        return _buildQuoteCard();
      case ChatMessageType.recieved:
        return _buildReceivedMessage(msg);
      case ChatMessageType.sent:
        return _buildSentMessage(msg);
      case ChatMessageType.oversight:
        return const SizedBox.shrink(); // oversight block removed
    }
  }

  Widget _buildSystemNotice() {
    return Column(
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(12)),
            child: const Text('Today • Camps Bay Residence', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primaryRust, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('SYSTEM NOTICE • Real-time SAPS Linked', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Booking Request Attached for Camps Bay Stay (24–27 Nov)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag(Icons.pets, '2 Dogs (Bella & Milo)'),
                  _buildTag(Icons.pets, '1 Cat (Cleo)'),
                  _buildTag(Icons.shield, 'ADT Liaison Ready'),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROPOSED SITTER QUOTE', style: TextStyle(color: AppColors.primaryRust, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: Text('3-Night Residential Care', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('R960', style: TextStyle(color: AppColors.primaryRust, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('R320 /\nnight', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          _buildServicesBlock(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRust, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text('Accept\nBooking & Rate', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Ignore / Decline', style: TextStyle(color: AppColors.primaryRust, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          const Center(child: Text('Funds placed in safe domestic escrow until stay completion.', style: TextStyle(fontSize: 10, color: Colors.grey))),
        ],
      ),
    );
  }

  // Requested services on the left, the sitter's price for each on the right.
  Widget _buildServicesBlock() {
    const labelStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: Colors.black54,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(child: Text('REQUESTED SERVICES', style: labelStyle)),
              Text('SITTER PRICE', style: labelStyle),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          ..._requestedServices.map((item) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.primaryRust, size: 14),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.$1,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.$2,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryRust),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

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

  Widget _buildTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
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