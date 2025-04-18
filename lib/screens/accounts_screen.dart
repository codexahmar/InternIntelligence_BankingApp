import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:banking_app/providers/user_provider.dart';
import 'package:banking_app/models/account.dart';
import 'package:banking_app/screens/transfer_screen.dart';
import 'package:intl/intl.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final accounts = userProvider.userAccounts;
    final currencyFormat = NumberFormat.currency(symbol: 'Rs');

    double totalBalance = 0;
    for (var account in accounts) {
      totalBalance += account.balance;
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade800, Colors.blue.shade600],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Balance',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(totalBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildActionButton(
                          context,
                          'Add Money',
                          Icons.add_circle_outline,
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Add money feature coming soon'),
                              ),
                            );
                          },
                        ),
                        _buildActionButton(
                          context,
                          'Transfer',
                          Icons.swap_horiz,
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransferScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionButton(
                          context,
                          'Statement',
                          Icons.receipt_long,
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Statement feature coming soon'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // const SizedBox(height: 24),
            // const Text(
            //   'Your Accounts',
            //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            // ),
            Expanded(
              child:
                  accounts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                        itemCount: accounts.length,
                        itemBuilder: (context, index) {
                          return _buildAccountCard(
                            context,
                            accounts[index],
                            currencyFormat,
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
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
            'No accounts found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add an account to get started',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    BuildContext context,
    Account account,
    NumberFormat formatter,
  ) {
    Color cardColor;
    IconData iconData;

    // Set color and icon based on account type
    switch (account.type.toLowerCase()) {
      case 'savings':
        cardColor = Colors.green.shade100;
        iconData = Icons.savings;
        break;
      case 'checking':
        cardColor = Colors.blue.shade100;
        iconData = Icons.account_balance;
        break;
      case 'investment':
        cardColor = Colors.purple.shade100;
        iconData = Icons.trending_up;
        break;
      default:
        cardColor = Colors.indigo.shade100;
        iconData = Icons.credit_card;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: cardColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: cardColor.withGreen(100), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${account.type} Account',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Account No: ${_formatAccountNumber(account.accountNumber)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatter.format(account.balance),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Available Balance',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatAccountNumber(String accountNumber) {
    if (accountNumber.contains('-')) {
      return accountNumber;
    }

    if (accountNumber.length == 16) {
      return '${accountNumber.substring(0, 4)}-'
          '${accountNumber.substring(4, 8)}-'
          '${accountNumber.substring(8, 12)}-'
          '${accountNumber.substring(12, 16)}';
    }

    return accountNumber;
  }
}
