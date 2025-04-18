import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:banking_app/models/budget.dart';
import 'package:banking_app/models/expense.dart';
import 'package:banking_app/providers/user_provider.dart';
import 'package:banking_app/utils/firebase_firestore_service.dart';
import 'package:banking_app/widgets/budget_form.dart';
import 'package:banking_app/widgets/expense_form.dart';
import 'package:banking_app/widgets/budget_overview_tab.dart';
import 'package:banking_app/widgets/budget_list_tab.dart';
import 'package:banking_app/widgets/expense_list_tab.dart';
import 'package:banking_app/widgets/expense_details_sheet.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<Budget> _budgets = [];
  List<Expense> _expenses = [];
  Map<String, double> _categorySpending = {};
  Map<String, double> _budgetUtilization = {};
  late TabController _tabController;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userId = userProvider.currentUser!.id;

      // Load budgets for current month/year
      _budgets = await _firestoreService.getUserBudgets(
        userId,
        _selectedMonth,
        _selectedYear,
      );

      // Load all expenses
      _expenses = await _firestoreService.getUserExpenses(userId);

      // Filter expenses for the selected month/year
      final filteredExpenses =
          _expenses.where((expense) {
            final expenseDate = DateTime.fromMillisecondsSinceEpoch(
              expense.date,
            );
            return expenseDate.month == _selectedMonth &&
                expenseDate.year == _selectedYear;
          }).toList();

      // Sort expenses by date (newest first)
      filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

      // Calculate spending by category
      _categorySpending = {};
      for (var expense in filteredExpenses) {
        if (_categorySpending.containsKey(expense.category)) {
          _categorySpending[expense.category] =
              _categorySpending[expense.category]! + expense.amount;
        } else {
          _categorySpending[expense.category] = expense.amount;
        }
      }

      // Calculate budget utilization
      _budgetUtilization = {};
      for (var budget in _budgets) {
        final spent = _categorySpending[budget.category] ?? 0;
        _budgetUtilization[budget.category] = (spent / budget.amount) * 100;
      }
    } catch (e) {
      print('Error loading budget data: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addExpense(
    String category,
    double amount,
    String description,
    int date,
  ) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser == null) return;

      final userId = userProvider.currentUser!.id;

      // Create expense
      final expense = Expense(
        id: '',
        userId: userId,
        category: category,
        amount: amount,
        description: description,
        date: date,
      );

      await _firestoreService.createExpense(expense);
      await _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully')),
      );
    } catch (e) {
      print('Error adding expense: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding expense: $e')));
    }
  }

  Future<void> _setBudget(String category, double amount) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.currentUser == null) return;

      final userId = userProvider.currentUser!.id;

      // Check if budget already exists
      final existingBudget = _budgets.firstWhere(
        (b) => b.category == category,
        orElse:
            () => Budget(
              id: '',
              userId: userId,
              category: category,
              amount: 0,
              month: _selectedMonth,
              year: _selectedYear,
            ),
      );

      if (existingBudget.id.isNotEmpty) {
        // Update existing budget
        final updatedBudget = Budget(
          id: existingBudget.id,
          userId: userId,
          category: category,
          amount: amount,
          month: _selectedMonth,
          year: _selectedYear,
        );

        await _firestoreService.updateBudget(updatedBudget);
      } else {
        // Create new budget
        final budget = Budget(
          id: '',
          userId: userId,
          category: category,
          amount: amount,
          month: _selectedMonth,
          year: _selectedYear,
        );

        await _firestoreService.createBudget(budget);
      }

      await _loadData();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Budget set successfully')));
    } catch (e) {
      print('Error setting budget: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error setting budget: $e')));
    }
  }

  Future<void> _editExpense(Expense expense) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: ExpenseForm(
            isEditing: true,
            initialExpense: expense,
            onAddExpense: (category, amount, description, date) async {
              try {
                final updatedExpense = Expense(
                  id: expense.id,
                  userId: expense.userId,
                  category: category,
                  amount: amount,
                  description: description,
                  date: date,
                );

                await _firestoreService.updateExpense(updatedExpense);
                await _loadData();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense updated successfully'),
                    ),
                  );
                }
              } catch (e) {
                print('Error updating expense: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating expense: $e')),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteExpense(String expenseId) async {
    try {
      await _firestoreService.deleteExpense(expenseId);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully')),
        );
      }
    } catch (e) {
      print('Error deleting expense: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting expense: $e')));
      }
    }
  }

  Future<void> _deleteBudget(String budgetId) async {
    try {
      await _firestoreService.deleteBudget(budgetId);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget deleted successfully')),
        );
      }
    } catch (e) {
      print('Error deleting budget: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting budget: $e')));
      }
    }
  }

  void _showBudgetActions(Budget budget) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: const Icon(Icons.edit, color: Colors.blue),
                  ),
                  title: const Text('Edit Budget'),
                  onTap: () {
                    Navigator.pop(context);
                    _showSetBudgetBottomSheet(existingBudget: budget);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Delete Budget'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Delete Budget'),
                            content: const Text(
                              'Are you sure you want to delete this budget?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteBudget(budget.id);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showSetBudgetBottomSheet({Budget? existingBudget}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: BudgetForm(
            onSetBudget: _setBudget,
            initialBudget: existingBudget,
          ),
        );
      },
    );
  }

  void _showAddExpenseBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: ExpenseForm(onAddExpense: _addExpense),
        );
      },
    );
  }

  void _navigateToExpenseDetails(String category) {
    // Filter expenses for this category and month/year
    final categoryExpenses =
        _expenses.where((expense) {
          final expenseDate = DateTime.fromMillisecondsSinceEpoch(expense.date);
          return expense.category == category &&
              expenseDate.month == _selectedMonth &&
              expenseDate.year == _selectedYear;
        }).toList();

    // Sort by date (newest first)
    categoryExpenses.sort((a, b) => b.date.compareTo(a.date));

    // Get budget for this category
    final budget = _budgets.firstWhere(
      (b) => b.category == category,
      orElse:
          () => Budget(
            id: '',
            userId: '',
            category: category,
            amount: 0,
            month: _selectedMonth,
            year: _selectedYear,
          ),
    );

    // Calculate total spending
    final totalSpent = _categorySpending[category] ?? 0.0;

    // Show bottom sheet with expense details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => ExpenseDetailsSheet(
            category: category,
            budget: budget,
            totalSpent: totalSpent,
            expenses: categoryExpenses,
            onEditExpense: _editExpense,
            onDeleteExpense: _deleteExpense,
          ),
    );
  }

  void _previousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
    _loadData();
  }

  void _nextMonth() {
    final now = DateTime.now();
    // Don't allow navigating to future months
    if (_selectedYear == now.year && _selectedMonth == now.month) {
      return;
    }

    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate totals for overview
    double totalBudget = 0;
    double totalSpending = 0;

    for (var budget in _budgets) {
      totalBudget += budget.amount;
    }

    for (var spending in _categorySpending.values) {
      totalSpending += spending;
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder:
                (context) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.withOpacity(0.1),
                          child: Icon(Icons.add_chart, color: Colors.green),
                        ),
                        title: Text('Add Expense'),
                        subtitle: Text('Record a new expense'),
                        onTap: () {
                          Navigator.pop(context);
                          _showAddExpenseBottomSheet();
                        },
                      ),
                      Divider(),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text('Set Budget'),
                        subtitle: Text('Set a new category budget'),
                        onTap: () {
                          Navigator.pop(context);
                          _showSetBudgetBottomSheet();
                        },
                      ),
                    ],
                  ),
                ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Expense or Budget',
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Budget Management',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: _showSetBudgetBottomSheet,
                                  tooltip: 'Set Budget',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Month selector
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios),
                                  onPressed: _previousMonth,
                                  iconSize: 18,
                                ),
                                Text(
                                  DateFormat('MMMM yyyy').format(
                                    DateTime(_selectedYear, _selectedMonth),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios),
                                  onPressed: _nextMonth,
                                  iconSize: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          labelColor: Theme.of(context).primaryColor,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Theme.of(context).primaryColor,
                          tabs: const [
                            Tab(text: 'Overview'),
                            Tab(text: 'Budgets'),
                            Tab(text: 'Expenses'),
                          ],
                        ),
                      ),
                      pinned: true,
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    BudgetOverviewTab(
                      totalBudget: totalBudget,
                      totalSpending: totalSpending,
                      categorySpending: _categorySpending,
                    ),
                    BudgetListTab(
                      budgets: _budgets,
                      budgetUtilization: _budgetUtilization,
                      onAddBudget: _showSetBudgetBottomSheet,
                      onCategoryTap: _navigateToExpenseDetails,
                      onEditBudget:
                          (budget) =>
                              _showSetBudgetBottomSheet(existingBudget: budget),
                      onDeleteBudget: (budget) => _deleteBudget(budget.id),
                    ),
                    ExpenseListTab(
                      expenses:
                          _expenses.where((expense) {
                            final expenseDate =
                                DateTime.fromMillisecondsSinceEpoch(
                                  expense.date,
                                );
                            return expenseDate.month == _selectedMonth &&
                                expenseDate.year == _selectedYear;
                          }).toList(),
                      onAddExpense: _showAddExpenseBottomSheet,
                      onEditExpense: _editExpense,
                      onDeleteExpense: _deleteExpense,
                    ),
                  ],
                ),
              ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
