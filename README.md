# Elite Pace: AI-Powered Running Race Time Predictor

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![XGBoost](https://img.shields.io/badge/XGBoost-EB5424?style=for-the-badge)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Google Gemini](https://img.shields.io/badge/Google%20Gemini-8E75C2?style=for-the-badge&logo=google&logoColor=white)

Elite Pace is an intelligent mobile and machine learning system that transforms physiological training metrics into precise race time predictions (5K, 10K, Half Marathon, Full Marathon) and delivers personalized training advice through an AI Running Coach powered by Google Gemini.

---

## 🚀 Key Features

- **Multi-Distance Precision Predictions:** Generates race predictions for 5K, 10K, Half Marathon, and Full Marathon distances using an XGBoost regression model.
- **Elite AI Coach:** Context-aware running coach powered by **Google Gemini** providing tailored race strategies, recovery plans, and pacing insights.
- **Data-Driven Analytics:** Performance history tracking with interactive progress charts (`fl_chart`).
- **Sports Science Data Enrichment:** Automatic proxy calculations for metrics like VO2 Max and pace zones when partial runner data is supplied.
- **Cloud Synchronization:** Secure authentication and real-time profile persistence using Firebase Authentication and Cloud Firestore.

---

## 🛠️ Tech Stack

- **Mobile Frontend:** Flutter (Dart) — Material 3 Design
- **API & Inference Backend:** FastAPI (Python)
- **Machine Learning:** XGBoost, Scikit-learn, Pandas, NumPy
- **Generative AI:** Google Gemini API (`gemini-2.5-flash`)
- **Cloud Infrastructure:** Firebase (Auth & Firestore)

---

## 📁 Project Architecture

```
CAT405-Project/
├── App/race_predictor_app/    # Flutter mobile application
│   ├── lib/
│   │   ├── config/            # API & backend endpoints configuration
│   │   ├── screens/           # UI Screens (Auth, Predictor, Coach, History, Profile)
│   │   ├── widgets/           # Reusable UI widgets and navigation
│   │   └── main.dart          # App entrypoint
│   └── android/               # Android native configuration
├── Backend/                   # FastAPI backend server
│   ├── main.py                # REST API routes (/predict_all, /coach, /health)
│   ├── xgboost_race_predictor.joblib # Trained XGBoost model
│   ├── race_predictor_scaler.joblib  # Feature scaler
│   └── requirements.txt       # Python dependencies
└── ML/                        # Research and ML exploration
    ├── *.ipynb                # Data exploration and training notebooks
    └── fyp_runner_dataset.csv # Runner training dataset
```

---

## 🏁 Getting Started

### 1. Backend Setup

1. Open a terminal and navigate to `Backend`:
   ```bash
   cd Backend
   ```
2. Create and activate a Python virtual environment:
   ```bash
   python -m venv venv
   # Windows:
   venv\Scripts\activate
   # macOS/Linux:
   source venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Configure environment variables:
   - Copy `.env.example` to `.env`:
     ```bash
     cp .env.example .env
     ```
   - Open `.env` and insert your [Google AI Studio Gemini API Key](https://aistudio.google.com/):
     ```env
     GEMINI_API_KEY=your_actual_gemini_api_key
     ```
5. Start the FastAPI server:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

---

### 2. Flutter Mobile App Setup

1. Navigate to the mobile app directory:
   ```bash
   cd App/race_predictor_app
   ```
2. Install Flutter packages:
   ```bash
   flutter pub get
   ```
3. **Configure Backend URL:**
   - Open `lib/config/api_config.dart`.
   - Update `baseUrl`:
     - Android Emulator: `http://10.0.2.2:8000`
     - iOS Simulator / Web: `http://127.0.0.1:8000`
     - Physical Device: `http://<YOUR_LOCAL_IP>:8000`
4. **Configure Firebase:**
   - Link your own Firebase project using the FlutterFire CLI:
     ```bash
     flutterfire configure
     ```
   *(Or populate `android/app/google-services.json` from `google-services.json.example` and your Firebase Console).*
5. Run the application:
   ```bash
   flutter run
   ```

---

## 📈 Development Milestones

- [x] XGBoost Multi-Feature Race Prediction Engine
- [x] High-Throughput FastAPI REST Backend
- [x] Material 3 Mobile Experience with Full Form Validation
- [x] Contextual Google Gemini AI Coach Integration
- [x] Cloud Firestore Sync & Performance History Visualization
- [x] Production Clean Architecture & Security Hardening

---

*Final Year Project (FYP) — Final Release.*
