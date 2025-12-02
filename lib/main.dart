import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env (if present)
  try {
    await dotenv.load(fileName: '.env');
    if (kDebugMode) debugPrint('Loaded .env file');
  } catch (e) {
    if (kDebugMode) debugPrint('No .env file found or failed to load. Using compile-time constants.');
  }

  // Initialize Supabase (will no-op if env vars missing)
  await SupabaseService.init();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'QuestForge',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isLoggedIn) {
              return const MainNavigation();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
