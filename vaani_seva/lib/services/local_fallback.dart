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

    String message;
    if (req.language == 'Kannada') {
      message = eligible
          ? "ಅರ್ಹತೆಯ ಮಾನದಂಡಗಳನ್ನು ನೀವು ಪೂರೈಸುತ್ತೀರಿ. ದಯವಿಟ್ಟು ನಿಮ್ಮ ಸಮೀಪದ ಜನ ಸೇವಾ ಕೇಂದ್ರವನ್ನು ಸಂಪರ್ಕಿಸಿ."
          : "ಪ್ರಸ್ತುತ ನೀವು ಯೋಜನೆಗಳಿಗೆ ಅರ್ಹರಾಗಿಲ್ಲ. ನಿಮ್ಮ ಆದಾಯ ಅಥವಾ ಭೂಮಿಯ ಮಿತಿ ಮೀರಿದೆ.";
    } else if (req.language == 'Hindi') {
      message = eligible
          ? "आप पात्रता मानदंडों को पूरा करते हैं। कृपया निकटतम जन सेवा केंद्र से संपर्क करें।"
          : "वर्तमान में आप योजनाओं के लिए पात्र नहीं हैं। आपकी आय या भूमि सीमा पार हो गई है।";
    } else {
      message = eligible
          ? 'You meet the eligibility criteria. Please contact your nearest Jan Seva Kendra.'
          : 'You are currently not eligible for these schemes. Your income or land size exceeds the limit.';
    }

    return PredictionResponse(
      isEligible: eligible,
      eligibilityScore: score,
      voiceUiMessage: message,
      matchingSchemes: schemes,
    );
  }
}
