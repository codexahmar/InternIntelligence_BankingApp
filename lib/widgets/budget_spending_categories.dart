import 'package:flutter/material.dart';
import 'package:banking_app/utils/budget_utils.dart';

class SpendingCategories extends StatelessWidget {
  final Map<String, double> categorySpending;
  final double totalSpending;

  const SpendingCategories({
    Key? key,
    required this.categorySpending,
    required this.totalSpending,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entries =
        categorySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 3 categories
    final topCategories = entries.take(3).toList();

    return Column(
      children: [
        ...topCategories.map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final percentage = (amount / totalSpending) * 100;

          return Card(
            color: Colors.white,
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BudgetUtils.getCategoryColor(
                    category,
                  ).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  BudgetUtils.getCategoryIcon(category),
                  color: BudgetUtils.getCategoryColor(category),
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
                          BudgetUtils.getCategoryColor(category),
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
}
