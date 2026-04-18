import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/prediction_request.dart';
import '../providers/prediction_provider.dart';
import '../providers/language_provider.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/translations.dart';
import 'results_screen.dart';

class FormScreen extends StatefulWidget {
  final String prefilledText;

  const FormScreen({super.key, this.prefilledText = ''});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _incomeController = TextEditingController();
  final _landController = TextEditingController();

  bool _isRural = false;
  bool _isPakkaGhar = false;
  bool _isTaxpayer = false;
  bool _isGovtEmp = false;
  bool _isParsing = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledText.isNotEmpty) {
      _parseVoiceData();
    }
  }

  Future<void> _parseVoiceData() async {
    setState(() => _isParsing = true);
    final data = await ApiService.parseSpeech(widget.prefilledText);
    if (data != null && mounted) {
      setState(() {
        _ageController.text = data['age']?.toString() ?? '';
        _incomeController.text = (data['income']?.toDouble() ?? 0.0).toStringAsFixed(0);
        _landController.text = (data['land_size']?.toDouble() ?? 0.0).toString();
        _isRural = data['is_rural'] == 1;
        _isPakkaGhar = data['house_type'] == 1;
        _isTaxpayer = data['is_taxpayer'] == 1;
        _isGovtEmp = data['is_govt_emp'] == 1;
      });
    }
    if (mounted) {
      setState(() => _isParsing = false);
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _incomeController.dispose();
    _landController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final request = PredictionRequest(
      age: int.parse(_ageController.text.trim()),
      income: double.parse(_incomeController.text.trim()),
      landSize: double.parse(_landController.text.trim()),
      isRural: _isRural ? 1 : 0,
      houseType: _isPakkaGhar ? 1 : 0,
      isTaxpayer: _isTaxpayer ? 1 : 0,
      isGovtEmp: _isGovtEmp ? 1 : 0,
      language: context.read<LanguageProvider>().languageName,
    );

    await context.read<PredictionProvider>().predict(request);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ResultsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().languageName;
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationHelper.t('Eligibility Form', lang)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: Icons.person_rounded,
                  title: TranslationHelper.t('Personal Details', lang),
                  subtitle: TranslationHelper.t('Enter your basic information', lang),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _ageController,
                  label: TranslationHelper.t('Age', lang) + ' (Years)',
                  hint: 'e.g. 45',
                  icon: Icons.cake_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your age';
                    final n = int.tryParse(v);
                    if (n == null || n < 1 || n > 120) return 'Enter valid age';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _incomeController,
                  label: TranslationHelper.t('Annual Income', lang) + ' (₹)',
                  hint: 'e.g. 150000',
                  icon: Icons.currency_rupee_rounded,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your income';
                    if (double.tryParse(v) == null) return 'Enter valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _landController,
                  label: TranslationHelper.t('Land Size', lang) + ' (Acres)',
                  hint: 'e.g. 2.5',
                  icon: Icons.landscape_rounded,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter land size';
                    if (double.tryParse(v) == null) return 'Enter valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                _SectionHeader(
                  icon: Icons.toggle_on_rounded,
                  title: TranslationHelper.t('Living Conditions', lang),
                  subtitle: TranslationHelper.t('Toggle the options that apply to you', lang),
                ),
                const SizedBox(height: 12),
                _buildSwitchCard(
                  icon: Icons.home_rounded,
                  title: TranslationHelper.t('Rural Area', lang),
                  subtitle: TranslationHelper.t('Are you from a rural area?', lang),
                  value: _isRural,
                  onChanged: (v) => setState(() => _isRural = v),
                ),
                const SizedBox(height: 10),
                _buildSwitchCard(
                  icon: Icons.house_rounded,
                  title: TranslationHelper.t('Pakka Ghar (Concrete House)', lang),
                  subtitle: TranslationHelper.t('Do you live in a Pucca (concrete) house?', lang),
                  value: _isPakkaGhar,
                  onChanged: (v) => setState(() => _isPakkaGhar = v),
                ),
                const SizedBox(height: 10),
                _buildSwitchCard(
                  icon: Icons.receipt_long_rounded,
                  title: TranslationHelper.t('Income Taxpayer', lang),
                  subtitle: TranslationHelper.t('Are you an Income Taxpayer?', lang),
                  value: _isTaxpayer,
                  onChanged: (v) => setState(() => _isTaxpayer = v),
                ),
                const SizedBox(height: 10),
                _buildSwitchCard(
                  icon: Icons.account_balance_rounded,
                  title: TranslationHelper.t('Government Employee', lang),
                  subtitle: TranslationHelper.t('Are you a Government Employee?', lang),
                  value: _isGovtEmp,
                  onChanged: (v) => setState(() => _isGovtEmp = v),
                ),
                const SizedBox(height: 32),
                Consumer<PredictionProvider>(
                  builder: (context, provider, _) {
                    final isLoading =
                        provider.status == PredictionStatus.loading || _isParsing;
                    return ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 58),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.5),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_rounded, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  TranslationHelper.t('Check Eligibility', lang),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: value ? AppColors.primary.withOpacity(0.04) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? AppColors.primary.withOpacity(0.3) : AppColors.border,
          width: 1.5,
        ),
      ),
      child: SwitchListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: value
                ? AppColors.primary.withOpacity(0.12)
                : Theme.of(context).dividerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: value ? AppColors.primary : AppColors.textHint,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
