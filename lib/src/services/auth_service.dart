import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _col = FirebaseFirestore.instance.collection('users');

  Stream<AppUser?> get userStream => _auth.authStateChanges().map((u) => u == null ? null : AppUser(uid: u.uid, email: u.email, displayName: u.displayName));

  Future<AppUser?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return _saveUser(cred.user);
  }

  Future<AppUser?> signUp(String email, String password, {String? displayName}) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(displayName);
    return _saveUser(cred.user);
  }

  Future<void> signOut() async => _auth.signOut();

  Future<AppUser?> _saveUser(User? u) async {
    if (u == null) return null;
    final doc = _col.doc(u.uid);
    await doc.set({
      'uid': u.uid,
      'email': u.email,
      'displayName': u.displayName,
      'points': 0,
      'rank': 0,
    }, SetOptions(merge: true));
    final snap = await doc.get();
    return AppUser.fromDoc(snap);
  }

  Future<AppUser?> getUser(String uid) async {
    final snap = await _col.doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromDoc(snap);
  }
}

final authService = AuthService();
