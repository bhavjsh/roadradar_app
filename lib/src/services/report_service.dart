import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/report.dart';

class ReportService {
  Future<void> updateVotes(String id, {required bool up}) async {
    final doc = _col.doc(id);
    final auth = FirebaseAuth.instance;
    final uid = auth.currentUser?.uid;
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(doc);
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;
      final upvotes = (data['upvotes'] as int? ?? 0) + (up ? 1 : 0);
      final downvotes = (data['downvotes'] as int? ?? 0) + (up ? 0 : 1);
      tx.update(doc, {
        'upvotes': upvotes,
        'downvotes': downvotes,
      });
      // Reward: add points for voting
      if (uid != null) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
        tx.set(userDoc, {
          'points': FieldValue.increment(2),
        }, SetOptions(merge: true));
      }
    });
  }
  final _col = FirebaseFirestore.instance.collection('reports');
  final _storage = FirebaseStorage.instance;

  Stream<List<Report>> get stream => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Report.fromDoc(d)).toList());

  Future<void> add(Report r, {XFile? photo}) async {
    // make sure we have a user
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    final uid = auth.currentUser?.uid ?? 'anon';

    String? photoUrl;
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      final ext = _guessExt(bytes);
      final path = 'reports/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final ref = _storage.ref(path);
      await ref.putData(
        bytes,
        SettableMetadata(contentType: _contentTypeForExt(ext)),
      );
      photoUrl = await ref.getDownloadURL();
    }

    final data = r
        .copyWith(
          photoUrl: photoUrl ?? r.photoUrl,
          status: r.status ?? 'pending',
          userId: uid,
        )
        .toMap();

    data['createdAt'] ??= FieldValue.serverTimestamp();
    print('DEBUG: About to write report to Firestore');
    await _col.add(data);
    print('DEBUG: Firestore write completed');

    // Reward: add points for submitting report
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    await userDoc.set({
      'points': FieldValue.increment(10),
    }, SetOptions(merge: true));
  }

  Future<void> updateStatus(String id, String status) async {
    await _col.doc(id).update({'status': status});
  }
}
  // Temporary: satisfy older calls; we'll remove or implement later.
  Future<void> seedDemoIfEmpty() async {}


// helpers
String _guessExt(Uint8List bytes) {
  if (bytes.length >= 4) {
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'jpg'; // JPEG
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'png'; // PNG
    }
  }
  return 'jpg';
}

String _contentTypeForExt(String ext) {
  switch (ext) {
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
    default:
      return 'image/jpeg';
  }
}

final reportService = ReportService();
