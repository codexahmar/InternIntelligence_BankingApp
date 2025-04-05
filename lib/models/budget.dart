class Budget {
  final String id;
  final String userId;
  final String category;
  final double amount;
  final int month;
  final int year;

  Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.month,
    required this.year,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'amount': amount,
      'month': month,
      'year': year,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      userId: map['userId'],
      category: map['category'],
      amount: map['amount'],
      month: map['month'],
      year: map['year'],
    );
  }
}
