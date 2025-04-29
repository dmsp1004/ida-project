import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:math';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // OAuth2 관련 설정
  final String _clientId = 'childcare-client';
  final String _redirectUri =
      kIsWeb
          ? 'http://localhost:3000/oauth/callback'
          : 'com.ida.childcare:/oauth/callback';

  // 플랫폼별 기본 URL 설정
  String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8085/api';
    } else {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8085/api';
      } else {
        return 'http://localhost:8085/api';
      }
    }
  }

  // OAuth2 서버 URL
  String get _oauth2BaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8085';
    } else {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8085';
      } else {
        return 'http://localhost:8085';
      }
    }
  }

  ApiService._internal() {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 요청 인터셉터 추가 (토큰 자동 첨부)
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('요청: ${options.method} ${options.path}');
          print('헤더: ${options.headers}');
          if (options.data != null) {
            print('데이터: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('응답: ${response.statusCode}');
          print('응답 데이터: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('오류: ${error.message}');
          if (error.response != null) {
            print('오류 응답: ${error.response?.data}');
          }
          // 401 에러 처리 (토큰 만료 등)
          if (error.response?.statusCode == 401) {
            // 토큰 삭제
            _secureStorage.delete(key: 'auth_token');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // _dio 객체에 접근할 수 있는 getter 메서드 추가
  Dio getDio() {
    return _dio;
  }

  // baseUrl 접근을 위한 getter 추가
  String getBaseUrl() {
    return _baseUrl;
  }

  // 로그인 메서드
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      // 토큰 저장
      await _secureStorage.write(
        key: 'auth_token',
        value: response.data['token'],
      );

      return response.data;
    } catch (e) {
      print('로그인 오류: $e');
      rethrow;
    }
  }

  // 소셜 로그인 URL 생성
  String getOAuth2AuthUrl(String provider) {
    final state = _generateRandomString(30); // CSRF 방지용 상태값
    _secureStorage.write(key: 'oauth2_state', value: state);

    // 제공자별 URL 생성
    switch (provider.toLowerCase()) {
      case 'google':
        return '$_oauth2BaseUrl/oauth2/authorization/google?client_id=$_clientId&redirect_uri=$_redirectUri&state=$state';
      case 'kakao':
        return '$_oauth2BaseUrl/oauth2/authorization/kakao?client_id=$_clientId&redirect_uri=$_redirectUri&state=$state';
      case 'naver':
        return '$_oauth2BaseUrl/oauth2/authorization/naver?client_id=$_clientId&redirect_uri=$_redirectUri&state=$state';
      default:
        throw Exception('지원하지 않는 소셜 로그인 제공자: $provider');
    }
  }

  // 소셜 로그인 처리
  Future<Map<String, dynamic>> processSocialLogin(
    String code,
    String provider,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/oauth2/callback/$provider',
        data: {'code': code, 'redirect_uri': _redirectUri},
      );

      // 토큰 저장
      await _secureStorage.write(
        key: 'auth_token',
        value: response.data['token'],
      );

      return response.data;
    } catch (e) {
      print('소셜 로그인 처리 오류: $e');
      rethrow;
    }
  }

  bool _isValidating = false;
  // 토큰 유효성 검증
  Future<bool> validateToken(String token) async {
    if (_isValidating) return true; // 중복 방지
    _isValidating = true;

    try {
      final response = await _dio.get('/auth/validate-token');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    } finally {
      _isValidating = false;
    }
  }

  // 회원가입 메서드
  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String phoneNumber,
    String userType,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          'userType': userType, // PARENT 또는 SITTER
        },
      );

      // 토큰 저장
      await _secureStorage.write(
        key: 'auth_token',
        value: response.data['token'],
      );

      return response.data;
    } catch (e) {
      print('회원가입 오류: $e');
      rethrow;
    }
  }

  // 로그아웃 메서드
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      print('로그아웃 API 오류: $e');
    } finally {
      await _secureStorage.delete(key: 'auth_token');
    }
  }

  // CSRF 방지용 랜덤 문자열 생성
  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
