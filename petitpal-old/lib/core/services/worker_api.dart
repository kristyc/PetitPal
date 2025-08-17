import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/internal_config.dart';

class WorkerApiService {
  static final WorkerApiService _instance = WorkerApiService._internal();
  factory WorkerApiService() => _instance;
  WorkerApiService._internal();

  static const Duration _defaultTimeout = Duration(seconds: 30);
  String get _baseUrl => InternalConfig.workerBaseUrl;
  
  // HTTP client with timeout
  final http.Client _client = http.Client();

  // Common headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'User-Agent': 'PetitPal-Flutter/${InternalConfig.appVersion}',
  };

  // Helper method to make HTTP requests with error handling
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Duration? timeout,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint').replace(
        queryParameters: queryParams,
      );

      late http.Response response;
      final requestTimeout = timeout ?? _defaultTimeout;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: _headers).timeout(requestTimeout);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(requestTimeout);
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: _headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(requestTimeout);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: _headers).timeout(requestTimeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (kDebugMode) {
        print('🌐 API Request: $method $endpoint');
        print('📤 Response: ${response.statusCode} - ${response.body}');
      }

      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        responseData = {
          'success': false,
          'error': 'Invalid JSON response',
          'raw_response': response.body,
        };
      }

      // Handle HTTP errors
      if (response.statusCode < 200 || response.statusCode >= 300) {
        responseData['success'] = false;
        responseData['status_code'] = response.statusCode;
        
        if (!responseData.containsKey('error')) {
          responseData['error'] = 'HTTP ${response.statusCode}: ${_getStatusMessage(response.statusCode)}';
        }
      }

      return responseData;

    } on SocketException {
      return {
        'success': false,
        'error': 'No internet connection. Please check your network and try again.',
        'error_type': 'network',
      };
    } on http.ClientException {
      return {
        'success': false,
        'error': 'Connection failed. Please try again.',
        'error_type': 'connection',
      };
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Request timed out. Please try again.',
        'error_type': 'timeout',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'An unexpected error occurred: ${e.toString()}',
        'error_type': 'unknown',
      };
    }
  }

  String _getStatusMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      default:
        return 'Unknown Error';
    }
  }

  // Chat/LLM endpoints
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    required String model,
    String? deviceId,
  }) async {
    return await _makeRequest('POST', '/api/chat', body: {
      'message': message,
      'model': model,
      'device_id': deviceId,
    });
  }

  // Provider key management
  Future<Map<String, dynamic>> saveProviderKeys({
    required String deviceId,
    required String encryptedData,
  }) async {
    return await _makeRequest('POST', '/api/keys/save', body: {
      'device_id': deviceId,
      'encrypted_data': encryptedData,
    });
  }

  Future<Map<String, dynamic>> getProviderKeys(String deviceId) async {
    return await _makeRequest('GET', '/api/keys/get', queryParams: {
      'device_id': deviceId,
    });
  }

  // Family management endpoints
  Future<Map<String, dynamic>> createFamilyInvite(String memberName) async {
    return await _makeRequest('POST', '/api/family/create_invite', body: {
      'member_name': memberName,
    });
  }

  Future<Map<String, dynamic>> acceptFamilyInvite(String token) async {
    return await _makeRequest('POST', '/api/family/accept_invite', body: {
      'token': token,
    });
  }

  Future<Map<String, dynamic>> getFamilyMembers() async {
    return await _makeRequest('GET', '/api/family/list');
  }

  Future<Map<String, dynamic>> removeFamilyMember(String deviceId) async {
    return await _makeRequest('DELETE', '/api/family/remove_member', body: {
      'device_id': deviceId,
    });
  }

  // Health check
  Future<Map<String, dynamic>> healthCheck() async {
    return await _makeRequest('GET', '/api/health');
  }

  // Version check
  Future<Map<String, dynamic>> getVersion() async {
    return await _makeRequest('GET', '/api/version');
  }

  // Test provider keys
  Future<Map<String, dynamic>> testProviderKey({
    required String provider,
    required String apiKey,
  }) async {
    return await _makeRequest('POST', '/api/test_key', body: {
      'provider': provider,
      'api_key': apiKey,
    });
  }

  // Cleanup
  void dispose() {
    _client.close();
  }
}

// Helper class for API responses
class ApiResponse {
  final bool success;
  final Map<String, dynamic> data;
  final String? error;
  final String? errorType;

  ApiResponse({
    required this.success,
    required this.data,
    this.error,
    this.errorType,
  });

  factory ApiResponse.fromMap(Map<String, dynamic> map) {
    return ApiResponse(
      success: map['success'] as bool? ?? false,
      data: map,
      error: map['error'] as String?,
      errorType: map['error_type'] as String?,
    );
  }

  bool get isNetworkError => errorType == 'network';
  bool get isTimeoutError => errorType == 'timeout';
  bool get isConnectionError => errorType == 'connection';
  bool get isUnknownError => errorType == 'unknown';

  @override
  String toString() {
    return 'ApiResponse(success: $success, error: $error, errorType: $errorType)';
  }
}