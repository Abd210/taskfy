import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
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
    
    // Combine: my own tasks OR tasks shared with me
    final controller = StreamController<List<Task>>.broadcast();
    List<Task> ownTasks = [];
    List<Task> sharedTasks = [];

    void emitMerged() {
      try {
        final map = <String, Task>{};
        for (final t in ownTasks) {
          map[t.id] = t;
        }
        for (final t in sharedTasks) {
          map[t.id] = t;
        }
        final tasks = map.values.toList();
        tasks.sort((a, b) {
          final p = b.priorityValue.compareTo(a.priorityValue);
          if (p != 0) return p;
          return b.createdAt.compareTo(a.createdAt);
        });
        controller.add(tasks);
      } catch (_) {
        controller.add(<Task>[]);
      }
    }

    final subA = _firestore
        .collection('tasks')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .listen((snapshot) {
      ownTasks = snapshot.docs.map((doc) {
        try {
          return Task.fromFirestore(doc);
        } catch (_) {
          return null;
        }
      }).whereType<Task>().toList();
      emitMerged();
    }, onError: (_) {
      ownTasks = [];
      emitMerged();
    });

    final subB = _firestore
        .collection('tasks')
        .where('sharedWith', arrayContains: _userId)
        .snapshots()
        .listen((snapshot) {
      sharedTasks = snapshot.docs.map((doc) {
        try {
          return Task.fromFirestore(doc);
        } catch (_) {
          return null;
        }
      }).whereType<Task>().toList();
      emitMerged();
    }, onError: (_) {
      sharedTasks = [];
      emitMerged();
    });

    controller.onCancel = () {
      subA.cancel();
      subB.cancel();
    };

    return controller.stream;
  }

  // Admin: get all tasks
  Stream<List<Task>> getAllTasks() {
    return _firestore.collection('tasks').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Task.fromFirestore(doc);
        } catch (_) {
          return null;
        }
      }).whereType<Task>().toList()
        ..sort((a, b) {
          final p = b.priorityValue.compareTo(a.priorityValue);
          if (p != 0) return p;
          return b.createdAt.compareTo(a.createdAt);
        });
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
  Future<void> toggleTaskCompletion(String taskId, bool markCompleted) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    
    final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    if (!taskDoc.exists) throw Exception('Task not found');
    
    final task = Task.fromFirestore(taskDoc);
    final currentUser = FirebaseAuth.instance.currentUser;
    final username = currentUser?.email?.split('@').first ?? 'User';
    
    List<TaskCompletion> completions = List.from(task.completions);
    
    if (markCompleted) {
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

