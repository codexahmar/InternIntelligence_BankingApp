import 'package:flutter/material.dart';
import 'package:banking_app/models/budget.dart';

class BudgetForm extends StatefulWidget {
  final Function(String category, double amount) onSetBudget;
  final Budget? initialBudget;

  const BudgetForm({Key? key, required this.onSetBudget, this.initialBudget})
    : super(key: key);

  @override
  State<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCategory;

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
  void initState() {
    super.initState();
    if (widget.initialBudget != null) {
      _amountController.text = widget.initialBudget!.amount.toString();
      _selectedCategory = widget.initialBudget!.category;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      widget.onSetBudget(_selectedCategory!, amount);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.initialBudget != null ? 'Edit Budget' : 'Set Budget',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            hint: Text('Select Category'),
            isExpanded: true,
            items:
                _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
            onChanged:
                widget.initialBudget != null
                    ? null // Disable category change for existing budgets
                    : (value) {
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
          SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an amount';
              }
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) {
                return 'Please enter a valid amount';
              }
              return null;
            },
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submitForm,
              child: Text(
                widget.initialBudget != null ? 'Update Budget' : 'Set Budget',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}
