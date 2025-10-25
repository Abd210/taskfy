import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high, urgent }

class TaskCompletion {
  final String userId;
  final String username;
  final DateTime completedAt;

  TaskCompletion({
    required this.userId,
    required this.username,
    required this.completedAt,
  });

  factory TaskCompletion.fromMap(Map<String, dynamic> data) {
    return TaskCompletion(
      userId: data['userId']?.toString() ?? '',
      username: data['username']?.toString() ?? '',
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }
}

class Task {
  final String id;
  final String title;
  final String? description;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final List<String> sharedWith; // List of friend user IDs
  final List<TaskCompletion> completions; // Who completed the task

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.sharedWith = const [],
    this.completions = const [],
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString(),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString() == 'TaskPriority.${data['priority']}',
        orElse: () => TaskPriority.medium,
      ),
      isCompleted: data['isCompleted'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId']?.toString() ?? '',
      sharedWith: (data['sharedWith'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      completions: (data['completions'] as List<dynamic>?)?.map((e) => TaskCompletion.fromMap(e as Map<String, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'priority': priority.toString().split('.').last,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
      'sharedWith': sharedWith,
      'completions': completions.map((e) => e.toMap()).toList(),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    List<String>? sharedWith,
    List<TaskCompletion>? completions,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      sharedWith: sharedWith ?? this.sharedWith,
      completions: completions ?? this.completions,
    );
  }

  int get priorityValue {
    switch (priority) {
      case TaskPriority.low:
        return 1;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.high:
        return 3;
      case TaskPriority.urgent:
        return 4;
    }
  }
}

