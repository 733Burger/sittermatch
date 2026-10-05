import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../theme/app_colors.dart';
import 'direct_chat_screen.dart';

/// One item on the sitter's task list.
class _Task {
  final String title;
  final String? note;
  final bool addedByOwner;
  bool done;
  String? doneAt; // e.g. '13:42'

  _Task({
    required this.title,
    this.note,
    this.addedByOwner = false,
    this.done = false,
    this.doneAt,
  });
}

class OngoingBookingScreen extends StatefulWidget {
  const OngoingBookingScreen({super.key});

  @override
  State<OngoingBookingScreen> createState() => _OngoingBookingScreenState();
}

class _OngoingBookingScreenState extends State<OngoingBookingScreen> {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  // Sample booking details. TODO: load the real booking from the backend.
  final String _stayTitle = 'Camps Bay Stay';
  final String _sitterName = 'Lerato Khumalo';
  final String _homeownerName = 'Joshua Stevens';

  // Sample dates are set relative to today so the screen always shows
  // "Day 3 of 7". Replace with the booking's real start and end dates.
  late final DateTime _start;
  late final DateTime _end;

  bool _loading = true;
  bool _isSitter = false;

  final List<_Task> _tasks = [
    _Task(
      title: 'Morning feed',
      note: 'Bella and Milo: 1 cup each. Cleo: half a sachet.',
      done: true,
      doneAt: '07:45',
    ),
    _Task(
      title: 'Midday walk',
      note: '30 minutes. Keep Milo on the lead near the road.',
    ),
    _Task(title: 'Evening feed'),
    _Task(
      title: 'Water the plants',
      note: 'Back garden only.',
      addedByOwner: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _start = today.subtract(const Duration(days: 2));
    _end = _start.add(const Duration(days: 6));
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AuthService().getUserRole();
    if (!mounted) return;
    setState(() {
      _isSitter = (role ?? '').toUpperCase() == 'SITTER';
      _loading = false;
    });
  }

  // ---------- Helpers ----------

  int get _totalDays => _end.difference(_start).inDays + 1;

  int get _currentDay {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return (today.difference(_start).inDays + 1).clamp(1, _totalDays);
  }

  String get _dateRange {
    final startText = '${_months[_start.month - 1]} ${_start.day}';
    final endText = _start.month == _end.month
        ? '${_end.day}'
        : '${_months[_end.month - 1]} ${_end.day}';
    return '$startText – $endText';
  }

  String _timeNow() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _toggleTask(_Task task) {
    if (!_isSitter) {
      _showSnack('Only the sitter can tick tasks off.');
      return;
    }
    setState(() {
      task.done = !task.done;
      task.doneAt = task.done ? _timeNow() : null;
    });
    // TODO: save the change to the backend.
  }

  void _removeTask(_Task task) {
    setState(() => _tasks.remove(task));
    _showSnack('Task removed.');
    // TODO: save the change to the backend.
  }

  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add a task', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Task *',
                  hintText: 'e.g. Water the plants',
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
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
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  setDialogState(() => error = 'Please enter a task');
                  return;
                }
                final note = noteCtrl.text.trim();
                setState(() {
                  _tasks.add(
                    _Task(
                      title: title,
                      note: note.isEmpty ? null : note,
                      addedByOwner: true,
                    ),
                  );
                });
                // TODO: save the new task to the backend.
                Navigator.pop(ctx);
                _showSnack('Task added for the sitter.');
              },
              child: const Text('Add task'),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
    );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ongoing Booking',
          style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRust))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildTasksCard(),
                const SizedBox(height: 16),
              ],
            ),
      bottomNavigationBar: _loading ? null : _buildMessageBar(),
    );
  }

  Widget _buildSummaryCard() {
    final daysLeft = _totalDays - _currentDay;
    final otherLabel = _isSitter ? 'Homeowner' : 'Sitter';
    final otherName = _isSitter ? _homeownerName : _sitterName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.lightRustBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: AppColors.primaryRust, size: 8),
                SizedBox(width: 4),
                Text(
                  'ONGOING',
                  style: TextStyle(
                    color: AppColors.primaryRust,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _stayTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: AppColors.primaryRust, size: 16),
              const SizedBox(width: 8),
              Text(
                _dateRange,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.primaryRust, size: 16),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$otherLabel: $otherName',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Day $_currentDay',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'of $_totalDays',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  daysLeft == 0
                      ? 'Last day'
                      : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} to go',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRust,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _currentDay / _totalDays,
              minHeight: 8,
              backgroundColor: AppColors.expandButtonBg,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryRust),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksCard() {
    final doneCount = _tasks.where((t) => t.done).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Today's tasks",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              Text(
                '$doneCount of ${_tasks.length} done',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isSitter
                ? 'Tick tasks off as you complete them.'
                : 'The sitter ticks these off. Add anything else you need done.',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (_tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No tasks yet.',
                  style: TextStyle(fontSize: 13, color: Colors.black45),
                ),
              ),
            )
          else
            ..._tasks.map(_buildTaskTile),
          if (!_isSitter) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAddTaskDialog,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: AppColors.primaryRust),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, color: AppColors.primaryRust, size: 18),
                label: const Text(
                  'Add a task for the sitter',
                  style: TextStyle(color: AppColors.primaryRust, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskTile(_Task task) {
    final canRemove = !_isSitter && task.addedByOwner && !task.done;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: () => _toggleTask(task),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: task.done ? AppColors.lightRustBg : AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                task.done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.done ? AppColors.primaryRust : Colors.black38,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: task.done ? Colors.black54 : AppColors.darkText,
                        decoration: task.done ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                    if (task.note != null && task.note!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          task.note!,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    if (task.done && task.doneAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Done at ${task.doneAt}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryRust,
                          ),
                        ),
                      ),
                    if (task.addedByOwner)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: task.done ? Colors.white : AppColors.lightRustBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'ADDED BY HOMEOWNER',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRust,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (canRemove)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 18, color: Colors.black45),
                  onPressed: () => _removeTask(task),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DirectChatScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRust,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
            label: Text(
              _isSitter ? 'Message Homeowner' : 'Message Sitter',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}