import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String id;
  final String userId;
  final String friendId;
  final String friendEmail;
  final String friendUsername;
  final String requesterEmail;
  final String requesterUsername;
  final bool isAccepted;
  final DateTime createdAt;

  Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.friendEmail,
    required this.friendUsername,
    required this.requesterEmail,
    required this.requesterUsername,
    required this.isAccepted,
    required this.createdAt,
  });

  factory Friend.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Friend(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      friendId: data['friendId']?.toString() ?? '',
      friendEmail: data['friendEmail']?.toString() ?? '',
      friendUsername: data['friendUsername']?.toString() ?? '',
      requesterEmail: data['requesterEmail']?.toString() ?? '',
      requesterUsername: data['requesterUsername']?.toString() ?? '',
      isAccepted: data['isAccepted'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'friendId': friendId,
      'friendEmail': friendEmail,
      'friendUsername': friendUsername,
      'requesterEmail': requesterEmail,
      'requesterUsername': requesterUsername,
      'isAccepted': isAccepted,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class UserSettings {
  final String userId;
  final bool showAllTasks;
  final DateTime updatedAt;
  final String theme; // 'green' | 'pink' | 'black' | 'ocean' | 'purple'

  UserSettings({
    required this.userId,
    required this.showAllTasks,
    required this.updatedAt,
    required this.theme,
  });

  factory UserSettings.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserSettings(
      userId: doc.id,
      showAllTasks: data['showAllTasks'] == true,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      theme: (data['theme']?.toString() ?? 'white'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'showAllTasks': showAllTasks,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'theme': theme,
    };
  }
}
