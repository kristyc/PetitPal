import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/voice_provider.dart';
import '../../providers/app_provider.dart';
import '../../config/internal_config.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize voice permissions on home screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(voiceProvider.notifier).initializeVoice();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final voiceState = ref.watch(voiceProvider);
    final appState = ref.watch(appProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PetitPal'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          // Settings button
          IconButton(
            onPressed: () => _showSettingsMenu(context),
            icon: const Icon(Icons.settings),
            iconSize: 28,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome message
              Text(
                'Hi there! 👋',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: theme.colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'What would you like to know?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Main voice button
              Center(
                child: GestureDetector(
                  onTap: () => _handleVoiceButtonTap(),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: _getButtonColor(theme, voiceState.isListening),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: voiceState.isListening ? 10 : 0,
                        ),
                      ],
                    ),
                    child: Icon(
                      _getButtonIcon(voiceState.isListening),
                      size: 80,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Status text
              Text(
                _getStatusText(voiceState),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onBackground,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Quick action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickActionButton(
                    context,
                    icon: Icons.family_restroom,
                    label: 'Family',
                    onTap: () => Navigator.pushNamed(context, '/family'),
                  ),
                  _buildQuickActionButton(
                    context,
                    icon: Icons.palette,
                    label: 'Themes',
                    onTap: () => Navigator.pushNamed(context, '/themes'),
                  ),
                  _buildQuickActionButton(
                    context,
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () => Navigator.pushNamed(context, '/providers'),
                  ),
                ],
              ),
              
              // Debug info (only in development)
              if (InternalConfig.showDebugInfo) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Debug Info',
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Device ID: ${appState.deviceId.substring(0, 8)}...',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        'Environment: ${InternalConfig.environment}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleVoiceButtonTap() {
    final voiceNotifier = ref.read(voiceProvider.notifier);
    final voiceState = ref.read(voiceProvider);
    
    if (voiceState.isListening) {
      voiceNotifier.stopListening();
    } else {
      voiceNotifier.startListening();
    }
  }

  Color _getButtonColor(ThemeData theme, bool isListening) {
    if (isListening) {
      return theme.colorScheme.error;
    }
    return theme.colorScheme.primary;
  }

  IconData _getButtonIcon(bool isListening) {
    if (isListening) {
      return Icons.stop;
    }
    return Icons.mic;
  }

  String _getStatusText(VoiceState voiceState) {
    if (voiceState.isListening) {
      return 'Listening... Tap to stop';
    } else if (voiceState.isProcessing) {
      return 'Processing your question...';
    } else if (voiceState.isSpeaking) {
      return 'Speaking...';
    } else if (voiceState.error != null) {
      return 'Error: ${voiceState.error}';
    } else {
      return 'Tap the microphone to start';
    }
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.palette),
              title: const Text('Change Theme'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/themes');
              },
            ),
            ListTile(
              leading: const Icon(Icons.family_restroom),
              title: const Text('Family Sharing'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/family');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Provider Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/providers');
              },
            ),
          ],
        ),
      ),
    );
  }
}
