import os
from dotenv import load_dotenv
from google import genai

# 1. Force load the .env file
load_dotenv(override=True)
key = os.getenv("GEMINI_API_KEY")

print(f"🔍 Checking Key: {key[:8]}... (Hidden for security)")

try:
    # 2. Try a simple connection
    client = genai.Client(api_key=key)
    response = client.models.generate_content(
        model='gemini-2.5-flash',
        contents='Reply with exactly two words: Hello World.'
    )
    print("✅ SUCCESS! Gemini says:", response.text)
except Exception as e:
    print("❌ GOOGLE ERROR:", e)