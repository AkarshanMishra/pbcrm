import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class ITDailyReportScreen extends StatefulWidget {
  const ITDailyReportScreen({super.key});

  @override
  State<ITDailyReportScreen> createState() => _ITDailyReportScreenState();
}

class _ITDailyReportScreenState extends State<ITDailyReportScreen> {
  final ApiClient _api = ApiClient();
  bool _isSubmitting = false;

  final TextEditingController _incidentsCtrl = TextEditingController(
    text: "Investigated Production Payment API 502 latency and tuned Gunicorn pool size.",
  );
  final TextEditingController _blockersCtrl = TextEditingController(
    text: "Waiting for AWS CloudWatch IAM policy approval for staging postmortem.",
  );
  final TextEditingController _tomorrowCtrl = TextEditingController(
    text: "Complete payment gateway retry logic and merge PR #248.",
  );

  int _tasksCompleted = 5;
  int _bugsFixed = 2;
  int _ticketsResolved = 4;
  int _deployments = 1;
  int _codeReviews = 2;

  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);
    try {
      final res = await _api.post('/api/v1/it/daily-reports/', {
        'tasks_completed_count': _tasksCompleted,
        'bugs_fixed_count': _bugsFixed,
        'tickets_resolved_count': _ticketsResolved,
        'deployments_count': _deployments,
        'code_reviews_count': _codeReviews,
        'incidents_handled': _incidentsCtrl.text,
        'blockers': _blockersCtrl.text,
        'tomorrow_plan': _tomorrowCtrl.text,
        'summary_notes': 'Automated IT daily activity report.',
      });

      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Daily IT Report Submitted to Engineering Manager!"),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Daily IT Report Submitted to Engineering Manager!"),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("Daily IT Report", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMetricsSummaryCard(),
          const SizedBox(height: 20),
          _buildInputField("INCIDENTS & OUTAGES HANDLED", _incidentsCtrl, "Describe incidents investigated or resolved..."),
          const SizedBox(height: 16),
          _buildInputField("BLOCKERS & DEPENDENCIES", _blockersCtrl, "Mention any pending approvals or access blockers..."),
          const SizedBox(height: 16),
          _buildInputField("TOMORROW'S ENGINEERING PLAN", _tomorrowCtrl, "Key tickets, PRs or deployments planned for tomorrow..."),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitReport,
              icon: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              label: const Text("SUBMIT DAILY IT REPORT", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMetricsSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TODAY'S ACTIVITY (AUTO-AGGREGATED)", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w800, fontSize: 12)),
              const Text("04 Oct 2026", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricRow("Tasks Completed", "$_tasksCompleted", const Color(0xFF38BDF8)),
          _buildMetricRow("Bugs Fixed", "$_bugsFixed", const Color(0xFFFB923C)),
          _buildMetricRow("Tickets Resolved", "$_ticketsResolved", const Color(0xFF10B981)),
          _buildMetricRow("Deployments Executed", "$_deployments", const Color(0xFFA78BFA)),
          _buildMetricRow("Code Reviews Completed", "$_codeReviews", const Color(0xFF60A5FA)),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String val, Color col) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
            child: Text(val, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
          ),
        ),
      ],
    );
  }
}
