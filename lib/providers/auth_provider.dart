import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/user_model.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    if (!SupabaseService.available) return;

    final session = SupabaseService.client.auth.currentSession;
    if (session != null) {
      await _loadUserProfile(session.user.id);
    }

    // Listen to auth state changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session == null) {
        _currentUser = null;
        notifyListeners();
      } else {
        _loadUserProfile(session.user.id);
      }
    });
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      _currentUser = UserModel.fromJson(response);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading profile: $e');
    }
  }

  /// Public method to reload user profile
  Future<void> loadUserProfile() async {
    if (_currentUser != null) {
      await _loadUserProfile(_currentUser!.id);
    }
  }

  /// Sign in with Google OAuth
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client.auth.signInWithOAuth(
        Provider.google,
        redirectTo: kIsWeb 
            ? '${Uri.base.origin}/' 
            : 'io.supabase.questforge://login-callback',
        authScreenLaunchMode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      );
      
      if (kDebugMode) print('OAuth response: $response');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (kDebugMode) print('Google sign in error: $e');
      return false;
    }
  }

  /// Sign in with email and password (for admin)
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Login failed';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (kDebugMode) print('Email sign in error: $e');
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? bio,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        updates['updated_at'] = DateTime.now().toIso8601String();

        await SupabaseService.client
            .from('profiles')
            .update(updates)
            .eq('id', _currentUser!.id);

        await _loadUserProfile(_currentUser!.id);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (kDebugMode) print('Update profile error: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await SupabaseService.client.auth.signOut();
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Sign out error: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
