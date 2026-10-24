import 'package:flutter/material.dart';

import '../../../models/task_model.dart';
import '../../../services/task_service.dart';
import '../../../theme/app_colors.dart';
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

class _ProfileTasksCardState extends State<ProfileTasksCard> {
  List<StayTask> _tasks = [];
  bool _loading = true;

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
    try {
      final tasks = await TaskService.fetchHomeownerTasks(id);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onMessage('Could not load your stay checklist.');
    }
  }

  Future<void> _showTaskDialog({StayTask? task}) async {
    final id = widget.homeownerId;
    if (id == null) return;

    final saved = await showDialog<bool>(
      context: context,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: profileCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Stay checklist',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkText),
                ),
              ),
              TextButton.icon(
                onPressed: widget.homeownerId == null ? null : () => _showTaskDialog(),
                icon: const Icon(Icons.add, size: 18, color: AppColors.primaryRust),
                label: const Text('Add task',
                    style: TextStyle(color: AppColors.primaryRust, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const Text(
            'Your sitter ticks these off each day of a stay, and you can see what was done.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryRust),
              ),
            )
          else if (_tasks.isEmpty)
            const Text(
              'No tasks yet. Add things like feeding times, walks or watering plants.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            )
          else
            ..._tasks.map(_buildTaskTile),
        ],
      ),
    );
  }

  Widget _buildTaskTile(StayTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.check_box_outlined, size: 18, color: AppColors.primaryRust),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (task.note != null && task.note!.isNotEmpty)
                    Text(task.note!, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.darkText),
            onPressed: () => _showTaskDialog(task: task),
          ),
          IconButton(
            tooltip: 'Delete',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
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

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isNew ? 'Add a task' : 'Edit task', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Task',
              hintText: 'e.g. Morning feed',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLength: 255,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Details (optional)',
              hintText: 'e.g. 1 cup of kibble each',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRust, foregroundColor: Colors.white),
          onPressed: _saving ? null : _save,
          child: Text(isNew ? 'Add task' : 'Save'),
        ),
      ],
    );
  }
}
