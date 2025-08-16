import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to PetitPal',
      description: 'Your voice-first assistant designed for seniors. Just speak to get started!',
      icon: Icons.waving_hand,
    ),
    OnboardingPage(
      title: 'Voice Commands',
      description: 'Simply tap the microphone button and speak your question. I\'ll respond with clear audio.',
      icon: Icons.mic,
    ),
    OnboardingPage(
      title: 'Family Sharing',
      description: 'Share PetitPal with family members using QR codes for easy setup.',
      icon: Icons.family_restroom,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      setState(() => _currentPage++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() async {
    await ref.read(appProvider.notifier).completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Progress indicator
              Row(
                children: List.generate(
                  _pages.length,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          page.icon,
                          size: 120,
                          color: theme.colorScheme.primary,
                        ),
                        
                        const SizedBox(height: 40),
                        
                        Text(
                          page.title,
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: theme.colorScheme.onBackground,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          page.description,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onBackground,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  if (_currentPage > 0)
                    ElevatedButton(
                      onPressed: _previousPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        foregroundColor: theme.colorScheme.onSurface,
                        side: BorderSide(color: theme.colorScheme.outline),
                      ),
                      child: const Text('Previous'),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(
                      _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Skip button
              if (_currentPage < _pages.length - 1)
                TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}
