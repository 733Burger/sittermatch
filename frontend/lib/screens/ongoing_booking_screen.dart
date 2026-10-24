import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../models/pet_model.dart';
import '../models/task_model.dart';
import '../services/auth_services.dart';
import '../services/booking_service.dart';
import '../services/task_service.dart';
import '../theme/app_colors.dart';
import 'complete_stay_review_screen.dart';
import 'direct_chat_screen.dart';
import 'homeowner_detail_screen.dart';
import 'sitter_detail_screen.dart';

class OngoingBookingScreen extends StatefulWidget {
  final BookingModel? booking;

  const OngoingBookingScreen({super.key, this.booking});

  @override
  State<OngoingBookingScreen> createState() => _OngoingBookingScreenState();
}

class _OngoingBookingScreenState extends State<OngoingBookingScreen> {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  bool _loading = true;
  bool _isSitter = false;
  List<PetModel> _pets = [];

  late DateTime _start;
  late DateTime _end;

  // Today's checklist from the homeowner's profile, with what the sitter has ticked off.
  List<StayTask> _tasks = [];
  String? _tasksError;
  final Set<int> _savingTaskIds = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final job = widget.booking;

    _start = _dateOnly(job?.startDate) ?? today;
    _end = _dateOnly(job?.endDate) ?? today.add(const Duration(days: 3));

    final role = await AuthService().getUserRole();

    try {
      if (job?.homeownerId != null) {
        _pets = await BookingService.fetchHomeownerPets(job!.homeownerId!);
      }
    } catch (e) {
      debugPrint('Error loading pets: $e');
    }

    await _loadTasks();

    if (!mounted) return;
    setState(() {
      _isSitter = (role ?? '').toUpperCase() == 'SITTER';
      _loading = false;
    });
  }

  DateTime? _dateOnly(DateTime? d) => d == null ? null : DateTime(d.year, d.month, d.day);

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  int get _totalDays {
    final diff = _end.difference(_start).inDays;
    return diff <= 0 ? 1 : diff + 1;
  }

  int get _currentDay => (_today.difference(_start).inDays + 1).clamp(1, _totalDays);

  // The last day counts as the end, so the sitter can wrap up on check-out day.
  bool get _isBookingEnded => !_today.isBefore(_end);

  String get _dateRange =>
      '${_months[_start.month - 1]} ${_start.day} – ${_months[_end.month - 1]} ${_end.day}';

  String get _homeownerName => widget.booking?.homeownerName ?? 'Homeowner';
  String get _sitterName => widget.booking?.sitterName ?? 'Sitter';
  String get _otherName => _isSitter ? _homeownerName : _sitterName;
  int? get _otherId => _isSitter ? widget.booking?.homeownerId : widget.booking?.sitterId;

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadTasks() async {
    final bookingId = widget.booking?.bookingId;
    if (bookingId == null) return;
    try {
      final tasks = await TaskService.fetchBookingTasks(bookingId, _today);
      _tasks = tasks;
      _tasksError = null;
    } catch (e) {
      debugPrint('Error loading tasks: $e');
      _tasksError = "Could not load today's tasks.";
    }
  }

  Future<void> _toggleTask(StayTask task) async {
    final bookingId = widget.booking?.bookingId;
    if (!_isSitter) {
      _showSnack('Only the sitter can tick tasks off.');
      return;
    }
    if (bookingId == null || _savingTaskIds.contains(task.id)) return;

    setState(() => _savingTaskIds.add(task.id));
    try {
      final tasks = await TaskService.setTaskDone(bookingId, task.id, _today, !task.done);
      if (!mounted) return;
      setState(() => _tasks = tasks);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingTaskIds.remove(task.id));
    }
  }

  String _timeLabel(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _openDirectChat() {
    final partnerId = _otherId;
    if (partnerId == null) {
      _showSnack('Chat cannot be started: user details missing.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(partnerId: partnerId, partnerName: _otherName),
      ),
    );
  }

  // Sitters open the homeowner's profile; homeowners open the sitter's.
  void _openPartnerProfile() {
    final partnerId = _otherId;
    if (partnerId == null) {
      _showSnack('Profile not available for this booking.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _isSitter
            ? HomeownerDetailScreen(
                homeownerId: partnerId,
                homeownerName: _homeownerName,
                booking: widget.booking,
              )
            : SitterDetailScreen(sitterId: partnerId),
      ),
    );
  }

  // Either side can end the stay; each then reviews the other.
  Future<void> _completeStay() async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CompleteStayReviewScreen(booking: widget.booking, pets: _pets, isSitter: _isSitter),
      ),
    );
    if (completed == true && mounted) Navigator.pop(context, true);
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryRust),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isSitter ? 'Current Job' : 'Ongoing Booking',
          style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRust))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildPartnerCard(),
                const SizedBox(height: 16),
                _buildPetsCard(),
                const SizedBox(height: 16),
                _buildTasksCard(),
                const SizedBox(height: 16),
                _buildNotesCard(),
                const SizedBox(height: 24),
              ],
            ),
      bottomNavigationBar: _loading ? null : _buildBottomActions(),
    );
  }

  Widget _buildSummaryCard() {
    final daysLeft = _totalDays - _currentDay;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.lightRustBg, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: AppColors.primaryRust, size: 8),
                    SizedBox(width: 6),
                    Text('ONGOING',
                        style: TextStyle(color: AppColors.primaryRust, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (widget.booking?.id.isNotEmpty == true)
                Text('ID #${widget.booking!.id}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 14),
          Text(widget.booking?.title ?? 'Ongoing Stay',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText)),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: AppColors.primaryRust, size: 16),
              const SizedBox(width: 8),
              Text(_dateRange, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Day $_currentDay', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Text('of $_totalDays', style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const Spacer(),
              Text(
                daysLeft <= 0 ? 'Final day' : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryRust),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_currentDay / _totalDays).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.expandButtonBg,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryRust),
            ),
          ),
        ],
      ),
    );
  }

  // Who the stay is with. Tap to open their profile.
  Widget _buildPartnerCard() {
    // The booking's avatar is the sitter's photo, so only show it to the homeowner.
    final avatarUrl = _isSitter ? null : widget.booking?.avatarUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openPartnerProfile,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.lightRustBg,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? const Icon(Icons.person, color: AppColors.primaryRust) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_otherName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkText)),
                    const SizedBox(height: 2),
                    Text(
                      _isSitter ? 'Homeowner · View profile' : 'Your sitter · View profile',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lightRustBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                tooltip: 'Message',
                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryRust, size: 20),
                onPressed: _openDirectChat,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.pets, _isSitter ? 'Pets to Care For' : 'Your Pets'),
          const SizedBox(height: 12),
          if (_pets.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.pets_outlined, size: 16, color: AppColors.primaryRust),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('No registered pets found for this homeowner.',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _pets.map(_buildPetChip).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPetChip(PetModel pet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pets_outlined, size: 14, color: AppColors.primaryRust),
          const SizedBox(width: 6),
          Text(
            '${pet.name} (${petTypeLabel(pet.species)}${pet.breed.isNotEmpty ? ' - ${pet.breed}' : ''})',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksCard() {
    final doneCount = _tasks.where((t) => t.done).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader(Icons.check_box_outlined, "Today's Tasks"),
              Text('$doneCount of ${_tasks.length} done',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
            ],
          ),
          if (_isSitter && _tasks.isNotEmpty) ...[
            const SizedBox(height: 4),
            const Text('Tap a task to tick it off.', style: TextStyle(fontSize: 11, color: Colors.black45)),
          ],
          const SizedBox(height: 8),
          if (_tasksError != null)
            Text(_tasksError!, style: const TextStyle(fontSize: 12, color: Colors.red))
          else if (_tasks.isEmpty)
            Text(
              _isSitter
                  ? "The homeowner hasn't added a checklist yet."
                  : 'Add a stay checklist on your profile and your sitter can tick it off each day.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            )
          else
            ..._tasks.map(_buildTaskTile),
        ],
      ),
    );
  }

  Widget _buildTaskTile(StayTask task) {
    final saving = _savingTaskIds.contains(task.id);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: saving ? null : () => _toggleTask(task),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: task.done ? AppColors.lightRustBg : AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryRust),
                      ),
                    )
                  : Icon(task.done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: task.done ? AppColors.primaryRust : Colors.black38, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: task.done ? TextDecoration.lineThrough : null)),
                    if (task.note != null)
                      Text(task.note!, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              ),
              if (task.done && task.checkedAt != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(_timeLabel(task.checkedAt!), style: const TextStyle(fontSize: 11, color: Colors.black45)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    final notes = widget.booking?.homeownerNotes ??
        widget.booking?.detailText2 ??
        'No special requirements specified.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.notes_outlined, _isSitter ? "Homeowner's Requirements" : 'Your Requirements'),
          const SizedBox(height: 10),
          Text(notes, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openDirectChat,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primaryRust),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryRust, size: 18),
                label: Text('Message ${_otherName.split(' ').first}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.primaryRust, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _completeStay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isBookingEnded ? Colors.green.shade700 : AppColors.primaryRust,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(_isBookingEnded ? Icons.check_circle_outline : Icons.flag_outlined,
                    color: Colors.white, size: 18),
                label: Text(_isBookingEnded ? 'End Booking' : 'Complete Stay',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
