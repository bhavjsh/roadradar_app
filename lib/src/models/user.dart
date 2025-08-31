import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final int points;
  final int rank;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.points = 0,
    this.rank = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'points': points,
      'rank': rank,
    };
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return AppUser(
      uid: m['uid'] ?? d.id,
      email: m['email'],
      displayName: m['displayName'],
      points: (m['points'] as int?) ?? 0,
      rank: (m['rank'] as int?) ?? 0,
    );
  }
}
