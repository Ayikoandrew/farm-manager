# 🐰 Farm Manager

A comprehensive livestock management application built with Flutter for tracking animals, feeding, weight, breeding, and ML-powered analytics.

![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange?logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

### 📊 Dashboard
- Overview of total animals, health status, and breeding stats
- Quick access to all modules
- Real-time data from Firestore

### 🐖 Animal Inventory
- Track animals with tag ID, breed, gender, birth date
- Monitor current weight and health status
- Status tracking: Healthy, Sick, Pregnant, Nursing, Sold, Deceased
- Age calculation and formatting

### 🍽️ Feeding Records
- Log daily feeding with feed type and quantity
- Track feeding history per animal
- Support for various feed types (Starter, Grower, Finisher)

### ⚖️ Weight Records
- Record weight measurements over time
- Automatic weight updates on animal profiles
- Track growth progression

### 🤰 Breeding Management
- Heat cycle tracking
- Breeding date and sire recording
- Pregnancy monitoring with days pregnant calculator
- Expected farrowing date calculation (114-day gestation)
- Litter size tracking

### 🤖 ML Analytics (Coming Soon)
- Weight prediction models
- Health risk assessment
- Breeding success predictions
- Feed optimization recommendations

## 🏗️ Architecture

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
│   ├── animal.dart
│   ├── breeding_record.dart
│   ├── feeding_record.dart
│   └── weight_record.dart
├── providers/                # Riverpod providers
│   └── providers.dart
├── repositories/             # Firestore repositories
│   ├── animal_repository.dart
│   ├── breeding_repository.dart
│   ├── feeding_repository.dart
│   └── weight_repository.dart
├── router/                   # Zenrouter coordinator
│   └── app_router.dart
└── screens/                  # UI screens
    ├── dashboard_screen.dart
    ├── animals/
    ├── breeding/
    ├── feeding/
    ├── weight/
    └── ml/
```

## 🛠️ Tech Stack

- **Framework**: Flutter 3.10+
- **State Management**: Riverpod
- **Navigation**: Zenrouter (Coordinator pattern)
- **Backend**: Supabase (Auth, Storage)
- **Architecture**: Repository pattern with reactive streams

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10+
- Firebase CLI
- A Firebase project

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/farm-manager.git
   cd farm-manager
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   ```bash
   flutterfire configure --project=your-project-id
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📱 Supported Platforms

- ✅ Android
- ✅ Web
- ✅ Windows
- ✅ Linux
- ⏳ iOS (pending configuration)
- ⏳ macOS (pending configuration)

## 📂 Data Models

### Animal
| Field | Type | Description |
|-------|------|-------------|
| tagId | String | Unique identifier tag |
| breed | String | Animal breed |
| gender | Enum | Male / Female |
| birthDate | DateTime | Date of birth |
| currentWeight | double | Current weight in kg |
| status | Enum | Health/life status |

### Breeding Record
| Field | Type | Description |
|-------|------|-------------|
| animalId | String | Reference to female animal |
| sireId | String? | Reference to male animal |
| heatDate | DateTime | Date heat was detected |
| breedingDate | DateTime? | Date of breeding |
| expectedFarrowDate | DateTime? | Calculated farrowing date |
| status | Enum | inHeat, bred, pregnant, farrowed, failed |

## 🗺️ Roadmap

See [ROADMAP.md](ROADMAP.md) for detailed future plans including:

- 🔐 Authentication & multi-farm support
- 📴 Offline-first architecture
- 🧠 ML model integration
- 🔔 Push notifications
- 💰 Financial tracking
- 🏥 Health management module
- 📊 Advanced reporting
- 🔗 Hardware integration (scales, RFID)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) - UI framework
- [Riverpod](https://riverpod.dev/) - State management
- [Zenrouter](https://pub.dev/packages/zenrouter) - Navigation
- [Firebase](https://firebase.google.com/) - Backend services

---

Built with ❤️ for farmers
