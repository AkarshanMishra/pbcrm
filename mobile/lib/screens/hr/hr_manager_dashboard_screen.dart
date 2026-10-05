import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'onboarding_wizard_screen.dart';
import 'hr_attendance_screen.dart';
import 'hr_recruitment_screen.dart';
import 'hr_policies_screen.dart';

class HRManagerDashboardScreen extends StatefulWidget {
  const HRManagerDashboardScreen({super.key});

  @override
  State<HRManagerDashboardScreen> createState() => _HRManagerDashboardScreenState();
}

class _HRManagerDashboardScreenState extends State<HRManagerDashboardScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTelemetry();
  }

  Future<void> _fetchTelemetry() async {
    setState(() => _isLoading = true);
    try {
      await _api.dio.get('/hr/telemetry/');
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("HR Control Center & Analytics", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExecutiveSummaryBanner(),
            const SizedBox(height: 16),
            const Text("ORGANIZATIONAL WORKFORCE METRICS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildMetricTile("124", "Total Headcount", "+8% MoM", const Color(0xFF3B82F6))),
                const SizedBox(width: 10),
                Expanded(child: _buildMetricTile("96.4%", "Retention Rate", "High", const Color(0xFF10B981))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildMetricTile("18 Days", "Avg Time-to-Hire", "-3 Days", const Color(0xFFEC4899))),
                const SizedBox(width: 10),
                Expanded(child: _buildMetricTile("14.2%", "Leave Utilization", "Optimal", const Color(0xFFF59E0B))),
              ],
            ),
            const SizedBox(height: 20),
            _buildDepartmentDistribution(),
            const SizedBox(height: 20),
            _buildComplianceMatrixCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveSummaryBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: Color(0xFFEC4899), size: 20),
              SizedBox(width: 8),
              Text("HR LEADERSHIP HEALTH SCORECARD", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEC4899))),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            "People Operations & Retention: Excellent (94/100)",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            "Overall attendance rate steady at 96.2%, Q3 recruitment targets 85% filled, and policy acknowledgement compliance at 94%.",
            style: TextStyle(fontSize: 12, color: Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String val, String label, String tag, Color color) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                child: Text(tag, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildDepartmentDistribution() {
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
          const Text("DEPARTMENT HEADCOUNT DISTRIBUTION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          _buildDeptRow("Information Technology", 48, 0.38, const Color(0xFF3B82F6)),
          const SizedBox(height: 8),
          _buildDeptRow("Operations & Field Logistics", 36, 0.29, const Color(0xFF10B981)),
          const SizedBox(height: 8),
          _buildDeptRow("Marketing & Institutional Sales", 22, 0.18, const Color(0xFFF59E0B)),
          const SizedBox(height: 8),
          _buildDeptRow("Human Resources & People Ops", 10, 0.08, const Color(0xFFEC4899)),
          const SizedBox(height: 8),
          _buildDeptRow("Accounts, Finance & Legal", 8, 0.07, const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildDeptRow(String name, int count, double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontSize: 12, color: Colors.white)),
            Text("$count Employees", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: pct,
          backgroundColor: const Color(0xFF0F172A),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildComplianceMatrixCard() {
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
          const Text("REGULATORY & HR COMPLIANCE STATUS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          _buildComplianceItem("POSH & ICC Committee Roster", "Active & Certified", const Color(0xFF10B981)),
          _buildComplianceItem("Provident Fund (PF) & ESI Returns", "Filed on 15th Sep", const Color(0xFF10B981)),
          _buildComplianceItem("Employee Identity Document Audit", "98.4% Verified", const Color(0xFF10B981)),
          _buildComplianceItem("Annual Appraisal Cycle Completion", "79% Complete", const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildComplianceItem(String title, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
          Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
