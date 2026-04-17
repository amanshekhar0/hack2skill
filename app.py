"""
VAANI SEVA — Flask API (Corrected)
====================================
Fixes applied:
  1. Removed duplicate dead-code block in generate_human_reasoning
  2. Section numbering restored (8 was missing)
  3. Consistent int/float casting in get_matching_schemes
  4. LAND_BINS upper bound raised to 1000 to prevent NaN on large holdings
  5. debug mode controlled via env var (DEBUG=true)
  6. Added /schemes and /languages introspection endpoints
  7. Minor: language fallback logic clarified

Run: python app.py
"""

import os
import logging
import joblib
import pandas as pd
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
from google import genai

# ── 1. BOOT CONFIG ──────────────────────────────────────────────
load_dotenv(override=True)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger("vaani_seva_api")

app = Flask(__name__)
CORS(app)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if not GEMINI_API_KEY:
    logger.error("🚨 GEMINI_API_KEY missing — add it to .env")

# ── 2. FEATURE CONSTANTS (single source of truth) ──────────────
# These MUST match train_model.py exactly. Never change one without the other.
INCOME_BINS = [0, 100000, 200000, 300000, 500000, 800001]
LAND_BINS   = [-0.1, 1, 2, 5, 10, 1000]   # FIX: raised ceiling from 15.1 → 1000
                                            #      to prevent NaN for large holdings
BIN_LABELS  = [0, 1, 2, 3, 4]

FEATURES = [
    # Original 7
    'age', 'income', 'land_size', 'is_rural', 'house_type',
    'is_taxpayer', 'is_govt_emp',
    # Engineered 9
    'income_per_acre', 'is_senior', 'is_very_senior', 'is_young_adult',
    'low_income_rural', 'poor_rural_farmer', 'income_band', 'land_band', 'risk_score'
]

# ── 3. ARTIFACT LOADING ─────────────────────────────────────────
try:
    xgb_model = joblib.load('model.pkl')
    explainer  = joblib.load('explainer.pkl')
    logger.info("✅ ML model and SHAP explainer loaded.")
except Exception as e:
    logger.error(f"❌ Failed to load ML artifacts: {e}")
    xgb_model = None
    explainer  = None

# ── 4. INPUT VALIDATION ─────────────────────────────────────────
REQUIRED_FIELDS = {
    'age':         (int,   0,   120),
    'income':      (float, 0,   10_000_000),
    'land_size':   (float, 0,   100),
    'is_rural':    (int,   0,   1),
    'house_type':  (int,   0,   1),
    'is_taxpayer': (int,   0,   1),
    'is_govt_emp': (int,   0,   1),
}

def validate_input(data: dict) -> list:
    errors = []
    for field, (dtype, min_val, max_val) in REQUIRED_FIELDS.items():
        if field not in data:
            errors.append(f"Missing required field: '{field}'")
        else:
            try:
                val = dtype(data[field])
                if not (min_val <= val <= max_val):
                    errors.append(f"'{field}' must be between {min_val} and {max_val}, got {val}")
            except (ValueError, TypeError):
                errors.append(f"'{field}' must be a {dtype.__name__}, got {type(data[field]).__name__}")
    return errors

# ── 5. FEATURE ENGINEERING (mirrors train_model.py exactly) ────
def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df['income_per_acre']   = df['income'] / (df['land_size'] + 1e-5)
    df['is_senior']         = (df['age'] >= 60).astype(int)
    df['is_very_senior']    = (df['age'] >= 70).astype(int)
    df['is_young_adult']    = ((df['age'] >= 18) & (df['age'] <= 35)).astype(int)
    df['low_income_rural']  = ((df['is_rural'] == 1) & (df['income'] <= 300000)).astype(int)
    df['poor_rural_farmer'] = (
        (df['is_rural'] == 1) & (df['land_size'] <= 5) & (df['income'] <= 300000)
    ).astype(int)
    df['income_band'] = pd.cut(df['income'],    bins=INCOME_BINS, labels=BIN_LABELS).astype(int)
    df['land_band']   = pd.cut(df['land_size'], bins=LAND_BINS,   labels=BIN_LABELS).astype(int)
    df['risk_score']  = (
        df['is_rural'] + df['low_income_rural']
        - df['is_taxpayer'] - df['is_govt_emp']
    )
    return df

def prepare_input(data: dict) -> pd.DataFrame:
    """
    Extract scalars from the raw request dict first, THEN build DataFrame.
    Never call df.get() — that returns a Series, not a scalar.
    """
    row = {
        'age':         int(data['age']),
        'income':      float(data['income']),
        'land_size':   float(data['land_size']),
        'is_rural':    int(data['is_rural']),
        'house_type':  int(data['house_type']),
        'is_taxpayer': int(data['is_taxpayer']),
        'is_govt_emp': int(data['is_govt_emp']),
    }
    df = pd.DataFrame([row])
    df = engineer_features(df)
    return df[FEATURES]

# ── 6. SCHEME MATCHER ───────────────────────────────────────────
SCHEME_MAP = [
    {
        "name": "Ayushman Bharat PM-JAY (Senior)",
        "condition": lambda d: int(d.get('age', 0)) >= 70
    },
    {
        "name": "PM Kisan Samman Nidhi",
        "condition": lambda d: (
            int(d.get('is_rural', 0)) == 1
            and float(d.get('land_size', 999)) <= 5
            and float(d.get('income', 999999)) <= 300000
        )
    },
    {
        "name": "PMAY-Gramin (Rural Housing)",
        "condition": lambda d: (
            int(d.get('is_rural', 0)) == 1
            and int(d.get('house_type', 1)) == 0
            and float(d.get('income', 999999)) <= 180000
        )
    },
    {
        "name": "MGNREGA (Employment Guarantee)",
        "condition": lambda d: (
            int(d.get('is_rural', 0)) == 1
            and float(d.get('income', 999999)) <= 300000
        )
    },
    {
        "name": "National Food Security Act (Ration Card)",
        "condition": lambda d: float(d.get('income', 999999)) <= 200000
    },
]

def get_matching_schemes(user_data: dict) -> list:
    """
    FIX: All values are explicitly cast to int/float before comparison
    to guard against string inputs that passed JSON parsing (e.g. "1" vs 1).
    Input is already validated + cast by prepare_input, but scheme matching
    reads from the raw request dict, so casting here is a necessary safeguard.
    """
    return [s["name"] for s in SCHEME_MAP if s["condition"](user_data)]

# ── 7. SHAP REASON EXTRACTION (version-safe) ───────────────────
def extract_shap_reasons(processed_df: pd.DataFrame) -> tuple:
    """
    Returns (raw_reasons list, sv array).
    Handles both SHAP output formats:
      - list of two arrays (older SHAP): use index [1] for positive class
      - single 2D array (newer SHAP):   use directly
    """
    shap_values = explainer.shap_values(processed_df)

    if isinstance(shap_values, list):
        # Older SHAP: shap_values[0] = class 0, shap_values[1] = class 1
        sv = shap_values[1][0]
    else:
        # Newer SHAP: single 2D array, first row = first sample
        sv = shap_values[0]

    importance = pd.Series(sv, index=FEATURES).sort_values(key=abs, ascending=False)

    raw_reasons = []
    for feat, val in importance.head(3).items():
        direction = "supports eligibility" if val > 0 else "reduces eligibility"
        raw_reasons.append(f"- {feat} ({direction}, impact: {val:+.3f})")

    return raw_reasons, sv

# ── 8. GEMINI HUMAN REASONING ───────────────────────────────────
SUPPORTED_LANGUAGES = {
    "Hindi":     "Hindi (हिंदी)",
    "English":   "English",
    "Kannada":   "Kannada (ಕನ್ನಡ)",
    "Tamil":     "Tamil (தமிழ்)",
    "Telugu":    "Telugu (తెలుగు)",
    "Malayalam": "Malayalam (മലയാളം)",
    "Marathi":   "Marathi (मराठी)",
    "Punjabi":   "Punjabi (ਪੰਜਾਬੀ)",
    "Bengali":   "Bengali (বাংলা)",
}

def generate_human_reasoning(user_data: dict, prediction: int,
                              technical_reasons: list, schemes: list) -> str:
    status     = "Eligible" if prediction == 1 else "Not Eligible"
    scheme_str = ", ".join(schemes) if schemes else "no specific scheme"

    # FIX: removed duplicate prompt block — only one prompt + one try/except now
    lang_key = user_data.get('language', 'English')
    language = SUPPORTED_LANGUAGES.get(lang_key, 'English')  # fallback to English if key invalid

    prompt = f"""
You are 'Vaani Seva', a voice-first, empathetic AI welfare navigator for Indian citizens.

User Context:
- Age: {user_data.get('age')}
- Annual Income: Rs.{user_data.get('income')}
- Rural Resident: {'Yes' if int(user_data.get('is_rural', 0)) == 1 else 'No'}
- Land Holding: {user_data.get('land_size')} acres

AI Decision: {status}
Matching Schemes: {scheme_str}
Key Factors:
{chr(10).join(technical_reasons)}

IMPORTANT: You MUST reply in {language} language only.
Write 2 warm, conversational sentences directly to the user (use "you" or equivalent in {language}).
If eligible, name the specific schemes and encourage them.
If not eligible, gently explain the main reason.
NEVER use technical terms like "SHAP", "algorithm", "model", or "risk score".
"""

    try:
        if not GEMINI_API_KEY:
            return "Your eligibility has been assessed based on the details provided."
        client   = genai.Client(api_key=GEMINI_API_KEY)
        response = client.models.generate_content(model='gemini-2.5-flash', contents=prompt)
        return response.text.strip()
    except Exception as e:
        logger.error(f"Gemini API error: {e}")
        return "Your eligibility has been processed based on the details provided."

# ── 9. ROUTES ───────────────────────────────────────────────────
@app.route('/predict', methods=['POST'])
def predict():
    if xgb_model is None or explainer is None:
        return jsonify({"status": "error", "message": "ML artifacts not loaded."}), 503

    user_input = request.get_json(silent=True)
    if not user_input:
        return jsonify({"status": "error", "message": "Request body must be valid JSON."}), 400

    errors = validate_input(user_input)
    if errors:
        return jsonify({"status": "error", "errors": errors}), 422

    try:
        processed_df = prepare_input(user_input)

        prediction  = int(xgb_model.predict(processed_df)[0])
        probability = float(xgb_model.predict_proba(processed_df)[0][1])

        raw_reasons, _ = extract_shap_reasons(processed_df)
        schemes         = get_matching_schemes(user_input)
        human_message   = generate_human_reasoning(user_input, prediction, raw_reasons, schemes)

        return jsonify({
            "status":            "success",
            "is_eligible":       bool(prediction),
            "eligibility_score": round(probability, 4),
            "matching_schemes":  schemes,
            "voice_ui_message":  human_message,
            "shap_factors":      raw_reasons,
        }), 200

    except Exception as e:
        logger.error(f"Prediction error: {e}", exc_info=True)
        return jsonify({"status": "error", "message": "Internal server error."}), 500


@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        "status":    "healthy",
        "model":     "loaded" if xgb_model else "missing",
        "explainer": "loaded" if explainer  else "missing",
        "lead":      "Sadhuram Agarwal",
    }), 200


@app.route('/schemes', methods=['GET'])
def list_schemes():
    """Introspection endpoint — returns all scheme names the matcher knows about."""
    return jsonify({
        "status":  "success",
        "schemes": [s["name"] for s in SCHEME_MAP],
    }), 200


@app.route('/languages', methods=['GET'])
def list_languages():
    """Introspection endpoint — returns all supported language keys for the 'language' field."""
    return jsonify({
        "status":    "success",
        "languages": list(SUPPORTED_LANGUAGES.keys()),
    }), 200


if __name__ == '__main__':
    # FIX: debug mode driven by env var so it's safe to leave this line in production deploys
    debug_mode = os.getenv("DEBUG", "false").lower() == "true"
    app.run(host='0.0.0.0', port=5000, debug=debug_mode)