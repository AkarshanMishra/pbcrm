import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard_screen.dart';
import '../marketing/marketing_shell_screen.dart';
import '../employee/employee_dashboard_screen.dart';
import 'it_security_screen.dart';

class ITProfileScreen extends StatelessWidget {
  final VoidCallback? onSwitchToManager;

  const ITProfileScreen({super.key, this.onSwitchToManager});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("My IT Profile & Settings", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildEngineeringStats(),
          const SizedBox(height: 20),
          const Text(
            "ROLE & PERSPECTIVE SWITCHER",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          _buildSwitcherOption(
            context,
            title: "Switch to IT Manager View",
            subtitle: "Team workload, sprint planning & approvals",
            icon: Icons.supervisor_account_rounded,
            color: const Color(0xFF38BDF8),
            onTap: () {
              if (onSwitchToManager != null) {
                onSwitchToManager!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Switched to IT Manager view!")));
              }
            },
          ),
          _buildSwitcherOption(
            context,
            title: "Switch to Marketing Team Hub",
            subtitle: "Field visits, leads pipeline & partner onboarding",
            icon: Icons.campaign_rounded,
            color: const Color(0xFF10B981),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MarketingShellScreen()));
            },
          ),
          _buildSwitcherOption(
            context,
            title: "Switch to Super Admin Portal",
            subtitle: "Full organizational control & configuration",
            icon: Icons.admin_panel_settings_rounded,
            color: const Color(0xFFA78BFA),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
            },
          ),
          _buildSwitcherOption(
            context,
            title: "Switch to General Employee Hub",
            subtitle: "HR leaves, attendance & general tasks",
            icon: Icons.work_outline_rounded,
            color: const Color(0xFFFBBF24),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EmployeeDashboardScreen()));
            },
          ),
          const SizedBox(height: 20),
          const Text(
            "SECURITY & CREDENTIALS",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          _buildSwitcherOption(
            context,
            title: "Security Center & Audit Log",
            subtitle: "MFA tokens, active sessions & SSL alerts",
            icon: Icons.security_rounded,
            color: const Color(0xFFF43F5E),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ITSecurityScreen())),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
              label: const Text("SIGN OUT FROM PCRM", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w800)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFF38BDF8),
            child: Text("AM", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Akarshan Mishra", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                const Text("Software Developer • SDE-2", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text("ID: PBE000003 • IT & Core Engineering", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineeringStats() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("42", "PRs Merged"),
          _buildStatItem("18", "Deployments"),
          _buildStatItem("99.9%", "Uptime SLA"),
          _buildStatItem("530d", "Warranty"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
      ],
    );
  }

  Widget _buildSwitcherOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF64748B), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
