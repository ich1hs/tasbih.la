# tasbih.la

A beautiful digital tasbih (prayer counter) app built with Flutter.

<p align="center">
  <img src="docs/screenshots/flutter_01.png" alt="Tasbih.la Screenshot" width="300"/>
</p>

## Features

- **Counter** — Tap anywhere to count, with smooth animations and haptic feedback
- **Progress Ring** — Visual progress with milestone markers at 33, 66, 99
- **Confetti Celebration** — Celebrate when you hit milestones or complete your target
- **Multiple Zikr** — Create and manage custom zikr presets with different targets
- **Quick Switcher** — Tap the zikr name to quickly switch between saved zikr
- **Chains** — Link multiple zikr together for guided dhikr sessions
- **Prayer Times** — View prayer times based on your location
- **Statistics** — Track your total counts and completion rates
- **Sound Effects** — Optional tap, milestone, and completion sounds
- **Backup & Restore** — Export and import your data
- **Dark/Light Mode** — Follows your system theme

## Download

Get the latest release from the [Releases](https://github.com/ich1hs/tasbih.la/releases) page.

## Building from Source

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.10.1+)
- Android Studio or VS Code with Flutter extension

### Setup

```bash
# Clone the repository
git clone https://github.com/ich1hs/tasbih.la.git
cd tasbih.la

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build APK

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`

## Project Structure

```
lib/
├── main.dart              # App entry point
├── models/                # Data models (Zikr, ZikrChain)
├── providers/             # State management (Provider)
├── repositories/          # Data access layer
├── services/              # Audio, backup, prayer times, storage
├── ui/
│   ├── screens/           # App screens
│   └── widgets/           # Reusable widgets
└── utils/                 # Utilities and helpers
```

## Documentation

- [Testing Guide](docs/TESTING_GUIDE.md) — How to test the app
- [Sound Files Guide](docs/SOUND_FILES_GUIDE.md) — Adding custom sound effects

## Tech Stack

- **Flutter** — Cross-platform UI framework
- **Provider** — State management
- **Hive** — Local NoSQL database
- **Audioplayers** — Sound effects
- **Geolocator** — Location for prayer times

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source.

---

Made with ❤️ for those who love... sabila?
