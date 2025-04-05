import 'package:flutter/material.dart';
import 'package:banking_app/models/budget.dart';

class BudgetCategoryCard extends StatelessWidget {
  final Budget budget;
  final double utilization;
  final VoidCallback onTap;

  const BudgetCategoryCard({
    Key? key,
    required this.budget,
    required this.utilization,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine color based on utilization percentage
    Color progressColor;
    if (utilization <= 50) {
      progressColor = Colors.green;
    } else if (utilization <= 80) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              budget.category,
                            ).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getCategoryIcon(budget.category),
                            color: _getCategoryColor(budget.category),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            budget.category,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rs ${budget.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: utilization / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                        minHeight: 8,
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
                      color: progressColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${utilization.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Show remaining amount text
              Text(
                'Remaining: Rs ${(budget.amount - (budget.amount * utilization / 100)).toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
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
}
