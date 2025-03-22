import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  String? _userType;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get userType => _userType;
  
  AuthProvider() {
    _checkAuthentication();
  }
  
  Future<void> _checkAuthentication() async {
    _isAuthenticated = await _apiService.isAuthenticated();
    if (_isAuthenticated) {
      _userType = await _apiService.getUserType();
    }
    notifyListeners();
  }
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.login(email, password);
      _isAuthenticated = true;
      _userType = response['userType'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register(String email, String password, String phoneNumber, String userType) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.register(email, password, phoneNumber, userType);
      _isAuthenticated = true;
      _userType = response['userType'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _getErrorMessage(e);
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    await _apiService.logout();
    _isAuthenticated = false;
    _userType = null;
    notifyListeners();
  }
  
  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return '요청 처리 중 오류가 발생했습니다.';
    }
    return error.toString();
  }
}