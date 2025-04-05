import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:banking_app/providers/user_provider.dart';
import 'package:banking_app/models/transaction.dart' as app_transaction;
import 'package:banking_app/models/account.dart';
import 'package:banking_app/widgets/transaction_filter_sheet.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<app_transaction.Transaction> _filteredTransactions = [];
  bool _isFiltering = false;
  DateTimeRange? _dateRange;
  String? _transactionType;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _updateFilteredTransactions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateFilteredTransactions();
  }

  void _updateFilteredTransactions() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final transactions = userProvider.recentTransactions;
    final accounts = userProvider.userAccounts;
    final userAccountIds = accounts.map((a) => a.id).toSet();

    // Debug print
    print('Updating filtered transactions. Total: ${transactions.length}');
    print('User accounts: ${accounts.length}, IDs: $userAccountIds');

    setState(() {
      _filteredTransactions =
          transactions.where((transaction) {
            // Filter by date range
            if (_dateRange != null) {
              final transactionDate = DateTime.fromMillisecondsSinceEpoch(
                transaction.timestamp,
              );
              if (transactionDate.isBefore(_dateRange!.start) ||
                  transactionDate.isAfter(
                    _dateRange!.end.add(const Duration(days: 1)),
                  )) {
                return false;
              }
            }

            // Filter by transaction type
            if (_transactionType != null) {
              final isFromUserAccount = userAccountIds.contains(
                transaction.fromAccountId,
              );
              final isToUserAccount = userAccountIds.contains(
                transaction.toAccountId,
              );

              print(
                'Transaction ${transaction.id} - From: ${transaction.fromAccountId}, To: ${transaction.toAccountId}',
              );
              print(
                'isFromUserAccount: $isFromUserAccount, isToUserAccount: $isToUserAccount',
              );

              if (_transactionType == 'Sent' &&
                  !(isFromUserAccount && !isToUserAccount)) {
                return false;
              } else if (_transactionType == 'Received' &&
                  !(!isFromUserAccount && isToUserAccount)) {
                return false;
              } else if (_transactionType == 'Transfer' &&
                  !(isFromUserAccount && isToUserAccount)) {
                return false;
              }
            }

            // Filter by account
            if (_accountId != null) {
              return transaction.fromAccountId == _accountId ||
                  transaction.toAccountId == _accountId;
            }

            return true;
          }).toList();

      print('Filtered transactions: ${_filteredTransactions.length}');

      _isFiltering =
          _dateRange != null || _transactionType != null || _accountId != null;
    });
  }

  void _showFilterBottomSheet() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final accounts = userProvider.userAccounts;

    // Convert accounts to map format for the filter sheet
    final accountsForFilter =
        accounts.map((account) {
          return {
            'id': account.id,
            'type': account.type,
            'accountNumber': account.accountNumber,
          };
        }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: TransactionFilterSheet(
            currentDateRange: _dateRange,
            currentTransactionType: _transactionType,
            currentAccountId: _accountId,
            accounts: accountsForFilter,
            onApplyFilter: (dateRange, transactionType, accountId) {
              setState(() {
                _dateRange = dateRange;
                _transactionType = transactionType;
                _accountId = accountId;
              });
              _updateFilteredTransactions();
            },
          ),
        );
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _dateRange = null;
      _transactionType = null;
      _accountId = null;
      _isFiltering = false;
    });
    _updateFilteredTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final transactions = userProvider.recentTransactions;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (_isFiltering)
                      GestureDetector(
                        onTap: _clearFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.close,
                                color: Colors.red.shade700,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Clear',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: _showFilterBottomSheet,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isFiltering)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    color: Theme.of(context).primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildFilterDescription(),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child:
                _filteredTransactions.isEmpty
                    ? _buildEmptyState(transactions.isEmpty)
                    : _buildTransactionsList(context, _filteredTransactions),
          ),
        ],
      ),
    );
  }

  String _buildFilterDescription() {
    List<String> filters = [];

    if (_dateRange != null) {
      filters.add(
        'Date: ${DateFormat('MMM d').format(_dateRange!.start)} - ${DateFormat('MMM d').format(_dateRange!.end)}',
      );
    }

    if (_transactionType != null) {
      filters.add('Type: $_transactionType');
    }

    if (_accountId != null) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final accounts = userProvider.userAccounts;
      final account = accounts.firstWhere(
        (a) => a.id == _accountId,
        orElse: () => throw Exception('Account not found'),
      );
      filters.add(
        'Account: ${account.accountNumber.substring(account.accountNumber.length - 4)}',
      );
    }

    return filters.join(' • ');
  }

  Widget _buildEmptyState(bool noTransactions) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isFiltering ? Icons.filter_list : Icons.receipt_long,
            size: 70,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _isFiltering
                ? 'No transactions match your filters'
                : 'No transactions yet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _isFiltering
                ? 'Try adjusting your filters'
                : 'Your transaction history will appear here',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          if (_isFiltering) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionsList(
    BuildContext context,
    List<app_transaction.Transaction> transactions,
  ) {
    final userProvider = Provider.of<UserProvider>(context);
    final accounts = userProvider.userAccounts;
    final userAccountIds = accounts.map((a) => a.id).toSet();

    // Group transactions by date
    final Map<String, List<app_transaction.Transaction>> groupedTransactions =
        {};

    for (final transaction in transactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(transaction.timestamp);
      final dateString = DateFormat('yyyy-MM-dd').format(date);

      if (!groupedTransactions.containsKey(dateString)) {
        groupedTransactions[dateString] = [];
      }

      groupedTransactions[dateString]!.add(transaction);
    }

    // Sort the dates in descending order
    final sortedDates =
        groupedTransactions.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final dateString = sortedDates[dateIndex];
        final date = DateTime.parse(dateString);
        final transactionsForDate = groupedTransactions[dateString]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                _formatDateHeader(date),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            ...transactionsForDate.map((transaction) {
              final fromAccount = accounts.firstWhere(
                (a) => a.id == transaction.fromAccountId,
                orElse:
                    () => Account(
                      id: '',
                      userId: '',
                      accountNumber: '',
                      balance: 0,
                      type: '',
                    ),
              );

              final toAccount = accounts.firstWhere(
                (a) => a.id == transaction.toAccountId,
                orElse:
                    () => Account(
                      id: '',
                      userId: '',
                      accountNumber: '',
                      balance: 0,
                      type: '',
                    ),
              );

              final isOutgoing =
                  userAccountIds.contains(fromAccount.id) &&
                  !userAccountIds.contains(toAccount.id);
              final isIncoming =
                  !userAccountIds.contains(fromAccount.id) &&
                  userAccountIds.contains(toAccount.id);
              final isTransfer =
                  userAccountIds.contains(fromAccount.id) &&
                  userAccountIds.contains(toAccount.id);

              final transactionColor =
                  isOutgoing
                      ? Colors.red
                      : isIncoming
                      ? Colors.green
                      : Theme.of(context).primaryColor;

              final transactionIcon =
                  isOutgoing
                      ? Icons.arrow_upward
                      : isIncoming
                      ? Icons.arrow_downward
                      : Icons.swap_horiz;

              final amountPrefix =
                  isOutgoing
                      ? '-'
                      : isIncoming
                      ? '+'
                      : '';

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: transactionColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(transactionIcon, color: transactionColor),
                  ),
                  title: Text(
                    isOutgoing
                        ? 'To: ${transaction.externalAccountNumber ?? "External Account"}'
                        : isIncoming
                        ? 'From: External Account'
                        : 'Transfer between accounts',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOutgoing
                            ? fromAccount.accountNumber
                            : isIncoming
                            ? toAccount.accountNumber
                            : '${fromAccount.accountNumber.substring(math.max(0, fromAccount.accountNumber.length - 4))} → ${toAccount.accountNumber.substring(math.max(0, toAccount.accountNumber.length - 4))}',
                      ),
                      if (transaction.note.isNotEmpty)
                        Text(
                          transaction.note,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$amountPrefix Rs ${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: transactionColor,
                        ),
                      ),
                      Text(
                        DateFormat('h:mm a').format(
                          DateTime.fromMillisecondsSinceEpoch(
                            transaction.timestamp,
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showTransactionDetails(transaction),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d').format(date);
    }
  }

  void _showTransactionDetails(app_transaction.Transaction transaction) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final accounts = userProvider.userAccounts;
    final userAccountIds = accounts.map((a) => a.id).toSet();

    final fromAccount = accounts.firstWhere(
      (a) => a.id == transaction.fromAccountId,
      orElse:
          () => Account(
            id: '',
            userId: '',
            accountNumber: '',
            balance: 0,
            type: '',
          ),
    );

    final toAccount = accounts.firstWhere(
      (a) => a.id == transaction.toAccountId,
      orElse:
          () => Account(
            id: '',
            userId: '',
            accountNumber: '',
            balance: 0,
            type: '',
          ),
    );

    final isOutgoing =
        userAccountIds.contains(fromAccount.id) &&
        !userAccountIds.contains(toAccount.id);
    final isIncoming =
        !userAccountIds.contains(fromAccount.id) &&
        userAccountIds.contains(toAccount.id);
    final isTransfer =
        userAccountIds.contains(fromAccount.id) &&
        userAccountIds.contains(toAccount.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Transaction Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(thickness: 1.2, height: 32),

                    // Icon + Amount
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color:
                                  isOutgoing
                                      ? Colors.red.withOpacity(0.1)
                                      : isIncoming
                                      ? Colors.green.withOpacity(0.1)
                                      : Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isOutgoing
                                  ? Icons.arrow_upward
                                  : isIncoming
                                  ? Icons.arrow_downward
                                  : Icons.swap_horiz,
                              color:
                                  isOutgoing
                                      ? Colors.red
                                      : isIncoming
                                      ? Colors.green
                                      : Theme.of(context).primaryColor,
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Rs ${transaction.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            isOutgoing
                                ? 'Sent'
                                : isIncoming
                                ? 'Received'
                                : 'Transferred',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            DateFormat('MMMM d, yyyy • h:mm a').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                transaction.timestamp,
                              ),
                            ),
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),

                    const Divider(thickness: 1.2, height: 40),

                    // Transaction Info
                    if (transaction.note.isNotEmpty) ...[
                      _buildDetailRow('Note', transaction.note),
                      const SizedBox(height: 16),
                    ],
                    if (fromAccount.id.isNotEmpty) ...[
                      _buildDetailRow(
                        'From',
                        '${fromAccount.type} Account (${_formatAccountNumber(fromAccount.accountNumber)})',
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (toAccount.id.isNotEmpty) ...[
                      _buildDetailRow(
                        'To',
                        '${toAccount.type} Account (${_formatAccountNumber(toAccount.accountNumber)})',
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (isOutgoing &&
                        !userAccountIds.contains(toAccount.id) &&
                        transaction.externalAccountNumber != null) ...[
                      _buildDetailRow(
                        'To',
                        _formatAccountNumber(
                          transaction.externalAccountNumber!,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildDetailRow('Transaction Type', transaction.type),
                    const SizedBox(height: 10),
                    _buildDetailRow('Status', transaction.status),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      'Transaction ID',
                      transaction.id.substring(0, 8),
                    ),

                    const SizedBox(height: 40),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Close'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    return 'x${accountNumber.substring(accountNumber.length - 4)}';
  }
}
