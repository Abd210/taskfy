import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/task_service.dart';
import '../services/friend_service.dart';
import '../models/friend_model.dart';

class TaskInput extends StatefulWidget {
  final VoidCallback onTaskAdded;

  const TaskInput({
    super.key,
    required this.onTaskAdded,
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
    return Container(
      padding: const EdgeInsets.all(16),
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
          
          // Input Row
          Row(
            children: [
              // Input Field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Add a new task...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addTask(),
                    onChanged: (value) {
                      setState(() {}); // Rebuild to update send button state
                    },
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Send Button
              GestureDetector(
                onTap: _controller.text.trim().isNotEmpty && !_isLoading ? _addTask : null,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _controller.text.trim().isNotEmpty && !_isLoading
                        ? Colors.deepPurple[400]
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                    boxShadow: _controller.text.trim().isNotEmpty && !_isLoading
                        ? [
                            BoxShadow(
                              color: Colors.deepPurple[400]!.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: _controller.text.trim().isNotEmpty && !_isLoading
                              ? Colors.white
                              : Colors.grey[500],
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
