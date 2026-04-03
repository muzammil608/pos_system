import 'package:flutter/material.dart';
import '../services/firebase/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;

  Future<void> login(String email, String password) async {
    isLoading = true;
    notifyListeners();

    await _authService.login(email, password);

    isLoading = false;
    notifyListeners();
  }
}
