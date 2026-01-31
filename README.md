# 🐰 Farm Manager

<div align="center">

**A comprehensive livestock management platform with ML-powered analytics**

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688?logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.12+-3776AB?logo=python&logoColor=white)](https://python.org)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3FCF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

[Features](#-features) • [Architecture](#-architecture) • [Getting Started](#-getting-started) • [Documentation](#-documentation) • [Roadmap](#-roadmap)

</div>

---

## 📖 Overview

Farm Manager is a full-stack livestock management solution designed for modern farmers. It combines a beautiful Flutter mobile/web application with a powerful Python ML backend to help farmers:

- 📊 Track animal inventory, health, feeding, and weight records
- 🤖 Get AI-powered predictions for weight gain and health risks
- 💰 Manage farm finances with transaction tracking and reports
- 🔔 Receive smart reminders for vaccinations, breeding cycles, and feeding schedules
- 📈 Generate comprehensive reports with actionable insights

---

## ✨ Features

### 📱 Mobile & Web App (Flutter)

| Feature | Description |
|---------|-------------|
| **Dashboard** | Real-time overview of farm stats, health status, and quick actions |
| **Animal Inventory** | Track animals with tag ID, breed, gender, birth date, and status |
| **Weight Tracking** | Record weight measurements and visualize growth progression |
| **Health Records** | Log treatments, vaccinations, and monitor health scores |
| **Feeding Management** | Track daily feeding with feed types and quantities |
| **Breeding Management** | Heat cycle tracking, pregnancy monitoring, litter size recording |
| **Financial Tracking** | Income/expense tracking, budgets, and financial reports |
| **ML Analytics** | Weight predictions, health risk assessment, SHAP explanations |
| **Reports & Export** | Generate PDF/CSV/Excel reports for records |
| **Multi-platform** | Android, iOS, Web, Linux, macOS, Windows |

### 🧠 ML Backend (FastAPI + Python)

| Feature | Description |
|---------|-------------|
| **Weight Prediction** | LightGBM models predicting 7, 14, and 30-day weights |
| **Health Risk Assessment** | Identify at-risk animals before problems occur |
| **SHAP Explainability** | Understand why predictions are made |
| **Feature Engineering** | Automated feature computation from raw farm data |
| **MLflow Tracking** | Experiment tracking, model versioning, and registry |
| **Batch Processing** | Efficient pipeline for training data generation |
| **RESTful API** | Clean API for mobile app integration |

---

## 🏗 Architecture

```
farm-manager/
├── manage/                 # Flutter Frontend
│   ├── lib/
│   │   ├── models/         # Data models (Animal, HealthRecord, etc.)
│   │   ├── providers/      # Riverpod state management
│   │   ├── repositories/   # Data access layer
│   │   ├── screens/        # UI screens
│   │   ├── services/       # Business logic (ML, Camera, etc.)
│   │   ├── widgets/        # Reusable components
│   │   └── router/         # Navigation (Zenrouter)
│   ├── android/            # Android platform
│   ├── ios/                # iOS platform
│   ├── web/                # Web platform
│   └── test/               # Unit & widget tests
│
└── backend/                # Python ML Backend
    ├── app/
    │   ├── api/            # FastAPI route handlers
    │   ├── core/           # Configuration & database
    │   ├── features/       # Feature engineering
    │   ├── models/         # ML models & schemas
    │   └── services/       # Business logic
    ├── models/             # Saved model artifacts
    ├── training/           # Training datasets
    └── mlruns/             # MLflow experiments
```

### Tech Stack

| Layer | Technologies |
|-------|-------------|
| **Frontend** | Flutter 3.10+, Riverpod, Zenrouter, FL Chart |
| **Backend** | FastAPI, Python 3.12, Pydantic |
| **Database** | Supabase (PostgreSQL), Row Level Security |
| **ML/AI** | LightGBM, scikit-learn, SHAP, Optuna |
| **MLOps** | MLflow (experiment tracking, model registry) |
| **Auth** | Supabase Auth, Google Sign-In |
| **Payments** | Flutterwave |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** 3.10+
- **Python** 3.12+
- **uv** package manager (for backend)
- **Supabase** project (free tier works)

### Frontend Setup (Flutter)

```bash
# Navigate to frontend directory
cd manage

# Install dependencies
flutter pub get

# Create environment file
cp .env.example .env
# Edit .env with your Supabase credentials

# Run the app
flutter run
```

### Backend Setup (Python)

```bash
# Navigate to backend directory
cd backend

# Install uv package manager (if not installed)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create virtual environment and install dependencies
uv venv
source .venv/bin/activate  # Linux/macOS
# .venv\Scripts\activate   # Windows
uv sync

# Create environment file
cp .env.example .env
# Edit .env with your Supabase credentials

# Run the server
uvicorn app.main:app --reload
```

### Environment Variables

#### Frontend (`manage/.env`)
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GEMINI_API_KEY=your-gemini-key  # For AI assistant
```

#### Backend (`backend/.env`)
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-role-key

API_HOST=0.0.0.0
API_PORT=8000
DEBUG=true

MLFLOW_TRACKING_URI=sqlite:///mlflow.db
MLFLOW_EXPERIMENT_NAME=farm-ml-pipeline
```

---

## 📚 Documentation

### API Documentation

Once the backend is running, access the interactive API docs:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

### Key API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/api/v1/features/weight/{animal_id}` | POST | Compute weight features |
| `/api/v1/features/health/{animal_id}` | POST | Compute health features |
| `/api/v1/models/predict/weight` | POST | Get weight predictions |
| `/api/v1/models/predict/health-risk` | POST | Get health risk assessment |
| `/api/v1/pipeline/compute-batch` | POST | Batch feature computation |

### Project Documentation

- [UI Design Guide](manage/UI_DESIGN.md) - Comprehensive UI/UX design specs
- [ML Pipeline Roadmap](backend/ML_PIPELINE_ROADMAP.md) - ML development roadmap
- [Project Roadmap](manage/ROADMAP.md) - Feature development roadmap

---

## 🗺 Roadmap

### ✅ Completed
- [x] Animal inventory management
- [x] Weight & feeding tracking
- [x] Breeding management with pregnancy calculator
- [x] Health records with vaccination tracking
- [x] Financial tracking (income/expense)
- [x] User authentication (Email, Google)
- [x] Multi-farm support with role-based access
- [x] PDF/CSV/Excel report generation
- [x] ML weight prediction models
- [x] SHAP explainability integration

### 🚧 In Progress
- [ ] Offline-first architecture
- [ ] Push notifications for reminders
- [ ] Health risk prediction model
- [ ] Feed optimization recommendations

### 📋 Planned
- [ ] Hardware integration (IoT scales, RFID readers)
- [ ] Breeding success prediction
- [ ] Multi-language support (i18n)
- [ ] Farm comparison analytics
- [ ] Community marketplace

---

## 🧪 Testing

### Frontend Tests
```bash
cd manage
flutter test
```

### Backend Tests
```bash
cd backend
source .venv/bin/activate
pytest
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📧 Contact

**Ayiko Andrew** - [@Ayikoandrew](https://github.com/Ayikoandrew)

Project Link: [https://github.com/Ayikoandrew/farm-manager](https://github.com/Ayikoandrew/farm-manager)

---

<div align="center">
Made with ❤️ for farmers everywhere
</div>
