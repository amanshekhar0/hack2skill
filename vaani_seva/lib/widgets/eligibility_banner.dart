import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class EligibilityBanner extends StatelessWidget {
  final bool isEligible;

  const EligibilityBanner({super.key, required this.isEligible});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: isEligible ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isEligible ? AppColors.success : AppColors.error,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isEligible ? AppColors.success : AppColors.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isEligible ? Icons.check_rounded : Icons.close_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEligible ? 'Aap Eligible Hain!' : 'Abhi Eligible Nahi',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color:
                        isEligible ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEligible
                      ? 'You qualify for government welfare schemes'
                      : 'You do not currently meet eligibility criteria',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isEligible
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
