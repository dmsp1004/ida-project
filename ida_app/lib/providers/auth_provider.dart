import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  int? _userId;
  String? _email;
  String? _userType; // 사용자 유형 (PARENT, SITTER, ADMIN)
  String? _errorMessage;
  bool _isLoading = false; // 로딩 상태

  // API 서비스 인스턴스
  final ApiService _apiService = ApiService();

  // Getter 메서드
  String? get token => _token;
  int? get userId => _userId;
  String? get email => _email;
  String? get userType => _userType;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading; // 로딩 상태 Getter

  // 로그인 처리
  Future<bool> login(String email, String password) async {
    _errorMessage = null; // 오류 메시지 초기화
    _isLoading = true; // 로딩 시작
    notifyListeners();

    try {
      // API 서비스를 통해 로그인 요청
      final responseData = await _apiService.login(email, password);

      // 토큰 및 사용자 정보 저장
      _token = responseData['token'];
      _userId = responseData['userId'];
      _email = email;
      _userType = responseData['role']; // 백엔드에서 제공하는 사용자 유형(role) 저장

      // 로컬 저장소에 정보 저장
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', _token!);
      prefs.setInt('userId', _userId!);
      prefs.setString('email', _email!);
      prefs.setString('userType', _userType!); // 사용자 유형 저장

      print('로그인 성공: 유형=$_userType, 이메일=$_email');
      _isLoading = false; // 로딩 종료
      notifyListeners();
      return true;
    } catch (e) {
      // DioError 등의 예외 처리
      _errorMessage = '로그인 실패: ${e.toString()}';
      print('로그인 예외 발생: $_errorMessage');
      _isLoading = false; // 로딩 종료
      notifyListeners();
      return false;
    }
  }

  // 소셜 로그인 처리
  Future<bool> socialLogin(String provider) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();

    try {
      // OAuth2 인증 URL 생성
      final authUrl = _apiService.getOAuth2AuthUrl(provider);

      // URL 실행
      final canLaunch = await canLaunchUrl(Uri.parse(authUrl));
      if (canLaunch) {
        await launchUrl(
          Uri.parse(authUrl),
          mode: LaunchMode.externalApplication,
        );

        // 소셜 로그인은 리다이렉트 기반이므로 여기서는 진행 중임을 알림
        _errorMessage = '브라우저에서 $provider 로그인을 완료한 후 앱으로 돌아오세요';
        _isLoading = false;
        notifyListeners();
        return false;
      } else {
        throw Exception('소셜 로그인 URL을 열 수 없습니다');
      }
    } catch (e) {
      _errorMessage = '소셜 로그인 실패: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 소셜 로그인 콜백 처리
  Future<bool> handleSocialLoginCallback(String code, String provider) async {
    _isLoading = true;
    notifyListeners();

    try {
      final loginResult = await _apiService.processSocialLogin(code, provider);

      _token = loginResult['token'];
      _userId = loginResult['userId'];
      _email = loginResult['email'];
      _userType = loginResult['role'];

      // 로컬 저장소에 정보 저장
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', _token!);
      prefs.setInt('userId', _userId!);
      prefs.setString('email', _email!);
      prefs.setString('userType', _userType!);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = '소셜 로그인 처리 실패: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 자동 로그인 시도
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();

    // 저장된 토큰이 없으면 자동 로그인 불가
    if (!prefs.containsKey('token')) return false;

    // 저장된 정보 불러오기
    _token = prefs.getString('token');
    _userId = prefs.getInt('userId');
    _email = prefs.getString('email');
    _userType = prefs.getString('userType');

    // 토큰 유효성 검증 (선택 사항)
    try {
      await _apiService.validateToken(_token!);
    } catch (e) {
      // 토큰이 유효하지 않으면 로그아웃 처리
      await logout();
      return false;
    }

    notifyListeners();
    return true;
  }

  // 로그아웃
  Future<void> logout() async {
    try {
      // API 서비스를 통해 로그아웃 (토큰 무효화)
      if (_token != null) {
        await _apiService.logout();
      }
    } catch (e) {
      print('로그아웃 오류 (무시됨): $e');
    } finally {
      // 로컬 상태 초기화
      _token = null;
      _userId = null;
      _email = null;
      _userType = null;

      // 저장된 정보 삭제
      final prefs = await SharedPreferences.getInstance();
      prefs.clear();

      notifyListeners();
    }
  }
}
