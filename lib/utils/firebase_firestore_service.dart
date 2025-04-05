import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:banking_app/models/user.dart' as app;
import 'package:banking_app/models/account.dart';
import 'package:banking_app/models/transaction.dart' as app_transaction;
import 'package:banking_app/models/budget.dart';
import 'package:banking_app/models/expense.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final Uuid _uuid = Uuid();
  final Random _random = Random();

  // Collections
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _accountsCollection =>
      _firestore.collection('accounts');
  CollectionReference get _transactionsCollection =>
      _firestore.collection('transactions');
  CollectionReference get _budgetsCollection =>
      _firestore.collection('budgets');
  CollectionReference get _expensesCollection =>
      _firestore.collection('expenses');

  // User operations
  Future<void> createUser(app.User user) async {
    try {
      await _usersCollection.doc(user.id).set({
        'name': user.name,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'profileImageUrl': user.profileImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating user: $e');
      throw Exception('Failed to create user');
    }
  }

  Future<app.User?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return app.User(
          id: doc.id,
          name: data['name'],
          email: data['email'],
          password: '', // Password is never stored or retrieved
          phoneNumber: data['phoneNumber'],
          profileImageUrl: data['profileImageUrl'] ?? '',
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  Future<bool> updateUser(app.User user) async {
    try {
      await _usersCollection.doc(user.id).update({
        'name': user.name,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'profileImageUrl': user.profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  // Account operations
  String generateAccountNumber() {
    // Generate a 16-digit account number
    String accountNumber = '';
    for (int i = 0; i < 16; i++) {
      accountNumber += _random.nextInt(10).toString();
    }

    // Format as XXXX-XXXX-XXXX-XXXX
    return '${accountNumber.substring(0, 4)}-${accountNumber.substring(4, 8)}-'
        '${accountNumber.substring(8, 12)}-${accountNumber.substring(12, 16)}';
  }

  Future<Account> createAccount({
    required String userId,
    required String type,
    double initialBalance = 0.0,
  }) async {
    try {
      final String accountId = _uuid.v4();
      final String accountNumber = generateAccountNumber();

      final account = Account(
        id: accountId,
        userId: userId,
        accountNumber: accountNumber,
        balance: initialBalance,
        type: type,
      );

      await _accountsCollection.doc(accountId).set({
        'userId': userId,
        'accountNumber': accountNumber,
        'balance': initialBalance,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return account;
    } catch (e) {
      debugPrint('Error creating account: $e');
      throw Exception('Failed to create account');
    }
  }

  Future<List<Account>> getUserAccounts(String userId) async {
    try {
      final querySnapshot =
          await _accountsCollection.where('userId', isEqualTo: userId).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Account(
          id: doc.id,
          userId: data['userId'],
          accountNumber: data['accountNumber'],
          balance: (data['balance'] as num).toDouble(),
          type: data['type'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user accounts: $e');
      return [];
    }
  }

  Future<Account?> getAccountById(String accountId) async {
    try {
      final doc = await _accountsCollection.doc(accountId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return Account(
          id: doc.id,
          userId: data['userId'],
          accountNumber: data['accountNumber'],
          balance: (data['balance'] as num).toDouble(),
          type: data['type'],
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting account: $e');
      return null;
    }
  }

  Future<Account?> getAccountByNumber(String accountNumber) async {
    try {
      final querySnapshot =
          await _accountsCollection
              .where('accountNumber', isEqualTo: accountNumber)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return Account(
          id: doc.id,
          userId: data['userId'],
          accountNumber: data['accountNumber'],
          balance: (data['balance'] as num).toDouble(),
          type: data['type'],
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error getting account by number: $e');
      return null;
    }
  }

  Future<bool> updateAccountBalance(String accountId, double newBalance) async {
    try {
      await _accountsCollection.doc(accountId).update({
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating account balance: $e');
      return false;
    }
  }

  Future<List<Account>> createDefaultAccounts(String userId) async {
    try {
      final List<Account> accounts = [];

      // Create a savings account
      final savingsAccount = await createAccount(
        userId: userId,
        type: 'Savings',
        initialBalance: 5000.0,
      );
      accounts.add(savingsAccount);

      // Create a checking account
      final checkingAccount = await createAccount(
        userId: userId,
        type: 'Checking',
        initialBalance: 2500.0,
      );
      accounts.add(checkingAccount);

      // Create an investment account
      final investmentAccount = await createAccount(
        userId: userId,
        type: 'Investment',
        initialBalance: 10000.0,
      );
      accounts.add(investmentAccount);

      return accounts;
    } catch (e) {
      debugPrint('Error creating default accounts: $e');
      throw Exception('Failed to create default accounts');
    }
  }

  // Transaction operations
  Future<String> createTransaction(
    app_transaction.Transaction transaction,
  ) async {
    try {
      final String transactionId =
          transaction.id.isEmpty ? _uuid.v4() : transaction.id;

      await _transactionsCollection.doc(transactionId).set({
        'fromAccountId': transaction.fromAccountId,
        'toAccountId': transaction.toAccountId,
        'amount': transaction.amount,
        'timestamp': transaction.timestamp,
        'note': transaction.note,
        'type': transaction.type,
        'status': transaction.status,
        'externalAccountNumber': transaction.externalAccountNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return transactionId;
    } catch (e) {
      debugPrint('Error creating transaction: $e');
      throw Exception('Failed to create transaction');
    }
  }

  Future<List<app_transaction.Transaction>> getAccountTransactions(
    String accountId,
  ) async {
    try {
      // Instead of using a single query with OR filter, which requires composite indexes,
      // we'll use two separate queries and merge the results

      // Get transactions where account is the source
      final fromQuerySnapshot =
          await _transactionsCollection
              .where('fromAccountId', isEqualTo: accountId)
              .get();

      // Get transactions where account is the destination
      final toQuerySnapshot =
          await _transactionsCollection
              .where('toAccountId', isEqualTo: accountId)
              .get();

      // Combine results from both queries
      final allTransactions = <app_transaction.Transaction>[];

      // Add 'from' transactions
      for (var doc in fromQuerySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        allTransactions.add(
          app_transaction.Transaction(
            id: doc.id,
            fromAccountId: data['fromAccountId'],
            toAccountId: data['toAccountId'],
            amount: (data['amount'] as num).toDouble(),
            timestamp: data['timestamp'],
            note: data['note'] ?? '',
            type: data['type'],
            status: data['status'],
            externalAccountNumber: data['externalAccountNumber'],
          ),
        );
      }

      // Add 'to' transactions (check for duplicates)
      for (var doc in toQuerySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final transaction = app_transaction.Transaction(
          id: doc.id,
          fromAccountId: data['fromAccountId'],
          toAccountId: data['toAccountId'],
          amount: (data['amount'] as num).toDouble(),
          timestamp: data['timestamp'],
          note: data['note'] ?? '',
          type: data['type'],
          status: data['status'],
          externalAccountNumber: data['externalAccountNumber'],
        );

        // Only add if not already in the list (avoid duplicates for internal transfers)
        if (!allTransactions.any((t) => t.id == transaction.id)) {
          allTransactions.add(transaction);
        }
      }

      // Sort the combined results by timestamp (most recent first)
      allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return allTransactions;
    } catch (e) {
      debugPrint('Error getting account transactions: $e');
      return [];
    }
  }

  // Transfer operations
  Future<bool> processInternalTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    String note = '',
  }) async {
    try {
      // Get source and destination accounts
      final fromAccount = await getAccountById(fromAccountId);
      final toAccount = await getAccountById(toAccountId);

      if (fromAccount == null) {
        throw Exception('Source account not found');
      }

      if (toAccount == null) {
        throw Exception('Destination account not found');
      }

      // Check if sufficient balance
      if (fromAccount.balance < amount) {
        throw Exception('Insufficient funds');
      }

      // Use transaction to ensure atomicity
      return await _firestore.runTransaction<bool>((txn) async {
        // Update source account balance
        final newFromBalance = fromAccount.balance - amount;
        await txn.update(_accountsCollection.doc(fromAccount.id), {
          'balance': newFromBalance,
        });

        // Update destination account balance
        final newToBalance = toAccount.balance + amount;
        await txn.update(_accountsCollection.doc(toAccount.id), {
          'balance': newToBalance,
        });

        // Create transaction record
        final transactionId = _uuid.v4();
        final transactionRef = _transactionsCollection.doc(transactionId);
        await txn.set(transactionRef, {
          'fromAccountId': fromAccount.id,
          'toAccountId': toAccount.id,
          'amount': amount,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'note': note,
          'type': 'transfer',
          'status': 'completed',
          'createdAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      debugPrint('Error processing internal transfer: $e');
      return false;
    }
  }

  Future<bool> processExternalTransfer({
    required String fromAccountId,
    required String externalAccountNumber,
    required double amount,
    String note = '',
  }) async {
    try {
      // Get source account
      final fromAccount = await getAccountById(fromAccountId);

      if (fromAccount == null) {
        throw Exception('Source account not found');
      }

      // Check if sufficient balance
      if (fromAccount.balance < amount) {
        throw Exception('Insufficient funds');
      }

      // Get destination account by account number
      final toAccount = await getAccountByNumber(externalAccountNumber);

      if (toAccount == null) {
        throw Exception('Destination account not found');
      }

      // Use transaction to ensure atomicity
      return await _firestore.runTransaction<bool>((txn) async {
        // Update source account balance
        final newFromBalance = fromAccount.balance - amount;
        await txn.update(_accountsCollection.doc(fromAccount.id), {
          'balance': newFromBalance,
        });

        // Update destination account balance
        final newToBalance = toAccount.balance + amount;
        await txn.update(_accountsCollection.doc(toAccount.id), {
          'balance': newToBalance,
        });

        // Create transaction record
        final transactionId = _uuid.v4();
        final transactionRef = _transactionsCollection.doc(transactionId);
        await txn.set(transactionRef, {
          'fromAccountId': fromAccount.id,
          'toAccountId': toAccount.id,
          'amount': amount,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'note': note,
          'type': 'external_transfer',
          'status': 'completed',
          'externalAccountNumber': externalAccountNumber,
          'createdAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      debugPrint('Error processing external transfer: $e');
      return false;
    }
  }

  // Budget operations
  Future<String> createBudget(Budget budget) async {
    try {
      final String budgetId = budget.id.isEmpty ? _uuid.v4() : budget.id;

      await _budgetsCollection.doc(budgetId).set({
        'userId': budget.userId,
        'category': budget.category,
        'amount': budget.amount,
        'month': budget.month,
        'year': budget.year,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return budgetId;
    } catch (e) {
      debugPrint('Error creating budget: $e');
      throw Exception('Failed to create budget');
    }
  }

  Future<bool> updateBudget(Budget budget) async {
    try {
      if (budget.id.isEmpty) {
        throw Exception('Budget ID cannot be empty for update');
      }

      await _budgetsCollection.doc(budget.id).update({
        'category': budget.category,
        'amount': budget.amount,
        'month': budget.month,
        'year': budget.year,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Error updating budget: $e');
      return false;
    }
  }

  Future<List<Budget>> getUserBudgets(
    String userId,
    int month,
    int year,
  ) async {
    try {
      final querySnapshot =
          await _budgetsCollection
              .where('userId', isEqualTo: userId)
              .where('month', isEqualTo: month)
              .where('year', isEqualTo: year)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Budget(
          id: doc.id,
          userId: data['userId'],
          category: data['category'],
          amount: (data['amount'] as num).toDouble(),
          month: data['month'],
          year: data['year'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user budgets: $e');
      return [];
    }
  }

  // Expense operations
  Future<String> createExpense(Expense expense) async {
    try {
      final String expenseId = expense.id.isEmpty ? _uuid.v4() : expense.id;

      await _expensesCollection.doc(expenseId).set({
        'userId': expense.userId,
        'category': expense.category,
        'amount': expense.amount,
        'description': expense.description,
        'date': expense.date,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return expenseId;
    } catch (e) {
      debugPrint('Error creating expense: $e');
      throw Exception('Failed to create expense');
    }
  }

  Future<List<Expense>> getUserExpenses(String userId) async {
    try {
      final querySnapshot =
          await _expensesCollection
              .where('userId', isEqualTo: userId)
              .orderBy('date', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Expense(
          id: doc.id,
          userId: data['userId'],
          category: data['category'],
          amount: (data['amount'] as num).toDouble(),
          description: data['description'],
          date: data['date'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user expenses: $e');
      return [];
    }
  }

  Future<List<Expense>> getUserExpensesByCategory(
    String userId,
    String category,
  ) async {
    try {
      final querySnapshot =
          await _expensesCollection
              .where('userId', isEqualTo: userId)
              .where('category', isEqualTo: category)
              .orderBy('date', descending: true)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Expense(
          id: doc.id,
          userId: data['userId'],
          category: data['category'],
          amount: (data['amount'] as num).toDouble(),
          description: data['description'],
          date: data['date'],
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user expenses by category: $e');
      return [];
    }
  }

  // Real-time account updates
  Stream<Account> getAccountStream(String accountId) {
    return _accountsCollection.doc(accountId).snapshots().map((snapshot) {
      final data = snapshot.data() as Map<String, dynamic>;
      return Account(
        id: snapshot.id,
        userId: data['userId'],
        accountNumber: data['accountNumber'],
        balance: (data['balance'] as num).toDouble(),
        type: data['type'],
      );
    });
  }

  // Real-time transaction updates
  Stream<List<app_transaction.Transaction>> getAccountTransactionsStream(
    String accountId,
  ) {
    // Just use a simple periodic refresh approach to avoid complex stream merging
    // This isn't truly real-time but it avoids the need for composite indexes
    return Stream.periodic(const Duration(seconds: 30), (_) async {
      return await getAccountTransactions(accountId);
    }).asyncMap((future) => future);
  }
}
