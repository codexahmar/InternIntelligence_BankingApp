import 'package:flutter/material.dart';
import 'package:banking_app/models/budget.dart';
import 'package:banking_app/models/expense.dart';
import 'package:intl/intl.dart';

class ExpenseDetailsSheet extends StatelessWidget {
  final String category;
  final Budget budget;
  final double totalSpent;
  final List<Expense> expenses;

  const ExpenseDetailsSheet({
    Key? key,
    required this.category,
    required this.budget,
    required this.totalSpent,
    required this.expenses,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      totalSpent > budget.amount ? Colors.red : Colors.green,
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
                    expenses.isEmpty
                        ? Center(
                          child: Text(
                            'No expenses found for $category',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                        : ListView.builder(
                          controller: scrollController,
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenses[index];
                            final date = DateTime.fromMillisecondsSinceEpoch(
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
                                  style: TextStyle(color: Colors.grey.shade600),
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
  }
}
