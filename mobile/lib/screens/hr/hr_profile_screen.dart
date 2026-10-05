import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'hr_policies_screen.dart';
import 'hr_training_screen.dart';
import 'hr_performance_screen.dart';

class HRProfileScreen extends StatelessWidget {
  final bool isManager;
  final ValueChanged<bool>? onToggleManagerView;
  const HRProfileScreen({
    super.key,
    this.isManager = false,
    this.onToggleManagerView,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("HR Profile & Preferences", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildRoleToggleCard(context),
            const SizedBox(height: 16),
            _buildComplianceScorecard(),
            const SizedBox(height: 20),
            _buildQuickLinks(context),
            const SizedBox(height: 20),
            _buildLogoutButton(context),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Color(0xFFEC4899),
            child: Text(
              "AS",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Ananya Sharma",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 2),
                Text(
                  "HR Lead & People Operations",
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
                SizedBox(height: 2),
                Text(
                  "ID: PBH000001 • Human Resources",
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleToggleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("HR Manager Leadership View", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 2),
              Text("Toggle analytics and policy control center", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
          Switch(
            value: isManager,
            onChanged: onToggleManagerView,
            activeColor: const Color(0xFFEC4899),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceScorecard() {
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
          const Text("PEOPLE OPERATIONS SCORECARD (Q3 2026)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          _buildScoreRow("Onboardings Driven", "14 Joiners", const Color(0xFF10B981)),
          const SizedBox(height: 8),
          _buildScoreRow("Doc Verification Turnaround", "< 24 Hours", const Color(0xFF3B82F6)),
          const SizedBox(height: 8),
          _buildScoreRow("Grievances Resolved", "100%", const Color(0xFF10B981)),
          const SizedBox(height: 8),
          _buildScoreRow("Appraisal Cycles Run", "2 Completed", const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("HR MODULE QUICK NAVIGATION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
        const SizedBox(height: 10),
        _buildNavTile(context, "Company Handbooks & Policies", Icons.menu_book, const HRPoliciesScreen()),
        _buildNavTile(context, "Training & Certifications", Icons.school, const HRTrainingScreen()),
        _buildNavTile(context, "Performance Appraisal Framework", Icons.star_border, const HRPerformanceScreen()),
      ],
    );
  }

  Widget _buildNavTile(BuildContext context, String title, IconData icon, Widget target) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFEC4899), size: 20),
        title: Text(title, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => target)),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await ApiClient().logout();
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        },
        icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
        label: const Text("Log Out of HR Portal", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEF4444)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
