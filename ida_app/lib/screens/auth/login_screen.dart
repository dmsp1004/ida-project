import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _initDeepLinkListener();
  }

  // 딥링크 리스너 초기화
  Future<void> _initDeepLinkListener() async {
    // 앱이 실행 중일 때 딥링크 수신 리스너
    _linkSubscription = uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null) {
          _handleIncomingLink(uri);
        }
      },
      onError: (err) {
        print('딥링크 에러: $err');
      },
    );

    // 앱이 실행되지 않은 상태에서 딥링크로 열렸을 때
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleIncomingLink(initialUri);
      }
    } catch (e) {
      print('초기 딥링크 에러: $e');
    }
  }

  // 딥링크 처리
  void _handleIncomingLink(Uri uri) {
    print('딥링크 수신: $uri');

    // OAuth 콜백 URL 처리
    if (uri.path.contains('/oauth/callback')) {
      // code와 state 추출
      final code = uri.queryParameters['code'];
      final provider =
          uri.queryParameters['provider'] ?? _getProviderFromPath(uri.path);

      if (code != null && provider != null) {
        _processSocialLogin(code, provider);
      }
    }
  }

  // URL 경로에서 제공자 추출
  String? _getProviderFromPath(String path) {
    final parts = path.split('/');
    for (final provider in ['google', 'kakao', 'naver']) {
      if (parts.contains(provider)) {
        return provider;
      }
    }
    return null;
  }

  // 소셜 로그인 처리
  Future<void> _processSocialLogin(String code, String provider) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.handleSocialLoginCallback(
      code,
      provider,
    );

    if (success) {
      _navigateBasedOnUserType(authProvider.userType ?? 'PARENT');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage ?? '소셜 로그인 처리 실패')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  // 사용자 유형에 따라 적절한 화면으로 이동하는 함수
  void _navigateBasedOnUserType(String userType) {
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
    print('사용자 유형: $userType에 따라 화면 이동');
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
                    authProvider.isLoading
                        ? null
                        : () async {
                          if (_formKey.currentState!.validate()) {
                            final success = await authProvider.login(
                              _emailController.text.trim(),
                              _passwordController.text,
                            );

                            if (success) {
                              _navigateBasedOnUserType(
                                authProvider.userType ?? 'PARENT',
                              );
                            } else {
                              // 에러 메시지가 이미 설정되어 있어야 함
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    authProvider.errorMessage ?? '로그인에 실패했습니다.',
                                  ),
                                ),
                              );
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
                    authProvider.isLoading
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
                    icon: 'assets/icons/kakao.png',
                    color: Colors.yellow.shade700,
                    label: '카카오',
                    provider: 'kakao',
                    isLoading: authProvider.isLoading,
                  ),
                  _buildSocialLoginButton(
                    icon: 'assets/icons/naver.png',
                    color: Colors.green.shade600,
                    label: '네이버',
                    provider: 'naver',
                    isLoading: authProvider.isLoading,
                  ),
                  _buildSocialLoginButton(
                    icon: 'assets/icons/google.png',
                    color: Colors.white,
                    label: '구글',
                    provider: 'google',
                    isLoading: authProvider.isLoading,
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
    required String icon,
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
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    await authProvider.socialLogin(provider);
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
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Image.asset(icon),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
