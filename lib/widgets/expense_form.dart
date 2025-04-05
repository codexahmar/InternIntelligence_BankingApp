import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseForm extends StatefulWidget {
  final Function(String category, double amount, String description, int date)
  onAddExpense;

  const ExpenseForm({Key? key, required this.onAddExpense}) : super(key: key);

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  // List of expense categories
  final List<String> _categories = [
    'Food',
    'Shopping',
    'Transportation',
    'Housing',
    'Utilities',
    'Entertainment',
    'Healthcare',
    'Education',
    'Personal',
    'Travel',
    'Savings',
    'Investments',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Expense',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Category Dropdown
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            hint: const Text('Select Category'),
            isExpanded: true,
            items:
                _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a category';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Amount Field
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.currency_rupee),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid amount';
              }
              if (double.parse(value) <= 0) {
                return 'Amount must be greater than zero';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Description Field
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          // Date Picker
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add Expense', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text.trim();
      final timestamp = _selectedDate.millisecondsSinceEpoch;

      widget.onAddExpense(_selectedCategory!, amount, description, timestamp);

      // Clear form
      _amountController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedCategory = null;
        _selectedDate = DateTime.now();
      });

      // Close the bottom sheet
      Navigator.pop(context);
    }
  }
}
