import 'package:flutter/material.dart';

class BudgetUtils {
  static IconData getCategoryIcon(String category) {
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

  static Color getCategoryColor(String category) {
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
