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
  // Flutter 바인딩 초기화 (필수)
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // AuthProvider 등록
      providers: [ChangeNotifierProvider(create: (context) => AuthProvider())],
      child: Consumer<AuthProvider>(
        builder:
            (ctx, auth, _) => MaterialApp(
              title: '아이다 - 아이 돌봄 매칭 플랫폼',
              theme: ThemeData(
                primarySwatch: Colors.blue,
                fontFamily: 'NotoSansKR',
                // 전체 앱 디자인 테마 설정
                elevatedButtonTheme: ElevatedButtonThemeData(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              // 자동 로그인 시도 및 결과에 따른 초기 화면 설정
              home: FutureBuilder(
                future: auth.tryAutoLogin(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    // 로그인 여부에 따라 홈 또는 로그인 화면으로 이동
                    return auth.isAuthenticated
                        ? _getHomeScreenByUserType(auth.userType)
                        : const LoginScreen();
                  }
                },
              ),
              // 앱 내 페이지 라우트 정의
              routes: {
                '/home': (context) => const HomeScreen(),
                '/parent_home': (context) => const ParentHomeScreen(),
                '/sitter_home': (context) => const SitterHomeScreen(),
                '/admin_home': (context) => const AdminHomeScreen(),
                '/register': (context) => const RegisterScreen(),
                // OAuth 콜백을 위한 라우트 추가
                '/oauth/callback': (context) => const OAuthCallbackScreen(),
                // 비밀번호 찾기 화면도 추가
                '/forgot_password': (context) => const ForgotPasswordScreen(),
              },
              // 딥링크 URI 처리 설정
              onGenerateRoute: (settings) {
                // URI 형식의 라우트인 경우 특별 처리
                if (settings.name != null &&
                    settings.name!.startsWith('/oauth/')) {
                  return MaterialPageRoute(
                    builder: (context) => const OAuthCallbackScreen(),
                    settings: settings,
                  );
                }
                return null;
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

// OAuth 콜백 처리 화면 (임시)
class OAuthCallbackScreen extends StatefulWidget {
  const OAuthCallbackScreen({Key? key}) : super(key: key);

  @override
  State<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends State<OAuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _processOAuthCallback();
  }

  // OAuth 콜백 처리 및 적절한 화면으로 리다이렉트
  Future<void> _processOAuthCallback() async {
    // URI 파라미터에서 code와 provider 추출
    final uri = Uri.parse(ModalRoute.of(context)?.settings.name ?? '');
    final queryParams = uri.queryParameters;

    final code = queryParams['code'];
    final provider = queryParams['provider'];

    if (code != null && provider != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.handleSocialLoginCallback(
        code,
        provider,
      );

      if (success) {
        // 로그인 성공 시 해당 유형 홈 화면으로 이동
        _navigateToHome(authProvider.userType);
      } else {
        // 로그인 실패 시 로그인 화면으로 복귀
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // 필요한 파라미터가 없으면 로그인 화면으로 이동
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _navigateToHome(String? userType) {
    switch (userType) {
      case 'PARENT':
        Navigator.pushReplacementNamed(context, '/parent_home');
        break;
      case 'SITTER':
        Navigator.pushReplacementNamed(context, '/sitter_home');
        break;
      case 'ADMIN':
        Navigator.pushReplacementNamed(context, '/admin_home');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/home');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('소셜 로그인 처리 중...'),
          ],
        ),
      ),
    );
  }
}

// 비밀번호 찾기 화면 (뼈대)
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('비밀번호 찾기')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '이메일 주소를 입력하시면 비밀번호 재설정 링크를 보내드립니다.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '이메일',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // 비밀번호 재설정 이메일 발송 로직 구현 필요
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('이 기능은 아직 구현 중입니다.')),
                );
              },
              child: const Text('비밀번호 재설정 링크 받기'),
            ),
          ],
        ),
      ),
    );
  }
}
