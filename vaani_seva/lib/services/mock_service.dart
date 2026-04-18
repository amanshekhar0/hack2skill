class MockService {
  static Future<Map<String, dynamic>> predictEligibility(Map<String, dynamic> data) async {
    // No mock delay for faster testing

    // Determine mock eligibility based on some input heuristics
    bool isEligible = true;
    double score = 0.89;
    
    // Simple mock logic: if income > 1,000,000 and they aren't rural, they fail.
    if ((data['income'] ?? 0) > 1000000 && (data['is_rural'] ?? 0) == 0) {
      isEligible = false;
      score = 0.32;
    }

    if (isEligible) {
      return {
        "status": "success",
        "is_eligible": true,
        "eligibility_score": score,
        "matching_schemes": ["Ayushman Bharat PM-JAY", "PM Kisan Samman Nidhi", "Pradhan Mantri Awas Yojana"],
        "voice_ui_message": "Namaste! Based on your details, you are highly likely to be eligible for 3 welfare schemes. Let me walk you through them.",
        "shap_factors": [
          "- age (supports eligibility, impact: +0.23)",
          "- is_rural (supports eligibility, impact: +0.15)",
          "- income (supports eligibility, impact: +0.08)"
        ]
      };
    } else {
       return {
        "status": "success",
        "is_eligible": false,
        "eligibility_score": score,
        "matching_schemes": [],
        "voice_ui_message": "Namaste. I have checked the eligibility criteria. Unfortunately, your current income bracket prevents you from availing these specific schemes at this time.",
        "shap_factors": [
          "- income (reduces eligibility, impact: -0.42)",
          "- is_rural (reduces eligibility, impact: -0.11)"
        ]
      };
    }
  }
}
