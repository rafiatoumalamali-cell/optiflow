import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String userId;
  final String type; // Bug, Feature, Billing, etc.
  final String description;
  final String status; // Pending, In Review, Resolved
  final DateTime createdAt;
  final String? resolvedBy;

  ReportModel({
    required this.reportId,
    required this.userId,
    required this.type,
    required this.description,
    required this.status,
    required this.createdAt,
    this.resolvedBy,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    final createdAtRaw = map['created_at'];
    final DateTime createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : DateTime.tryParse(createdAtRaw?.toString() ?? '') ?? DateTime.now();

    return ReportModel(
      reportId: map['report_id'] ?? '',
      userId: map['user_id'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'Pending',
      createdAt: createdAt,
      resolvedBy: map['resolved_by'],
    );
  }

  factory ReportModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReportModel.fromMap({...data, 'report_id': doc.id});
  }

  Map<String, dynamic> toMap() {
    return {
      'report_id': reportId,
      'user_id': userId,
      'type': type,
      'description': description,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'resolved_by': resolvedBy,
    };
  }
}
