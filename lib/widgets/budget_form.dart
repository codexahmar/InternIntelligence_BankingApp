import 'package:flutter/material.dart';

class BudgetForm extends StatefulWidget {
  final Function(String category, double amount) onSetBudget;

  const BudgetForm({Key? key, required this.onSetBudget}) : super(key: key);

  @override
  State<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCategory;

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
            'Set New Budget',
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
              labelText: 'Monthly Budget Amount',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.currency_rupee),
              helperText: 'Set your monthly spending limit for this category',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a budget amount';
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
          const SizedBox(height: 24),
          // Category Information
          if (_selectedCategory != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Setting a budget for $_selectedCategory will help you track and limit your spending in this category.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
              child: const Text('Set Budget', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);

      widget.onSetBudget(_selectedCategory!, amount);

      // Clear form
      _amountController.clear();
      setState(() {
        _selectedCategory = null;
      });

      // Close the bottom sheet
      Navigator.pop(context);
    }
  }
}
