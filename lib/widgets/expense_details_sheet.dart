import 'package:flutter/material.dart';
import 'package:banking_app/models/budget.dart';
import 'package:banking_app/models/expense.dart';
import 'package:banking_app/utils/budget_utils.dart';
import 'package:intl/intl.dart';

class ExpenseDetailsSheet extends StatelessWidget {
  final String category;
  final Budget budget;
  final double totalSpent;
  final List<Expense> expenses;
  final Function(Expense) onEditExpense;
  final Function(String) onDeleteExpense;

  const ExpenseDetailsSheet({
    Key? key,
    required this.category,
    required this.budget,
    required this.totalSpent,
    required this.expenses,
    required this.onEditExpense,
    required this.onDeleteExpense,
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

  void _showDeleteConfirmation(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Expense'),
            content: Text('Are you sure you want to delete this expense?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onDeleteExpense(expense.id);
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BudgetUtils.getCategoryColor(
                        category,
                      ).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      BudgetUtils.getCategoryIcon(category),
                      color: BudgetUtils.getCategoryColor(category),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    category,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _budgetRow(
                        'Budget',
                        'Rs ${budget.amount.toStringAsFixed(2)}',
                        Colors.blue,
                      ),
                      SizedBox(height: 8),
                      _budgetRow(
                        'Spent',
                        'Rs ${totalSpent.toStringAsFixed(2)}',
                        Colors.red,
                      ),
                      SizedBox(height: 8),
                      _budgetRow(
                        'Remaining',
                        'Rs ${(budget.amount - totalSpent).toStringAsFixed(2)}',
                        totalSpent > budget.amount ? Colors.red : Colors.green,
                      ),
                      SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalSpent / budget.amount,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            totalSpent > budget.amount
                                ? Colors.red
                                : Colors.green,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              Text(
                'Expenses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              ...expenses.map((expense) {
                final date = DateTime.fromMillisecondsSinceEpoch(expense.date);
                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(Icons.receipt, color: Colors.blue),
                    ),
                    title: Text(
                      expense.description.isNotEmpty
                          ? expense.description
                          : 'Expense on ${DateFormat('MMM d').format(date)}',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      DateFormat('MMM d, yyyy').format(date),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rs ${expense.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEditExpense(expense);
                            } else if (value == 'delete') {
                              _showDeleteConfirmation(context, expense);
                            }
                          },
                          itemBuilder:
                              (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
