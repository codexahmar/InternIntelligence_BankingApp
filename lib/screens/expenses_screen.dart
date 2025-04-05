import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:banking_app/models/expense.dart';
import 'package:banking_app/providers/user_provider.dart';
import 'package:banking_app/utils/budget_service.dart';

class ExpensesScreen extends StatefulWidget {
  @override
  _ExpensesScreenState createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final BudgetService _budgetService = BudgetService();
  final Uuid _uuid = Uuid();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;
  String? _selectedCategory;
  List<Expense> _expenses = [];
  DateTime _selectedDate = DateTime.now();

  // Predefined categories (same as in BudgetScreen)
  final List<String> _categories = [
    'Housing',
    'Transportation',
    'Food',
    'Utilities',
    'Entertainment',
    'Healthcare',
    'Shopping',
    'Personal',
    'Education',
    'Misc',
  ];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id ?? _uuid.v4();

      // Load expenses
      _expenses = await _budgetService.getUserExpenses(userId);

      // Sort expenses by date (most recent first)
      _expenses.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      print('Error loading expenses: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addExpense() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a category')));
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a description')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.currentUser?.id ?? _uuid.v4();

      // Add expense
      await _budgetService.addExpense(
        userId: userId,
        category: _selectedCategory!,
        amount: amount,
        description: _descriptionController.text,
        date: _selectedDate,
      );

      // Reload expenses
      await _loadExpenses();

      // Clear form
      _amountController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedCategory = null;
        _selectedDate = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding expense: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Expense Tracker')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExpenseForm(),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Expenses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _loadExpenses,
                          child: Text('Refresh'),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    _buildExpensesList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildExpenseForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Expense',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  hint: Text('Select category'),
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down),
                  items:
                      _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter amount',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Enter description',
              ),
            ),
            SizedBox(height: 16),
            InkWell(
              onTap: _selectDate,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy').format(_selectedDate),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _addExpense,
                child: Text('Add Expense', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesList() {
    if (_expenses.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('No expenses recorded yet')),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final expense = _expenses[index];
        final date = DateTime.fromMillisecondsSinceEpoch(expense.date);

        return Card(
          margin: EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(
                _getCategoryIcon(expense.category),
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              expense.description,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${expense.category} • ${DateFormat('MMM dd, yyyy').format(date)}',
            ),
            trailing: Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red[700],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Housing':
        return Icons.home;
      case 'Transportation':
        return Icons.directions_car;
      case 'Food':
        return Icons.restaurant;
      case 'Utilities':
        return Icons.power;
      case 'Entertainment':
        return Icons.movie;
      case 'Healthcare':
        return Icons.medical_services;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Personal':
        return Icons.person;
      case 'Education':
        return Icons.school;
      default:
        return Icons.attach_money;
    }
  }
}
