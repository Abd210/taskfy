import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  Future<UserProfile?> getCurrentUserProfile() async {
    if (_uid.isEmpty) return null;
    final doc = await _firestore.collection('users').doc(_uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
    
  }

  Future<UserProfile?> ensureCurrentUserProfile({String? username, String? email}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final docRef = _firestore.collection('users').doc(user.uid);
    final now = DateTime.now();

    final existing = await docRef.get();
    String finalEmail = (email ?? user.email ?? '').toLowerCase();
    String finalUsername = (username ?? finalEmail.split('@').first).trim();

    if (!existing.exists) {
      final profile = UserProfile(
        uid: user.uid,
        email: finalEmail,
        username: finalUsername.isEmpty ? (user.email?.split('@').first ?? 'user') : finalUsername,
        createdAt: now,
        updatedAt: now,
      );
      await docRef.set(profile.toFirestore());
      return profile;
    } else {
      // Optionally update missing fields
      await docRef.set({
        if ((existing.data() ?? const {})['email'] == null || (existing.data()!['email'] as String).isEmpty) 'email': finalEmail,
        if ((existing.data() ?? const {})['username'] == null || (existing.data()!['username'] as String).isEmpty) 'username': finalUsername,
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true));
      final refreshed = await docRef.get();
      return UserProfile.fromFirestore(refreshed);
    }
  }

  Future<UserProfile?> getUserByEmail(String email) async {
    final q = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return UserProfile.fromFirestore(q.docs.first);
  }

  Future<UserProfile?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromFirestore(doc);
  }

  Stream<QuerySnapshot> streamAllUsers() {
    return _firestore.collection('users').snapshots();
  }

  Future<void> updateUsername(String uid, String newUsername) async {
    await _firestore.collection('users').doc(uid).set({
      'username': newUsername,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  Stream<UserProfile?> streamCurrentUserProfile() {
    if (_uid.isEmpty) return Stream.value(null);
    return _firestore.collection('users').doc(_uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromFirestore(doc);
    });
  }
}
