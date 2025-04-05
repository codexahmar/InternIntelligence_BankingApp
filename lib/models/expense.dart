class Expense {
  final String id;
  final String userId;
  final String category;
  final double amount;
  final String description;
  final int date;

  Expense({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      userId: map['userId'],
      category: map['category'],
      amount: map['amount'],
      description: map['description'],
      date: map['date'],
    );
  }
}
