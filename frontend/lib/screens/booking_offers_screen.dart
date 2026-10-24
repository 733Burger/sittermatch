import 'package:flutter/material.dart';

import '../models/booking_model.dart';
import '../services/booking_service.dart';
import '../theme/app_colors.dart';
import 'direct_chat_screen.dart';
import 'sitter_detail_screen.dart';

/// The sitters who offered to take a booking. The homeowner compares their prices, checks their
/// profile or messages them, then accepts one; the other offers are removed.
/// Pops true if an offer was accepted or declined.
class BookingOffersScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingOffersScreen({super.key, required this.booking});

  @override
  State<BookingOffersScreen> createState() => _BookingOffersScreenState();
}

class _BookingOffersScreenState extends State<BookingOffersScreen> {
  late List<SitterOffer> _offers = List.of(widget.booking.offers);
  bool _changed = false;
  int? _busySitterId;

  int get _nights {
    final start = widget.booking.startDate, end = widget.booking.endDate;
    if (start == null || end == null) return 1;
    final n = DateTime(end.year, end.month, end.day).difference(DateTime(start.year, start.month, start.day)).inDays;
    return n < 1 ? 1 : n;
  }

  String _money(num v) => 'R${v == v.roundToDouble() ? v.toInt() : v.toStringAsFixed(2)}';

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _error(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '');
    final match = RegExp(r'"message"\s*:\s*"([^"]*)"').firstMatch(text);
    return match?.group(1) ?? text;
  }

  Future<void> _accept(SitterOffer offer) async {
    final bookingId = widget.booking.bookingId;
    if (bookingId == null) return;
    final others = _offers.length - 1;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Accept ${offer.sitterName}?'),
        content: Text(others > 0
            ? '${offer.sitterName} gets this booking at the prices offered. '
                'The other $others ${others == 1 ? 'offer' : 'offers'} will be removed.'
            : '${offer.sitterName} gets this booking at the prices offered.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Go back')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRust, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busySitterId = offer.sitterId);
    try {
      await BookingService.acceptOffer(bookingId, offer.sitterId);
      if (!mounted) return;
      _showSnack('${offer.sitterName} is booked for your stay.');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busySitterId = null);
      _showSnack('Could not accept: ${_error(e)}');
    }
  }

  Future<void> _decline(SitterOffer offer) async {
    final bookingId = widget.booking.bookingId;
    if (bookingId == null) return;
    setState(() => _busySitterId = offer.sitterId);
    try {
      await BookingService.declineOffer(bookingId, offer.sitterId);
      if (!mounted) return;
      setState(() {
        _offers = _offers.where((o) => o.sitterId != offer.sitterId).toList();
        _changed = true;
        _busySitterId = null;
      });
      _showSnack("${offer.sitterName}'s offer was declined.");
    } catch (e) {
      if (!mounted) return;
      setState(() => _busySitterId = null);
      _showSnack('Could not decline: ${_error(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          title: const Text('Offers', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.booking.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkText),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.booking.rightBadgeText} · ${widget.booking.subtitle}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            if (_offers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No offers right now. Sitters who want this booking will show up here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              )
            else
              ..._offers.map(_buildOfferCard),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(SitterOffer offer) {
    final busy = _busySitterId == offer.sitterId;
    final lines = <(String, double, int?)>[
      if (offer.pricePerNight != null) ('Overnight stay', offer.pricePerNight!, _nights),
      if (offer.pricePerVisit != null) ('Drop-in visit', offer.pricePerVisit!, null),
      if (offer.pricePerWalk != null) ('Dog walk', offer.pricePerWalk!, null),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SitterDetailScreen(sitterId: offer.sitterId)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${offer.sitterId}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer.sitterName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            offer.reviewCount == 0
                                ? 'No reviews yet · View profile'
                                : '${offer.rating.toStringAsFixed(1)} (${offer.reviewCount}) · View profile',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black38),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(l.$1, style: const TextStyle(fontSize: 13))),
                    Text(
                      l.$3 == null
                          ? '${_money(l.$2)} each'
                          : '${_money(l.$2)} × ${l.$3} = ${_money(l.$2 * l.$3!)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryRust),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          if (busy)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryRust))
          else
            Row(
              children: [
                IconButton(
                  tooltip: 'Message',
                  style: IconButton.styleFrom(backgroundColor: AppColors.lightRustBg),
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryRust, size: 18),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DirectChatScreen(partnerId: offer.sitterId, partnerName: offer.sitterName),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busySitterId == null ? () => _decline(offer) : null,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Decline', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busySitterId == null ? () => _accept(offer) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRust,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Accept',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
