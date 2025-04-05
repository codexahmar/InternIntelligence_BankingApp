import 'package:uuid/uuid.dart';
import 'package:banking_app/models/account.dart';
import 'package:banking_app/models/transaction.dart';
import 'package:banking_app/utils/database_helper.dart';
import 'package:banking_app/utils/account_service.dart';

class TransactionService {
  static final TransactionService _instance = TransactionService._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = Uuid();
  final AccountService _accountService = AccountService();

  factory TransactionService() => _instance;

  TransactionService._internal();

  // Transfer money between accounts
  Future<bool> transferMoney({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required String description,
  }) async {
    // Validate amount
    if (amount <= 0) {
      throw Exception('Invalid amount: Amount must be greater than zero');
    }

    // Get source account
    List<Account> sourceAccounts = await _dbHelper.getUserAccounts('');
    Account? fromAccount = sourceAccounts.firstWhere(
      (account) => account.id == fromAccountId,
      orElse: () => throw Exception('Source account not found'),
    );

    // Check if source account has sufficient balance
    if (fromAccount.balance < amount) {
      throw Exception('Insufficient funds');
    }

    // Get destination account
    List<Account> allAccounts = await _dbHelper.getUserAccounts('');
    Account? toAccount = allAccounts.firstWhere(
      (account) => account.id == toAccountId,
      orElse: () => throw Exception('Destination account not found'),
    );

    // Create transaction record
    final transaction = Transaction(
      id: _uuid.v4(),
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      note: description,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: 'transfer',
      status: 'completed',
    );

    // Update account balances
    await _dbHelper.updateAccountBalance(
      fromAccountId,
      fromAccount.balance - amount,
    );
    await _dbHelper.updateAccountBalance(
      toAccountId,
      toAccount.balance + amount,
    );

    // Save transaction
    final result = await _dbHelper.insertTransaction(transaction);
    return result > 0;
  }

  // Process transfer between internal accounts
  Future<bool> processInternalTransfer(Transaction transaction) async {
    try {
      // Get the accounts
      final fromAccount = await _accountService.getAccountById(
        transaction.fromAccountId,
      );
      final toAccount = await _accountService.getAccountById(
        transaction.toAccountId,
      );

      if (fromAccount == null || toAccount == null) {
        throw Exception('One or both accounts not found');
      }

      if (fromAccount.balance < transaction.amount) {
        throw Exception('Insufficient funds');
      }

      // Update account balances
      await _accountService.updateAccountBalance(
        fromAccount.id,
        fromAccount.balance - transaction.amount,
      );

      await _accountService.updateAccountBalance(
        toAccount.id,
        toAccount.balance + transaction.amount,
      );

      // Record the transaction
      await _dbHelper.insertTransaction(transaction);

      return true;
    } catch (e) {
      print('Error in internal transfer: $e');
      rethrow;
    }
  }

  // Process external transfer (to accounts outside the system)
  Future<bool> processExternalTransfer(Transaction transaction) async {
    try {
      // Get the source account
      final fromAccount = await _accountService.getAccountById(
        transaction.fromAccountId,
      );

      if (fromAccount == null) {
        throw Exception('Source account not found');
      }

      if (fromAccount.balance < transaction.amount) {
        throw Exception('Insufficient funds');
      }

      // Deduct amount from source account
      await _accountService.updateAccountBalance(
        fromAccount.id,
        fromAccount.balance - transaction.amount,
      );

      // Record the transaction
      await _dbHelper.insertTransaction(transaction);

      return true;
    } catch (e) {
      print('Error in external transfer: $e');
      rethrow;
    }
  }

  // Get all transactions for a user
  Future<List<Transaction>> getUserTransactions(String userId) async {
    try {
      // Use existing method instead
      final accounts = await _dbHelper.getUserAccounts(userId);
      final List<Transaction> allTransactions = [];

      for (final account in accounts) {
        final transactions = await _dbHelper.getAccountTransactions(account.id);
        allTransactions.addAll(transactions);
      }

      // Sort by timestamp in descending order
      allTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return allTransactions;
    } catch (e) {
      print('Error getting user transactions: $e');
      return [];
    }
  }

  // Get transactions for a specific account
  Future<List<Transaction>> getAccountTransactions(String accountId) async {
    try {
      final transactions = await _dbHelper.getAccountTransactions(accountId);
      return transactions;
    } catch (e) {
      print('Error getting account transactions: $e');
      return [];
    }
  }

  // Get recent transactions (last n)
  Future<List<Transaction>> getRecentTransactions(
    String userId,
    int limit,
  ) async {
    try {
      final allTransactions = await getUserTransactions(userId);
      return allTransactions.take(limit).toList();
    } catch (e) {
      print('Error getting recent transactions: $e');
      return [];
    }
  }

  // Get account balance
  Future<double> getAccountBalance(String accountId) async {
    final accounts = await _dbHelper.getUserAccounts('');
    try {
      final account = accounts.firstWhere((account) => account.id == accountId);
      return account.balance;
    } catch (e) {
      throw Exception('Account not found');
    }
  }

  // Deposit money
  Future<bool> depositMoney({
    required String accountId,
    required double amount,
    required String description,
  }) async {
    if (amount <= 0) {
      throw Exception('Invalid amount: Amount must be greater than zero');
    }

    // Get account
    List<Account> accounts = await _dbHelper.getUserAccounts('');
    Account? account = accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => throw Exception('Account not found'),
    );

    // Create transaction record
    final transaction = Transaction(
      id: _uuid.v4(),
      fromAccountId: '', // Empty for deposit
      toAccountId: accountId,
      amount: amount,
      note: description,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: 'deposit',
      status: 'completed',
    );

    // Update account balance
    await _dbHelper.updateAccountBalance(accountId, account.balance + amount);

    // Save transaction
    final result = await _dbHelper.insertTransaction(transaction);
    return result > 0;
  }

  // Withdraw money
  Future<bool> withdrawMoney({
    required String accountId,
    required double amount,
    required String description,
  }) async {
    if (amount <= 0) {
      throw Exception('Invalid amount: Amount must be greater than zero');
    }

    // Get account
    List<Account> accounts = await _dbHelper.getUserAccounts('');
    Account? account = accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => throw Exception('Account not found'),
    );

    // Check if account has sufficient balance
    if (account.balance < amount) {
      throw Exception('Insufficient funds');
    }

    // Create transaction record (withdrawal)
    final transaction = Transaction(
      id: _uuid.v4(),
      fromAccountId: accountId,
      toAccountId: '', // Empty for withdrawal
      amount: amount,
      note: description,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      type: 'withdrawal',
      status: 'completed',
    );

    // Update account balance
    await _dbHelper.updateAccountBalance(accountId, account.balance - amount);

    // Save transaction
    final result = await _dbHelper.insertTransaction(transaction);
    return result > 0;
  }
}
