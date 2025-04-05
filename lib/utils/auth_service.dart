import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:local_auth/local_auth.dart';
import 'package:banking_app/models/user.dart';
import 'package:banking_app/utils/database_helper.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Encryption key - in a real app, this would be securely stored
  final _key = encrypt.Key.fromLength(32);
  final _iv = encrypt.IV.fromLength(16);

  late encrypt.Encrypter _encrypter;

  factory AuthService() => _instance;

  AuthService._internal() {
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  // Generate and store OTP
  Future<String> generateOTP() async {
    final random = Random();
    final otp = random.nextInt(900000) + 100000; // 6-digit OTP

    // Store OTP with timestamp
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('otp', otp);
    await prefs.setInt('otp_timestamp', DateTime.now().millisecondsSinceEpoch);

    return otp.toString();
  }

  // Verify OTP
  Future<bool> verifyOTP(String inputOTP) async {
    final prefs = await SharedPreferences.getInstance();
    final storedOTP = prefs.getInt('otp');
    final otpTimestamp = prefs.getInt('otp_timestamp') ?? 0;

    // Check if OTP exists and is not expired (5 minutes validity)
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final otpAge = currentTime - otpTimestamp;
    final otpExpired = otpAge > 300000; // 5 minutes in milliseconds

    if (storedOTP != null && !otpExpired && storedOTP.toString() == inputOTP) {
      // OTP verified, clear it
      await prefs.remove('otp');
      await prefs.remove('otp_timestamp');
      return true;
    }

    return false;
  }

  // Login with email and password
  Future<User?> login(String email, String password) async {
    // Encrypt password before checking
    final encryptedPass = _encryptPassword(password);
    return await _dbHelper.getUser(email, encryptedPass);
  }

  // Register a new user
  Future<bool> register(User user) async {
    // Encrypt password before storing
    final userWithEncryptedPass = User(
      id: user.id,
      name: user.name,
      email: user.email,
      password: _encryptPassword(user.password),
      phoneNumber: user.phoneNumber,
      profileImageUrl: user.profileImageUrl,
    );

    final result = await _dbHelper.insertUser(userWithEncryptedPass);
    return result > 0;
  }

  // Encrypt password
  String _encryptPassword(String password) {
    final encrypted = _encrypter.encrypt(password, iv: _iv);
    return encrypted.base64;
  }

  // Check if device supports biometric authentication
  Future<bool> canUseBiometrics() async {
    return await _localAuth.canCheckBiometrics;
  }

  // Authenticate using biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // Store current user ID in shared preferences
  Future<void> saveCurrentUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);
  }

  // Get current user ID from shared preferences
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_id');
  }

  // Logout - clear current user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
  }
}
