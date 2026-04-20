import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import pickle
import pandas as pd
import uvicorn
from fastapi.middleware.cors import CORSMiddleware

# ✅ Create app
app = FastAPI()

# ✅ Add CORS (FIXED — no syntax error)
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

# ✅ Load ML model safely
try:
    with open("final_model.pkl", "rb") as file:
        model = pickle.load(file)
    print("✅ Model loaded successfully")
except Exception as e:
    print("❌ Error loading model:", e)
    model = None

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

# ✅ Root endpoint
@app.get("/")
def root():
    return {"message": "✅ Maize Yield Prediction API is running!"}

# ✅ Prediction endpoint
@app.post("/predict/")
def predict_yield(data: PredictionInput):
    try:
        if model is None:
            raise Exception("Model not loaded")

        # Convert input to DataFrame
        df = pd.DataFrame([data.dict()])

        # Encode categorical variables
        df = pd.get_dummies(df)

        # Handle model features safely
        try:
            model_features = model.feature_names_in_
        except AttributeError:
            print("⚠️ feature_names_in_ not found, using input columns")
            model_features = df.columns

        # Add missing columns
        for col in model_features:
            if col not in df.columns:
                df[col] = 0

        # Ensure correct column order
        df = df[model_features]

        # Predict
        prediction = model.predict(df)
        predicted_yield = float(prediction[0])

        # Confidence range
        lower = round(predicted_yield * 0.9, 2)
        upper = round(predicted_yield * 1.1, 2)

        # Category
        category = (
            "High Yield" if predicted_yield > 30 else
            "Moderate Yield" if predicted_yield > 20 else
            "Low Yield"
        )

        # Recommendation
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
        print("🔥 ERROR in /predict/:", str(e))
        raise HTTPException(status_code=500, detail=str(e))

# ✅ Run server (for local use only)
if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)