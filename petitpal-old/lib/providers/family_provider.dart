import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FamilyMember {
  final String deviceId;
  final String name;
  final DateTime joinedAt;

  const FamilyMember({
    required this.deviceId,
    required this.name,
    required this.joinedAt,
  });

  FamilyMember copyWith({
    String? deviceId,
    String? name,
    DateTime? joinedAt,
  }) {
    return FamilyMember(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class FamilyState {
  final String? familyId;
  final List<FamilyMember> members;
  final String? pendingInviteToken;
  final bool isLoading;

  const FamilyState({
    this.familyId,
    this.members = const [],
    this.pendingInviteToken,
    this.isLoading = false,
  });

  FamilyState copyWith({
    String? familyId,
    List<FamilyMember>? members,
    String? pendingInviteToken,
    bool? isLoading,
  }) {
    return FamilyState(
      familyId: familyId ?? this.familyId,
      members: members ?? this.members,
      pendingInviteToken: pendingInviteToken ?? this.pendingInviteToken,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FamilyNotifier extends StateNotifier<FamilyState> {
  FamilyNotifier() : super(const FamilyState());

  Future<void> loadFamily() async {
    // TODO: Implement loading family from storage/API
    print('Loading family data...');
  }

  void setPendingInviteToken(String token) {
    state = state.copyWith(pendingInviteToken: token);
  }

  Future<bool> acceptInvite(String token) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // TODO: Implement actual invite acceptance
      print('Accepting invite with token: $token');
      
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      // For now, just clear the pending token
      state = state.copyWith(
        pendingInviteToken: null,
        isLoading: false,
      );
      
      return true; // Success
    } catch (e) {
      print('Error accepting invite: $e');
      state = state.copyWith(isLoading: false);
      return false; // Failure
    }
  }

  Future<void> createInvite() async {
    // TODO: Implement invite creation
    print('Creating family invite...');
  }

  Future<void> removeMember(String deviceId) async {
    // TODO: Implement member removal
    print('Removing member: $deviceId');
  }
}

final familyProvider = StateNotifierProvider<FamilyNotifier, FamilyState>((ref) {
  return FamilyNotifier();
});