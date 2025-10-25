import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/friend_model.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream controllers to avoid multiple listeners
  StreamController<List<Friend>>? _friendsController;
  StreamController<List<Friend>>? _requestsController;
  StreamController<UserSettings>? _settingsController;

  String get _userId => _auth.currentUser?.uid ?? '';

  void dispose() {
    _friendsController?.close();
    _requestsController?.close();
    _settingsController?.close();
  }

  // Get all friends
  Stream<List<Friend>> getFriends() {
    if (_userId.isEmpty) return Stream.value([]);
    
    _friendsController?.close();
    _friendsController = StreamController<List<Friend>>.broadcast();
    
    _firestore
        .collection('friends')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .listen(
      (snapshot) {
        final friends = snapshot.docs
            .map((doc) => Friend.fromFirestore(doc))
            .where((friend) => friend.isAccepted)
            .toList();
        _friendsController?.add(friends);
      },
      onError: (error) {
        print('Error loading friends: $error');
        _friendsController?.add([]);
      },
    );
    
    return _friendsController!.stream;
  }

  // Get pending friend requests
  Stream<List<Friend>> getPendingRequests() {
    if (_userId.isEmpty) return Stream.value([]);
    
    _requestsController?.close();
    _requestsController = StreamController<List<Friend>>.broadcast();
    
    // Simplified query - get all friends where current user is the friendId and not accepted
    _firestore
        .collection('friends')
        .where('friendId', isEqualTo: _userId)
        .snapshots()
        .listen(
      (snapshot) {
        final requests = snapshot.docs
            .map((doc) => Friend.fromFirestore(doc))
            .where((friend) => !friend.isAccepted)
            .toList();
        _requestsController?.add(requests);
      },
      onError: (error) {
        print('Error loading requests: $error');
        _requestsController?.add([]);
      },
    );
    
    return _requestsController!.stream;
  }

  // Send friend request
  Future<void> sendFriendRequest(String friendEmail) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    
    final friendUsername = friendEmail.split('@').first;
    final friendId = 'temp_${friendEmail.hashCode}';
    
    // Create friend request directly without checking (for demo purposes)
    await _firestore.collection('friends').add({
      'userId': _userId,
      'friendId': friendId,
      'friendEmail': friendEmail,
      'friendUsername': friendUsername,
      'isAccepted': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String friendId) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    
    // Find the friend request
    final friendQuery = await _firestore
        .collection('friends')
        .where('friendId', isEqualTo: _userId)
        .where('userId', isEqualTo: friendId)
        .limit(1)
        .get();
    
    if (friendQuery.docs.isEmpty) {
      throw Exception('Friend request not found');
    }
    
    final friendDoc = friendQuery.docs.first;
    final friendData = friendDoc.data();
    
    // Update the friend request to accepted
    await friendDoc.reference.update({'isAccepted': true});
    
    // Create reverse friendship
    await _firestore.collection('friends').add({
      'userId': _userId,
      'friendId': friendId,
      'friendEmail': friendData['friendEmail'],
      'friendUsername': friendData['friendUsername'],
      'isAccepted': true,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Reject friend request
  Future<void> rejectFriendRequest(String friendId) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    
    final friendQuery = await _firestore
        .collection('friends')
        .where('friendId', isEqualTo: _userId)
        .where('userId', isEqualTo: friendId)
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
    if (_userId.isEmpty) return Stream.value(UserSettings(userId: '', showAllTasks: true, updatedAt: DateTime.now()));
    
    _settingsController?.close();
    _settingsController = StreamController<UserSettings>.broadcast();
    
    _firestore
        .collection('userSettings')
        .doc(_userId)
        .snapshots()
        .listen(
      (doc) {
        if (doc.exists && doc.data() != null) {
          _settingsController?.add(UserSettings.fromFirestore(doc));
        } else {
          _settingsController?.add(UserSettings(userId: _userId, showAllTasks: true, updatedAt: DateTime.now()));
        }
      },
      onError: (error) {
        _settingsController?.add(UserSettings(userId: _userId, showAllTasks: true, updatedAt: DateTime.now()));
      },
    );
    
    return _settingsController!.stream;
  }

  // Update user settings
  Future<void> updateUserSettings(bool showAllTasks) async {
    if (_userId.isEmpty) throw Exception('User not authenticated');
    
    await _firestore.collection('userSettings').doc(_userId).set({
      'showAllTasks': showAllTasks,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
