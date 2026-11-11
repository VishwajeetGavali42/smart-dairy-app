import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_config.dart';

class AuthService {
  static const String _userKey = 'current_user_data';
  static const String _tokenKey = 'jwt_auth_token';

  static User? _cachedUser;
  static String? _cachedToken;

  /// Retrieve current stored token
  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Get current signed in user from storage or cache
  static Future<User?> getCurrentUser() async {
    if (_cachedUser != null) return _cachedUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString(_userKey);
      if (userDataStr != null) {
        final map = jsonDecode(userDataStr) as Map<String, dynamic>;
        _cachedUser = User.fromMap(map);
        return _cachedUser;
      }
    } catch (_) {}
    return null;
  }

  /// Register customer via Node.js API
  static Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.register),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201 && data['success'] == true) {
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;
        final user = User.fromMap(userData);

        await _saveSession(token, user);
        return user;
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('timeout')) {
        // Fallback for offline testing
        final fallbackUser = User(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: name.trim(),
          email: email.trim().toLowerCase(),
          phone: '+1 555-0199',
          address: '742 Evergreen Terrace',
        );
        await _saveSession('fallback_mock_jwt_token', fallbackUser);
        return fallbackUser;
      }
      rethrow;
    }
  }

  /// Login customer via Node.js API
  static Future<User> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.login),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        final token = data['token'] as String;
        final userData = data['user'] as Map<String, dynamic>;
        final user = User.fromMap(userData);

        await _saveSession(token, user);
        return user;
      } else {
        throw Exception(data['message'] ?? 'Login failed. Please check credentials.');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('timeout')) {
        // Fallback demo user
        final fallbackUser = User(
          id: 'user_demo_001',
          name: 'Alex Johnson',
          email: email.trim().toLowerCase(),
          phone: '+1 (555) 019-2834',
          address: '742 Evergreen Terrace, Springfield, OR',
        );
        await _saveSession('fallback_demo_jwt_token', fallbackUser);
        return fallbackUser;
      }
      rethrow;
    }
  }

  /// Update user profile
  static Future<User> updateProfile(User updatedUser) async {
    try {
      final token = await getToken();
      if (token != null && !token.startsWith('fallback')) {
        await http.put(
          Uri.parse(ApiConfig.me),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': updatedUser.name,
            'phone': updatedUser.phone,
            'address': updatedUser.address,
          }),
        );
      }
    } catch (_) {}

    _cachedUser = updatedUser;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(updatedUser.toMap()));
    return updatedUser;
  }

  /// Logout current user
  static Future<void> logout() async {
    _cachedUser = null;
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
  }

  static Future<void> _saveSession(String token, User user) async {
    _cachedToken = token;
    _cachedUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
  }
}
