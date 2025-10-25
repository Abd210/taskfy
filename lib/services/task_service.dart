import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Get tasks stream
  Stream<List<Task>> getTasks() {
    if (_userId.isEmpty) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('tasks')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      try {
        final tasks = snapshot.docs.map((doc) {
          try {
            return Task.fromFirestore(doc);
          } catch (e) {
            // Error parsing task, skip it
            return null;
          }
        }).where((task) => task != null).cast<Task>().toList();
        
        // Sort tasks by priority (urgent first) and then by creation date
        tasks.sort((a, b) {
          // First sort by priority (higher priority first)
          int priorityComparison = b.priorityValue.compareTo(a.priorityValue);
          if (priorityComparison != 0) return priorityComparison;
          
          // Then sort by creation date (newer first)
          return b.createdAt.compareTo(a.createdAt);
        });
        
        return tasks;
      } catch (e) {
        // Error processing tasks
        return <Task>[];
      }
    });
  }

  // Add new task
  Future<void> addTask(String title, {String? description, TaskPriority priority = TaskPriority.medium, List<String> sharedWith = const []}) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    final now = DateTime.now();
    final task = Task(
      id: '', // Will be set by Firestore
      title: title,
      description: description,
      priority: priority,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
      userId: _userId,
      sharedWith: sharedWith,
    );

    await _firestore.collection('tasks').add(task.toFirestore());
  }

  // Update task
  Future<void> updateTask(Task task) async {
    await _firestore.collection('tasks').doc(task.id).update(task.toFirestore());
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    
    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    if (!taskDoc.exists) throw Exception('Task not found');
    
    final task = Task.fromFirestore(taskDoc);
    final currentUser = FirebaseAuth.instance.currentUser;
    final username = currentUser?.email?.split('@').first ?? 'User';
    
    List<TaskCompletion> completions = List.from(task.completions);
    
    if (isCompleted) {
      // Add completion if not already completed by this user
      if (!completions.any((c) => c.userId == _userId)) {
        completions.add(TaskCompletion(
          userId: _userId,
          username: username,
          completedAt: DateTime.now(),
        ));
      }
    } else {
      // Remove completion for this user
      completions.removeWhere((c) => c.userId == _userId);
    }
    
    await _firestore.collection('tasks').doc(taskId).update({
      'isCompleted': isCompleted,
      'completions': completions.map((c) => c.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Update task priority
  Future<void> updateTaskPriority(String taskId, TaskPriority priority) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'priority': priority.toString().split('.').last,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Update task details
  Future<void> updateTaskDetails(String taskId, String title, String? description, TaskPriority priority) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'title': title,
      'description': description,
      'priority': priority.toString().split('.').last,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }
}

