// lib/services/auth_service.dart
import 'dart:convert';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  // POST /auth/register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final res = await ApiService.instance.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      await _saveSession(res.data['token'], res.data['user']);
      return {'success': true, 'user': res.data['user']};
    } on Exception catch (e) {
      return {'success': false, 'message': _extractError(e)};
    }
  }

  // POST /auth/login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await ApiService.instance.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      await _saveSession(res.data['token'], res.data['user']);
      return {'success': true, 'user': res.data['user']};
    } on Exception catch (e) {
      return {'success': false, 'message': _extractError(e)};
    }
  }

  // GET /auth/profile — token auto-injected by ApiService interceptor
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await ApiService.instance.get('/auth/profile');
      return {'success': true, 'user': res.data};
    } on Exception catch (e) {
      return {'success': false, 'message': _extractError(e)};
    }
  }

  static Future<void> logout() async {
    await StorageService.removeItem('token');
    await StorageService.removeItem('user');
  }

  static Future<Map<String, dynamic>?> getSavedUser() async {
    final userStr = await StorageService.getItem('user');
    if (userStr == null) return null;
    return jsonDecode(userStr);
  }

  static Future<bool> isLoggedIn() async {
    final token = await StorageService.getItem('token');
    return token != null;
  }

  static Future<void> _saveSession(String token, dynamic user) async {
    await StorageService.setItem('token', token);
    await StorageService.setItem('user', jsonEncode(user));
  }

  static String _extractError(dynamic e) {
    try {
      return e.response?.data['message'] ?? e.toString();
    } catch (_) {
      return e.toString();
    }
  }
}