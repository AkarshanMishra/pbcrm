import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class MarketingReportScreen extends StatefulWidget {
  const MarketingReportScreen({super.key});

  @override
  State<MarketingReportScreen> createState() => _MarketingReportScreenState();
}

class _MarketingReportScreenState extends State<MarketingReportScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  bool _isSubmitting = false;

  Map<String, dynamic> _draft = {
    'auto_tasks_completed': 7,
    'auto_visits_completed': 3,
    'auto_followups_completed': 8,
    'auto_leads_created': 2,
    'auto_onboardings_completed': 1,
  };

  final _summaryCtrl = TextEditingController();
  final _challengesCtrl = TextEditingController();
  final _tomorrowCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDraftSummary();
  }

  Future<void> _fetchDraftSummary() async {
    try {
      final res = await _api.get('/api/v1/marketing/reports/draft-summary/');
      if (mounted && res.data != null) {
        setState(() {
          _draft = res.data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitDailyReport() async {
    if (_summaryCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a summary of today\'s work.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _api.post('/api/v1/marketing/reports/', {
        'auto_tasks_completed': _draft['auto_tasks_completed'] ?? 0,
        'auto_visits_completed': _draft['auto_visits_completed'] ?? 0,
        'auto_followups_completed': _draft['auto_followups_completed'] ?? 0,
        'auto_leads_created': _draft['auto_leads_created'] ?? 0,
        'auto_onboardings_completed': _draft['auto_onboardings_completed'] ?? 0,
        'summary': _summaryCtrl.text.trim(),
        'challenges': _challengesCtrl.text.trim(),
        'tomorrow_plan': _tomorrowCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marketing daily report submitted successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit report: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int tasks = _draft['auto_tasks_completed'] ?? 7;
    final int visits = _draft['auto_visits_completed'] ?? 3;
    final int followups = _draft['auto_followups_completed'] ?? 8;
    final int leads = _draft['auto_leads_created'] ?? 2;
    final int onboardings = _draft['auto_onboardings_completed'] ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Daily Marketing Report', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auto-aggregated telemetry header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AUTOMATICALLY RECORDED ACTIVITY',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 10),
                        _buildAutoMetricRow('✓ $tasks Tasks Completed'),
                        _buildAutoMetricRow('✓ $visits Field Visits Logged'),
                        _buildAutoMetricRow('✓ $followups Customer Follow-ups'),
                        _buildAutoMetricRow('✓ $leads New Leads Generated'),
                        _buildAutoMetricRow('✓ $onboardings Partner Onboarding Progress'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Qualitative form
                  const Text('WHAT ELSE HAPPENED TODAY?', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _summaryCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Work Summary *',
                      hintText: 'Met with ABC Banquet owner. Completed photography and verified documents...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _challengesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Challenges / Client Objections',
                      hintText: 'Venue requested 8% commission instead of 10%...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tomorrowCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Tomorrow\'s Action Plan',
                      hintText: 'Visit XYZ Banquet at 10 AM, send agreement draft to Kuhu Espresso...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitDailyReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_isSubmitting ? 'Submitting...' : 'SUBMIT DAILY REPORT', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAutoMetricRow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}
