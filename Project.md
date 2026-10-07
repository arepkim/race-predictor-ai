# Elite Pace: AI-Powered Running Race Time Predictor - Project Documentation

## Project Overview
Elite Pace is a comprehensive, production-ready mobile application designed for runners to accurately predict race completion times for 5K, 10K, Half Marathon, and Full Marathon distances. By leveraging advanced machine learning and physiological data, it provides athletes with data-driven goals and a personalized AI Running Coach to optimize their training.

## Core Features
The application delivers a professional-grade experience with the following core modules:

### 1. Secure User Ecosystem
- **Firebase Authentication:** Enterprise-grade secure login and registration.
- **Dynamic User Profiles:** Cloud-synced management of personal metrics (Age, Gender) and training history using **Firestore**.

### 2. High-Precision Prediction Engine
- **XGBoost Inference:** A sophisticated machine learning model trained on diverse runner datasets, evaluating:
  - **Physiological Metrics:** Resting HR, Max HR, and VO2 Max.
  - **Training Dynamics:** Weekly mileage, training consistency, and pace zones (Easy vs. Tempo).
  - **Historical Performance:** Personal bests (PBs) across multiple distances for baseline calibration.
- **Automated Data Enrichment:** Intelligent backend logic that utilizes sports science proxies to maintain prediction accuracy even when optional user data is missing.

### 3. Elite AI Running Coach
- **Generative AI Integration:** Powered by **Google Gemini**, providing interactive, context-aware training advice.
- **Personalized Insights:** The coach analyzes the user's specific predictions and training volume to offer tailored strategy, injury prevention tips, and motivational support.

### 4. Advanced Performance Analytics
- **Data Visualization:** High-impact interactive charts (via `fl_chart`) that track performance trends and training consistency over time.

## Tech Stack
- **Frontend:** Flutter (Dart) - Material 3 Design System.
- **Backend:** Python (FastAPI) - Robust API for model serving and AI orchestration.
- **AI/ML:** XGBoost, Scikit-learn, Pandas.
- **LLM:** Google Gemini 1.5 Flash.
- **Infrastructure:** Firebase (Authentication, Cloud Firestore).

## Project Roadmap
- [x] **[Phase 1] Backend Architecture:** FastAPI implementation with optimized XGBoost model serving.
- [x] **[Phase 2] Cloud Integration:** Full Firebase suite setup for identity and real-time data sync.
- [x] **[Phase 3] Mobile Experience:** Implementation of the Material 3 UI, multi-step forms, and navigation.
- [x] **[Phase 4] Intelligence Layer:** Integration of the Gemini-powered Elite AI Coach.
- [x] **[Phase 5] Optimization & Delivery:** Final UI/UX polish, integration testing, and performance tuning.

---
*Developed as a Final Year Project (FYP) - Final Release.*
