import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pickle
import pandas as pd

from fastapi.middleware.cors import CORSMiddleware

# ✅ Create app FIRST
app = FastAPI()

# ✅ THEN add CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Import DB + Auth
from App.database import Base, engine
from App.routes.auth import router as auth_router

# ✅ Create tables
Base.metadata.create_all(bind=engine)

# ✅ Include auth routes
app.include_router(auth_router)

# ✅ Load ML model
with open("final_model.pkl", "rb") as file:
    model = pickle.load(file)

# ✅ Prediction schema
class PredictionInput(BaseModel):
    Soil_Type: str
    pH: float
    Seed_Variety: str
    Rainfall_mm: float
    Temperature_C: float
    Humidity_percent: float
    Planting_Date: str
    Fertilizer_Type: str

# ✅ Root
@app.get("/")
def root():
    return {"message": "✅ Maize Yield Prediction API is running!"}

# ✅ Prediction endpoint
@app.post("/predict/")
def predict_yield(data: PredictionInput):
    try:
        df = pd.DataFrame([data.dict()])
        df = pd.get_dummies(df)

        for col in model.feature_names_in_:
            if col not in df.columns:
                df[col] = 0

        df = df[model.feature_names_in_]

        predicted_yield = model.predict(df)[0]
        lower = round(predicted_yield * 0.9, 2)
        upper = round(predicted_yield * 1.1, 2)

        category = (
            "High Yield" if predicted_yield > 30 else
            "Moderate Yield" if predicted_yield > 20 else
            "Low Yield"
        )

        recommendation = (
            "✅ Maintain current practices." if category == "High Yield" else
            "⚠️ Improve soil or irrigation." if category == "Moderate Yield" else
            "❌ Use more fertilizer, adjust planting date."
        )

        return {
            "predicted_yield": round(predicted_yield, 2),
            "confidence_range": f"{lower} - {upper} bags per acre",
            "category": category,
            "recommendation": recommendation
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))