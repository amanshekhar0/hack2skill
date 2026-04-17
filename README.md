# 🎙️ Vaani Seva — ML Backend
**Voice-First AI Welfare Navigator for Underserved India**

> Solution Challenge 2026 · Hack2Skill × Google for Developers  
> Track: **Smart Resource Allocation**

---

## 👨‍💻 Built by
**Sadhuram Agarwal** — ML Backend Lead  
CMR Institute of Technology, Bengaluru · BE ISE 6th Sem · CGPA 9.0

Team: Aman Shekhar (Leader) · Anushka Sinha · Abhishek Tiwari

---

## 🧠 What This Does
India has 1,000+ central welfare schemes. 600M+ citizens don't know they qualify.

Vaani Seva is a voice-first, multilingual AI agent that:
- Takes 7 basic inputs about a citizen
- Predicts welfare scheme eligibility using XGBoost (trained on 5,000 profiles)
- Explains WHY using SHAP values
- Returns a warm, conversational response via Gemini 2.5 Flash
- Supports 9 Indian languages (Hindi, Kannada, Tamil, Telugu, Malayalam, Marathi, Punjabi, Bengali, English)

---

## 🗂️ Files
| File | Purpose |
|------|---------|
| `data_gen.py` | Generates 5,000 synthetic Indian citizen profiles |
| `train_model.py` | Full ML pipeline — XGBoost + Optuna + SMOTE + SHAP |
| `app.py` | Production Flask REST API |
| `test_api.py` | Full test suite (6 test cases + introspection endpoints) |
| `test_gemini.py` | Gemini API connection test |
| `model.pkl` | Trained XGBoost model |
| `explainer.pkl` | SHAP TreeExplainer |
| `features.json` | Feature list for serving |
| `Dockerfile` | Container for Cloud Run deployment |
| `requirements.txt` | Python dependencies |

---

## ⚙️ Tech Stack
- **ML:** XGBoost, SMOTE, Optuna (60-trial hyperparameter search), SHAP
- **API:** Flask, Flask-CORS
- **AI:** Google Gemini 2.5 Flash
- **Deployment:** ngrok (permanent tunnel) / Docker + Cloud Run ready

---

## 🚀 Run Locally

```bash
# 1. Clone and setup
git clone https://github.com/amanshekhar0/hack2skill.git
cd hack2skill
git checkout backend

# 2. Create virtual environment
python -m venv venv
venv\Scripts\activate   # Windows
source venv/bin/activate  # Mac/Linux

# 3. Install dependencies
pip install -r requirements.txt

# 4. Add your Gemini API key
# Create a .env file and add:
# GEMINI_API_KEY=your_key_here

# 5. Generate training data and train model
python data_gen.py
python train_model.py

# 6. Start the API
python app.py
```

---

## 📡 API Endpoints

### `POST /predict`
```json
{
  "age": 75,
  "income": 40000,
  "land_size": 1.5,
  "is_rural": 1,
  "house_type": 0,
  "is_taxpayer": 0,
  "is_govt_emp": 0,
  "language": "Hindi"
}
```

**Response:**
```json
{
  "status": "success",
  "is_eligible": true,
  "eligibility_score": 0.9999,
  "matching_schemes": [
    "Ayushman Bharat PM-JAY (Senior)",
    "PM Kisan Samman Nidhi",
    "PMAY-Gramin (Rural Housing)",
    "MGNREGA (Employment Guarantee)",
    "National Food Security Act (Ration Card)"
  ],
  "voice_ui_message": "Namaste! Aapki umar aur aarthik sthiti ke aadhar par...",
  "shap_factors": [
    "- age (supports eligibility, impact: +2.997)",
    "- risk_score (supports eligibility, impact: +2.492)",
    "- is_taxpayer (supports eligibility, impact: +0.825)"
  ]
}
```

### `GET /health` — Server status check
### `GET /schemes` — List all supported schemes  
### `GET /languages` — List all supported languages

---

## 🌐 Supported Languages
Hindi · English · Kannada · Tamil · Telugu · Malayalam · Marathi · Punjabi · Bengali

---

## 🏛️ Government Schemes Covered
| Scheme | Eligibility |
|--------|------------|
| Ayushman Bharat PM-JAY | Age ≥ 70 |
| PM Kisan Samman Nidhi | Rural, land ≤ 5 acres, income ≤ ₹3L |
| PMAY-Gramin | Rural, kutcha house, income ≤ ₹1.8L |
| MGNREGA | Rural, income ≤ ₹3L |
| National Food Security Act | Income ≤ ₹2L |

---

## 📊 Model Performance
- **ROC-AUC:** ~0.99
- **Accuracy:** ~97%
- **Features:** 16 (7 raw + 9 engineered)
- **Training samples:** 5,000 (SMOTE balanced)
- **Hyperparameter search:** 60 Optuna trials

---

*Live API: https://volatilisable-demetrice-unchambered.ngrok-free.dev (when server is running)*