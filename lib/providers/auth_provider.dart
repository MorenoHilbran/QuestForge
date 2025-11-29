import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/user_model.dart';
import '../../core/constants/app_constants.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoggedIn = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  AuthProvider() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
    
    if (_isLoggedIn) {
      _currentUser = UserModel(
        id: prefs.getString(AppConstants.keyUserId) ?? '',
        name: prefs.getString(AppConstants.keyUserName) ?? '',
        email: prefs.getString(AppConstants.keyUserEmail) ?? '',
        avatar: prefs.getString(AppConstants.keyUserAvatar) ?? '',
        isAdmin: prefs.getBool(AppConstants.keyIsAdmin) ?? false,
      );
      notifyListeners();
    }
  }

  Future<void> login(String name, String email, {bool isAdmin = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = DateTime.now().millisecondsSinceEpoch.toString();
    
    _currentUser = UserModel(
      id: userId,
      name: name,
      email: email,
      isAdmin: isAdmin,
    );
    
    await prefs.setString(AppConstants.keyUserId, userId);
    await prefs.setString(AppConstants.keyUserName, name);
    await prefs.setString(AppConstants.keyUserEmail, email);
    await prefs.setString(AppConstants.keyUserAvatar, '');
    await prefs.setBool(AppConstants.keyIsAdmin, isAdmin);
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? email, String? avatar}) async {
    if (_currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    
    _currentUser = _currentUser!.copyWith(
      name: name,
      email: email,
      avatar: avatar,
    );
    
    if (name != null) await prefs.setString(AppConstants.keyUserName, name);
    if (email != null) await prefs.setString(AppConstants.keyUserEmail, email);
    if (avatar != null) await prefs.setString(AppConstants.keyUserAvatar, avatar);
    
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
