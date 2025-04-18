import 'package:flutter/material.dart';
import 'package:banking_app/models/budget.dart';
import 'package:banking_app/widgets/budget_category_card.dart';

class BudgetListTab extends StatelessWidget {
  final List<Budget> budgets;
  final Map<String, double> budgetUtilization;
  final Function() onAddBudget;
  final Function(String) onCategoryTap;

  const BudgetListTab({
    Key? key,
    required this.budgets,
    required this.budgetUtilization,
    required this.onAddBudget,
    required this.onCategoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          budgets.isEmpty
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set budgets to track your spending',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: onAddBudget,
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
                itemCount: budgets.length,
                itemBuilder: (context, index) {
                  final budget = budgets[index];
                  final utilization = budgetUtilization[budget.category] ?? 0.0;

                  return BudgetCategoryCard(
                    budget: budget,
                    utilization: utilization,
                    onTap: () => onCategoryTap(budget.category),
                  );
                },
              ),
      floatingActionButton:
          budgets.isNotEmpty
              ? FloatingActionButton(
                onPressed: onAddBudget,
                child: const Icon(Icons.add),
                tooltip: 'Add Budget',
              )
              : null,
    );
  }
}
