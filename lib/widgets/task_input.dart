import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ui/widgets/app_card.dart';
import '../services/task_service.dart';
import '../services/friend_service.dart';
import '../models/friend_model.dart';

class TaskInput extends StatefulWidget {
  final VoidCallback onTaskAdded;
  final String? themeKey;

  const TaskInput({
    super.key,
    required this.onTaskAdded,
    this.themeKey,
  });

  @override
  State<TaskInput> createState() => _TaskInputState();
}

class _TaskInputState extends State<TaskInput> {
  final TextEditingController _controller = TextEditingController();
  final TaskService _taskService = TaskService();
  final FriendService _friendService = FriendService();
  bool _isLoading = false;
  List<Friend> _friends = [];
  bool _showAllTasks = true;
  List<String> _selectedFriends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadUserSettings();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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


  Future<void> _addTask() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      // Determine recipients: if show all, share with all friends; else, selected only
      final recipients = _showAllTasks
          ? _friends.map((f) => f.friendId).toList()
          : List<String>.from(_selectedFriends);

      await _taskService.addTask(
        text,
        sharedWith: recipients,
      );
      _controller.clear();
      _selectedFriends.clear();
      widget.onTaskAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add task: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      themeKey: widget.themeKey,
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // Friend Selection (only show if not show all tasks and has friends)
          if (!_showAllTasks && _friends.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share with friends:',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _friends.map((friend) {
                      final isSelected = _selectedFriends.contains(friend.friendId);
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedFriends.remove(friend.friendId);
                            } else {
                              _selectedFriends.add(friend.friendId);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.deepPurple[400] : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.deepPurple[400]! : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            friend.friendUsername,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Input Field with integrated send
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Add a new task...',
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        tooltip: 'Send',
                        onPressed: _controller.text.trim().isNotEmpty ? _addTask : null,
                        icon: const Icon(Icons.send_rounded),
                        color: Theme.of(context).colorScheme.primary,
                      ),
              ),
            ),
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[800]),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _addTask(),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
