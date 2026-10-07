from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import joblib
import pandas as pd
import numpy as np
import os

import google.generativeai as genai
from dotenv import load_dotenv
import os

app = FastAPI()

# Load environment variables
load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
else:
    print("Warning: GEMINI_API_KEY not found in environment variables.")

# Enable CORS for Flutter communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load Model and Scaler
try:
    prediction_model = joblib.load("xgboost_race_predictor.joblib")
    prediction_scaler = joblib.load("race_predictor_scaler.joblib")
    print("Models loaded successfully!")
except Exception as e:
    print(f"Error loading models: {e}")
    prediction_model = None
    prediction_scaler = None

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

class CoachMessage(BaseModel):
    role: str # "user" or "model"
    content: str

class CoachRequest(BaseModel):
    message: str
    history: list[CoachMessage] = []
    user_context: dict | None = None

def get_system_prompt(user_context: dict | None):
    prompt = """You are 'Elite Pace Coach', a professional and motivational AI running coach. 
    Your goal is to provide expert training advice, injury prevention tips, and race strategy.
    
    Guidelines:
    1. Be encouraging but realistic.
    2. Base your advice on sports science (e.g., the 10% rule for mileage increase).
    3. If user context is provided (like predicted race times or weekly mileage), use it to make your advice specific.
    4. Keep responses concise and formatted with bullet points for readability.
    5. If a user asks something unrelated to running or fitness, politely steer them back to training."""
    
    if user_context:
        prompt += f"\n\nUser Context:\n{user_context}"
    
    return prompt

@app.post("/coach")
async def chat_with_coach(request: CoachRequest):
    if not GEMINI_API_KEY:
        raise HTTPException(status_code=500, detail="Gemini API key not configured.")
    
    try:
        model = genai.GenerativeModel(
            model_name="models/gemini-2.5-flash",
            system_instruction=get_system_prompt(request.user_context)
        )
        
        # Convert history to Gemini format
        chat_history = []
        for msg in request.history:
            chat_history.append({
                "role": "user" if msg.role == "user" else "model",
                "parts": [msg.content]
            })
            
        chat = model.start_chat(history=chat_history)
        response = chat.send_message(request.message)
        
        return {
            "response": response.text,
            "role": "model"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

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
    if not prediction_model or not prediction_scaler:
        raise HTTPException(status_code=500, detail="Model or Scaler not loaded.")
    
    try:
        # 1. Preprocess and align features
        input_df = prepare_data(input_data)
        
        # 2. Scale
        input_scaled = prediction_scaler.transform(input_df)
        
        # 3. Predict
        predicted_minutes = prediction_model.predict(input_scaled)[0]
        
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

def get_top_factors(input_df: pd.DataFrame):
    """Identifies which features contributed most to the prediction."""
    try:
        # Get feature importance from XGBoost (weight/gain)
        # Note: In a production app with SHAP, we'd do local explanations.
        # For this prototype, we'll combine global importance with user values.
        importances = prediction_model.feature_importances_
        feature_names = FEATURES
        
        # Map feature names to user-friendly labels
        friendly_names = {
            'weekly_mileage_km': 'Weekly Mileage',
            'max_hr': 'Max Heart Rate',
            'resting_hr': 'Resting Heart Rate',
            'vo2_max': 'VO2 Max',
            'age': 'Age',
            'training_consistency': 'Consistency',
            'avg_easy_pace_min_km': 'Easy Pace',
            'avg_tempo_pace_min_km': 'Tempo Pace'
        }
        
        # Create a list of (feature, importance) and sort
        factors = []
        for name, imp in zip(feature_names, importances):
            if name in friendly_names:
                factors.append({"label": friendly_names[name], "importance": float(imp)})
        
        # Sort by importance and take top 3
        factors.sort(key=lambda x: x['importance'], reverse=True)
        return [f['label'] for f in factors[:3]]
    except:
        return ["Training Volume", "Heart Rate Metrics", "Consistency"]

@app.post("/predict_all")
async def predict_all(input_data: PredictionInput):
    """Returns predictions for 5K, 10K, Half, and Full Marathon distances."""
    if not prediction_model or not prediction_scaler:
        raise HTTPException(status_code=500, detail="Model or Scaler not loaded.")
    
    distances = [5.0, 10.0, 21.1, 42.2]
    labels = ["5K", "10K", "Half Marathon", "Full Marathon"]
    results = []

    try:
        # Get common top factors once (since input stats are the same)
        temp_input = input_data.copy(update={"target_distance_km": 5.0})
        temp_df = prepare_data(temp_input)
        top_factors = get_top_factors(temp_df)

        for dist, label in zip(distances, labels):
            # Create a copy of input data with the specific distance
            current_input = input_data.copy(update={"target_distance_km": dist})
            input_df = prepare_data(current_input)
            input_scaled = prediction_scaler.transform(input_df)
            
            predicted_minutes = prediction_model.predict(input_scaled)[0]
            
            hours = int(predicted_minutes // 60)
            minutes = int(predicted_minutes % 60)
            seconds = int((predicted_minutes * 60) % 60)
            formatted_time = f"{hours:02d}:{minutes:02d}:{seconds:02d}"

            # Calculate pace (min/km)
            pace_min = int(predicted_minutes // dist)
            pace_sec = int(((predicted_minutes / dist) % 1) * 60)
            formatted_pace = f"{pace_min}:{pace_sec:02d} min/km"

            results.append({
                "label": label,
                "distance": dist,
                "predicted_time": formatted_time,
                "pace": formatted_pace,
                "top_factors": top_factors
            })
        
        return {"predictions": results}
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/health")
async def health_check():
    return {"status": "online", "model_loaded": prediction_model is not None}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
