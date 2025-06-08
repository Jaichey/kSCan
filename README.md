# kscan

A new Flutter project from team #111(KMIT).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

##To build apps for all architecture
flutter build apk --debug --split-per-abi

##To build for specific version(debug mode)
flutter build apk --debug --split-per-abi --target-platform=android-arm64

##To build for specific version(release mode)
flutter build apk --release --split-per-abi --target-platform=android-arm64

##To create new launcher Icon
flutter pub run flutter_launcher_icons:main
