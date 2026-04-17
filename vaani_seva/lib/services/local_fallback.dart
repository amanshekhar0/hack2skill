import '../models/prediction_request.dart';
import '../models/prediction_response.dart';

class LocalFallback {
  static PredictionResponse evaluate(PredictionRequest req) {
    double score = 0.0;
    List<String> schemes = [];

    if (req.income < 100000) score += 0.3;
    else if (req.income < 300000) score += 0.15;

    if (req.isRural == 1) score += 0.2;
    if (req.landSize < 1.0) score += 0.15;
    if (req.houseType == 0) score += 0.1;
    if (req.isTaxpayer == 0) score += 0.1;
    if (req.isGovtEmp == 0) score += 0.1;
    if (req.age >= 60) score += 0.05;

    score = score.clamp(0.0, 1.0);
    bool eligible = score >= 0.4;

    if (req.isRural == 1 && req.income < 200000) {
      schemes.add('PM Kisan Samman Nidhi');
    }
    if (req.houseType == 0 && req.income < 300000) {
      schemes.add('PM Awas Yojana (Gramin)');
    }
    if (req.age >= 60 && req.isGovtEmp == 0) {
      schemes.add('Indira Gandhi National Old Age Pension');
    }
    if (req.income < 150000 && req.isTaxpayer == 0) {
      schemes.add('Ayushman Bharat - PM Jan Arogya Yojana');
    }
    if (req.landSize < 0.5) {
      schemes.add('PM Fasal Bima Yojana');
    }

    if (schemes.isEmpty && eligible) {
      schemes.add('General Welfare Assistance');
    }

    String message = eligible
        ? 'Aap eligibility criteria ko pura karte hain. Kripya nazdiki Jan Seva Kendra se sampark karein.'
        : 'Abhi aap in yojanaon ke liye yogya nahi hain. Aapki aay ya bhumi size ki sima paar nahi hui hai.';

    return PredictionResponse(
      isEligible: eligible,
      eligibilityScore: score,
      voiceUiMessage: message,
      matchingSchemes: schemes,
    );
  }
}
