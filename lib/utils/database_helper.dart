import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:banking_app/models/account.dart';
import 'package:banking_app/models/transaction.dart';
import 'package:banking_app/models/budget.dart';
import 'package:banking_app/models/expense.dart';
import 'package:banking_app/models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static sql.Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<sql.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<sql.Database> _initDatabase() async {
    String path = join(await sql.getDatabasesPath(), 'banking_app.db');
    return await sql.openDatabase(path, version: 1, onCreate: _createDb);
  }

  Future<void> _createDb(sql.Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        password TEXT,
        phoneNumber TEXT,
        profileImageUrl TEXT
      )
    ''');

    // Accounts table
    await db.execute('''
      CREATE TABLE accounts(
        id TEXT PRIMARY KEY,
        userId TEXT,
        accountNumber TEXT,
        balance REAL,
        type TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        fromAccountId TEXT,
        toAccountId TEXT,
        amount REAL,
        note TEXT,
        timestamp INTEGER,
        type TEXT,
        status TEXT,
        externalAccountNumber TEXT,
        FOREIGN KEY (fromAccountId) REFERENCES accounts (id)
      )
    ''');

    // Budgets table
    await db.execute('''
      CREATE TABLE budgets(
        id TEXT PRIMARY KEY,
        userId TEXT,
        category TEXT,
        amount REAL,
        month INTEGER,
        year INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Expenses table
    await db.execute('''
      CREATE TABLE expenses(
        id TEXT PRIMARY KEY,
        userId TEXT,
        category TEXT,
        amount REAL,
        description TEXT,
        date INTEGER,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');
  }

  // User methods
  Future<int> insertUser(User user) async {
    sql.Database db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUser(String email, String password) async {
    sql.Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Account methods
  Future<int> insertAccount(Account account) async {
    sql.Database db = await database;
    return await db.insert('accounts', account.toMap());
  }

  Future<List<Account>> getUserAccounts(String userId) async {
    sql.Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
  }

  Future<int> updateAccountBalance(String accountId, double newBalance) async {
    sql.Database db = await database;
    return await db.update(
      'accounts',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  // Transaction methods
  Future<int> insertTransaction(Transaction transaction) async {
    sql.Database db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<Transaction>> getAccountTransactions(String accountId) async {
    sql.Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'fromAccountId = ? OR toAccountId = ?',
      whereArgs: [accountId, accountId],
      orderBy: 'timestamp DESC',
    );
    return List.generate(maps.length, (i) => Transaction.fromMap(maps[i]));
  }

  // Budget methods
  Future<int> insertBudget(Budget budget) async {
    sql.Database db = await database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<List<Budget>> getUserBudgets(
    String userId,
    int month,
    int year,
  ) async {
    sql.Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'userId = ? AND month = ? AND year = ?',
      whereArgs: [userId, month, year],
    );
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  // Expense methods
  Future<int> insertExpense(Expense expense) async {
    sql.Database db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getUserExpenses(String userId) async {
    sql.Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<List<Expense>> getUserExpensesByCategory(
    String userId,
    String category,
  ) async {
    sql.Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'userId = ? AND category = ?',
      whereArgs: [userId, category],
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }
}
