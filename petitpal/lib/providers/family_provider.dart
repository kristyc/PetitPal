import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/worker_api.dart';

// Family data model
class FamilyMember {
  final String deviceId;
  final String name;
  final DateTime joinedAt;

  FamilyMember({
    required this.deviceId,
    required this.name,
    required this.joinedAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      deviceId: json['device_id'] as String,
      name: json['name'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'name': name,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}

class FamilyGroup {
  final String familyId;
  final List<FamilyMember> members;
  final String ownerDeviceId;
  final DateTime createdAt;

  FamilyGroup({
    required this.familyId,
    required this.members,
    required this.ownerDeviceId,
    required this.createdAt,
  });

  factory FamilyGroup.fromJson(Map<String, dynamic> json) {
    return FamilyGroup(
      familyId: json['family_id'] as String,
      members: (json['members'] as List)
          .map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      ownerDeviceId: json['owner_device_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

// Family state
class FamilyState {
  final FamilyGroup? family;
  final bool isLoading;
  final String? error;
  final String? pendingInviteToken;

  FamilyState({
    this.family,
    this.isLoading = false,
    this.error,
    this.pendingInviteToken,
  });

  FamilyState copyWith({
    FamilyGroup? family,
    bool? isLoading,
    String? error,
    String? pendingInviteToken,
  }) {
    return FamilyState(
      family: family ?? this.family,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pendingInviteToken: pendingInviteToken ?? this.pendingInviteToken,
    );
  }
}

// Family provider
class FamilyNotifier extends StateNotifier<FamilyState> {
  FamilyNotifier() : super(FamilyState());

  final WorkerApiService _apiService = WorkerApiService();

  // Create a new family invite
  Future<String?> createInvite(String memberName) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.createFamilyInvite(memberName);
      if (response['success'] == true) {
        final token = response['token'] as String;
        return token;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['error'] as String? ?? 'Failed to create invite',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
      );
      return null;
    }
  }

  // Accept family invite
  Future<bool> acceptInvite(String token) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.acceptFamilyInvite(token);
      if (response['success'] == true) {
        await loadFamily(); // Reload family data
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['error'] as String? ?? 'Failed to accept invite',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
      );
      return false;
    }
  }

  // Load current family data
  Future<void> loadFamily() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.getFamilyMembers();
      if (response['success'] == true && response['family'] != null) {
        final family = FamilyGroup.fromJson(response['family'] as Map<String, dynamic>);
        state = state.copyWith(
          family: family,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['error'] as String?,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load family: ${e.toString()}',
      );
    }
  }

  // Remove family member
  Future<bool> removeMember(String deviceId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.removeFamilyMember(deviceId);
      if (response['success'] == true) {
        await loadFamily(); // Reload family data
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['error'] as String? ?? 'Failed to remove member',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error: ${e.toString()}',
      );
      return false;
    }
  }

  // Set pending invite token (for deep link handling)
  void setPendingInviteToken(String? token) {
    state = state.copyWith(pendingInviteToken: token);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider definition
final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  return FamilyNotifier();
});

// Convenience providers
final familyMembersProvider = Provider<List<FamilyMember>>((ref) {
  final family = ref.watch(familyProvider).family;
  return family?.members ?? [];
});

final isInFamilyProvider = Provider<bool>((ref) {
  final family = ref.watch(familyProvider).family;
  return family != null && family.members.isNotEmpty;
});