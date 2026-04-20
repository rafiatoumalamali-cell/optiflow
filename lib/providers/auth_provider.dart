import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/firebase/firebase_auth_service.dart';
import '../utils/logger.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _verificationId;
  String? _phoneNumber;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoggedIn => _currentUser != null;
  String get userRole => _currentUser?.role ?? '';
  String? get phoneNumber => _phoneNumber;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      await fetchUserData(firebaseUser.uid);
    }
    notifyListeners();
  }

  Future<bool> checkIfUserExists(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } on FirebaseException catch (e, stack) {
      Logger.error('Firebase error checking user existence', name: 'AuthProvider', error: e, stackTrace: stack);
      return false;
    } catch (e, stack) {
      Logger.error('Error checking user existence', name: 'AuthProvider', error: e, stackTrace: stack);
      return false;
    }
  }

  Future<void> fetchUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    } on FirebaseException catch (e, stack) {
      Logger.error('Firebase error fetching user data', name: 'AuthProvider', error: e, stackTrace: stack);
    } catch (e, stack) {
      Logger.error('Error fetching user data', name: 'AuthProvider', error: e, stackTrace: stack);
    }
  }

  Future<void> updateUserProfile({
    required String fullName,
    required String email,
    required String role,
    required String businessId,
  }) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final updatedUser = UserModel(
      userId: uid,
      phone: user.phoneNumber ?? _phoneNumber ?? '',
      fullName: fullName,
      email: email,
      role: role,
      businessId: businessId,
      createdAt: DateTime.now(),
    );

    try {
      await _firestore.collection('users').doc(uid).set(updatedUser.toMap(), SetOptions(merge: true));
      _currentUser = updatedUser;
      notifyListeners();
    } on FirebaseException catch (e, stack) {
      Logger.error('Firebase error updating profile', name: 'AuthProvider', error: e, stackTrace: stack);
      rethrow;
    } catch (e, stack) {
      Logger.error('Error updating profile', name: 'AuthProvider', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> signInWithPhone(String phoneNumber, Function(String) onCodeSent, Function(String) onError) async {
    _isLoading = true;
    _phoneNumber = phoneNumber;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signInWithPhone(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _isLoading = false;
          notifyListeners();
        },
        verificationFailed: (FirebaseAuthException e) {
          _isLoading = false;
          _errorMessage = e.message;
          notifyListeners();
          onError(e.message ?? 'verification_failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      onError(e.message ?? 'verification_failed');
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'unexpected_error';
      notifyListeners();
      onError(_errorMessage!);
    }
  }

  Future<void> verifyOtp(String smsCode) async {
    if (_verificationId == null) {
      throw Exception('verification_id_missing');
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.verifyOtp(_verificationId!, smsCode);
      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unexpected error: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Unexpected error: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    try {
      // Reauthenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: _currentUser?.email ?? '',
        password: currentPassword,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
      Logger.info('Password changed successfully for user: ${user.uid}');
    } on FirebaseAuthException catch (e) {
      Logger.error('Firebase error changing password', name: 'AuthProvider', error: e);
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect');
      } else if (e.code == 'weak-password') {
        throw Exception('New password is too weak');
      } else {
        throw Exception('Failed to change password: ${e.message}');
      }
    } catch (e, stack) {
      Logger.error('Error changing password', name: 'AuthProvider', error: e, stackTrace: stack);
      throw Exception('Failed to change password');
    }
  }

  Future<void> updateUserSecurityQuestions({
    required String userId,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'security_question': securityQuestion,
        'security_answer': securityAnswer.toLowerCase(), // Store in lowercase for consistent comparison
        'security_questions_set_at': FieldValue.serverTimestamp(),
      });
      
      Logger.info('Security questions updated for user: $userId');
    } catch (e, stack) {
      Logger.error('Error updating security questions', name: 'AuthProvider', error: e, stackTrace: stack);
      throw Exception('Failed to update security questions');
    }
  }
}
