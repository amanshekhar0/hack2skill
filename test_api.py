"""
test_api.py — Vaani Seva API Test Suite
========================================
Covers:
  1. Eligible rural user  (positive case)
  2. Non-eligible urban user (negative case)
  3. Senior citizen triggering Ayushman Bharat (age >= 70)
  4. Missing required field (validation error expected)
  5. Out-of-range value (validation error expected)
  6. Hindi language response
  7. /health, /schemes, /languages introspection endpoints
"""

import requests
import json

BASE_URL = "http://127.0.0.1:5000"
TIMEOUT  = 30   # seconds — Gemini can be slow on first call

# ── HELPERS ─────────────────────────────────────────────────────
def post_predict(payload: dict, label: str):
    print(f"\n{'='*55}")
    print(f"🧪 TEST: {label}")
    print(f"{'='*55}")
    print(f"📤 Payload: {json.dumps(payload, indent=2)}")

    try:
        response = requests.post(f"{BASE_URL}/predict", json=payload, timeout=TIMEOUT)
        print(f"📶 HTTP Status: {response.status_code}")
        print(f"📥 Response:\n{json.dumps(response.json(), indent=2, ensure_ascii=False)}")

        # Flag unexpected status codes clearly
        if response.status_code not in (200, 422):
            print(f"⚠️  UNEXPECTED STATUS CODE: {response.status_code}")

    except requests.exceptions.Timeout:
        print("❌ Request timed out — is Gemini/Flask slow or down?")
    except requests.exceptions.ConnectionError:
        print("❌ Connection failed — is the Flask server running on port 5000?")
    except Exception as e:
        print(f"❌ Unexpected error: {e}")


def get_endpoint(path: str, label: str):
    print(f"\n{'='*55}")
    print(f"🧪 TEST: {label}")
    print(f"{'='*55}")
    try:
        response = requests.get(f"{BASE_URL}{path}", timeout=10)
        print(f"📶 HTTP Status: {response.status_code}")
        print(f"📥 Response:\n{json.dumps(response.json(), indent=2, ensure_ascii=False)}")
    except Exception as e:
        print(f"❌ Error: {e}")


# ── TEST CASES ───────────────────────────────────────────────────

# 1. Eligible rural user — should match PM Kisan, MGNREGA, NFSA, PMAY-Gramin
post_predict(
    label="Eligible rural user (PMAY + PM Kisan + MGNREGA + NFSA)",
    payload={
        "age":         45,
        "income":      20000,
        "land_size":   1,
        "is_rural":    1,
        "house_type":  0,       # kutcha house → triggers PMAY-Gramin
        "is_taxpayer": 0,
        "is_govt_emp": 0,
        "language":    "English"
    }
)

# 2. Non-eligible urban professional
post_predict(
    label="Non-eligible urban professional",
    payload={
        "age":         35,
        "income":      900000,
        "land_size":   0,
        "is_rural":    0,
        "house_type":  1,
        "is_taxpayer": 1,
        "is_govt_emp": 1,
        "language":    "English"
    }
)

# 3. Senior citizen aged 72 — FIX: original test had age=45 with wrong comment
#    Ayushman Bharat PM-JAY (Senior) triggers at age >= 70, not 45
post_predict(
    label="Senior citizen (age=72) — Ayushman Bharat trigger",
    payload={
        "age":         72,      # FIX: was 45 in original test, must be >= 70
        "income":      80000,
        "land_size":   2,
        "is_rural":    1,
        "house_type":  0,
        "is_taxpayer": 0,
        "is_govt_emp": 0,
        "language":    "English"
    }
)

# 4. Hindi language response
post_predict(
    label="Tamil language response",
    payload={
        "age":         50,
        "income":      150000,
        "land_size":   3,
        "is_rural":    1,
        "house_type":  0,
        "is_taxpayer": 0,
        "is_govt_emp": 0,
        "language":    "Tamil"
    }
)

# 5. Missing required field — expect HTTP 422
post_predict(
    label="Missing 'income' field — expect 422 validation error",
    payload={
        "age":         40,
        # income intentionally omitted
        "land_size":   1,
        "is_rural":    1,
        "house_type":  0,
        "is_taxpayer": 0,
        "is_govt_emp": 0,
    }
)

# 6. Out-of-range value — age=200 should fail validation
post_predict(
    label="Out-of-range age (200) — expect 422 validation error",
    payload={
        "age":         200,     # max allowed is 120
        "income":      50000,
        "land_size":   1,
        "is_rural":    1,
        "house_type":  0,
        "is_taxpayer": 0,
        "is_govt_emp": 0,
    }
)

# ── INTROSPECTION ENDPOINTS ──────────────────────────────────────
get_endpoint("/health",    "Health check")
get_endpoint("/schemes",   "List all schemes")
get_endpoint("/languages", "List supported languages")