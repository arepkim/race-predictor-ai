# AI-Powered Running Race Time Predictor (MVP)

A Flutter-based mobile application that predicts race completion times (5K, 10K, Half/Full Marathons) based on recent training data using an XGBoost machine learning model.

## 🚀 Features
- **User Authentication:** Secure login and registration via Firebase Auth.
- **Data-Driven Predictions:** Predicts race times from:
  - Recent long run distance.
  - Average training pace.
  - Weekly mileage.
  - Average heart rate.
- **Real-time Inference:** Communicates with a Python backend (FastAPI/Flask) to serve ML predictions.

## 🛠️ Tech Stack
- **Frontend:** [Flutter](https://flutter.dev/) (Dart)
- **Backend:** [Python](https://www.python.org/) (FastAPI)
- **Machine Learning:** XGBoost, Scikit-learn
- **Database & Auth:** [Firebase](https://firebase.google.com/) (Firestore & Authentication)

## 📁 Project Structure
- `App/`: Flutter mobile application.
- `Backend/`: Python API for ML model serving.
- `ML/`: Jupyter notebooks for data processing and model training.

## 🏁 Getting Started

### Backend Setup
1. Navigate to the `Backend` directory.
2. Install dependencies: `pip install -r requirements.txt`.
3. Run the API: `uvicorn main:app --reload`.

### Flutter App Setup
1. Navigate to `App/race_predictor_app`.
2. Install Flutter packages: `flutter pub get`.
3. Run the app: `flutter run`.

## 📈 Roadmap
- [x] Backend API Bridge (ML Model Serving)
- [x] Firebase Integration (Auth & Firestore)
- [x] Flutter UI (Input Form & Results Display)
- [ ] Integration Testing

---
*Developed as a Final Year Project (FYP) prototype.*
