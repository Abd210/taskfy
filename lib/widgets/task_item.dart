import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final Function(bool) onToggle;
  final VoidCallback onTap;

  const TaskItem({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
  });

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
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(task.priority);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final mineCompleted = uid != null && task.completions.any((c) => c.userId == uid);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mineCompleted ? Colors.grey[300]! : priorityColor.withOpacity(0.3),
          width: mineCompleted ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => onToggle(!mineCompleted),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: mineCompleted ? priorityColor : Colors.grey[400]!,
                        width: 2,
                      ),
                      color: mineCompleted ? priorityColor : Colors.transparent,
                    ),
                    child: mineCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Task Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Title
                      Text(
                        task.title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: mineCompleted ? Colors.grey[500] : Colors.grey[800],
                          decoration: mineCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      
                      // Task Description
                      if (task.description != null && task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: mineCompleted ? Colors.grey[400] : Colors.grey[600],
                            decoration: mineCompleted ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      
                      const SizedBox(height: 8),
                      
                      // Priority and Time
                      Row(
                        children: [
                          // Priority Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: priorityColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getPriorityText(task.priority),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: priorityColor,
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                          // Time
                          Text(
                            _formatTime(task.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          
                          // Completion Avatars
                          if (task.completions.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Row(
                              children: task.completions.take(3).map((completion) {
                                return Container(
                                  margin: const EdgeInsets.only(left: 2),
                                  child: CircleAvatar(
                                    radius: 8,
                                    backgroundColor: Colors.deepPurple[400],
                                    child: Text(
                                      completion.username.substring(0, 1).toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (task.completions.length > 3)
                              Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '+${task.completions.length - 3}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Menu Button
                IconButton(
                  onPressed: onTap,
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

