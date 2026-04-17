class PredictionResponse {
  final bool isEligible;
  final double eligibilityScore;
  final String voiceUiMessage;
  final List<String> matchingSchemes;

  PredictionResponse({
    required this.isEligible,
    required this.eligibilityScore,
    required this.voiceUiMessage,
    required this.matchingSchemes,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    return PredictionResponse(
      isEligible: json['is_eligible'] as bool? ?? false,
      eligibilityScore: (json['eligibility_score'] as num?)?.toDouble() ?? 0.0,
      voiceUiMessage: json['voice_ui_message'] as String? ?? '',
      matchingSchemes: (json['matching_schemes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
