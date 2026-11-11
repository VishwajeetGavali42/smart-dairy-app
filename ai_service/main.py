from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Optional
import datetime

app = FastAPI(title="Smart Dairy AI/ML Microservice", version="1.0.0")

class AnomalyCheckRequest(BaseModel):
    memberCode: str
    animalType: str
    quantity: float
    fat: float
    snf: float

class AnomalyCheckResponse(BaseModel):
    isAnomaly: bool
    confidence: float
    reason: Optional[str] = None

class QualityPredictionRequest(BaseModel):
    animalType: str
    fat: float
    snf: float
    temperature: Optional[float] = 4.0

class QualityPredictionResponse(BaseModel):
    grade: str # Good, Normal, Attention
    qualityScore: float
    recommendation: str

class CollectionForecastResponse(BaseModel):
    morningShiftForecastLtr: float
    eveningShiftForecastLtr: float
    weeklyTrend: str
    confidence: float

@app.get("/")
def root():
    return {"service": "Smart Dairy AI Service", "status": "running"}

@app.post("/detect/anomaly", response_model=AnomalyCheckResponse)
def detect_anomaly(req: AnomalyCheckRequest):
    # Rule and statistical boundary check
    if req.animalType.lower() == "cow":
        if req.fat < 3.2 or req.fat > 5.5:
            return AnomalyCheckResponse(isAnomaly=True, confidence=0.92, reason=f"FAT {req.fat}% is outside normal Cow milk bounds (3.2% - 5.5%)")
        if req.snf < 8.0 or req.snf > 9.5:
            return AnomalyCheckResponse(isAnomaly=True, confidence=0.88, reason=f"SNF {req.snf}% is outside normal Cow milk bounds (8.0% - 9.5%)")
    else: # Buffalo
        if req.fat < 5.5 or req.fat > 10.0:
            return AnomalyCheckResponse(isAnomaly=True, confidence=0.94, reason=f"FAT {req.fat}% is outside normal Buffalo milk bounds (5.5% - 10.0%)")
        if req.snf < 8.5 or req.snf > 10.5:
            return AnomalyCheckResponse(isAnomaly=True, confidence=0.90, reason=f"SNF {req.snf}% is outside normal Buffalo milk bounds (8.5% - 10.5%)")

    return AnomalyCheckResponse(isAnomaly=False, confidence=0.96, reason=None)

@app.post("/predict/quality", response_model=QualityPredictionResponse)
def predict_quality(req: QualityPredictionRequest):
    # Quality scoring based on FAT & SNF
    base_score = 70.0
    if req.animalType.lower() == "cow":
        base_score += (req.fat - 3.5) * 15 + (req.snf - 8.2) * 20
    else:
        base_score += (req.fat - 6.0) * 10 + (req.snf - 8.8) * 15

    quality_score = min(max(base_score, 0.0), 100.0)

    if quality_score >= 85.0:
        return QualityPredictionResponse(
            grade="Good",
            qualityScore=round(quality_score, 1),
            recommendation="Premium Grade A milk. Eligible for bonus quality incentive."
        )
    elif quality_score >= 65.0:
        return QualityPredictionResponse(
            grade="Normal",
            qualityScore=round(quality_score, 1),
            recommendation="Standard quality milk meeting dairy compliance thresholds."
        )
    else:
        return QualityPredictionResponse(
            grade="Attention",
            qualityScore=round(quality_score, 1),
            recommendation="Sub-standard solids detected. Check cattle feeding and chilling temperature."
        )

@app.get("/forecast/collection", response_model=CollectionForecastResponse)
def forecast_collection():
    return CollectionForecastResponse(
        morningShiftForecastLtr=720.5,
        eveningShiftForecastLtr=533.5,
        weeklyTrend="↑ 12% anticipated rise in buffalo yield",
        confidence=0.89
    )

@app.get("/insights")
def get_insights():
    return {
        "insights": [
            "Milk collection is projected 12% higher than last week.",
            "2 unusual FAT values detected today on Khed route.",
            "Optimal evening dispatch vehicle timing: 06:30 PM."
        ]
    }