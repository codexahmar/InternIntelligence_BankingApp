import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:banking_app/providers/user_provider.dart';
import 'package:banking_app/screens/accounts_screen.dart';
import 'package:banking_app/screens/transactions_screen.dart';
import 'package:banking_app/screens/budget_screen.dart';
import 'package:banking_app/screens/profile_screen.dart';
import 'package:banking_app/utils/firebase_firestore_service.dart';
import 'package:banking_app/widgets/custom_dashboard_app_bar.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  final PageController _pageController = PageController();
  final FirestoreService _firestoreService = FirestoreService();

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
        final userId = userProvider.currentUser?.id ?? '';
        await _firestoreService.createDefaultAccounts(userId);
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    CustomDashboardAppBar(
                      userName: user?.name ?? 'User',
                      currentIndex: _currentIndex,
                    ),
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
}
