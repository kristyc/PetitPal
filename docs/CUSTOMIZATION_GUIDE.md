# Customization Guide

- **Themes**: Add/edit entries in `lib/src/theme/registry.dart`. Each theme carries tokens and descriptions.
- **Animations**: Use tokens (durations) from `PetitTokens`. Add premium effects per theme family.
- **Providers**: Extend ProviderSetupScreen; store locally; push encrypted backup via Worker.
- **Feature Flags**: Central toggles in `lib/config/internal_config.dart`.
- **Auto-switching**: Server logic in Worker `pickModel()`.
