import 'package:flutter/foundation.dart';
import 'package:banking_app/models/user.dart';
import 'package:banking_app/models/account.dart';
import 'package:banking_app/utils/firebase_auth_service.dart';
import 'package:banking_app/utils/firebase_firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:banking_app/models/transaction.dart' as app_transaction;
import 'dart:async';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  List<Account> _userAccounts = [];
  bool _initialized = false;
  List<StreamSubscription> _accountSubscriptions = [];
  List<app_transaction.Transaction> _recentTransactions = [];

  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? get currentUser => _currentUser;
  List<Account> get userAccounts => _userAccounts;
  bool get isInitialized => _initialized;
  List<app_transaction.Transaction> get recentTransactions =>
      _recentTransactions;

  // Initialize provider
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Check if user is already logged in
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn) {
        // Get the stored user ID
        final userId = prefs.getString('current_user_id');

        if (userId != null) {
          // Try to auto-login with stored user ID
          final firebaseUser = _authService.currentUser;

          if (firebaseUser != null) {
            // Load user details from Firestore
            final appUser = await _firestoreService.getUser(firebaseUser.uid);

            if (appUser != null) {
              _currentUser = appUser;
              await loadUserAccounts();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing user provider: $e');
    }

    _initialized = true;
    notifyListeners();
  }

  // User Registration
  Future<bool> registerUser({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
  }) async {
    try {
      final userCredential = await _authService.signUpWithEmail(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );

      if (userCredential.user != null) {
        // Fetch the user from Firestore
        final appUser = await _firestoreService.getUser(
          userCredential.user!.uid,
        );
        if (appUser != null) {
          _currentUser = appUser;

          // Load the newly created accounts
          await loadUserAccounts();

          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error registering user: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // User Login
  Future<bool> login(String email, String password) async {
    try {
      final userCredential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Fetch the user from Firestore
        final appUser = await _firestoreService.getUser(
          userCredential.user!.uid,
        );
        if (appUser != null) {
          _currentUser = appUser;

          // Save login state and user ID
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('current_user_id', appUser.id);

          // Load user accounts
          await loadUserAccounts();

          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error logging in: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // User Logout
  Future<void> logout() async {
    try {
      await _authService.signOut();

      // Clear login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('current_user_id');

      _currentUser = null;
      _userAccounts = [];

      notifyListeners();
    } catch (e) {
      debugPrint('Error logging out: $e');
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Start listening to real-time account updates
  void startAccountsListener() {
    // Cancel any existing subscriptions
    for (var subscription in _accountSubscriptions) {
      subscription.cancel();
    }
    _accountSubscriptions.clear();

    // Start new subscriptions for each account
    for (var account in _userAccounts) {
      final subscription = _firestoreService
          .getAccountStream(account.id)
          .listen((updatedAccount) {
            final index = _userAccounts.indexWhere(
              (a) => a.id == updatedAccount.id,
            );
            if (index != -1) {
              _userAccounts[index] = updatedAccount;
              notifyListeners();
            }
          });
      _accountSubscriptions.add(subscription);
    }
  }

  // Load transaction history
  Future<void> loadTransactionHistory() async {
    if (_currentUser == null || _userAccounts.isEmpty) return;

    try {
      // Reset transactions list
      _recentTransactions = [];

      // Get account IDs for all user accounts
      final List<String> accountIds = _userAccounts.map((a) => a.id).toList();

      // For each account, get its transactions
      for (var accountId in accountIds) {
        final transactions = await _firestoreService.getAccountTransactions(
          accountId,
        );

        // Add transactions that aren't already in the list (avoid duplicates)
        for (var transaction in transactions) {
          if (!_recentTransactions.any((t) => t.id == transaction.id)) {
            _recentTransactions.add(transaction);
          }
        }
      }

      // Sort transactions by timestamp (most recent first)
      _recentTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Debug print
      print('Loaded ${_recentTransactions.length} transactions');
      for (var transaction in _recentTransactions) {
        print(
          'Transaction: ${transaction.id}, From: ${transaction.fromAccountId}, To: ${transaction.toAccountId}, Amount: ${transaction.amount}, Type: ${transaction.type}',
        );
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading transaction history: $e');
    }
  }

  // Clean up resources
  void dispose() {
    for (var subscription in _accountSubscriptions) {
      subscription.cancel();
    }
    _accountSubscriptions.clear();
  }

  // Load user accounts
  Future<void> loadUserAccounts() async {
    if (_currentUser == null) return;

    try {
      _userAccounts = await _firestoreService.getUserAccounts(_currentUser!.id);

      // Start listening for real-time updates
      startAccountsListener();

      // Load transaction history
      await loadTransactionHistory();

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user accounts: $e');
    }
  }

  // Generate OTP for secure transactions
  Future<String> generateOTP() async {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }

    try {
      final otp = _authService.generateOTP();
      await _authService.storeOTP(_currentUser!.id, otp);
      return otp;
    } catch (e) {
      debugPrint('Error generating OTP: $e');
      throw Exception('Failed to generate OTP: ${e.toString()}');
    }
  }

  // Verify OTP
  Future<bool> verifyOTP(String enteredOTP) async {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }

    try {
      return await _authService.verifyOTP(_currentUser!.id, enteredOTP);
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return false;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }

    try {
      await _authService.updateUserProfile(
        displayName: name,
        phoneNumber: phoneNumber,
        photoURL: profileImageUrl,
      );

      // Update local user object
      if (name != null) _currentUser!.name = name;
      if (phoneNumber != null) _currentUser!.phoneNumber = phoneNumber;
      if (profileImageUrl != null)
        _currentUser!.profileImageUrl = profileImageUrl;

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  // Change password
  Future<void> changePassword(String newPassword) async {
    if (_currentUser == null) {
      throw Exception('User not logged in');
    }

    try {
      await _authService.changePassword(newPassword);
    } catch (e) {
      debugPrint('Error changing password: $e');
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  // Method to set current user
  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}
