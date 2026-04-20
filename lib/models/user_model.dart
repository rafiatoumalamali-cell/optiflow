import 'package:cloud_firestore/cloud_firestore.dart';



class UserModel {

  final String userId;

  final String phone;

  final String? email;

  final String fullName;

  final String role; // Business Owner, Manager, Driver, Admin

  final String? businessId;

  final DateTime createdAt;

  final DateTime? lastLogin;

  final bool isActive;

  final String? fcmToken;



  final String? sequentialId;

  final String? password; // Hashed password stored for reference as requested



  final bool mustChangePassword;

  final String? createdBy;

  final String verificationStatus; // pending, approved, rejected

  

  // Security Questions for Password Reset

  final String? securityQuestion;

  final String? securityAnswer;



  // Add getters for backward compatibility

  String get uid => userId;



  UserModel({

    required this.userId,

    required this.phone,

    this.email,

    required this.fullName,

    required this.role,

    this.businessId,

    required this.createdAt,

    this.lastLogin,

    this.isActive = true,

    this.fcmToken,

    this.sequentialId,

    this.password,

    this.mustChangePassword = false,

    this.createdBy,

    this.verificationStatus = 'pending',

    this.securityQuestion,

    this.securityAnswer,

  });



  factory UserModel.fromMap(Map<String, dynamic> map) {

    return UserModel(

      userId: map['user_id_uid'] ?? map['user_id'] ?? '', // Handle both UID and seq_id if needed

      phone: map['phone'] ?? '',

      email: map['email'],

      fullName: map['full_name'] ?? '',

      role: map['role'] ?? '',

      businessId: map['business_id'],

      createdAt: (map['created_at'] as Timestamp).toDate(),

      lastLogin: map['last_login'] != null ? (map['last_login'] as Timestamp).toDate() : null,

      isActive: map['is_active'] ?? true,

      fcmToken: map['fcm_token'],

      sequentialId: map['user_id'] is String && (map['user_id'] as String).startsWith('OPT-') ? map['user_id'] : null,

      password: map['password'],

      mustChangePassword: map['must_change_password'] ?? false,

      createdBy: map['created_by'],

      verificationStatus: map['verification_status'] ?? 'pending',

      securityQuestion: map['security_question'],

      securityAnswer: map['security_answer'],

    );

  }



  Map<String, dynamic> toMap() {

    return {

      'user_id': sequentialId ?? userId, // Requested format: OPT-001

      'user_id_uid': userId, // Keep reference to real UID

      'phone': phone,

      'email': email,

      'full_name': fullName,

      'role': role,

      'business_id': businessId,

      'created_at': Timestamp.fromDate(createdAt),

      'last_login': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,

      'is_active': isActive,

      'fcm_token': fcmToken,

      'password': password,

      'must_change_password': mustChangePassword,

      'created_by': createdBy,

      'verification_status': verificationStatus,

    };

  }

  /// Creates a copy of this UserModel with optional field updates
  UserModel copyWith({
    String? userId,
    String? phone,
    String? email,
    String? fullName,
    String? role,
    String? businessId,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
    String? fcmToken,
    String? sequentialId,
    String? password,
    bool? mustChangePassword,
    String? createdBy,
    String? verificationStatus,
    String? securityQuestion,
    String? securityAnswer,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      businessId: businessId ?? this.businessId,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      fcmToken: fcmToken ?? this.fcmToken,
      sequentialId: sequentialId ?? this.sequentialId,
      password: password ?? this.password,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      createdBy: createdBy ?? this.createdBy,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      securityAnswer: securityAnswer ?? this.securityAnswer,
    );
  }

}

