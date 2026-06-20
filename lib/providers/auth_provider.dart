import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  User? _currentUser;
  String _currentBranch = 'Main';
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  String get currentBranch => _currentBranch;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthProvider() {
    // Intercept 401 logouts
    _apiClient.onUnauthorized = () {
      logout();
    };
    loadSession();
  }

  Future<void> loadSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _authService.getCurrentSessionUser();
    } catch (e) {
      debugPrint('Error loading auth session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void changeBranch(String branch) {
    _currentBranch = branch;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentUser = await _authService.login(username, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> registerData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _currentUser = await _authService.register(registerData);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.logout();
      _currentUser = null;
    } catch (e) {
      debugPrint('Error logging out: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
