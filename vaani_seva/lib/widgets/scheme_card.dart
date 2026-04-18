import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class SchemeCard extends StatelessWidget {
  final String schemeName;
  final int index;

  const SchemeCard({super.key, required this.schemeName, required this.index});

  IconData get _schemeIcon {
    final icons = [
      Icons.home_rounded,
      Icons.agriculture_rounded,
      Icons.health_and_safety_rounded,
      Icons.elderly_rounded,
      Icons.account_balance_rounded,
      Icons.school_rounded,
    ];
    return icons[index % icons.length];
  }

  Color get _schemeColor =>
      AppColors.schemeColors[index % AppColors.schemeColors.length];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _schemeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_schemeIcon, color: _schemeColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schemeName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Government of India Welfare Scheme',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _schemeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              color: _schemeColor,
              size: 14,
            ),
          ),
        ],
      ),
    );
  }
}
