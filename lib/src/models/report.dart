import 'package:cloud_firestore/cloud_firestore.dart';

enum HazardType { pothole, waterLogging, accident, obstruction, other }

String hazardTypeToString(HazardType t) => t.name;

HazardType hazardTypeFromString(String s) {
  return HazardType.values.firstWhere(
    (e) => e.name == s,
    orElse: () => HazardType.other,
  );
}

class Report {
  final String? id;
  final double lat;
  final double lng;
  final HazardType type;
  final int severity; // 1..5
  final String description;
  final String? photoUrl;
  final DateTime? createdAt;
  final String? status; // pending | reviewed | resolved
  final String? userId;

  Report({
    this.id,
    required this.lat,
    required this.lng,
    required this.type,
    required this.severity,
    required this.description,
    this.photoUrl,
    this.createdAt,
    this.status,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'type': hazardTypeToString(type),
      'severity': severity,
      'description': description,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (status != null) 'status': status,
      if (userId != null) 'userId': userId,
    };
  }

  factory Report.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return Report(
      id: d.id,
      lat: (m['lat'] as num?)?.toDouble() ?? 0,
      lng: (m['lng'] as num?)?.toDouble() ?? 0,
      type: hazardTypeFromString(m['type']?.toString() ?? 'other'),
      severity: (m['severity'] as num?)?.toInt() ?? 1,
      description: (m['description'] as String?) ?? '',
      photoUrl: m['photoUrl'] as String?,
      createdAt: (m['createdAt'] is Timestamp)
          ? (m['createdAt'] as Timestamp).toDate()
          : null,
      status: (m['status'] as String?) ?? 'pending',
      userId: m['userId'] as String?,
    );
  }

  Report copyWith({
    String? id,
    double? lat,
    double? lng,
    HazardType? type,
    int? severity,
    String? description,
    String? photoUrl,
    DateTime? createdAt,
    String? status,
    String? userId,
  }) {
    return Report(
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      userId: userId ?? this.userId,
    );
  }
}
