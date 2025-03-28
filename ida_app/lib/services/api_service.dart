import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // 플랫폼별 기본 URL 설정
  String get _baseUrl {
    if (kIsWeb) {
      // 웹 환경
      return 'http://localhost:8085/api';
    } else {
      // 네이티브 환경
      if (Platform.isAndroid) {
        // 안드로이드 에뮬레이터
        return 'http://10.0.2.2:8085/api';
      } else if (Platform.isIOS) {
        // iOS 시뮬레이터
        return 'http://localhost:8085/api';
      } else {
        // 기타 플랫폼 (윈도우, 맥OS, 리눅스 등)
        return 'http://localhost:8085/api';
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
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
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
          return handler.next(options);
        },
        onError: (error, handler) {
          // 401 에러 처리 (토큰 만료 등)
          if (error.response?.statusCode == 401) {
            // 로그인 화면으로 리다이렉트 로직 추가 가능
          }
          return handler.next(error);
        },
      ),
    );
  }

  // 로그인 메서드
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('로그인 요청: $email, $_baseUrl/auth/login');

      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 데이터: ${response.data}');

      // 토큰 저장
      await _secureStorage.write(
        key: 'auth_token',
        value: response.data['token'],
      );

      // 사용자 역할에 따른 userType 저장
      String userType = 'PARENT'; // 기본값
      if (response.data.containsKey('role')) {
        final role = response.data['role'];
        if (role == 'ADMIN') {
          userType = 'ADMIN';
        } else if (role == 'SITTER') {
          userType = 'SITTER';
        } else if (role == 'PARENT') {
          userType = 'PARENT';
        }
      }

      await _secureStorage.write(key: 'user_type', value: userType);
      await _secureStorage.write(
        key: 'user_id',
        value: response.data['userId'].toString(),
      );

      return response.data;
    } catch (e) {
      print('로그인 오류: $e');
      rethrow;
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
      print('회원가입 요청: $email, $_baseUrl/auth/register');

      final response = await _dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          'role': userType, // PARENT 또는 SITTER
        },
      );

      print('응답 상태 코드: ${response.statusCode}');
      print('응답 데이터: ${response.data}');

      // 토큰 저장
      await _secureStorage.write(
        key: 'auth_token',
        value: response.data['token'],
      );
      await _secureStorage.write(key: 'user_type', value: userType);
      await _secureStorage.write(
        key: 'user_id',
        value: response.data['userId'].toString(),
      );

      return response.data;
    } catch (e) {
      print('회원가입 오류: $e');
      rethrow;
    }
  }

  // 로그아웃 메서드
  Future<void> logout() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'user_type');
    await _secureStorage.delete(key: 'user_id');
  }

  // 인증 상태 확인
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return token != null;
  }

  Future<String?> getUserType() async {
    return await _secureStorage.read(key: 'user_type');
  }
}
