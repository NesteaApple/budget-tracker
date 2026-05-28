import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ─── CONFIG ────────────────────────────────────────────────────────────────
  static const String baseUrl = 'http://10.44.234.83:8000/api';
  static const String _tokenKey = 'sanctum_token';
  static const String _userKey = 'auth_user';

  // ─── TOKEN HELPERS ─────────────────────────────────────────────────────────

  /// Returns the stored Sanctum token, or null if the user is not logged in.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Saves the Sanctum token to SharedPreferences.
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Saves the authenticated user's JSON data to SharedPreferences.
  static Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  /// Returns the locally cached user data as a Map, or null.
  static Future<Map<String, dynamic>?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Clears both the token and user data from SharedPreferences.
  static Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Builds the standard authenticated headers for every API request.
  /// Format: `Authorization: Bearer <token>`
  static Future<Map<String, String>> authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── AUTH ENDPOINTS ────────────────────────────────────────────────────────

  /// Attempts to log in with [email] and [password].
  ///
  /// On success: saves the Sanctum token and user object, then returns the
  /// user data map.
  ///
  /// On failure: throws an [ApiException] with the server's error message.
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final uri = Uri.parse('$baseUrl/login');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': password,
            'device_name': 'mobile_app',
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      // Laravel Sanctum returns: { "token": "...", "user": { ... } }
      final token = body['token'] as String?;
      final user = body['user'] as Map<String, dynamic>?;

      if (token == null || user == null) {
        throw ApiException('Unexpected response format from server.');
      }

      await _saveToken(token);
      await _saveUser(user);
      return user;
    }

    // Surface the server's validation / auth error message.
    final message = body['message'] as String? ?? 'Login failed.';
    throw ApiException(message, statusCode: response.statusCode);
  }

  /// Sends a DELETE /logout request to invalidate the token on the server,
  /// then clears the local session regardless of the server response.
  static Future<void> logout() async {
    try {
      final uri = Uri.parse('$baseUrl/logout');
      final headers = await authHeaders();
      await http
          .post(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Even if the network request fails, we still clear the local session
      // so the user is never stuck on the logged-in state.
    } finally {
      await _clearSession();
    }
  }
}

// ─── CUSTOM EXCEPTION ──────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
