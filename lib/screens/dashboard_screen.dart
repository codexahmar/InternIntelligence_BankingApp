import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:banking_app/providers/user_provider.dart';
import 'package:banking_app/screens/accounts_screen.dart';
import 'package:banking_app/screens/transactions_screen.dart';
import 'package:banking_app/screens/budget_screen.dart';
import 'package:banking_app/screens/profile_screen.dart';
import 'package:banking_app/utils/account_service.dart';

import 'package:banking_app/screens/login_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  final PageController _pageController = PageController();
  final AccountService _accountService = AccountService();

  final List<Widget> _pages = [
    const AccountsScreen(),
    const TransactionsScreen(),
    BudgetScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _createDemoAccountsIfNeeded();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await userProvider.loadUserAccounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createDemoAccountsIfNeeded() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.userAccounts.isEmpty) {
      try {
        // Create demo accounts with unique account numbers
        final userId = userProvider.currentUser?.id ?? '';
        await _accountService.createDemoAccounts(userId);
        await userProvider.loadUserAccounts();
      } catch (e) {
        print('Error creating demo accounts: $e');
      }
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  void _logout() {
    Provider.of<UserProvider>(context, listen: false).logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation to login screen
        return false;
      },
      child: Scaffold(
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    // Custom App Bar
                    _buildCustomAppBar(context, user?.name ?? 'User'),

                    // Main Content
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        children: _pages,
                      ),
                    ),
                  ],
                ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          elevation: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: 'Accounts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart),
              label: 'Budget',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context, String userName) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_currentIndex == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Manage your accounts, track your expenses and transfer money securely.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
