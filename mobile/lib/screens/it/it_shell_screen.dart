import 'package:flutter/material.dart';
import 'it_home_screen.dart';
import 'it_work_screen.dart';
import 'it_tickets_screen.dart';
import 'it_systems_screen.dart';
import 'it_profile_screen.dart';
import 'it_manager_team_screen.dart';
import 'it_deployment_screen.dart';
import 'it_development_screen.dart';
import 'it_knowledge_base_screen.dart';
import 'it_daily_report_screen.dart';

class ITShellScreen extends StatefulWidget {
  final bool isManager;
  const ITShellScreen({super.key, this.isManager = false});

  @override
  State<ITShellScreen> createState() => _ITShellScreenState();
}

class _ITShellScreenState extends State<ITShellScreen> {
  int _currentIndex = 0;
  late bool _managerView;

  @override
  void initState() {
    super.initState();
    _managerView = widget.isManager;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showQuickActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF475569),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  "IT & ENGINEERING QUICK ACTIONS",
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    _buildActionItem(
                      ctx,
                      label: "New Task",
                      icon: Icons.add_task_rounded,
                      color: const Color(0xFF38BDF8),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _currentIndex = 1);
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Create Ticket",
                      icon: Icons.confirmation_number_outlined,
                      color: const Color(0xFFFB923C),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _currentIndex = 2);
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Deploy Release",
                      icon: Icons.rocket_launch_rounded,
                      color: const Color(0xFFA78BFA),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDeploymentScreen()));
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Review PRs",
                      icon: Icons.code_rounded,
                      color: const Color(0xFF60A5FA),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDevelopmentScreen()));
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Knowledge Base",
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF34D399),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ITKnowledgeBaseScreen()));
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Daily Report",
                      icon: Icons.edit_note_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDailyReportScreen()));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionItem(
    BuildContext ctx, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = <Widget>[
      ITHomeScreen(
        onSwitchToTickets: () => setState(() => _currentIndex = 2),
        onSwitchToSystems: () => setState(() => _currentIndex = 3),
        onSwitchToWork: () => setState(() => _currentIndex = 1),
      ),
      const ITWorkScreen(),
      _managerView ? const ITManagerTeamScreen() : const ITTicketsScreen(),
      const ITSystemsScreen(),
      ITProfileScreen(
        onSwitchToManager: () {
          setState(() {
            _managerView = !_managerView;
          });
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF38BDF8),
        onPressed: _showQuickActionSheet,
        child: const Icon(Icons.bolt_rounded, color: Color(0xFF0F172A), size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1E293B),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(0, Icons.home_rounded, "Home"),
              _buildNavItem(1, Icons.assignment_rounded, "Work"),
              const SizedBox(width: 40),
              _buildNavItem(2, _managerView ? Icons.groups_rounded : Icons.confirmation_number_rounded, _managerView ? "Team" : "Tickets"),
              _buildNavItem(3, Icons.dns_rounded, "Systems"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSel = _currentIndex == index;
    Color col = isSel ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8);
    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: col, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: col, fontSize: 10, fontWeight: isSel ? FontWeight.w800 : FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
