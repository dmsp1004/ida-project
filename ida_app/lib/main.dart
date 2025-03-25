import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/parent_home_screen.dart';
import 'screens/sitter_home_screen.dart';
import 'screens/admin_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (context) => AuthProvider())],
      child: Consumer<AuthProvider>(
        builder:
            (ctx, auth, _) => MaterialApp(
              title: '아이다 - 아이 돌봄 매칭 플랫폼',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                fontFamily: 'NotoSansKR',
              ),
              home: FutureBuilder(
                future: auth.tryAutoLogin(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    return auth.isAuthenticated
                        ? _getHomeScreenByUserType(auth.userType)
                        : const LoginScreen();
                  }
                },
              ),
              routes: {
                '/home': (context) => const HomeScreen(),
                '/parent_home': (context) => const ParentHomeScreen(),
                '/sitter_home': (context) => const SitterHomeScreen(),
                '/admin_home': (context) => const AdminHomeScreen(),
                '/register': (context) => const RegisterScreen(),
              },
            ),
      ),
    );
  }

  // 사용자 유형에 따라 적절한 홈 화면 위젯을 반환하는 함수
  Widget _getHomeScreenByUserType(String? userType) {
    switch (userType) {
      case 'PARENT':
        return const ParentHomeScreen();
      case 'SITTER':
        return const SitterHomeScreen();
      case 'ADMIN':
        return const AdminHomeScreen();
      default:
        return const HomeScreen();
    }
  }
}
