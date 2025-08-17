import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ChatPhase { idle, listening, thinking, speaking }

final chatPhaseProvider = StateProvider<ChatPhase>((ref) => ChatPhase.idle);
