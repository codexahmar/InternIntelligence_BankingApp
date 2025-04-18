class Account {
  final String id;
  final String userId;
  final String accountNumber;
  final double balance;
  final String type;

  Account({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.balance,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'accountNumber': accountNumber,
      'balance': balance,
      'type': type,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      userId: map['userId'],
      accountNumber: map['accountNumber'],
      balance: map['balance'],
      type: map['type'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
