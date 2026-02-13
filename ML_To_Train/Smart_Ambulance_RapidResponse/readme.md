```md
# Gray Mobility – AI/ML Engineer Intern Assignment (Smart Ambulance)

This repository contains my solution for the **Gray Mobility Smart Ambulance AI/ML Engineer Intern Assignment**.  
The goal is to build a realistic **time-series anomaly detection + risk scoring system** for streamed patient vitals under noisy, safety-critical ambulance conditions, and expose it via an API service.

---

## Problem Statement (Summary)

Patient vitals are streamed every second from a smart ambulance system:

- Heart Rate (HR)
- SpO₂
- Blood Pressure (Systolic/Diastolic – simulated)
- Motion/Vibration (vehicle + patient movement)

### Objectives
1. Generate or source realistic time-series data (~30 minutes per patient)
2. Perform **explicit artifact detection & correction** (before anomaly detection)
3. Build an anomaly detection system for early warning signals (not only thresholds)
4. Design a risk scoring / triage logic combining vitals + confidence
5. Evaluate alert quality (precision, recall, false alert rate, alert latency)
6. Deploy the system as a reproducible mini ML service using an API (FastAPI/Flask)

---

## Repository Structure

```

.
├── dataset/
│   ├── raw/                # raw dataset (synthetic or adapted)
│   ├── processed/          # cleaned + artifact-handled dataset
│   └── README.md           # dataset assumptions + limitations
│
├── models/
│   ├── anomaly_model.pkl   # trained anomaly detection model
│   ├── scaler.pkl          # scaler / feature transform artifacts
│   └── metadata.json       # model configuration, feature list, versioning
│
├── src/
│   ├── api/
│   │   ├── main.py         # API entrypoint
│   │   ├── schemas.py      # request/response formats
│   │   └── routes.py       # endpoints
│   │
│   ├── preprocessing/
│   │   ├── artifact.py     # artifact detection & correction logic
│   │   ├── features.py     # windowing + feature extraction
│   │   └── utils.py
│   │
│   ├── inference/
│   │   ├── predictor.py    # anomaly + risk score inference pipeline
│   │   └── risk_logic.py   # risk scoring rules + confidence scoring
│   │
│   ├── training/
│   │   ├── train.py        # model training script
│   │   └── evaluate.py     # evaluation + metrics + failure cases
│   │
│   └── config.py           # global configs (sampling rate, window size, etc.)
│
├── notebooks/
│   └── reproducibility.ipynb   # end-to-end reproducibility notebook
│
├── report/
│   ├── report.md               # short writeup (or PDF export)
│   └── plots/                  # key plots: before/after artifacts, failures, etc.
│
├── requirements.txt
└── README.md

````

---

## High-Level Solution Workflow

### 1) Data Generation / Sourcing
- Data is created or adapted to simulate:
  - normal ambulance transport
  - distress / deterioration scenarios
  - sensor noise and real-world artifacts

### 2) Artifact Detection (Mandatory Step)
Explicit artifact handling is applied before anomaly detection, including:
- motion-induced SpO₂ drops
- HR spikes due to bumps/vibration
- missing segments / dropouts

Before vs after plots are generated and stored in `report/plots/`.

### 3) Anomaly Detection
An anomaly detection model is trained using windowed time-series features to detect early warning signals.

### 4) Risk Scoring Logic
A triage-style risk score is produced using:
- multi-vital combination
- trends
- anomaly confidence
- suppression rules (to reduce false alerts)

### 5) Evaluation
Metrics reported include:
- precision
- recall
- false alert rate
- alert latency  
Plus failure analysis on at least 3 cases.

### 6) API Service
A FastAPI/Flask service exposes:
- anomaly flag
- risk score
- confidence

---

## API Usage

### Run API
```bash
pip install -r requirements.txt
python -m src.api.main
````

### Example Request Format

The API accepts vitals streamed every second (single point or buffered window depending on implementation):

```json
{
  "timestamp": 1700000000,
  "hr": 92,
  "spo2": 97,
  "bp_sys": 120,
  "bp_dia": 78,
  "motion": 0.12
}
```

### Example Response Format

```json
{
  "anomaly": false,
  "risk_score": 0.18,
  "confidence": 0.82
}
```

---

## Training & Evaluation

### Train Model

```bash
python -m src.training.train
```

### Evaluate Model

```bash
python -m src.training.evaluate
```

Trained models and preprocessing artifacts are saved under:

```
models/
```

---

## Reproducibility

* Full reproducibility is provided via:

  * `notebooks/reproducibility.ipynb`
  * training scripts
  * deterministic preprocessing pipeline
  * consistent folder structure

---

## Notes

* This project is designed for safety-critical ML behavior:

  * explicit artifact handling is mandatory
  * anomaly detection is not only threshold-based
  * alert suppression and confidence scoring are included
  * failure analysis is documented

---

## Author

**(Drona Bopche)**
AI/ML Engineer Intern Assignment – Gray Mobility

```
```
