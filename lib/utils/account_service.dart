import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:banking_app/models/account.dart';
import 'package:banking_app/utils/database_helper.dart';

class AccountService {
  static final AccountService _instance = AccountService._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = Uuid();
  final Random _random = Random();

  factory AccountService() {
    return _instance;
  }

  AccountService._internal();

  // Generate a unique account number
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

  // Create a new account
  Future<Account> createAccount({
    required String userId,
    required String type,
    double initialBalance = 0.0,
  }) async {
    final account = Account(
      id: _uuid.v4(),
      userId: userId,
      accountNumber: generateAccountNumber(),
      balance: initialBalance,
      type: type,
    );

    await _dbHelper.insertAccount(account);
    return account;
  }

  // Get all accounts for a user
  Future<List<Account>> getUserAccounts(String userId) async {
    return await _dbHelper.getUserAccounts(userId);
  }

  // Get account by ID
  Future<Account?> getAccountById(String accountId) async {
    final accounts = await _dbHelper.getUserAccounts('');
    try {
      return accounts.firstWhere((account) => account.id == accountId);
    } catch (e) {
      return null;
    }
  }

  // Get account by account number
  Future<Account?> getAccountByNumber(String accountNumber) async {
    final accounts = await _dbHelper.getUserAccounts('');
    try {
      return accounts.firstWhere(
        (account) => account.accountNumber == accountNumber,
      );
    } catch (e) {
      return null;
    }
  }

  // Update account balance
  Future<bool> updateAccountBalance(String accountId, double newBalance) async {
    try {
      final result = await _dbHelper.updateAccountBalance(
        accountId,
        newBalance,
      );
      return result > 0;
    } catch (e) {
      print('Error updating account balance: $e');
      return false;
    }
  }

  // Create a default account for a new user
  Future<Account> createDefaultAccount(String userId) async {
    return await createAccount(
      userId: userId,
      type: 'Savings',
      initialBalance: 1000.0,
    );
  }

  // Create demo accounts for testing
  Future<List<Account>> createDemoAccounts(String userId) async {
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
  }
}
