import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../models/prediction_request.dart';
import '../services/api_service.dart';

class SchemeCard extends StatefulWidget {
  final Map<String, dynamic> schemeData;
  final int index;
  final PredictionRequest? requestData;

  const SchemeCard({
    super.key,
    required this.schemeData,
    required this.index,
    this.requestData,
  });

  @override
  State<SchemeCard> createState() => _SchemeCardState();
}

class _SchemeCardState extends State<SchemeCard> {
  bool _isLoadingGuide = false;
  bool _isExpanded = false;

  IconData get _schemeIcon {
    final icons = [
      Icons.home_rounded,
      Icons.agriculture_rounded,
      Icons.health_and_safety_rounded,
      Icons.elderly_rounded,
      Icons.account_balance_rounded,
      Icons.school_rounded,
    ];
    return icons[widget.index % icons.length];
  }

  Color get _schemeColor =>
      AppColors.schemeColors[widget.index % AppColors.schemeColors.length];

  Future<void> _openLink() async {
    final url = widget.schemeData['apply_link'] ?? widget.schemeData['official_portal'];
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _generateGuide() async {
    if (widget.requestData == null) return;
    setState(() => _isLoadingGuide = true);
    
    try {
      final guideText = await ApiService.generateGuide(widget.requestData!);
      
      if (!mounted) return;
      
      if (guideText != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Application Guide'),
            content: SingleChildScrollView(
              child: SelectableText(guideText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              )
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate guide.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGuide = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          widget.schemeData['name'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.schemeData['benefit'] ?? 'Government Welfare Scheme',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  )
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    'Steps to Apply:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  if (widget.schemeData['steps'] != null)
                    ...List<Widget>.from((widget.schemeData['steps'] as List).asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${entry.key + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Expanded(child: Text(entry.value.toString(), style: const TextStyle(fontSize: 12, height: 1.4))),
                          ],
                        ),
                      ),
                    ))
                  else
                    Text(
                      widget.schemeData['approval_process'] ?? widget.schemeData['description'] ?? 'Contact nearest nodal office for steps.',
                      style: GoogleFonts.inter(fontSize: 12, height: 1.4),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Documents Required:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  if (widget.schemeData['documents'] != null)
                    ...List<Widget>.from((widget.schemeData['documents'] as List).map(
                      (doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(doc.toString(), style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                      ),
                    ))
                  else
                    const Text('No specific documents listed.', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 140),
                        child: OutlinedButton.icon(
                          onPressed: _openLink,
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: Text(
                            'Official Website',
                            style: GoogleFonts.inter(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 140),
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingGuide ? null : _generateGuide,
                          icon: _isLoadingGuide
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.assignment_rounded, size: 14),
                          label: Text(
                            'AI Guide',
                            style: GoogleFonts.inter(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }
}
