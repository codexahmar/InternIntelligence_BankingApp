import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:banking_app/models/account.dart';

import 'package:banking_app/providers/user_provider.dart';
import 'package:banking_app/utils/firebase_firestore_service.dart';
import 'package:banking_app/screens/otp_screen.dart';

class TransferScreen extends StatefulWidget {
  final Account? fromAccount;

  const TransferScreen({Key? key, this.fromAccount}) : super(key: key);

  @override
  _TransferScreenState createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _firestoreService = FirestoreService();

  Account? _selectedFromAccount;
  Account? _selectedToAccount;
  bool _isLoading = false;
  bool _isExternalTransfer = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedFromAccount = widget.fromAccount;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _initiateTransfer() async {
    // Validate form
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final double amount = double.parse(_amountController.text);

        // Check sufficient funds
        if (_selectedFromAccount!.balance < amount) {
          setState(() {
            _errorMessage = 'Insufficient funds';
            _isLoading = false;
          });
          return;
        }

        // Generate OTP for verification
        final otp = await userProvider.generateOTP();

        // Navigate to OTP verification screen
        if (!mounted) return;

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => OTPScreen(
                  otp: otp,
                  isTransfer: true,
                  onVerified: () async {
                    // Process transfer and handle navigation
                    try {
                      await _processTransfer(amount);

                      if (!mounted) return;
                      // Pop both screens at once to avoid state issues
                      Navigator.popUntil(context, (route) => route.isFirst);
                    } catch (e) {
                      if (!mounted) return;
                      Navigator.pop(context); // Just pop OTP screen on error
                      setState(() {
                        _errorMessage = 'Transfer failed: ${e.toString()}';
                        _isLoading = false;
                      });
                    }
                  },
                ),
          ),
        );

        // Reset loading state if we return without completing transfer
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processTransfer(double amount) async {
    try {
      bool success = false;

      if (_isExternalTransfer) {
        // Process external transfer using account number
        success = await _firestoreService.processExternalTransfer(
          fromAccountId: _selectedFromAccount!.id,
          externalAccountNumber: _accountNumberController.text.trim(),
          amount: amount,
          note: _noteController.text,
        );
      } else {
        // Process internal transfer between user accounts
        success = await _firestoreService.processInternalTransfer(
          fromAccountId: _selectedFromAccount!.id,
          toAccountId: _selectedToAccount!.id,
          amount: amount,
          note: _noteController.text,
        );
      }

      if (!mounted) return;

      if (success) {
        // Refresh user accounts
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUserAccounts();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userAccounts = userProvider.userAccounts;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.6),
              Colors.white,
            ],
            stops: const [0.0, 0.2, 0.4],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Transfer type selector
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.swap_horiz,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Transfer Type',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SwitchListTile(
                                  title: Text(
                                    _isExternalTransfer
                                        ? 'External Transfer'
                                        : 'Between My Accounts',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  value: _isExternalTransfer,
                                  activeColor: Theme.of(context).primaryColor,
                                  onChanged: (value) {
                                    setState(() {
                                      _isExternalTransfer = value;
                                      _selectedToAccount = null;
                                    });
                                  },
                                  dense: true,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // From Account Selector
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'From Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<Account>(
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            value: _selectedFromAccount,
                            hint: const Text('Select source account'),
                            items:
                                userAccounts
                                    .map(
                                      (account) => DropdownMenuItem<Account>(
                                        value: account,
                                        key: ValueKey(
                                          account.id,
                                        ), // Add unique key
                                        child: Text(
                                          '${account.type} - ${account.accountNumber} (Rs${account.balance.toStringAsFixed(2)})',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (Account? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedFromAccount = value;
                                  // Reset destination account if it's the same as source
                                  if (_selectedToAccount?.id == value.id) {
                                    _selectedToAccount = null;
                                  }
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a source account';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // To Account Selector
                    if (!_isExternalTransfer)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'To Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Account>(
                              dropdownColor: Colors.white,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              value: _selectedToAccount,
                              hint: const Text('Select destination account'),
                              items:
                                  userAccounts
                                      .where(
                                        (account) =>
                                            account.id !=
                                            _selectedFromAccount?.id,
                                      )
                                      .map(
                                        (account) => DropdownMenuItem<Account>(
                                          value: account,
                                          key: ValueKey(
                                            account.id,
                                          ), // Add unique key
                                          child: Text(
                                            '${account.type} - ${account.accountNumber}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (Account? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedToAccount = value;
                                  });
                                }
                              },
                              validator: (value) {
                                if (!_isExternalTransfer && value == null) {
                                  return 'Please select a destination account';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Recipient Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _accountNumberController,
                              decoration: InputDecoration(
                                labelText: 'Recipient Account Number',
                                hintText: 'XXXX-XXXX-XXXX-XXXX',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (value) {
                                if (_isExternalTransfer &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please enter recipient account number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Amount and Note
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.money,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Amount & Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixText: 'Rs ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an amount';
                              }

                              final double? amount = double.tryParse(value);
                              if (amount == null) {
                                return 'Please enter a valid number';
                              }

                              if (amount <= 0) {
                                return 'Amount must be greater than zero';
                              }

                              if (_selectedFromAccount != null &&
                                  amount > _selectedFromAccount!.balance) {
                                return 'Insufficient funds';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              labelText: 'Note (Optional)',
                              hintText: 'e.g. Rent payment',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            maxLength: 50,
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Security info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Icon(Icons.security, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Security Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'For your security, this transaction will require verification with a 6-digit OTP sent to your registered mobile number.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _initiateTransfer,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Continue',
                                  style: TextStyle(fontSize: 16),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
