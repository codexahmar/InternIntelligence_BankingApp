import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:banking_app/models/user.dart';
import 'package:banking_app/providers/user_provider.dart';
import 'package:banking_app/screens/login_screen.dart';
import 'package:banking_app/screens/otp_screen.dart';
import 'package:banking_app/screens/dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _phoneController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all personal information'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(_emailController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid email address'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _currentStep += 1;
    });
  }

  void _previousStep() {
    setState(() {
      _currentStep -= 1;
    });
  }

  Future<void> _signUp() async {
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set your password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use UserProvider to register
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final success = await userProvider.registerUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
      );

      if (success) {
        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate directly to dashboard
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
          (route) => false,
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create account'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Header with logo and title
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 48), // To balance the back button
                      ],
                    ),
                  ),

                  // Content Card
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Stepper indicator
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                StepIndicator(
                                  isActive: _currentStep >= 0,
                                  number: 1,
                                  title: "Personal Info",
                                ),
                                StepConnector(isActive: _currentStep >= 1),
                                StepIndicator(
                                  isActive: _currentStep >= 1,
                                  number: 2,
                                  title: "Security",
                                ),
                              ],
                            ),
                          ),

                          // Form content
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              child:
                                  _currentStep == 0
                                      ? _buildPersonalInfoStep()
                                      : _buildSecurityStep(),
                            ),
                          ),

                          // Bottom navigation buttons
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child:
                                _currentStep == 0
                                    ? SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _nextStep,
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Continue',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    )
                                    : Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: OutlinedButton(
                                            onPressed: _previousStep,
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              side: BorderSide(
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).primaryColor,
                                              ),
                                              minimumSize: const Size(0, 50),
                                            ),
                                            child: const Text('Back'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 3,
                                          child: ElevatedButton(
                                            onPressed:
                                                _isLoading ? null : _signUp,
                                            style: ElevatedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              minimumSize: const Size(0, 50),
                                            ),
                                            child:
                                                _isLoading
                                                    ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                    : const Text(
                                                      'Create Account',
                                                    ),
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Login link
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tell us about yourself',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        // Name field
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 15),
        // Email field
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 15),
        // Phone field
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  Widget _buildSecurityStep() {
    // Add focus nodes for password fields
    final _passwordFocusNode = FocusNode();
    final _confirmPasswordFocusNode = FocusNode();

    // Request focus on the password field when this widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentStep == 1) {
        _passwordFocusNode.requestFocus();
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Secure your account',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        // Password field
        TextFormField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onFieldSubmitted: (_) {
            // Move to confirm password when done
            _confirmPasswordFocusNode.requestFocus();
          },
        ),
        const SizedBox(height: 15),
        // Confirm password field
        TextFormField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocusNode,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 20),
        // Security info card
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Password requirements:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PasswordRequirement(
                text: 'At least 6 characters long',
                isChecked: _passwordController.text.length >= 6,
              ),
              PasswordRequirement(
                text: 'Contains uppercase letters',
                isChecked: _passwordController.text.contains(RegExp(r'[A-Z]')),
              ),
              PasswordRequirement(
                text: 'Contains numbers',
                isChecked: _passwordController.text.contains(RegExp(r'[0-9]')),
              ),
              if (_passwordController.text.isNotEmpty &&
                  _confirmPasswordController.text.isNotEmpty)
                PasswordRequirement(
                  text: 'Passwords match',
                  isChecked:
                      _passwordController.text ==
                      _confirmPasswordController.text,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class StepIndicator extends StatelessWidget {
  final bool isActive;
  final int number;
  final String title;

  const StepIndicator({
    Key? key,
    required this.isActive,
    required this.number,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color:
                isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color:
                isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class StepConnector extends StatelessWidget {
  final bool isActive;

  const StepConnector({Key? key, required this.isActive}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade300,
    );
  }
}

class PasswordRequirement extends StatelessWidget {
  final String text;
  final bool isChecked;

  const PasswordRequirement({
    Key? key,
    required this.text,
    required this.isChecked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.circle_outlined,
            color: isChecked ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
