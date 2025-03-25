import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http; // http 패키지 추가
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert'; // JSON 인코딩/디코딩을 위한 패키지 추가
import '../../providers/auth_provider.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // API 테스트 함수 추가
  Future<void> _testApiConnection() async {
    try {
      // 테스트할 이메일과 비밀번호
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이메일과 비밀번호를 입력해주세요')));
        return;
      }

      // final url = 'http://10.0.2.2:8085/api/auth/login';
      final url = 'http://localhost:8085/api/auth/login';
      print('API 요청 URL: $url');
      print('요청 데이터: email=$email, password=$password');

      // HTTP 요청 직접 테스트
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 헤더: ${response.headers}');
      print('응답 본문: ${response.body}');

      // 응답 데이터 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '응답: ${response.statusCode} - ${response.body.length > 100 ? '${response.body.substring(0, 100)}...' : response.body}',
          ),
          duration: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      print('API 테스트 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    }
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
        // 기본값으로 일반 홈 화면으로 이동
        Navigator.pushReplacementNamed(context, '/home');
        break;
    }
    print('사용자 유형: $userType에 따라 화면 이동');
  }

  @override
  Widget build(BuildContext context) {
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
                  },
                  child: const Text('비밀번호 찾기'),
                ),
              ),
              const SizedBox(height: 24),
              // 로그인 버튼
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final authProvider = Provider.of<AuthProvider>(
                      context,
                      listen: false,
                    );
                    final success = await authProvider.login(
                      _emailController.text.trim(),
                      _passwordController.text,
                    );

                    if (success) {
                      // 사용자 유형에 따라 적절한 화면으로 이동
                      _navigateBasedOnUserType(
                        authProvider.userType ?? 'PARENT',
                      );
                    } else {
                      // 에러 메시지 표시
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
                child: const Text('로그인', style: TextStyle(fontSize: 16)),
              ),

              // API 테스트 버튼 추가
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _testApiConnection,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'API 직접 테스트',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
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
                    icon: Icons.chat_bubble,
                    color: Colors.yellow.shade700,
                    label: '카카오',
                  ),
                  _buildSocialLoginButton(
                    icon: Icons.language,
                    color: Colors.green.shade600,
                    label: '네이버',
                  ),
                  _buildSocialLoginButton(
                    icon: Icons.g_mobiledata,
                    color: Colors.red.shade400,
                    label: '구글',
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
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('$label 로그인 기능 구현 예정입니다')));
          },
          icon: Icon(icon, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
