import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:banking_app/models/user.dart' as app_user;
import 'package:banking_app/utils/firebase_firestore_service.dart';
import 'dart:math';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      // Create user with email and password
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create user profile in Firestore
      if (userCredential.user != null) {
        final app_user.User newUser = app_user.User(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          password: '', // Don't store actual password in Firestore
          phoneNumber: phoneNumber,
          profileImageUrl: '',
        );

        // Save user to Firestore
        await _firestoreService.createUser(newUser);

        // Create default accounts for the new user
        await _firestoreService.createDefaultAccounts(userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
        }

        if (photoURL != null) {
          await user.updatePhotoURL(photoURL);
        }

        // Update Firestore user document
        final userRef = _firestore.collection('users').doc(user.uid);
        final updateData = <String, dynamic>{};

        if (displayName != null) {
          updateData['name'] = displayName;
        }

        if (photoURL != null) {
          updateData['profileImageUrl'] = photoURL;
        }

        if (phoneNumber != null) {
          updateData['phoneNumber'] = phoneNumber;
        }

        if (updateData.isNotEmpty) {
          await userRef.update(updateData);
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Two-factor authentication - Generate OTP
  String generateOTP() {
    final Random random = Random();
    // Generate a 6-digit OTP
    final int otp = random.nextInt(900000) + 100000; // 100000-999999
    return otp.toString();
  }

  // Store the OTP in Firestore with expiration
  Future<void> storeOTP(String userId, String otp) async {
    try {
      final expiryTime = DateTime.now().add(const Duration(minutes: 5));

      await _firestore.collection('otps').doc(userId).set({
        'otp': otp,
        'expiresAt': expiryTime.millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error storing OTP: $e');
      throw Exception('Failed to store OTP');
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String userId, String enteredOTP) async {
    try {
      final otpDoc = await _firestore.collection('otps').doc(userId).get();

      if (!otpDoc.exists) {
        return false;
      }

      final data = otpDoc.data()!;
      final storedOTP = data['otp'];
      final expiresAt = data['expiresAt'];

      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if OTP is valid and not expired
      if (storedOTP == enteredOTP && expiresAt > now) {
        // Delete the OTP after verification
        await _firestore.collection('otps').doc(userId).delete();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return false;
    }
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    debugPrint('Auth Error Code: ${e.code}');

    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email.');
      case 'wrong-password':
        return Exception('Incorrect password.');
      case 'email-already-in-use':
        return Exception('The email address is already in use.');
      case 'weak-password':
        return Exception('The password is too weak.');
      case 'invalid-email':
        return Exception('The email address is invalid.');
      case 'requires-recent-login':
        return Exception('Please sign in again to complete this action.');
      default:
        return Exception('Authentication failed: ${e.message}');
    }
  }
}
