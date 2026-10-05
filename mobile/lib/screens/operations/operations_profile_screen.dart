import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../marketing/marketing_shell_screen.dart';
import '../it/it_shell_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';

class OperationsProfileScreen extends StatefulWidget {
  final VoidCallback? onSwitchToManager;
  const OperationsProfileScreen({super.key, this.onSwitchToManager});

  @override
  State<OperationsProfileScreen> createState() => _OperationsProfileScreenState();
}

class _OperationsProfileScreenState extends State<OperationsProfileScreen> {
  final ApiClient _api = ApiClient();

  void _logout() async {
    await _api.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          "Operations Profile",
          style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: <Widget>[
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFF10B981),
                    child: Text(
                      "R",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Rahul Sharma",
                    style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "PBE000003 • Operations Executive",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                    ),
                    child: const Text(
                      "🟢 On Duty • 09:12 AM",
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mode & Role Switcher
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    "VIEW & ROLE MANAGEMENT",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.swap_vertical_circle_rounded, color: Color(0xFF10B981)),
                    title: const Text("Switch Executive / Manager View", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                    onTap: () {
                      widget.onSwitchToManager?.call();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Switched Operations Role View")),
                      );
                    },
                  ),
                  const Divider(color: Color(0xFF334155)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.campaign_rounded, color: Color(0xFFFB923C)),
                    title: const Text("Open Marketing Portal", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketingShellScreen()));
                    },
                  ),
                  const Divider(color: Color(0xFF334155)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.developer_mode_rounded, color: Color(0xFF38BDF8)),
                    title: const Text("Open IT & Engineering Portal", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ITShellScreen()));
                    },
                  ),
                  const Divider(color: Color(0xFF334155)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFA78BFA)),
                    title: const Text("Open Admin Dashboard", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text("SIGN OUT", style: TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444).withOpacity(0.2),
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
