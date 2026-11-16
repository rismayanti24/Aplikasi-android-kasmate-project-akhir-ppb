import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'screens/splash_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/login_screen.dart';
import 'data/kas_store.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/firestore_service.dart';
import 'models/pengguna.dart';
import 'data/profil_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    kasStore.inisialisasiFirestoreSync();
    await notificationService.inisialisasi();
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'KasMate',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: _showSplash
              ? SplashScreen(
                  onSelesai: () => setState(() => _showSplash = false),
                )
              : const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAFAFA),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF074E3B)),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return FutureBuilder<Pengguna?>(
            future: firestoreService.getProfilUser(user.uid),
            builder: (context, profilSnap) {
              if (profilSnap.connectionState == ConnectionState.waiting &&
                  profilNotifier.value.id.isEmpty) {
                return const Scaffold(
                  backgroundColor: Color(0xFFFAFAFA),
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFF074E3B)),
                  ),
                );
              }
              if (profilSnap.hasData && profilSnap.data != null) {
                profilNotifier.value = profilSnap.data!;
              } else if (user.displayName != null &&
                  user.displayName!.isNotEmpty &&
                  profilNotifier.value.id.isEmpty) {
                profilNotifier.value = Pengguna(
                  id: user.uid,
                  nama: user.displayName!,
                  noWa: '',
                  bank: '',
                  noRekening: '',
                );
              }
              return const MainNavigationScreen();
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}