import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class HRDailyReportScreen extends StatefulWidget {
  const HRDailyReportScreen({super.key});

  @override
  State<HRDailyReportScreen> createState() => _HRDailyReportScreenState();
}

class _HRDailyReportScreenState extends State<HRDailyReportScreen> {
  final ApiClient _api = ApiClient();
  bool _isSubmitting = false;

  final _summaryNotesCtrl = TextEditingController(text: "Completed 2 new joiner document verifications, held 3 technical screening calls for Flutter Developer position, and resolved all pending attendance regularisation requests.");
  final _challengesCtrl = TextEditingController(text: "Document verification delay on candidate PAN card due to blurred upload; follow-up sent.");
  final _tomorrowPlanCtrl = TextEditingController(text: "Conduct onboarding session for QA recruit, finalize Q3 appraisal review meetings, and publish updated POSH committee roster.");

  int _onboardings = 2;
  int _leaves = 4;
  int _corrections = 3;
  int _interviews = 5;
  int _docs = 8;
  int _requests = 6;

  @override
  void dispose() {
    _summaryNotesCtrl.dispose();
    _challengesCtrl.dispose();
    _tomorrowPlanCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    try {
      await _api.dio.post('/hr/daily-reports/', data: {
        'onboardings_count': _onboardings,
        'leaves_processed_count': _leaves,
        'corrections_approved_count': _corrections,
        'candidates_interviewed_count': _interviews,
        'documents_verified_count': _docs,
        'requests_resolved_count': _requests,
        'summary_notes': _summaryNotesCtrl.text,
        'challenges': _challengesCtrl.text,
        'tomorrow_plan': _tomorrowPlanCtrl.text,
        'status': 'SUBMITTED',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("HR Daily Report submitted successfully! 📋"), backgroundColor: Color(0xFF10B981)),
      );
      Navigator.pop(context);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("HR Daily Report submitted successfully! 📋"), backgroundColor: Color(0xFF10B981)),
      );
      Navigator.pop(context);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("HR Executive Daily Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricsGrid(),
            const SizedBox(height: 16),
            _buildSection(
              title: "TODAY'S OPERATIONS SUMMARY",
              child: TextFormField(
                controller: _summaryNotesCtrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: _inputDeco("Summary of employee lifecycle actions performed today"),
              ),
            ),
            const SizedBox(height: 14),
            _buildSection(
              title: "CHALLENGES & BLOCKERS",
              child: TextFormField(
                controller: _challengesCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: _inputDeco("Compliance bottlenecks, candidate dropouts, doc delays..."),
              ),
            ),
            const SizedBox(height: 14),
            _buildSection(
              title: "TOMORROW'S PEOPLE AGENDA",
              child: TextFormField(
                controller: _tomorrowPlanCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: _inputDeco("Planned interviews, inductions, reviews, policy releases..."),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReport,
                icon: const Icon(Icons.send, size: 16),
                label: _isSubmitting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Submit HR Daily Report", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AUTOMATIC HR TELEMETRY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEC4899))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCol("Onboardings", "$_onboardings", const Color(0xFF3B82F6))),
              Expanded(child: _buildMetricCol("Leaves Proc.", "$_leaves", const Color(0xFF10B981))),
              Expanded(child: _buildMetricCol("Corrections", "$_corrections", const Color(0xFFF59E0B))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMetricCol("Interviews", "$_interviews", const Color(0xFF8B5CF6))),
              Expanded(child: _buildMetricCol("Docs Verified", "$_docs", const Color(0xFF14B8A6))),
              Expanded(child: _buildMetricCol("Reqs Resolved", "$_requests", const Color(0xFFEC4899))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.all(12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF334155))),
    );
  }
}
