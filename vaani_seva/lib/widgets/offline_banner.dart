import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final bool usedFallback;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    this.usedFallback = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && !usedFallback) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: usedFallback ? AppColors.warning : AppColors.error,
      child: Row(
        children: [
          Icon(
            usedFallback ? Icons.wifi_off_rounded : Icons.signal_wifi_off,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              usedFallback
                  ? 'Offline Mode: Using local eligibility engine'
                  : 'No internet connection detected',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
