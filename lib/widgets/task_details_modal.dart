import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import '../models/friend_model.dart';
import '../services/friend_service.dart';

class TaskDetailsModal extends StatefulWidget {
  final Task task;
  final Function(Task) onUpdate;
  final VoidCallback onDelete;

  const TaskDetailsModal({
    super.key,
    required this.task,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<TaskDetailsModal> createState() => _TaskDetailsModalState();
}

class _TaskDetailsModalState extends State<TaskDetailsModal> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TaskPriority _selectedPriority;
  bool _hasChanges = false;
  List<String> _selectedFriends = [];
  List<Friend> _friends = [];
  bool _showAllTasks = true;
  final FriendService _friendService = FriendService();
  DateTime? _dueAt;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _selectedPriority = widget.task.priority;
    _selectedFriends = List.from(widget.task.sharedWith);
  _dueAt = widget.task.dueAt;
    
    _titleController.addListener(_checkForChanges);
    _descriptionController.addListener(_checkForChanges);
    
    _loadFriends();
    _loadUserSettings();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final hasChanges = _titleController.text.trim() != widget.task.title ||
        _descriptionController.text.trim() != (widget.task.description ?? '') ||
        _selectedPriority != widget.task.priority ||
    !_listEquals(_selectedFriends, widget.task.sharedWith) ||
    _dueAt != widget.task.dueAt;
    
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _onPriorityChanged(TaskPriority priority) {
    setState(() {
      _selectedPriority = priority;
    });
    _checkForChanges();
  }

  void _loadFriends() {
    _friendService.getFriends().listen((friends) {
      if (mounted) {
        setState(() {
          _friends = friends;
        });
      }
    });
  }

  void _loadUserSettings() {
    _friendService.getUserSettings().listen((settings) {
      if (mounted) {
        setState(() {
          _showAllTasks = settings.showAllTasks;
        });
      }
    });
  }

  void _toggleFriendSelection(String friendId) {
    setState(() {
      if (_selectedFriends.contains(friendId)) {
        _selectedFriends.remove(friendId);
      } else {
        _selectedFriends.add(friendId);
      }
    });
    _checkForChanges();
  }

  Future<void> _pickDueDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dueAt ?? now,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueAt ?? now.add(const Duration(hours: 1))),
    );
    setState(() {
      if (time == null) {
        _dueAt = DateTime(date.year, date.month, date.day);
      } else {
        _dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      }
    });
    _checkForChanges();
  }

  String _formatDue(DateTime due) {
    final now = DateTime.now();
    final dif = due.difference(now);
    if (dif.inDays >= 1) {
      return 'Due in ${dif.inDays}d';
    } else if (dif.inHours >= 1) {
      return 'Due in ${dif.inHours}h';
    } else if (dif.inMinutes > 0) {
      return 'Due in ${dif.inMinutes}m';
    }
    return 'Due now';
  }

  void _saveChanges() {
    if (_titleController.text.trim().isEmpty) return;
    
    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      priority: _selectedPriority,
      sharedWith: _selectedFriends,
      updatedAt: DateTime.now(),
      dueAt: _dueAt,
    );
    
    widget.onUpdate(updatedTask);
    Navigator.of(context).pop();
  }

  void _deleteTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Task',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this task? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close modal
              widget.onDelete();
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red[600]),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green[400]!;
      case TaskPriority.medium:
        return Colors.blue[400]!;
      case TaskPriority.high:
        return Colors.orange[400]!;
      case TaskPriority.urgent:
        return Colors.red[400]!;
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Low Priority';
      case TaskPriority.medium:
        return 'Medium Priority';
      case TaskPriority.high:
        return 'High Priority';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Task Details',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _deleteTask,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red[400],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field
                  Text(
                    'Title',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Enter task title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.deepPurple[400]!),
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  
                  const SizedBox(height: 20),

                  // Due date/time
                  Text(
                    'Due date (optional)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickDueDateTime,
                        icon: const Icon(Icons.event),
                        label: Text(
                          _dueAt == null ? 'Add due' : _formatDue(_dueAt!),
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                      if (_dueAt != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setState(() => _dueAt = null);
                            _checkForChanges();
                          },
                          icon: const Icon(Icons.close),
                          tooltip: 'Clear due',
                        ),
                      ],
                    ],
                  ),
                  
                  // Description Field
                  Text(
                    'Description',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter task description (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.deepPurple[400]!),
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 16),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Priority Selection
                  Text(
                    'Priority',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: TaskPriority.values.map((priority) {
                      final isSelected = _selectedPriority == priority;
                      final color = _getPriorityColor(priority);
                      
                      return GestureDetector(
                        onTap: () => _onPriorityChanged(priority),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? color : color.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            _getPriorityText(priority),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Friend Selection (only show if not show all tasks)
                  if (!_showAllTasks) ...[
                    Text(
                      'Share with Friends',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (_friends.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'No friends added yet. Add friends to share tasks!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _friends.map((friend) {
                          final isSelected = _selectedFriends.contains(friend.friendId);
                          
                          return GestureDetector(
                            onTap: () => _toggleFriendSelection(friend.friendId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? Colors.deepPurple[400] 
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected 
                                      ? Colors.deepPurple[400]! 
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: isSelected 
                                        ? Colors.white 
                                        : Colors.grey[400],
                                    child: Text(
                                      friend.friendUsername.substring(0, 1).toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected 
                                            ? Colors.deepPurple[400] 
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    friend.friendUsername,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected 
                                          ? Colors.white 
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    
                    const SizedBox(height: 20),
                  ],
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          
          // Save Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hasChanges ? _saveChanges : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Changes',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

