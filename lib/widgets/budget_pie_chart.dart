import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BudgetPieChart extends StatelessWidget {
  final Map<String, double> categorySpending;
  final double totalSpending;

  const BudgetPieChart({
    Key? key,
    required this.categorySpending,
    required this.totalSpending,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entries =
        categorySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Limit to top 5 categories, and combine the rest
    final topCategories = entries.take(5).toList();
    double otherAmount = 0;
    if (entries.length > 5) {
      for (int i = 5; i < entries.length; i++) {
        otherAmount += entries[i].value;
      }
      if (otherAmount > 0) {
        topCategories.add(MapEntry('Other', otherAmount));
      }
    }

    // Prepare chart data
    final sections = <PieChartSectionData>[];
    final categoryColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.grey,
    ];

    for (int i = 0; i < topCategories.length; i++) {
      final entry = topCategories[i];
      sections.add(
        PieChartSectionData(
          color: categoryColors[i % categoryColors.length],
          value: entry.value,
          title: '${(entry.value / totalSpending * 100).toStringAsFixed(0)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...List.generate(topCategories.length, (index) {
                final category = topCategories[index].key;
                final color = categoryColors[index % categoryColors.length];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
