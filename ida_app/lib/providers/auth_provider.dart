import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  int? _userId;
  String? _email;
  String? _userType; // 사용자 유형 (PARENT, SITTER, ADMIN)
  String? _errorMessage;

  // Getter 메서드
  String? get token => _token;
  int? get userId => _userId;
  String? get email => _email;
  String? get userType => _userType;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;

  // 로그인 처리
  Future<bool> login(String email, String password) async {
    _errorMessage = null; // 오류 메시지 초기화
    try {
      // API URL 설정 (에뮬레이터/실제 기기 여부에 따라 분기)
      final url =
          kIsWeb
              ? 'http://localhost:8085/api/auth/login' // 웹
              : 'http://10.0.2.2:8085/api/auth/login'; // 에뮬레이터

      // HTTP 요청
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      // 응답 처리
      if (response.statusCode == 200) {
        // JSON 응답 파싱
        final responseData = json.decode(response.body);

        // 토큰 및 사용자 정보 저장
        _token = responseData['token'];
        _userId = responseData['userId'];
        _email = responseData['email'];
        _userType = responseData['role']; // 백엔드에서 제공하는 사용자 유형(role) 저장

        // 로컬 저장소에 정보 저장
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('token', _token!);
        prefs.setInt('userId', _userId!);
        prefs.setString('email', _email!);
        prefs.setString('userType', _userType!); // 사용자 유형 저장

        print('로그인 성공: 유형=$_userType, 이메일=$_email');
        notifyListeners();
        return true;
      } else {
        // 오류 응답 처리
        final responseData = json.decode(response.body);
        _errorMessage = responseData['message'] ?? '로그인에 실패했습니다.';
        print('로그인 실패: $_errorMessage');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = '서버 연결 오류: $e';
      print('로그인 예외 발생: $_errorMessage');
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
    _userType = prefs.getString('userType'); // 저장된 사용자 유형 불러오기

    notifyListeners();
    return true;
  }

  // 로그아웃
  Future<void> logout() async {
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
