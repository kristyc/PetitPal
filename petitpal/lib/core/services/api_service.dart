import 'dart:convert';
import 'package:dio/dio.dart';
import '../../config/internal_config.dart';

class ApiService {
  late final Dio _dio;
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: InternalConfig.workerBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptors for logging in debug mode
    if (InternalConfig.showDebugMenu) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  // Chat with LLM
  Future<ChatResponse> chat({
    required String message,
    required String provider,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post('/api/chat', data: {
        'message': message,
        'provider': provider,
        'deviceId': deviceId,
      });
      return ChatResponse.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Please add your API key for $provider');
      }
      throw Exception('Failed to send message: ${e.message}');
    }
  }

  // Save encrypted keys
  Future<void> saveKeys({
    required String deviceId,
    required Map<String, String> encryptedKeys,
  }) async {
    try {
      await _dio.post('/api/keys/save', data: {
        'deviceId': deviceId,
        'encryptedKeys': encryptedKeys,
      });
    } catch (e) {
      throw Exception('Failed to save keys: $e');
    }
  }

  // Get encrypted keys
  Future<Map<String, String>?> getKeys(String deviceId) async {
    try {
      final response = await _dio.get('/api/keys/get', queryParameters: {
        'deviceId': deviceId,
      });
      return Map<String, String>.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw Exception('Failed to get keys: ${e.message}');
    }
  }

  // Create family invite
  Future<FamilyInvite> createInvite({
    required String deviceId,
    required String memberName,
  }) async {
    try {
      final response = await _dio.post('/api/family/create_invite', data: {
        'deviceId': deviceId,
        'memberName': memberName,
      });
      return FamilyInvite.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create invite: $e');
    }
  }

  // Accept family invite
  Future<void> acceptInvite({
    required String token,
    required String deviceId,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      await _dio.post('/api/family/accept_invite', data: {
        'token': token,
        'deviceId': deviceId,
        'deviceInfo': deviceInfo,
      });
    } catch (e) {
      throw Exception('Failed to accept invite: $e');
    }
  }

  // Get family members
  Future<List<FamilyMemberData>> getFamilyMembers(String familyId) async {
    try {
      final response = await _dio.get('/api/family/list', queryParameters: {
        'familyId': familyId,
      });
      final data = response.data;
      final members = (data['members'] as List)
          .map((m) => FamilyMemberData.fromJson(m))
          .toList();
      return members;
    } catch (e) {
      throw Exception('Failed to get family members: $e');
    }
  }
}

// Response models
class ChatResponse {
  final String summary;
  final String fullResponse;
  final String modelUsed;
  final String? switchReason;

  ChatResponse({
    required this.summary,
    required this.fullResponse,
    required this.modelUsed,
    this.switchReason,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      summary: json['summary'],
      fullResponse: json['fullResponse'],
      modelUsed: json['modelUsed'],
      switchReason: json['switchReason'],
    );
  }
}

class FamilyInvite {
  final String token;
  final String familyId;
  final String inviteLink;
  final String expiresIn;

  FamilyInvite({
    required this.token,
    required this.familyId,
    required this.inviteLink,
    required this.expiresIn,
  });

  factory FamilyInvite.fromJson(Map<String, dynamic> json) {
    return FamilyInvite(
      token: json['token'],
      familyId: json['familyId'],
      inviteLink: json['inviteLink'],
      expiresIn: json['expiresIn'],
    );
  }
}

class FamilyMemberData {
  final String deviceId;
  final String name;
  final String role;
  final DateTime joinedAt;

  FamilyMemberData({
    required this.deviceId,
    required this.name,
    required this.role,
    required this.joinedAt,
  });

  factory FamilyMemberData.fromJson(Map<String, dynamic> json) {
    return FamilyMemberData(
      deviceId: json['deviceId'],
      name: json['name'],
      role: json['role'],
      joinedAt: DateTime.parse(json['joinedAt']),
    );
  }
}