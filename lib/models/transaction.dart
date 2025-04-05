class Transaction {
  final String id;
  final String fromAccountId;
  final String toAccountId;
  final double amount;
  final int timestamp;
  final String type;
  final String status;
  final String note;
  final String? externalAccountNumber;

  Transaction({
    required this.id,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.timestamp,
    required this.type,
    required this.status,
    required this.note,
    this.externalAccountNumber,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      fromAccountId: map['fromAccountId'],
      toAccountId: map['toAccountId'],
      amount: map['amount'],
      timestamp: map['timestamp'],
      type: map['type'],
      status: map['status'],
      note: map['note'],
      externalAccountNumber: map['externalAccountNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      'amount': amount,
      'timestamp': timestamp,
      'type': type,
      'status': status,
      'note': note,
      'externalAccountNumber': externalAccountNumber,
    };
  }
}
