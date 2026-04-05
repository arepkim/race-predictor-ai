from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import joblib
import pandas as pd
import numpy as np
import os

app = FastAPI()

# Enable CORS for Flutter communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load Model and Scaler (Relative to project root if run from Backend folder)
MODEL_PATH = "xgboost_race_predictor.joblib"
SCALER_PATH = "race_predictor_scaler.joblib"

try:
    model = joblib.load(MODEL_PATH)
    scaler = joblib.load(SCALER_PATH)
except Exception as e:
    print(f"Error loading model/scaler: {e}")
    model = None
    scaler = None

# Feature list defined in the training notebook
FEATURES = [
    'age', 'gender_encoded', 'resting_hr', 'max_hr', 'vo2_max', 
    'weekly_mileage_km', 'avg_easy_pace_min_km', 'avg_tempo_pace_min_km', 
    'training_consistency', 'pb_5k_mins', 'pb_10k_mins', 
    'pb_half_mins', 'pb_full_mins', 'target_distance_km'
]

class PredictionInput(BaseModel):
    # Required Core fields
    target_distance_km: float
    weekly_mileage_km: float
    resting_hr: float
    max_hr: float
    age: int
    gender_encoded: int  # 1 for Male, 0 for Female
    
    # Optional fields with None defaults for proxy calculation
    avg_easy_pace_min_km: float | None = None
    avg_tempo_pace_min_km: float | None = None
    vo2_max: float | None = None
    training_consistency: float | None = 0.85
    pb_5k_mins: float | None = None
    pb_10k_mins: float | None = None
    pb_half_mins: float | None = None
    pb_full_mins: float | None = None
    
    # Keeping this for backward compatibility or as a reference pace if easy/tempo are missing
    avg_pace_min_km: float | None = None

def prepare_data(data: PredictionInput):
    """Fills in missing optional data using sports science proxies from the notebook."""
    user_data = data.dict()
    
    # 1. Handle VO2 Max
    if user_data.get('vo2_max') is None:
        user_data['vo2_max'] = 15.3 * (user_data['max_hr'] / user_data['resting_hr'])
    
    # 2. Handle Training Paces (using avg_pace_min_km if specific ones are missing)
    base_pace = user_data.get('avg_pace_min_km') or 5.5 # Fallback
    if user_data.get('avg_easy_pace_min_km') is None:
        user_data['avg_easy_pace_min_km'] = base_pace * 1.15
    if user_data.get('avg_tempo_pace_min_km') is None:
        user_data['avg_tempo_pace_min_km'] = base_pace * 0.95
        
    # 3. Handle PBs (Sequential proxies)
    if user_data.get('pb_10k_mins') is None:
        # Estimate 10k from base pace
        user_data['pb_10k_mins'] = base_pace * 10
        
    if user_data.get('pb_5k_mins') is None:
        user_data['pb_5k_mins'] = user_data['pb_10k_mins'] * 0.45
        
    if user_data.get('pb_half_mins') is None:
        user_data['pb_half_mins'] = user_data['pb_10k_mins'] * 2.22
        
    if user_data.get('pb_full_mins') is None:
        user_data['pb_full_mins'] = user_data['pb_half_mins'] * 2.1
    
    # Ensure consistency is set
    if user_data.get('training_consistency') is None:
        user_data['training_consistency'] = 0.85
    
    # Align with model's expected feature order
    return pd.DataFrame([user_data])[FEATURES]

@app.post("/predict")
async def predict(input_data: PredictionInput):
    if not model or not scaler:
        raise HTTPException(status_code=500, detail="Model or Scaler not loaded.")
    
    try:
        # 1. Preprocess and align features
        input_df = prepare_data(input_data)
        
        # 2. Scale
        input_scaled = scaler.transform(input_df)
        
        # 3. Predict
        predicted_minutes = model.predict(input_scaled)[0]
        
        # 4. Format Output (HH:MM:SS)
        hours = int(predicted_minutes // 60)
        minutes = int(predicted_minutes % 60)
        seconds = int((predicted_minutes * 60) % 60)
        
        formatted_time = f"{hours:02d}:{minutes:02d}:{seconds:02d}"
        
        return {
            "prediction_minutes": float(predicted_minutes),
            "formatted_time": formatted_time,
            "target_race": f"{input_data.target_distance_km} km"
        }
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/health")
async def health_check():
    return {"status": "online", "model_loaded": model is not None}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
