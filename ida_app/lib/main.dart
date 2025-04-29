import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home_screen.dart';
// 충돌하는 import 수정
import 'screens/parent_home_screen.dart' as parent;
import 'screens/sitter_home_screen.dart' as sitter;
import 'screens/admin_home_screen.dart';

// 구인구직 관련 화면 추가
import 'screens/job_posting_list_screen.dart';
import 'screens/job_posting_detail_screen.dart';
import 'screens/job_application_list_screen.dart';
import 'screens/create_job_application_screen.dart';

void main() async {
  // Flutter 바인딩 초기화 (필수)
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 날짜 형식 초기화
  await initializeDateFormatting('ko_KR', null);

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
                // 입력 폼 테마
                inputDecorationTheme: InputDecorationTheme(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                // 카드 테마
                cardTheme: CardTheme(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
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
                // '/': (context) => const LoginScreen(), // 루트 경로 제거 (home 속성과 충돌)
                '/home': (context) => const HomeScreen(),
                '/parent_home': (context) => const parent.ParentHomeScreen(),
                '/sitter_home': (context) => const sitter.SitterHomeScreen(),
                '/admin_home': (context) => const AdminHomeScreen(),
                '/register': (context) => const RegisterScreen(),

                // 구인구직 관련 라우트 추가
                '/job_postings': (context) => const JobPostingListScreen(),
                '/my_job_postings':
                    (context) =>
                        const JobPostingListScreen(onlyMyPostings: true),
                '/job_applications':
                    (context) => const JobApplicationListScreen(),
                '/my_applications':
                    (context) =>
                        const JobApplicationListScreen(myApplications: true),

                // OAuth 콜백 및 비밀번호 찾기 화면은 임시로 제거 (구현 필요)
                // '/oauth/callback': (context) => const OAuthCallbackScreen(),
                // '/forgot_password': (context) => const ForgotPasswordScreen(),
              },
              // 딥링크 URI 처리 설정
              onGenerateRoute: (settings) {
                // URI 형식의 라우트인 경우 특별 처리
                if (settings.name != null &&
                    settings.name!.startsWith('/oauth/')) {
                  // 임시로 로그인 화면으로 리다이렉트
                  return MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                    settings: settings,
                  );
                }

                // 구인글 상세 페이지 (ID 기반 동적 라우팅)
                if (settings.name != null &&
                    settings.name!.startsWith('/job_posting/')) {
                  final postingId = int.tryParse(
                    settings.name!.split('/').last,
                  );
                  if (postingId != null) {
                    return MaterialPageRoute(
                      builder:
                          (context) =>
                              JobPostingDetailScreen(jobPostingId: postingId),
                    );
                  }
                }

                // 지원서 작성 페이지
                if (settings.name != null &&
                    settings.name!.startsWith('/apply_job/')) {
                  final postingId = int.tryParse(
                    settings.name!.split('/').last,
                  );
                  if (postingId != null) {
                    return MaterialPageRoute(
                      builder:
                          (context) => CreateJobApplicationScreen(
                            jobPostingId: postingId,
                          ),
                    );
                  }
                }

                // 특정 구인글의 지원서 목록 페이지
                if (settings.name != null &&
                    settings.name!.startsWith('/job_applications/')) {
                  final postingId = int.tryParse(
                    settings.name!.split('/').last,
                  );
                  if (postingId != null) {
                    return MaterialPageRoute(
                      builder:
                          (context) =>
                              JobApplicationListScreen(jobPostingId: postingId),
                    );
                  }
                }

                return null;
              },
            ),
      ),
    );
  }

  // 사용자 유형에 따라 적절한 홈 화면 위젯을 반환하는 함수
  Widget _getHomeScreenByUserType(String? userType) {
    if (userType == null) return const HomeScreen();

    switch (userType) {
      case 'PARENT':
        return const parent.ParentHomeScreen();
      case 'SITTER':
        return const sitter.SitterHomeScreen();
      case 'ADMIN':
        return const AdminHomeScreen();
      default:
        return const HomeScreen();
    }
  }
}

// OAuth 관련 기능은 이후에 구현하도록 주석 처리

// 비밀번호 찾기 화면도 이후에 구현하도록 주석 처리
