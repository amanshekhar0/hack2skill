import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _showLanguagePicker = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward().then((_) {
      if (mounted) setState(() => _showLanguagePicker = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectLanguage(String code, String name) async {
    final langProvider = context.read<LanguageProvider>();
    await langProvider.setLanguage(code, name);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(
                  context.watch<ThemeProvider>().themeMode == ThemeMode.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
                onPressed: () => context.read<ThemeProvider>().toggleTheme(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
              ScaleTransition(
                scale: _scaleAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.gradient1, AppColors.gradient2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'VAANI SEVA',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI-Powered Welfare Eligibility',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Powered by Machine Learning',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 2),
              AnimatedOpacity(
                opacity: _showLanguagePicker ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: AnimatedSlide(
                  offset: _showLanguagePicker
                      ? Offset.zero
                      : const Offset(0, 0.3),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  child: Column(
                    children: [
                      Text(
                        'Apni bhasha chunein',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select your preferred language',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _LanguageButton(
                        flag: '🇮🇳',
                        language: 'हिंदी',
                        subtitle: 'Hindi',
                        onTap: () => _selectLanguage('hi-IN', 'Hindi'),
                      ),
                      const SizedBox(height: 14),
                      _LanguageButton(
                        flag: '🏔️',
                        language: 'ಕನ್ನಡ',
                        subtitle: 'Kannada',
                        onTap: () => _selectLanguage('kn-IN', 'Kannada'),
                      ),
                      const SizedBox(height: 14),
                      _LanguageButton(
                        flag: '🇬🇧',
                        language: 'English',
                        subtitle: 'English',
                        onTap: () => _selectLanguage('en-US', 'English'),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Government of India Initiative',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String flag;
  final String language;
  final String subtitle;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.flag,
    required this.language,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
