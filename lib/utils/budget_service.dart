import 'package:uuid/uuid.dart';
import 'package:banking_app/models/budget.dart';
import 'package:banking_app/models/expense.dart';
import 'package:banking_app/utils/database_helper.dart';

class BudgetService {
  static final BudgetService _instance = BudgetService._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = Uuid();

  factory BudgetService() => _instance;

  BudgetService._internal();

  // Create or update a budget for a category
  Future<bool> setBudget({
    required String userId,
    required String category,
    required double amount,
    required int month,
    required int year,
  }) async {
    // Get existing budget if any
    final budgets = await _dbHelper.getUserBudgets(userId, month, year);
    final existingBudget =
        budgets.where((b) => b.category == category).toList();

    if (existingBudget.isNotEmpty) {
      // Update existing budget
      final budget = Budget(
        id: existingBudget.first.id,
        userId: userId,
        category: category,
        amount: amount,
        month: month,
        year: year,
      );

      // In a real app, we would update the budget, but SQLite doesn't have a method
      // for this in our simplified implementation, so we'll delete and re-add
      await _dbHelper.insertBudget(budget);
      return true;
    } else {
      // Create new budget
      final budget = Budget(
        id: _uuid.v4(),
        userId: userId,
        category: category,
        amount: amount,
        month: month,
        year: year,
      );

      final result = await _dbHelper.insertBudget(budget);
      return result > 0;
    }
  }

  // Get all budgets for a user in a specific month/year
  Future<List<Budget>> getUserBudgets(
    String userId,
    int month,
    int year,
  ) async {
    return await _dbHelper.getUserBudgets(userId, month, year);
  }

  // Add an expense
  Future<bool> addExpense({
    required String userId,
    required String category,
    required double amount,
    required String description,
    DateTime? date,
  }) async {
    final expense = Expense(
      id: _uuid.v4(),
      userId: userId,
      category: category,
      amount: amount,
      description: description,
      date: (date ?? DateTime.now()).millisecondsSinceEpoch,
    );

    final result = await _dbHelper.insertExpense(expense);
    return result > 0;
  }

  // Get all expenses for a user
  Future<List<Expense>> getUserExpenses(String userId) async {
    return await _dbHelper.getUserExpenses(userId);
  }

  // Get expenses by category
  Future<List<Expense>> getExpensesByCategory(
    String userId,
    String category,
  ) async {
    return await _dbHelper.getUserExpensesByCategory(userId, category);
  }

  // Get monthly spending for a category
  Future<double> getCategorySpending(
    String userId,
    String category,
    int month,
    int year,
  ) async {
    final expenses = await _dbHelper.getUserExpensesByCategory(
      userId,
      category,
    );

    // Filter expenses for the specified month and year
    final monthlyExpenses =
        expenses.where((expense) {
          final expenseDate = DateTime.fromMillisecondsSinceEpoch(expense.date);
          return expenseDate.month == month && expenseDate.year == year;
        }).toList();

    // Sum up the expenses
    double total = 0;
    for (var expense in monthlyExpenses) {
      total += expense.amount;
    }
    return total;
  }

  // Get budget utilization (percentage of budget spent)
  Future<double> getBudgetUtilization(
    String userId,
    String category,
    int month,
    int year,
  ) async {
    final budgets = await _dbHelper.getUserBudgets(userId, month, year);
    final categoryBudget =
        budgets.where((b) => b.category == category).toList();

    if (categoryBudget.isEmpty) {
      return 0.0; // No budget set
    }

    final budgetAmount = categoryBudget.first.amount;
    final spending = await getCategorySpending(userId, category, month, year);

    if (budgetAmount == 0) {
      return 0.0; // Avoid division by zero
    }

    return (spending / budgetAmount) * 100;
  }

  // Get spending summary for all categories in a month
  Future<Map<String, double>> getMonthlySummary(
    String userId,
    int month,
    int year,
  ) async {
    final expenses = await _dbHelper.getUserExpenses(userId);
    final Map<String, double> summary = {};

    // Filter expenses for the specified month and year
    final monthlyExpenses =
        expenses.where((expense) {
          final expenseDate = DateTime.fromMillisecondsSinceEpoch(expense.date);
          return expenseDate.month == month && expenseDate.year == year;
        }).toList();

    // Group by category and sum
    for (var expense in monthlyExpenses) {
      if (summary.containsKey(expense.category)) {
        summary[expense.category] = summary[expense.category]! + expense.amount;
      } else {
        summary[expense.category] = expense.amount;
      }
    }

    return summary;
  }
}
