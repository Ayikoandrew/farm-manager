# 🐰 Farm Manager

A comprehensive livestock management application built with Flutter and Supabase for tracking animals, health records, breeding, feeding, weight progression, financial management, and an integrated livestock marketplace.

![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3FCF8E?logo=supabase&logoColor=white)
![Riverpod](https://img.shields.io/badge/Riverpod-State_Management-0553B1?logo=riverpod&logoColor=white)
![PostGIS](https://img.shields.io/badge/PostGIS-Geospatial-4169E1?logo=postgresql&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ Features

### 📊 Dashboard
- Overview of total animals, health status, and breeding stats
- Quick access to all modules
- Real-time data sync with Supabase

### 🐖 Animal Inventory
- Track animals with tag ID, breed, gender, birth date
- Monitor current weight and health status
- Status tracking: Healthy, Sick, Pregnant, Nursing, Sold, Deceased
- Age calculation and photo management
- Link animals to their parents (sire/dam lineage)

### 🏥 Health Management
- Comprehensive health records per animal
- Vaccination tracking and scheduling
- Treatment logs with medication details
- Health status monitoring

### 🍽️ Feeding Records
- Log daily feeding with feed type and quantity
- Track feeding history per animal
- Support for various feed types (Starter, Grower, Finisher, Custom)
- Cost tracking per feeding

### ⚖️ Weight Records
- Record weight measurements over time
- Automatic weight updates on animal profiles
- Track growth progression with charts
- Weight gain/loss analytics

### 🤰 Breeding Management
- Heat cycle tracking and detection
- Breeding date and sire recording
- Pregnancy monitoring with days pregnant calculator
- Expected farrowing/calving date calculation
- Litter size tracking and offspring linking

### 💰 Financial Management
- Income and expense tracking
- Transaction categorization
- Financial reports and summaries
- Payment integration with Flutterwave

### 🛒 Livestock Marketplace (In progress)
- **Peer-to-peer marketplace** for buying, selling, and trading livestock
- **PostGIS-powered** location-based search (find animals near you)
- Seller profiles with verification levels
- In-app messaging between buyers and sellers
- **Live auctions** with real-time bidding
- Transaction management with dispute resolution
- Review and rating system for sellers
- Saved searches with notifications

### 🤖 AI-Powered Assistant
- Natural language queries about your farm data
- AI-generated insights and recommendations
- Powered by Google Gemini
- GenUI components for interactive responses

### 📈 Reports & Analytics
- Export data to PDF, CSV, and Excel
- Weight progression charts
- Breeding success rates
- Financial summaries

### 🔌 Hardware Integration (R&D)
We're actively researching and developing custom IoT hardware solutions:

- **Custom IoT Scales** — Bluetooth/WiFi-enabled weighing scales designed specifically for livestock, with automatic weight capture and sync to the app
- **RFID Readers** — Custom NFC/RFID tag readers for quick animal identification and instant record lookup
- **Integration Goals**: Seamless data flow from physical devices → Farm Manager app → Cloud analytics

> 🧪 *Currently in research phase. Hardware prototypes and documentation coming soon.*

---

## 🏗️ Architecture

```
lib/
├── main.dart                    # App entry point
├── config/
│   └── supabase_config.dart     # Supabase initialization
├── models/                      # Data models
│   ├── animal.dart
│   ├── breeding_record.dart
│   ├── feeding_record.dart
│   ├── health_record.dart
│   ├── weight_record.dart
│   ├── transaction.dart
│   ├── payment.dart
│   ├── user.dart
│   └── marketplace/             # Marketplace models
│       ├── marketplace_listing.dart
│       ├── seller_profile.dart
│       ├── marketplace_auction.dart
│       └── ...
├── providers/                   # Riverpod state providers
│   └── providers.dart
├── repositories/                # Data access layer (Supabase)
│   ├── animal_repository.dart
│   ├── breeding_repository.dart
│   ├── feeding_repository.dart
│   ├── health_repository.dart
│   ├── weight_repository.dart
│   ├── financial_repository.dart
│   ├── payment_repository.dart
│   ├── marketplace_repository.dart
│   └── auth_repository.dart
├── services/                    # Business logic & external services
│   ├── gemini_content_generator.dart
│   ├── memory_service.dart
│   ├── ml_service.dart
│   ├── connectivity_service.dart
│   └── camera_service.dart
├── router/                      # Navigation (Zenrouter)
│   └── app_router.dart
├── screens/                     # UI screens
│   ├── dashboard/
│   ├── animals/
│   ├── breeding/
│   ├── feeding/
│   ├── weight/
│   ├── health/
│   ├── financial/
│   ├── payments/
│   ├── reports/
│   ├── settings/
│   ├── auth/
│   └── ml/
├── widgets/                     # Reusable UI components
└── utils/                       # Utility functions & helpers
```

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| **Framework** | Flutter 3.10+ (Dart) |
| **State Management** | Riverpod 3.x |
| **Navigation** | Zenrouter (Coordinator pattern) |
| **Backend** | Supabase (PostgreSQL, Auth, Storage, Realtime) |
| **Geospatial** | PostGIS extension for location-based features |
| **AI/ML** | Google Gemini API, GenUI |
| **Payments** | Flutterwave integration |
| **Charts** | FL Chart |
| **PDF/Export** | pdf, csv, excel packages |
| **Architecture** | Repository pattern with reactive streams (RxDart) |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10+
- A Supabase project (free tier works)
- Google Gemini API key (for AI features)
- Flutterwave API keys (for payments, optional)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/farm-manager.git
   cd farm-manager/manage
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   
   Create a `.env` file in the project root:
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   GEMINI_API_KEY=your-gemini-api-key
   FLUTTERWAVE_PUBLIC_KEY=your-flutterwave-key
   ```

4. **Set up Supabase database**
   
   Apply the schema migrations from `supabase/schema.sql` to your Supabase project, or use the Supabase CLI:
   ```bash
   supabase db push
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/repositories/animal_repository_test.dart
```

---

## 📱 Supported Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| Android | ✅ Ready | Primary development platform |
| Web | ✅ Ready | Full PWA support |
| Windows | ✅ Ready | Desktop experience |
| Linux | ✅ Ready | Desktop experience |
| iOS | ⏳ Pending | Requires Apple Developer account |
| macOS | ⏳ Pending | Requires Apple Developer account |

---

## 📂 Key Data Models

### Animal
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| tagId | String | Physical tag number |
| name | String? | Optional animal name |
| species | String | Species (cattle, goat, sheep, pig, etc.) |
| breed | String | Animal breed |
| gender | Enum | Male / Female |
| birthDate | DateTime | Date of birth |
| currentWeight | double | Latest weight in kg |
| status | Enum | Healthy, Sick, Pregnant, Nursing, Sold, Deceased |
| sireId | UUID? | Father reference |
| damId | UUID? | Mother reference |
| photoUrl | String? | Profile photo URL |

### Marketplace Listing
| Field | Type | Description |
|-------|------|-------------|
| id | UUID | Unique identifier |
| sellerId | UUID | Reference to seller profile |
| title | String | Listing title |
| species | String | Animal species |
| breed | String? | Animal breed |
| price | double | Asking price |
| currency | String | Currency code (UGX, KES, USD) |
| negotiable | bool | Open to negotiation |
| listingType | Enum | sale, auction, trade |
| status | Enum | draft, active, sold, expired |
| location | PostGIS Point | Geographic coordinates |
| region | String | Region/state |
| district | String? | District/county |

---

## 🗺️ Roadmap

### Completed ✅
- Animal inventory management
- Breeding records & pregnancy tracking
- Feeding & weight records
- Health management module
- Financial tracking & payments
- AI-powered assistant
- Livestock marketplace (database & models)
- PostGIS geospatial queries
- Supabase Realtime for messaging & auctions

### In Progress 🚧
- Marketplace UI screens
- Hardware IoT integration (R&D)
- ML prediction models
- Multi-farm support

### Planned 📋
- Offline-first architecture with sync
- Push notifications
- Advanced analytics dashboard
- White-label customization

See detailed roadmaps:
- [ROADMAP.md](ROADMAP.md) — General development roadmap
- [LIVESTOCK_MARKETPLACE_ROADMAP.md](LIVESTOCK_MARKETPLACE_ROADMAP.md) — Marketplace feature roadmap
- [ML_PIPELINE_ROADMAP.md](ML_PIPELINE_ROADMAP.md) — Machine learning pipeline roadmap

---

## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. Fork the repository
2. Create a feature branch
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. Make your changes and write tests
4. Commit with a descriptive message
   ```bash
   git commit -m 'Add amazing feature'
   ```
5. Push to your fork
   ```bash
   git push origin feature/amazing-feature
   ```
6. Open a Pull Request

### Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Run `dart format .` before committing
- Ensure `flutter analyze` passes with no issues

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) — Beautiful native apps framework
- [Supabase](https://supabase.com/) — Open-source Firebase alternative
- [Riverpod](https://riverpod.dev/) — Reactive state management
- [PostGIS](https://postgis.net/) — Spatial database extender
- [Zenrouter](https://pub.dev/packages/zenrouter) — Coordinator-based navigation
- [Google Gemini](https://ai.google.dev/) — AI/ML capabilities
- [Flutterwave](https://flutterwave.com/) — African payments infrastructure

---

<p align="center">
  Built with ❤️ for farmers across Africa and beyond
</p>
