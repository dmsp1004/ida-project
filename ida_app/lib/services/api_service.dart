import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _baseUrl = 'http://10.0.2.2:8085/api'; // 에뮬레이터에서 localhost 접근
  
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // 요청 인터셉터 추가 (토큰 자동 첨부)
    _dio.interceptors.add(InterceptorsWrapper(
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
      }
    ));
  }
  
  // 로그인 메서드
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      // 토큰 저장
      await _secureStorage.write(key: 'auth_token', value: response.data['token']);
      await _secureStorage.write(key: 'user_type', value: response.data['userType']);
      await _secureStorage.write(key: 'user_id', value: response.data['userId'].toString());
      
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
  
  // 회원가입 메서드
  Future<Map<String, dynamic>> register(String email, String password, String phoneNumber, String userType) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'userType': userType,
      });
      
      // 토큰 저장
      await _secureStorage.write(key: 'auth_token', value: response.data['token']);
      await _secureStorage.write(key: 'user_type', value: response.data['userType']);
      await _secureStorage.write(key: 'user_id', value: response.data['userId'].toString());
      
      return response.data;
    } catch (e) {
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