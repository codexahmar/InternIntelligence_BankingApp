import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:banking_app/models/budget.dart';
import 'package:banking_app/models/expense.dart';
import 'package:banking_app/providers/user_provider.dart';
import 'package:banking_app/utils/firebase_firestore_service.dart';
import 'package:banking_app/widgets/budget_category_card.dart';
import 'package:banking_app/widgets/budget_form.dart';
import 'package:banking_app/widgets/expense_form.dart';
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

      // Debug print to verify data
      print('Loaded ${_budgets.length} budgets');
      print('Loaded ${_expenses.length} total expenses');
      print(
        'Filtered ${filteredExpenses.length} expenses for current month/year',
      );
      print('Category spending: $_categorySpending');
      print('Budget utilization: $_budgetUtilization');
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

      // Reload data
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

      // Reload data
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

  void _showSetBudgetBottomSheet() {
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
          child: BudgetForm(onSetBudget: _setBudget),
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

    // Helper widget for budget rows
    Widget _budgetRow(String title, String value, Color color) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      );
    }

    // Show bottom sheet with expense details
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$category Expenses',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Budget Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _budgetRow(
                          'Monthly Budget:',
                          'Rs ${budget.amount.toStringAsFixed(2)}',
                          Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 8),
                        _budgetRow(
                          'Total Spent:',
                          'Rs ${totalSpent.toStringAsFixed(2)}',
                          Colors.red,
                        ),
                        const SizedBox(height: 8),
                        _budgetRow(
                          'Remaining:',
                          'Rs ${(budget.amount - totalSpent).toStringAsFixed(2)}',
                          totalSpent > budget.amount
                              ? Colors.red
                              : Colors.green,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Expense History',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  // Expense List
                  Expanded(
                    child:
                        categoryExpenses.isEmpty
                            ? Center(
                              child: Text(
                                'No expenses found for $category',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            )
                            : ListView.builder(
                              controller: scrollController,
                              itemCount: categoryExpenses.length,
                              itemBuilder: (context, index) {
                                final expense = categoryExpenses[index];
                                final date =
                                    DateTime.fromMillisecondsSinceEpoch(
                                      expense.date,
                                    );

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.05),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.blue.shade100,
                                      child: const Icon(
                                        Icons.receipt,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    title: Text(
                                      expense.description.isNotEmpty
                                          ? expense.description
                                          : 'Expense on ${DateFormat('MMM d').format(date)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      DateFormat('MMM d, yyyy').format(date),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    trailing: Text(
                                      'Rs ${expense.amount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueGrey,
        onPressed: _showAddExpenseBottomSheet,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Expense',
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
                    _buildOverviewTab(),
                    _buildBudgetsTab(),
                    _buildExpensesTab(),
                  ],
                ),
              ),
    );
  }

  Widget _buildOverviewTab() {
    // Get total budget and spending
    double totalBudget = 0;
    double totalSpending = 0;

    for (var budget in _budgets) {
      totalBudget += budget.amount;
    }

    for (var spending in _categorySpending.values) {
      totalSpending += spending;
    }

    // Calculate overall progress
    double overallPercentage =
        totalBudget > 0 ? (totalSpending / totalBudget) * 100 : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Budget Card
          Card(
            color: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Monthly Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value:
                                totalBudget > 0
                                    ? (totalSpending / totalBudget).clamp(0, 1)
                                    : 0,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              overallPercentage > 100
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (overallPercentage > 100
                                  ? Colors.red
                                  : Colors.green)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${overallPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            color:
                                overallPercentage > 100
                                    ? Colors.red
                                    : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Budget details
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildOverviewItem(
                        title: 'Total Budget',
                        amount: totalBudget,
                        textColor: Theme.of(context).primaryColor,
                      ),
                      _buildOverviewItem(
                        title: 'Spent',
                        amount: totalSpending,
                        textColor: Colors.red,
                      ),
                      _buildOverviewItem(
                        title: 'Remaining',
                        amount: totalBudget - totalSpending,
                        textColor:
                            totalBudget - totalSpending < 0
                                ? Colors.red
                                : Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Spending by Category Chart
          if (_categorySpending.isNotEmpty) ...[
            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 250, child: _buildPieChart()),
          ] else ...[
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(Icons.bar_chart, size: 70, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'No expenses yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some expenses to see your spending analysis',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Top Categories
          if (_categorySpending.isNotEmpty) ...[
            const Text(
              'Top Spending Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTopCategories(),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewItem({
    required String title,
    required double amount,
    required Color textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          'Rs ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart() {
    final entries =
        _categorySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Limit to top 5 categories, and combine the rest
    final topCategories = entries.take(5).toList();
    double otherAmount = 0;
    if (entries.length > 5) {
      for (int i = 5; i < entries.length; i++) {
        otherAmount += entries[i].value;
      }
      if (otherAmount > 0) {
        topCategories.add(MapEntry('Other', otherAmount));
      }
    }

    // Prepare chart data
    final sections = <PieChartSectionData>[];
    final categoryColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.grey,
    ];

    for (int i = 0; i < topCategories.length; i++) {
      final entry = topCategories[i];
      sections.add(
        PieChartSectionData(
          color: categoryColors[i % categoryColors.length],
          value: entry.value,
          title:
              '${(entry.value / _getTotalSpending() * 100).toStringAsFixed(0)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(topCategories.length, (index) {
                final category = topCategories[index].key;
                final color = categoryColors[index % categoryColors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopCategories() {
    final entries =
        _categorySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 3 categories
    final topCategories = entries.take(3).toList();

    return Column(
      children: [
        ...topCategories.map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final percentage = (amount / _getTotalSpending()) * 100;

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCategoryIcon(category),
                  color: _getCategoryColor(category),
                ),
              ),
              title: Text(category),
              subtitle: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCategoryColor(category),
                        ),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${percentage.toStringAsFixed(0)}%'),
                ],
              ),
              trailing: Text(
                'Rs ${amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBudgetsTab() {
    return _budgets.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 70,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'No budgets set',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Set budgets to track your spending',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showSetBudgetBottomSheet,
                icon: const Icon(Icons.add),
                label: const Text('Set Budget'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        )
        : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _budgets.length,
          itemBuilder: (context, index) {
            final budget = _budgets[index];
            final utilization = _budgetUtilization[budget.category] ?? 0.0;

            return BudgetCategoryCard(
              budget: budget,
              utilization: utilization,
              onTap: () => _navigateToExpenseDetails(budget.category),
            );
          },
        );
  }

  Widget _buildExpensesTab() {
    // Filter expenses for the selected month/year
    final monthlyExpenses =
        _expenses.where((expense) {
          final expenseDate = DateTime.fromMillisecondsSinceEpoch(expense.date);
          return expenseDate.month == _selectedMonth &&
              expenseDate.year == _selectedYear;
        }).toList();

    // Sort by date (newest first)
    monthlyExpenses.sort((a, b) => b.date.compareTo(a.date));

    return monthlyExpenses.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 70,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'No expenses yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add expenses to track your spending',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _showAddExpenseBottomSheet,
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        )
        : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: monthlyExpenses.length,
          itemBuilder: (context, index) {
            final expense = monthlyExpenses[index];
            final date = DateTime.fromMillisecondsSinceEpoch(expense.date);

            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(expense.category).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.category),
                    color: _getCategoryColor(expense.category),
                    size: 24,
                  ),
                ),
                title: Text(
                  expense.description.isNotEmpty
                      ? expense.description
                      : expense.category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      expense.category,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(date),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  'Rs ${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            );
          },
        );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'shopping':
        return Icons.shopping_bag;
      case 'transportation':
        return Icons.directions_car;
      case 'housing':
        return Icons.home;
      case 'utilities':
        return Icons.bolt;
      case 'entertainment':
        return Icons.movie;
      case 'healthcare':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'personal':
        return Icons.person;
      case 'travel':
        return Icons.flight;
      case 'savings':
        return Icons.savings;
      case 'investments':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'shopping':
        return Colors.purple;
      case 'transportation':
        return Colors.blue;
      case 'housing':
        return Colors.brown;
      case 'utilities':
        return Colors.amber;
      case 'entertainment':
        return Colors.pink;
      case 'healthcare':
        return Colors.red;
      case 'education':
        return Colors.indigo;
      case 'personal':
        return Colors.teal;
      case 'travel':
        return Colors.green;
      case 'savings':
        return Colors.blueGrey;
      case 'investments':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  double _getTotalSpending() {
    double total = 0;
    for (var amount in _categorySpending.values) {
      total += amount;
    }
    return total;
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
