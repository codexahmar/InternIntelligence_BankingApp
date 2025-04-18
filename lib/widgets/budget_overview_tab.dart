import 'package:flutter/material.dart';
import 'package:banking_app/widgets/budget_pie_chart.dart';
import 'package:banking_app/widgets/budget_spending_categories.dart';

class BudgetOverviewTab extends StatelessWidget {
  final double totalBudget;
  final double totalSpending;
  final Map<String, double> categorySpending;

  const BudgetOverviewTab({
    Key? key,
    required this.totalBudget,
    required this.totalSpending,
    required this.categorySpending,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
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
          if (categorySpending.isNotEmpty) ...[
            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BudgetPieChart(
                categorySpending: categorySpending,
                totalSpending: totalSpending,
              ),
            ),
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
          if (categorySpending.isNotEmpty) ...[
            const Text(
              'Top Spending Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SpendingCategories(
              categorySpending: categorySpending,
              totalSpending: totalSpending,
            ),
          ],
        ],
      ),
    );
  }
}
