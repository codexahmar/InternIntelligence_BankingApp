import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionFilterSheet extends StatefulWidget {
  final Function(
    DateTimeRange? dateRange,
    String? transactionType,
    String? accountId,
  )
  onApplyFilter;
  final DateTimeRange? currentDateRange;
  final String? currentTransactionType;
  final String? currentAccountId;
  final List<Map<String, dynamic>> accounts;

  const TransactionFilterSheet({
    Key? key,
    required this.onApplyFilter,
    this.currentDateRange,
    this.currentTransactionType,
    this.currentAccountId,
    required this.accounts,
  }) : super(key: key);

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  DateTimeRange? _selectedDateRange;
  String? _selectedTransactionType;
  String? _selectedAccountId;
  final List<String> _transactionTypes = [
    'All',
    'Sent',
    'Received',
    'Transfer',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDateRange = widget.currentDateRange;
    _selectedTransactionType = widget.currentTransactionType;
    _selectedAccountId = widget.currentAccountId;
  }

  @override
  Widget build(BuildContext context) {
    print('TransactionFilterSheet is being built');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Transactions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'Date Range',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectDateRange(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDateRange != null
                        ? '${DateFormat('MMM d, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}'
                        : 'Select date range',
                    style: TextStyle(
                      color:
                          _selectedDateRange != null
                              ? Colors.black
                              : Colors.grey.shade600,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Transaction Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                _transactionTypes.map((type) {
                  final isSelected =
                      _selectedTransactionType == type ||
                      (_selectedTransactionType == null && type == 'All');
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTransactionType = selected ? type : null;
                      });
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      color:
                          isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.black,
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),

          const Text(
            'Account',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedAccountId,
                isExpanded: true,
                hint: const Text('All Accounts'),
                icon: const Icon(Icons.arrow_drop_down),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Accounts'),
                  ),
                  ...widget.accounts.map((account) {
                    return DropdownMenuItem<String>(
                      value: account['id'],
                      child: Text(
                        '${account['type']} (${account['accountNumber'].substring(account['accountNumber'].length - 4)})',
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedAccountId = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedDateRange = null;
                    _selectedTransactionType = null;
                    _selectedAccountId = null;
                  });
                },
                child: const Text('Reset Filters'),
              ),
              ElevatedButton(
                onPressed: () {
                  widget.onApplyFilter(
                    _selectedDateRange,
                    _selectedTransactionType == 'All'
                        ? null
                        : _selectedTransactionType,
                    _selectedAccountId,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Apply Filter'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange =
        _selectedDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 30)),
          end: DateTime.now(),
        );

    final newDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDateRange != null) {
      setState(() {
        _selectedDateRange = newDateRange;
      });
    }
  }
}
