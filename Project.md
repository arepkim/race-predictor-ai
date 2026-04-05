# AI-Powered Running Race Time Predictor - MVP Documentation

## Project Overview
This project is a mobile application prototype designed for runners to predict their race completion times (5K, 10K, Half Marathon, or Full Marathon) based on their recent training data. The goal is to provide a simple, data-driven tool to help athletes set realistic race goals.

## Core Objectives (MVP Phase)
The current stage focuses strictly on the "Core Loop": **User Authentication -> Data Input -> ML Inference -> Result Display**.

### 1. User Authentication
- Implement secure Login and Registration using **Firebase Authentication**.
- Ensure users can manage their sessions (Email/Password).

### 2. Prediction Engine
- Capture four primary metrics:
  - **Distance** (Recent long run or session distance).
  - **Average Pace** (min/km).
  - **Weekly Mileage** (Total volume).
  - **Heart Rate** (Average during training).
- Communicate with a **Python (FastAPI/Flask)** backend hosting a pre-trained ML model.

### 3. User Interface
- **Screen 1 (Auth):** Minimalist login/signup forms.
- **Screen 2 (Input):** A validated form for training metrics.
- **Screen 3 (Result):** High-visibility display of predicted race times returned by the API.

## Tech Stack
- **Frontend:** Flutter (Dart) - Material Design.
- **Backend:** Python (FastAPI/Flask) - Model serving.
- **ML Framework:** Scikit-learn / XGBoost.
- **Database & Identity:** Firebase (Firestore & Auth).

## Current Roadmap
1. **[Phase 1] Backend Bridge:** Setup Python API to load `.joblib`/`.h5` models and handle POST requests.
2. **[Phase 2] Firebase Setup:** Connect Flutter app to Firebase projects.
3. **[Phase 3] Flutter Core:** Implement Auth logic and the Input Form.
4. **[Phase 4] Integration:** Connect Flutter to the Backend API and verify end-to-end flow.

---
*Note: This is a prototype for the Final Year Project (FYP). Complexity like dashboards, chatbots, or XAI are out of scope for the current MVP.*
