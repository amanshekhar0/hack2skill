import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCol = isDark ? const Color(0xFF0F2027) : const Color(0xFFF7FAFC);
    final appBarCol = isDark ? const Color(0xFF203A43) : Colors.white;
    final cardCol = isDark ? const Color(0xFF203A43) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A365D);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF718096);
    final shadowColor = isDark ? Colors.transparent : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: bgCol,
      appBar: AppBar(
        title: Text(
          'Admin Analytics Dashboard',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: appBarCol,
        elevation: isDark ? 0 : 2,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'District Level Overview',
                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: textColor),
              ).animate().fadeIn(),
              const SizedBox(height: 8),
              Text(
                'AI Trend Prediction & Coverage Gaps',
                style: GoogleFonts.inter(fontSize: 15, color: textMuted),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 32),
              
              _buildStatRow(cardCol, textColor, textMuted, shadowColor).animate().fadeIn(delay: 200.ms).slideY(),
              const SizedBox(height: 36),
              
              Text(
                'Scheme Uptake Forecast (Vertex AI)',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),
              _buildLineChartCard(cardCol, shadowColor).animate().fadeIn(delay: 400.ms).scale(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(Color cardCol, Color textColor, Color textMuted, Color shadowColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _buildStatCard('Total Applicants', '14,203', Icons.people, Colors.blue, cardCol, textColor, textMuted, shadowColor)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Eligible Ratio', '68%', Icons.pie_chart, Colors.green, cardCol, textColor, textMuted, shadowColor)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, Color cardCol, Color textColor, Color textMuted, Color shadowColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardCol,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: textColor, height: 1.1),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartCard(Color cardCol, Color shadowColor) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardCol,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: shadowColor, blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold);
                  switch (value.toInt()) {
                    case 0: return const Text('Jan', style: style);
                    case 2: return const Text('Feb', style: style);
                    case 4: return const Text('Mar', style: style);
                    case 6: return const Text('Apr', style: style);
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 3.5), FlSpot(3, 5), 
                FlSpot(4, 4), FlSpot(5, 6), FlSpot(6, 7),
              ],
              isCurved: true,
              color: const Color(0xFF00C9FF),
              barWidth: 4,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF00C9FF).withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
