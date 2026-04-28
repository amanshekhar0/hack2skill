"""
VAANI SEVA — Flask API (Final Complete Version)
================================================
Features:
  1. XGBoost eligibility prediction
  2. SHAP explainability (version-safe)
  3. Gemini humanizer in 9 Indian languages
  4. Scheme matching with benefit + description + apply link + documents + steps
  5. /generate_guide endpoint — downloadable .txt in user's language
  6. Input validation with clear error messages
  7. /health /schemes /languages introspection endpoints
Run: python app.py
"""

import os
import io
import logging
import joblib
import pandas as pd
from flask import Flask, request, jsonify, send_file
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
    logger.error("GEMINI_API_KEY missing — add it to .env")

# ── 2. FEATURE CONSTANTS ────────────────────────────────────────
INCOME_BINS = [0, 100000, 200000, 300000, 500000, 800001]
LAND_BINS   = [-0.1, 1, 2, 5, 10, 1000]
BIN_LABELS  = [0, 1, 2, 3, 4]

FEATURES = [
    'age', 'income', 'land_size', 'is_rural', 'house_type',
    'is_taxpayer', 'is_govt_emp',
    'income_per_acre', 'is_senior', 'is_very_senior', 'is_young_adult',
    'low_income_rural', 'poor_rural_farmer', 'income_band', 'land_band', 'risk_score'
]

# ── 3. ARTIFACT LOADING ─────────────────────────────────────────
try:
    xgb_model = joblib.load('model.pkl')
    explainer  = joblib.load('explainer.pkl')
    logger.info("ML model and SHAP explainer loaded.")
except Exception as e:
    logger.error(f"Failed to load ML artifacts: {e}")
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

# ── 5. FEATURE ENGINEERING ──────────────────────────────────────
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

# ── 6. SCHEME MAP ───────────────────────────────────────────────
SCHEME_MAP = [
    {
        "name":        "Ayushman Bharat PM-JAY (Senior)",
        "benefit":     "Free health insurance up to Rs.5 lakh per year",
        "description": "Health coverage for senior citizens aged 70 and above",
        "apply_link":  "https://pmjay.gov.in",
        "documents": [
            "Aadhaar card",
            "Age proof (birth certificate or school certificate)",
            "Ration card or BPL certificate",
            "Passport size photograph",
            "Mobile number linked to Aadhaar"
        ],
        "steps": [
            "Visit your nearest Common Service Centre (CSC) or government hospital",
            "Carry your Aadhaar card and age proof documents",
            "Ask the operator to register you under Ayushman Bharat PM-JAY Senior",
            "Your details will be verified against the government database",
            "You will receive an Ayushman card (golden card) within 7 days",
            "Use this card at any empanelled hospital for free treatment up to Rs.5 lakh"
        ],
        "condition": lambda d: int(d.get('age', 0)) >= 70
    },
    {
        "name":        "PM Kisan Samman Nidhi",
        "benefit":     "Rs.6000 per year in 3 instalments directly to bank account",
        "description": "Financial support for small and marginal farmers",
        "apply_link":  "https://pmkisan.gov.in",
        "documents": [
            "Aadhaar card",
            "Land ownership documents (Khasra/Khatauni/7-12 extract)",
            "Bank account passbook linked to Aadhaar",
            "Mobile number",
            "Passport size photograph"
        ],
        "steps": [
            "Visit pmkisan.gov.in or your nearest CSC centre",
            "Click on New Farmer Registration on the website",
            "Enter your Aadhaar number and mobile number",
            "Fill in your personal details — name, address, bank account number",
            "Upload your land ownership documents (Khasra or Khatauni)",
            "Submit the form and note down your registration number",
            "Your application will be verified by the state government within 30 days",
            "Once approved, Rs.2000 will be credited to your bank account every 4 months"
        ],
        "condition": lambda d: (
            int(d.get('is_rural', 0)) == 1
            and float(d.get('land_size', 99)) <= 5
            and float(d.get('income', 999999)) <= 300000
        )
    },
    {
        "name":        "PMAY-Gramin (Rural Housing)",
        "benefit":     "Rs.1.2 lakh grant for house construction",
        "description": "Housing assistance for rural families without a pucca house",
        "apply_link":  "https://pmayg.nic.in",
        "documents": [
            "Aadhaar card of all family members",
            "BPL certificate or ration card",
            "Land ownership proof or NOC from gram panchayat",
            "Bank account passbook linked to Aadhaar",
            "Photograph of existing kutcha house",
            "Income certificate from tehsildar"
        ],
        "steps": [
            "Contact your Gram Panchayat office and ask for PMAY-Gramin registration",
            "Your name must be in the SECC-2011 list — ask your Gram Pradhan to check",
            "If your name is not listed, ask your Gram Pradhan to add it",
            "Submit all required documents to the Gram Panchayat",
            "Block Development Officer (BDO) will verify your application",
            "Once approved, first instalment of Rs.40000 will be transferred to your bank",
            "Construct foundation — submit photo proof to receive second instalment",
            "Complete roof construction — submit photo proof to receive final instalment"
        ],
        "condition": lambda d: (
            int(d.get('is_rural', 0)) == 1
            and int(d.get('house_type', 1)) == 0
            and float(d.get('income', 999999)) <= 180000
        )
    },
    {
        "name":        "MGNREGA (Employment Guarantee)",
        "benefit":     "100 days of guaranteed paid employment per year at minimum wage",
        "description": "Employment guarantee scheme for rural households",
        "apply_link":  "https://nrega.nic.in",
        "documents": [
            "Aadhaar card",
            "Ration card or voter ID",
            "Bank account passbook or post office account",
            "Passport size photograph",
            "Mobile number"
        ],
        "steps": [
            "Visit your Gram Panchayat office and ask for a MGNREGA Job Card",
            "Fill the Job Card registration form with your family details",
            "Submit Aadhaar card, photograph and bank account details",
            "Your Job Card will be issued within 15 days — it is free of cost",
            "When you need work, submit a written application at Gram Panchayat",
            "Work must be provided within 15 days of your application",
            "If work is not provided, you are entitled to unemployment allowance",
            "Wages are paid directly to your bank account within 15 days of work completion"
        ],
        "condition": lambda d: (
            int(d.get('is_rural', 0)) == 1
            and float(d.get('income', 999999)) <= 300000
        )
    },
    {
        "name":        "National Food Security Act (Ration Card)",
        "benefit":     "Rice at Rs.3/kg, Wheat at Rs.2/kg, Coarse grains at Rs.1/kg every month",
        "description": "Subsidized food grains for low income families via ration card",
        "apply_link":  "https://nfsa.gov.in",
        "documents": [
            "Aadhaar card of all family members",
            "Proof of residence (electricity bill, rent agreement, or voter ID)",
            "Income certificate from tehsildar",
            "Passport size photographs of all family members",
            "Mobile number linked to Aadhaar"
        ],
        "steps": [
            "Visit your nearest Food and Civil Supplies office or CSC centre",
            "Ask for the Ration Card application form — it is free",
            "Fill the form with details of all family members",
            "Attach Aadhaar cards and photographs of all members",
            "Attach your income certificate and residence proof",
            "Submit the form at the office and get an acknowledgement receipt",
            "A field officer will visit your home for verification within 30 days",
            "Your ration card will be issued within 45 days of application",
            "Collect your monthly ration from your nearest Fair Price Shop"
        ],
        "condition": lambda d: float(d.get('income', 999999)) <= 200000
    },
]

def get_matching_schemes(user_data: dict) -> list:
    return [
        {
            "name":        s["name"],
            "benefit":     s["benefit"],
            "description": s["description"],
            "apply_link":  s["apply_link"],
            "documents":   s["documents"],
            "steps":       s["steps"],
        }
        for s in SCHEME_MAP if s["condition"](user_data)
    ]

# ── 7. SHAP REASON EXTRACTION ───────────────────────────────────
def extract_shap_reasons(processed_df: pd.DataFrame) -> tuple:
    shap_values = explainer.shap_values(processed_df)
    if isinstance(shap_values, list):
        sv = shap_values[1][0]
    else:
        sv = shap_values[0]
    importance = pd.Series(sv, index=FEATURES).sort_values(key=abs, ascending=False)
    raw_reasons = []
    for feat, val in importance.head(3).items():
        direction = "supports eligibility" if val > 0 else "reduces eligibility"
        raw_reasons.append(f"- {feat} ({direction}, impact: {val:+.3f})")
    return raw_reasons, sv

# ── 8. SUPPORTED LANGUAGES ──────────────────────────────────────
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

# ── 9. GEMINI HUMANIZER ─────────────────────────────────────────
def generate_human_reasoning(user_data: dict, prediction: int,
                              technical_reasons: list, schemes: list) -> str:
    status     = "Eligible" if prediction == 1 else "Not Eligible"
    scheme_str = ", ".join([s["name"] for s in schemes]) if schemes else "no specific scheme"
    lang_key   = user_data.get('language', 'English')
    language   = SUPPORTED_LANGUAGES.get(lang_key, 'English')

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
Write 2 warm, conversational sentences directly to the user.
If eligible, name the specific schemes and encourage them.
If not eligible, gently explain the main reason.
NEVER use technical terms like SHAP, algorithm, model, or risk score.
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

# ── 10. SCHEME GUIDE GENERATOR ──────────────────────────────────
def generate_scheme_guide(schemes: list, user_data: dict) -> str:
    lang_key = user_data.get('language', 'English')
    language = SUPPORTED_LANGUAGES.get(lang_key, 'English')

    scheme_details = ""
    for s in schemes:
        scheme_details += f"""
Scheme Name: {s['name']}
Benefit: {s['benefit']}
Official Website: {s['apply_link']}
Required Documents: {', '.join(s['documents'])}
Steps: {' | '.join([f"Step {i+1}: {step}" for i, step in enumerate(s['steps'])])}
"""

    prompt = f"""
You are a helpful government welfare assistant for Indian citizens.

The following citizen qualifies for these government schemes:
{scheme_details}

Citizen Details:
- Age: {user_data.get('age')} years
- Annual Income: Rs.{user_data.get('income')}
- Rural Resident: {'Yes' if int(user_data.get('is_rural', 0)) == 1 else 'No'}
- Land Holding: {user_data.get('land_size')} acres

CRITICAL: Write the ENTIRE response in {language} ONLY.
Every single word — headings, steps, documents, tips — must be in {language}.
Only keep the official website links in English.

Write a detailed application guide for EACH scheme in this exact format:

===========================================
[Scheme name translated to {language}]
===========================================

[Word for Benefit in {language}]:
[What citizen receives — in {language}]

[Word for How to Apply in {language}]:
[Step 1 in {language}]
[Step 2 in {language}]
[Step 3 in {language}]
[Step 4 in {language}]
[Step 5 in {language}]
[Step 6 in {language}]
[All remaining steps in {language}]

[Word for Required Documents in {language}]:
- [Document 1 in {language}]
- [Document 2 in {language}]
- [Document 3 in {language}]
- [Document 4 in {language}]
- [All remaining documents in {language}]

[Word for Important Tips in {language}]:
- [Tip 1 — simple language for uneducated rural citizen in {language}]
- [Tip 2 in {language}]
- [Tip 3 in {language}]

[Word for Official Website in {language}]: [website link]

-------------------------------------------

Use the simplest words possible. Imagine explaining to an elderly farmer
who has never visited a government office. Be warm, patient and encouraging.
"""

    try:
        if not GEMINI_API_KEY:
            return "API key missing — cannot generate guide."
        client   = genai.Client(api_key=GEMINI_API_KEY)
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt
        )
        return response.text.strip()
    except Exception as e:
        logger.error(f"Guide generation error: {e}")
        return "Guide could not be generated. Please try again."

# ── 11. ROUTES ───────────────────────────────────────────────────
@app.route('/')
def home():
    return {
        "message": "Vaani Seva API is running",
        "endpoints": [
            "/predict",
            "/generate_guide",
            "/health",
            "/schemes",
            "/languages"
        ]
    }


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
        prediction   = int(xgb_model.predict(processed_df)[0])
        probability  = float(xgb_model.predict_proba(processed_df)[0][1])

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


@app.route('/generate_guide', methods=['POST'])
def generate_guide():
    """
    Returns a downloadable .txt file in the user's chosen language.
    Contains step-by-step guide to apply for all matched schemes.
    Request body: same 7 fields as /predict + optional 'language' field.
    """
    if xgb_model is None:
        return jsonify({"status": "error", "message": "ML artifacts not loaded."}), 503

    user_input = request.get_json(silent=True)
    if not user_input:
        return jsonify({"status": "error", "message": "Request body must be valid JSON."}), 400

    errors = validate_input(user_input)
    if errors:
        return jsonify({"status": "error", "errors": errors}), 422

    try:
        schemes  = get_matching_schemes(user_input)
        lang_key = user_input.get('language', 'English')

        if not schemes:
            return jsonify({
                "status":  "success",
                "message": "No schemes matched — no guide generated.",
            }), 200

        guide_text = generate_scheme_guide(schemes, user_input)

        header = f"""
VAANI SEVA — WELFARE SCHEME APPLICATION GUIDE
==============================================
Age       : {user_input.get('age')} years
Income    : Rs.{user_input.get('income')} per year
Language  : {lang_key}
Schemes   : {len(schemes)} matched
Generated : {pd.Timestamp.now().strftime('%d %B %Y, %I:%M %p')}
==============================================

"""
        full_guide  = header + guide_text
        file_buffer = io.BytesIO()
        file_buffer.write(full_guide.encode('utf-8'))
        file_buffer.seek(0)

        filename = f"vaani_seva_guide_{lang_key.lower()}.txt"

        return send_file(
            file_buffer,
            mimetype='text/plain; charset=utf-8',
            as_attachment=True,
            download_name=filename
        )

    except Exception as e:
        logger.error(f"Guide endpoint error: {e}", exc_info=True)
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
    return jsonify({
        "status":  "success",
        "schemes": [s["name"] for s in SCHEME_MAP],
    }), 200


@app.route('/languages', methods=['GET'])
def list_languages():
    return jsonify({
        "status":    "success",
        "languages": list(SUPPORTED_LANGUAGES.keys()),
    }), 200


if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    debug_mode = os.getenv("DEBUG", "false").lower() == "true"
    app.run(host='0.0.0.0', port=port, debug=debug_mode)