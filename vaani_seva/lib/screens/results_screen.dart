import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/prediction_provider.dart';
import '../utils/translations.dart';
import '../services/pdf_service.dart';
import '../theme/app_colors.dart';
import '../widgets/eligibility_banner.dart';
import '../widgets/offline_banner.dart';
import '../widgets/scheme_card.dart';
import '../widgets/score_bar.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _hasSpokeResult = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakResult();
    });
  }

  Future<void> _speakResult() async {
    if (_hasSpokeResult) return;
    final result = context.read<PredictionProvider>().result;
    final langCode = context.read<LanguageProvider>().languageCode;
    if (result != null && result.voiceUiMessage.isNotEmpty) {
      await _tts.setLanguage(langCode);
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.speak(result.voiceUiMessage);
      _hasSpokeResult = true;
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _generatePdf() async {
    try {
      await PdfService.generateAndPrint(
          context.read<PredictionProvider>().result!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded,
                  color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'PDF Generated Successfully!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not generate PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PredictionProvider>();
    final result = provider.result;
    final usedFallback = provider.usedFallback;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationHelper.t('Your Results', context.read<LanguageProvider>().languageName)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
            tooltip: 'Replay voice message',
            onPressed: () {
              _hasSpokeResult = false;
              _speakResult();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(isOffline: false, usedFallback: usedFallback),
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EligibilityBanner(isEligible: result.isEligible),
                  const SizedBox(height: 16),
                  ScoreBar(score: result.eligibilityScore),
                  const SizedBox(height: 20),
                  if (result.voiceUiMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.record_voice_over_rounded,
                                  color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                TranslationHelper.t('AI Message', context.read<LanguageProvider>().languageName),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            result.voiceUiMessage,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (result.matchingSchemes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.category_rounded,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          TranslationHelper.t('Matching Schemes', context.read<LanguageProvider>().languageName) + ' (${result.matchingSchemes.length})',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...result.matchingSchemes.asMap().entries.map(
                          (e) => SchemeCard(
                            schemeData: e.value,
                            index: e.key,
                            requestData: provider.request,
                          ),
                        ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _generatePdf,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: Text(TranslationHelper.t('Generate Documents', context.read<LanguageProvider>().languageName)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<PredictionProvider>().reset();
                      Navigator.popUntil(
                          context, (route) => route.isFirst);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(TranslationHelper.t('Check Again', context.read<LanguageProvider>().languageName)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
