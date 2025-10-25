import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/friend_model.dart';
import 'user_service.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream controllers to avoid multiple listeners
  // Legacy controllers removed in favor of direct Firestore streams

  String get _userId => _auth.currentUser?.uid ?? '';

  void dispose() {}

  // Get all friends
  Stream<List<Friend>> getFriends() {
    if (_userId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('friends')
        .where('userId', isEqualTo: _userId)
        .where('isAccepted', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Friend.fromFirestore).toList());
  }

  // Get pending friend requests
  Stream<List<Friend>> getPendingRequests() {
    if (_userId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('friends')
        .where('friendId', isEqualTo: _userId)
        .where('isAccepted', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Friend.fromFirestore).toList());
  }

  // Send friend request
  Future<void> sendFriendRequest(String friendEmail) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    final normalizedEmail = friendEmail.trim().toLowerCase();

    // Resolve friend user by email from users collection
    final userService = UserService();
    final me = await userService.getCurrentUserProfile();
    if (me == null) {
      // Try to ensure my profile exists (first-time login)
      await userService.ensureCurrentUserProfile();
    }

    final target = await userService.getUserByEmail(normalizedEmail);
    if (target == null) {
      throw Exception('User with this email was not found');
    }

    final friendId = target.uid;
    if (friendId == _userId) {
      throw Exception('You cannot send a friend request to yourself');
    }

    // Prevent duplicate requests (either direction)
    final existingA = await _firestore
        .collection('friends')
        .where('userId', isEqualTo: _userId)
        .where('friendId', isEqualTo: friendId)
        .limit(1)
        .get();

    final existingB = await _firestore
        .collection('friends')
        .where('userId', isEqualTo: friendId)
        .where('friendId', isEqualTo: _userId)
        .limit(1)
        .get();

    if (existingA.docs.isNotEmpty || existingB.docs.isNotEmpty) {
      throw Exception('You already have a pending or existing friendship');
    }

    final requesterEmail = (me?.email ?? _auth.currentUser?.email ?? '').toLowerCase();
    final requesterUsername = requesterEmail.split('@').first;

    // Create friend request document (requester -> receiver)
    await _firestore.collection('friends').add({
      'userId': _userId, // requester
      'friendId': friendId, // receiver
      'isAccepted': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      // denormalized for UI
      'friendEmail': target.email,
      'friendUsername': target.username,
      'requesterEmail': requesterEmail,
      'requesterUsername': requesterUsername,
    });
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String requesterId) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    // Find the friend request (requester -> me)
    final friendQuery = await _firestore
        .collection('friends')
        .where('friendId', isEqualTo: _userId)
        .where('userId', isEqualTo: requesterId)
        .limit(1)
        .get();

    if (friendQuery.docs.isEmpty) {
      throw Exception('Friend request not found');
    }

    final friendDoc = friendQuery.docs.first;
    final friendData = friendDoc.data();

    // Update the friend request to accepted
    await friendDoc.reference.update({'isAccepted': true});

    // Create reverse friendship (me -> requester)
    // Need both users' display info
    final userService = UserService();
    final me = await userService.getCurrentUserProfile() ??
        await userService.ensureCurrentUserProfile();
    final requester = await userService.getUserById(requesterId);

    final myViewFriendEmail = requester?.email ?? friendData['requesterEmail'] ?? '';
    final myViewFriendUsername = requester?.username ?? friendData['requesterUsername'] ?? '';

    await _firestore.collection('friends').add({
      'userId': _userId,
      'friendId': requesterId,
      'isAccepted': true,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      // denormalized friend (the person I see as friend)
      'friendEmail': myViewFriendEmail,
      'friendUsername': myViewFriendUsername,
      // denormalize me as requester for symmetry (not strictly needed here)
      'requesterEmail': me?.email ?? (_auth.currentUser?.email ?? ''),
      'requesterUsername': (me?.username ?? (_auth.currentUser?.email ?? '')).split('@').first,
    });
  }

  // Reject friend request
  Future<void> rejectFriendRequest(String requesterId) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');

    final friendQuery = await _firestore
        .collection('friends')
        .where('friendId', isEqualTo: _userId)
        .where('userId', isEqualTo: requesterId)
        .limit(1)
        .get();

    if (friendQuery.docs.isNotEmpty) {
      await friendQuery.docs.first.reference.delete();
    }
  }

  // Remove friend
  Future<void> removeFriend(String friendId) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    
    // Delete both directions of friendship
    final friendships = await _firestore
        .collection('friends')
        .where('userId', isEqualTo: _userId)
        .where('friendId', isEqualTo: friendId)
        .get();
    
    for (var doc in friendships.docs) {
      await doc.reference.delete();
    }
    
    final reverseFriendships = await _firestore
        .collection('friends')
        .where('userId', isEqualTo: friendId)
        .where('friendId', isEqualTo: _userId)
        .get();
    
    for (var doc in reverseFriendships.docs) {
      await doc.reference.delete();
    }
  }

  // Get user settings
  Stream<UserSettings> getUserSettings() {
    if (_userId.isEmpty) {
      return Stream.value(UserSettings(userId: '', showAllTasks: true, updatedAt: DateTime.now(), theme: 'white'));
    }
    return _firestore
        .collection('userSettings')
        .doc(_userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserSettings.fromFirestore(doc);
      } else {
        return UserSettings(userId: _userId, showAllTasks: true, updatedAt: DateTime.now(), theme: 'white');
      }
    });
  }

  // Update user settings
  Future<void> updateUserSettings(bool showAllTasks) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    
    await _firestore.collection('userSettings').doc(_userId).set({
      'showAllTasks': showAllTasks,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Update user theme only
  Future<void> updateUserTheme(String themeKey) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    await _firestore.collection('userSettings').doc(_userId).set({
      'theme': themeKey,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }
}
