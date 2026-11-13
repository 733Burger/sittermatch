import 'package:flutter/material.dart';

import '../../../models/task_model.dart';
import '../../../services/task_service.dart';
import '../../../theme/app_colors.dart';
import 'profile_pets_section.dart';
import 'profile_styles.dart';

/// The homeowner's stay checklist. Sitters tick these tasks off each day of a booking.
class ProfileTasksCard extends StatefulWidget {
  const ProfileTasksCard({super.key, required this.homeownerId, required this.onMessage});

  /// Null until the profile screen knows who is signed in.
  final int? homeownerId;
  final void Function(String message) onMessage;

  @override
  State<ProfileTasksCard> createState() => _ProfileTasksCardState();
}

// Kept alive so it isn't thrown away when the profile list scrolls it out of view. The keyboard
// covering it while the task dialog is open used to do that, and the card that replaced it loaded
// the list before the new task had saved, so the first task didn't show.
class _ProfileTasksCardState extends State<ProfileTasksCard> with AutomaticKeepAliveClientMixin {
  List<StayTask> _tasks = [];
  bool _loading = true;
  // Only the newest load may update the list, so a slow older one can't overwrite it.
  int _loadId = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(ProfileTasksCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.homeownerId != widget.homeownerId) _load();
  }

  Future<void> _load() async {
    final id = widget.homeownerId;
    if (id == null) return;
    final loadId = ++_loadId;
    try {
      final tasks = await TaskService.fetchHomeownerTasks(id);
      if (!mounted || loadId != _loadId) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || loadId != _loadId) return;
      setState(() => _loading = false);
      widget.onMessage('Could not load your stay checklist.');
    }
  }

  Future<void> _showTaskDialog({StayTask? task}) async {
    final id = widget.homeownerId;
    if (id == null) return;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _TaskDialog(homeownerId: id, task: task),
    );
    if (saved != true) return;
    await _load();
    widget.onMessage(task == null ? 'Task added.' : 'Task updated.');
  }

  Future<void> _delete(StayTask task) async {
    final id = widget.homeownerId;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete "${task.title}"?'),
        content: const Text("It's removed from your checklist, along with the days sitters ticked it off."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await TaskService.deleteTask(id, task.id);
      await _load();
      widget.onMessage('Task deleted.');
    } catch (e) {
      widget.onMessage('Could not delete the task.');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // needed for AutomaticKeepAliveClientMixin
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          title: 'Stay checklist',
          actionLabel: 'Add task',
          onAction: widget.homeownerId == null ? null : () => _showTaskDialog(),
        ),
        const Text(
          'Your sitter ticks these off each day of a stay, and you can see what was done.',
          style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryRust),
              ),
            ),
          )
        else if (_tasks.isEmpty)
          const ProfileEmptyCard('No tasks yet. Add things like feeding times, walks or watering plants.')
        else
          Container(
            width: double.infinity,
            decoration: profileCardDecoration(),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  for (var i = 0; i < _tasks.length; i++) ...[
                    if (i > 0) Divider(height: 1, indent: 16, color: Colors.grey.shade200),
                    _buildTaskRow(_tasks[i]),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskRow(StayTask task) {
    final note = task.note?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 6, 16),
      child: Row(
        crossAxisAlignment: note.isEmpty ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkText),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(note, style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.35)),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined, size: 22, color: AppColors.primaryRust),
            onPressed: () => _showTaskDialog(task: task),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline, size: 22, color: profileDeleteRed),
            onPressed: () => _delete(task),
          ),
        ],
      ),
    );
  }
}

/// Adds or edits one task. Owns its text fields so they are only disposed once the dialog has fully
/// closed, not while its closing animation still shows them. Pops true when the task was saved.
class _TaskDialog extends StatefulWidget {
  const _TaskDialog({required this.homeownerId, this.task});

  final int homeownerId;
  final StayTask? task;

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late final TextEditingController _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
  late final TextEditingController _noteCtrl = TextEditingController(text: widget.task?.note ?? '');
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give the task a name');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final note = _noteCtrl.text.trim();
      final task = widget.task;
      if (task == null) {
        await TaskService.addTask(widget.homeownerId, title: title, note: note);
      } else {
        await TaskService.updateTask(widget.homeownerId, task.id, title: title, note: note);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.task == null;

    return ProfileDialogShell(
      children: [
        ProfileDialogHeader(
          icon: Icons.checklist_rounded,
          title: isNew ? 'Add a task' : 'Edit task',
          subtitle: 'Something your sitter should do each day of the stay.',
        ),
        const SizedBox(height: 20),
        const ProfileFieldLabel('Task'),
        TextField(
          controller: _titleCtrl,
          enabled: !_saving,
          autofocus: true,
          maxLength: 100,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.sentences,
          decoration: profileFieldDecoration(null, hint: 'e.g. Morning feed').copyWith(counterText: ''),
        ),
        const SizedBox(height: 16),
        const Text(
          'Details',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkText),
        ),
        const SizedBox(height: 2),
        const Text(
          'Optional. Amounts, times or where things are kept.',
          style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.35),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteCtrl,
          enabled: !_saving,
          minLines: 1,
          maxLines: 3,
          maxLength: 255,
          textCapitalization: TextCapitalization.sentences,
          decoration: profileFieldDecoration(null, hint: 'e.g. 1 cup of kibble each').copyWith(counterText: ''),
        ),
        if (_error != null) ...[const SizedBox(height: 14), ProfileDialogError(message: _error!)],
        const SizedBox(height: 18),
        ProfileSaveButton(
          label: isNew ? 'Add task' : 'Save changes',
          saving: _saving,
          onPressed: _saving ? null : _save,
        ),
        ProfileDialogCancelButton(enabled: !_saving),
      ],
    );
  }
}
