# PetitPal B1.1 (fix: remove qr_code_scanner)

Run:
  cd petitpal
  flutter pub get
  flutter clean
  flutter run

If you had the previous overlay, this build removes the 'qr_code_scanner' package which caused AGP namespace errors on Windows.


B1.2: Fix missing import in settings_screen.dart.
