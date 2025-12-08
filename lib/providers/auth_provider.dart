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
    // Retry mechanism for network issues
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        // Add small delay for first-time OAuth users (profile creation)
        if (retryCount > 0) {
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }
        
        final response = await SupabaseService.client
            .from('profiles')
            .select('*, user_badges(*, badges(*))')
            .eq('id', userId)
            .single();

        if (kDebugMode) {
          print('Profile loaded successfully for user: $userId');
          print('Profile data keys: ${response.keys}');
        }
        
        // Validate essential fields before parsing
        if (response['id'] == null) {
          throw Exception('Profile ID is null');
        }
        if (response['email'] == null) {
          throw Exception('Profile email is null');
        }
        
        _currentUser = UserModel.fromJson(response);
        notifyListeners();
        return; // Success, exit
      } catch (e, stackTrace) {
        if (kDebugMode) {
          print('Error loading profile (attempt ${retryCount + 1}): $e');
          print('Stack trace: $stackTrace');
        }
        
        // If profile doesn't exist on first attempt (new OAuth user), create it
        if (retryCount == 0 && e.toString().contains('JSON object')) {
          try {
            final user = SupabaseService.client.auth.currentUser;
            if (user != null) {
              // Ensure email is not empty
              final email = user.email ?? '';
              if (email.isEmpty) {
                throw Exception('Cannot create profile: email is empty');
              }
              
              // Get name with fallback
              final name = user.userMetadata?['full_name']?.toString() ?? 
                           user.userMetadata?['name']?.toString() ?? 
                           email.split('@').first;
              
              // Ensure name is not empty
              final finalName = name.isEmpty ? 'User' : name;
              
              final avatarUrl = user.userMetadata?['avatar_url']?.toString() ?? 
                               user.userMetadata?['picture']?.toString();
              
              if (kDebugMode) {
                print('Creating new profile for user: $email');
                print('Name: $finalName, Avatar: $avatarUrl');
              }
              
              // Use upsert to avoid conflicts
              await SupabaseService.client.from('profiles').upsert({
                'id': userId,
                'name': finalName,
                'email': email,
                'avatar_url': avatarUrl,
                'role': 'user',
              }, onConflict: 'id');
              
              if (kDebugMode) print('Profile created successfully');
            }
          } catch (createError) {
            if (kDebugMode) {
              print('Error creating profile: $createError');
              print('Stack trace: ${StackTrace.current}');
            }
          }
        }
        
        retryCount++;
        if (retryCount >= maxRetries) {
          if (kDebugMode) print('Max retries reached for loading profile');
          break;
        }
      }
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
        OAuthProvider.google,
        redirectTo: kIsWeb 
            ? '${Uri.base.origin}/' 
            : 'questforge://login-callback',
        authScreenLaunchMode: LaunchMode.inAppWebView,
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

  /// Sign up with email and password
  Future<bool> signUpWithEmail(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name, // Store in auth metadata for trigger to use
        },
      );

      if (response.user != null) {
        // Profile is automatically created by handle_new_user() trigger
        // No need to manually insert here!
        
        await _loadUserProfile(response.user!.id);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      _errorMessage = 'Registration failed';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      if (kDebugMode) print('Email sign up error: $e');
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
