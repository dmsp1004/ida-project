import 'package:flutter/material.dart';
import 'package:ida_app/screens/job_posting_list_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' if (dart.library.io) 'dart:ui' show window;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  StreamSubscription? _linkSubscription;
  bool _processingLogin = false; // Flag to prevent multiple login attempts

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  // 딥링크 리스너 초기화 (웹 호환)
  Future<void> _initDeepLinkListener() async {
    // 웹 환경인 경우 다른 방식으로 처리
    if (kIsWeb) {
      try {
        // 현재 URL 확인하여 OAuth 콜백 파라미터 추출
        final href = Uri.base.toString();
        print('현재 웹 URL: $href');
        final currentUri = Uri.parse(href);

        if (currentUri.path.contains('/oauth/callback') ||
            currentUri.queryParameters.containsKey('code')) {
          print('웹 환경에서 OAuth 콜백 감지: ${currentUri.toString()}');
          _handleIncomingLink(currentUri);
        }
      } catch (e) {
        print('웹 딥링크 처리 오류: $e');
      }
      return;
    }

    // 모바일 환경에서는 기존 코드 사용
    try {
      // 앱이 실행 중일 때 딥링크 수신 리스너
      _linkSubscription = uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null && mounted) {
            print('모바일 딥링크 수신: $uri');
            _handleIncomingLink(uri);
          }
        },
        onError: (err) {
          print('딥링크 에러: $err');
        },
      );

      // 앱이 실행되지 않은 상태에서 딥링크로 열렸을 때
      final initialUri = await getInitialUri();
      if (initialUri != null && mounted) {
        print('초기 딥링크 수신: $initialUri');
        _handleIncomingLink(initialUri);
      }
    } catch (e) {
      print('초기 딥링크 에러: $e');
    }
  }

  // 딥링크 처리
  void _handleIncomingLink(Uri uri) {
    print('딥링크 처리 시작: $uri');

    // 이미 처리 중이라면 중복 처리 방지
    if (_processingLogin) {
      print('이미 로그인 처리 중입니다.');
      return;
    }
    _processingLogin = true;

    // OAuth 콜백 URL 처리
    if (uri.path.contains('/oauth/callback') ||
        uri.queryParameters.containsKey('code')) {
      // code와 state 추출
      final code = uri.queryParameters['code'];
      final provider =
          uri.queryParameters['provider'] ?? _getProviderFromPath(uri.path);

      if (code != null && provider != null) {
        print('OAuth 콜백 감지 - 코드: $code, 제공자: $provider');
        _processSocialLogin(code, provider);
      } else {
        print('OAuth 콜백 파라미터 누락 - 코드: $code, 제공자: $provider');
        _processingLogin = false;
      }
    } else {
      print('OAuth 콜백 URL이 아닙니다: $uri');
      _processingLogin = false;
    }
  }

  // URL 경로에서 제공자 추출
  String? _getProviderFromPath(String path) {
    print('URL 경로에서 제공자 추출 시도: $path');
    final parts = path.split('/');
    for (final provider in ['google', 'kakao', 'naver']) {
      if (parts.contains(provider)) {
        print('제공자 감지: $provider');
        return provider;
      }
    }

    // 경로에서 찾지 못한 경우 URL의 다른 부분에서 검색
    if (path.contains('google')) return 'google';
    if (path.contains('kakao')) return 'kakao';
    if (path.contains('naver')) return 'naver';

    print('제공자를 찾을 수 없습니다');
    return null;
  }

  // 소셜 로그인 처리
  Future<void> _processSocialLogin(String code, String provider) async {
    print('소셜 로그인 처리 시작 - 코드: $code, 제공자: $provider');
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.handleSocialLoginCallback(
        code,
        provider,
      );

      if (success && mounted) {
        print('소셜 로그인 성공: ${authProvider.userType}');
        _navigateBasedOnUserType(authProvider.userType ?? 'PARENT');
      } else if (mounted) {
        print('소셜 로그인 실패: ${authProvider.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? '소셜 로그인 처리 실패')),
        );
      }
    } catch (e) {
      print('소셜 로그인 처리 예외: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그인 처리 중 오류가 발생했습니다: $e')));
      }
    } finally {
      // 항상 플래그 리셋
      if (mounted) {
        setState(() {
          _processingLogin = false;
        });
      } else {
        _processingLogin = false;
      }
      print('소셜 로그인 처리 완료');
    }
  }

  @override
  void dispose() {
    print('LoginScreen dispose');
    _emailController.dispose();
    _passwordController.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  // 사용자 유형에 따라 적절한 화면으로 이동하는 함수
  void _navigateBasedOnUserType(String userType) {
    if (!mounted) return;
    print('유형에 따른 화면 이동 시작: $userType');

    // 모든 사용자 유형에 대해 로그인 후 구인구직 게시판으로 이동
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/job_postings', // 구인구직 게시판 라우트
      (route) => false,
    );

    print('사용자 유형: $userType - 구인구직 게시판으로 이동 완료');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              // 로고 또는 타이틀
              const Center(
                child: Text(
                  '아이다',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  '아이 돌봄 매칭 플랫폼',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 50),
              // 이메일 입력 필드
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return '유효한 이메일 주소를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // 비밀번호 입력 필드
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '비밀번호를 입력해주세요';
                  }
                  if (value.length < 6) {
                    return '비밀번호는 최소 6자 이상이어야 합니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // 비밀번호 찾기 버튼
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // 비밀번호 찾기 화면으로 이동
                    Navigator.pushNamed(context, '/forgot_password');
                  },
                  child: const Text('비밀번호 찾기'),
                ),
              ),
              const SizedBox(height: 24),
              // 로그인 버튼
              ElevatedButton(
                onPressed:
                    authProvider.isLoading || _processingLogin
                        ? null
                        : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _processingLogin = true; // 로그인 처리 중 플래그 설정
                            });
                            try {
                              print(
                                '이메일 로그인 시도: ${_emailController.text.trim()}',
                              );
                              final success = await authProvider.login(
                                _emailController.text.trim(),
                                _passwordController.text,
                              );

                              if (success && mounted) {
                                print('로그인 성공: ${authProvider.userType}');
                                _navigateBasedOnUserType(
                                  authProvider.userType ?? 'PARENT',
                                );
                              } else if (mounted) {
                                print('로그인 실패: ${authProvider.errorMessage}');
                                // 에러 메시지가 이미 설정되어 있어야 함
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      authProvider.errorMessage ??
                                          '로그인에 실패했습니다.',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              print('로그인 예외 발생: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('로그인 처리 중 오류: $e')),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _processingLogin = false; // 플래그 리셋
                                });
                              } else {
                                _processingLogin = false;
                              }
                            }
                          }
                        },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    authProvider.isLoading || _processingLogin
                        ? const CircularProgressIndicator()
                        : const Text('로그인', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 16),
              // 소셜 로그인 섹션
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('또는'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              // 소셜 로그인 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSocialLoginButton(
                    iconData: Icons.chat_bubble,
                    color: Colors.yellow.shade700,
                    label: '카카오',
                    provider: 'kakao',
                    isLoading: authProvider.isLoading || _processingLogin,
                  ),
                  _buildSocialLoginButton(
                    iconData: Icons.edit,
                    color: Colors.green.shade600,
                    label: '네이버',
                    provider: 'naver',
                    isLoading: authProvider.isLoading || _processingLogin,
                  ),
                  _buildSocialLoginButton(
                    iconData: Icons.g_mobiledata,
                    color: Colors.white,
                    label: '구글',
                    provider: 'google',
                    isLoading: authProvider.isLoading || _processingLogin,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // 회원가입 안내
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('계정이 없으신가요?'),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text('회원가입'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required IconData iconData,
    required Color color,
    required String label,
    required String provider,
    required bool isLoading,
  }) {
    return Column(
      children: [
        InkWell(
          onTap:
              isLoading
                  ? null
                  : () async {
                    if (_processingLogin) return;

                    setState(() {
                      _processingLogin = true;
                    });

                    try {
                      print('소셜 로그인 시도: $provider');
                      final authProvider = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      );
                      await authProvider.socialLogin(provider);
                    } catch (e) {
                      print('소셜 로그인 요청 오류: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('소셜 로그인 오류: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _processingLogin = false;
                        });
                      } else {
                        _processingLogin = false;
                      }
                    }
                  },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            // 이미지 로드 오류를 해결하기 위해 Icon 위젯으로 대체
            child: Icon(
              iconData,
              color: provider == 'google' ? Colors.blue : Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
