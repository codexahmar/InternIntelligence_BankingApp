import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:banking_app/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OTPScreen extends StatefulWidget {
  final VoidCallback onVerified;
  final String? otp; 
  final String? phoneNumber; 
  final bool isTransfer; 

  const OTPScreen({
    Key? key,
    required this.onVerified,
    this.otp,
    this.phoneNumber,
    this.isTransfer = false,
  }) : super(key: key);

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<String> _otpDigits = List.filled(6, '');
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  String? _errorMessage;
  Timer? _autoFillTimer;
  int _countdown = 120; 
  Timer? _countdownTimer;
  String? _verificationId; 

  @override
  void initState() {
    super.initState();
    _startCountdown();

    // Auto-fill OTP after a short delay (for demo purposes)
    if (widget.otp != null) {
      _autoFillTimer = Timer(const Duration(seconds: 2), () {
        _autoFillOtp();
      });
    } else if (widget.phoneNumber != null) {
      // Initialize real SMS verification
      _sendSmsOtp(widget.phoneNumber!);
    }
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }

    _autoFillTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _countdownTimer?.cancel();
        }
      });
    });
  }

  // Auto-fill OTP for demo
  void _autoFillOtp() {
    if (widget.otp != null && widget.otp!.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = widget.otp![i];
        _otpDigits[i] = widget.otp![i];
      }

      // Show a snackbar to inform the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo OTP auto-filled for convenience'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Send real SMS OTP using Firebase
  Future<void> _sendSmsOtp(String phoneNumber) async {
    try {
      setState(() {
        _errorMessage = null;
      });

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification completed (Android only)
          await FirebaseAuth.instance.signInWithCredential(credential);
          _onVerificationSuccess();
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _errorMessage = 'Verification failed: ${e.message}';
          });

          // For development, auto-fill with demo OTP
          if (widget.otp != null) {
            _autoFillTimer = Timer(const Duration(seconds: 2), () {
              _autoFillOtp();
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent to your phone'),
              backgroundColor: Colors.green,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
          });
        },
        timeout: const Duration(seconds: 120),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sending OTP: $e';
      });

      // Fallback to demo OTP
      if (widget.otp != null) {
        _autoFillTimer = Timer(const Duration(seconds: 2), () {
          _autoFillOtp();
        });
      }
    }
  }

  void _onDigitChanged(String value, int index) {
    if (value.length == 1) {
      setState(() {
        _otpDigits[index] = value;
        _errorMessage = null;
      });

      // Move focus to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last digit entered, verify OTP
        _verifyOTP();
      }
    } else if (value.isEmpty) {
      setState(() {
        _otpDigits[index] = '';
      });

      // Move focus to previous field
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _verifyOTP() async {
    // Check if all digits are filled
    if (_otpDigits.any((digit) => digit.isEmpty)) {
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final enteredOTP = _otpDigits.join();
      bool isVerified = false;

      // VERIFICATION LOGIC:
      // 1. For demo mode (has widget.otp)
      if (widget.otp != null && enteredOTP == widget.otp) {
        isVerified = true;
      }
      // 2. For Firebase Phone Auth
      else if (_verificationId != null) {
        try {
          // Create credential
          PhoneAuthCredential credential = PhoneAuthProvider.credential(
            verificationId: _verificationId!,
            smsCode: enteredOTP,
          );

          // Sign in with credential
          await FirebaseAuth.instance.signInWithCredential(credential);
          isVerified = true;
        } catch (e) {
          throw Exception('Invalid OTP: $e');
        }
      }
      // 3. For Firebase custom OTP (for transfers)
      else if (widget.isTransfer) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        isVerified = await userProvider.verifyOTP(enteredOTP);
      }

      if (isVerified) {
        _onVerificationSuccess();
      } else {
        setState(() {
          _errorMessage = 'Invalid OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error verifying OTP: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  void _onVerificationSuccess() {
    // Call the onVerified callback
    widget.onVerified();
  }

  void _resendOTP() async {
    setState(() {
      _errorMessage = null;
      _countdown = 120; // Reset countdown
    });

    // Start countdown again
    _startCountdown();

    // Clear existing OTP fields
    for (int i = 0; i < 6; i++) {
      _controllers[i].clear();
      _otpDigits[i] = '';
    }

    // RESEND LOGIC:
    try {
      // 1. For demo mode
      if (widget.otp != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New demo OTP has been sent'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Auto-fill after a short delay
        _autoFillTimer = Timer(const Duration(seconds: 2), () {
          _autoFillOtp();
        });
      }
      // 2. For real phone verification
      else if (widget.phoneNumber != null) {
        await _sendSmsOtp(widget.phoneNumber!);
      }
      // 3. For transfer verification
      else if (widget.isTransfer) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final newOtp = await userProvider.generateOTP();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New OTP has been sent'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error sending OTP: ${e.toString()}';
        });
      }
    }
  }

  String _formatCountdown() {
    final minutes = (_countdown / 60).floor();
    final seconds = _countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatPhoneNumber() {
    if (widget.phoneNumber == null) return '';
    String number = widget.phoneNumber!;
    if (number.length > 6) {
      return '${number.substring(0, 3)}****${number.substring(number.length - 3)}';
    }
    return number;
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 3,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.security,
                        size: 60,
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.isTransfer
                            ? 'Verify Transaction'
                            : 'Verify Your Identity',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.phoneNumber != null
                            ? 'Enter the 6-digit code sent to ${_formatPhoneNumber()}'
                            : 'Enter the 6-digit verification code',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          6,
                          (index) => SizedBox(
                            width: 45,
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(fontSize: 20),
                              decoration: InputDecoration(
                                counterText: '',
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              onChanged:
                                  (value) => _onDigitChanged(value, index),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 15),
                        Container(
                          padding: const EdgeInsets.all(10),
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
                              const SizedBox(width: 10),
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
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Code expires in: ',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          Text(
                            _formatCountdown(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  _countdown < 30
                                      ? Colors.red
                                      : Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verifyOTP,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child:
                              _isVerifying
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'Verify',
                                    style: TextStyle(fontSize: 16),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: _countdown == 0 ? _resendOTP : null,
                        child: Text(
                          _countdown > 0
                              ? 'Resend code in $_countdown seconds'
                              : 'Resend code',
                          style: TextStyle(
                            color:
                                _countdown == 0
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!widget.isTransfer)
                  TextButton.icon(
                    onPressed: () {
                      // For testing only - skip OTP verification
                      widget.onVerified();
                    },
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip for demo'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
