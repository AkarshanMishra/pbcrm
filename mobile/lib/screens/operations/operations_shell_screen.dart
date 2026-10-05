import 'package:flutter/material.dart';
import 'operations_home_screen.dart';
import 'operations_work_screen.dart';
import 'operations_dashboard_screen.dart';
import 'operations_requests_screen.dart';
import 'operations_profile_screen.dart';
import 'operations_manager_team_screen.dart';
import 'operations_issues_screen.dart';
import 'quality_control_screen.dart';
import 'operations_inventory_screen.dart';
import 'operations_daily_report_screen.dart';

class OperationsShellScreen extends StatefulWidget {
  final bool isManager;
  const OperationsShellScreen({super.key, this.isManager = false});

  @override
  State<OperationsShellScreen> createState() => _OperationsShellScreenState();
}

class _OperationsShellScreenState extends State<OperationsShellScreen> {
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
                  "OPERATIONS QUICK ACTIONS",
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
                      label: "+ Task",
                      icon: Icons.add_task_rounded,
                      color: const Color(0xFF38BDF8),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _currentIndex = 1);
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "+ Issue",
                      icon: Icons.report_problem_rounded,
                      color: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsIssuesScreen()));
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Quality Audit",
                      icon: Icons.verified_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const QualityControlScreen()));
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "+ Request",
                      icon: Icons.post_add_rounded,
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _currentIndex = 3);
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Asset Inventory",
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFFA78BFA),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsInventoryScreen()));
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Daily Report",
                      icon: Icons.edit_note_rounded,
                      color: const Color(0xFF34D399),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsDailyReportScreen()));
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
      OperationsHomeScreen(
        onSwitchToWork: () => setState(() => _currentIndex = 1),
        onSwitchToOperations: () => setState(() => _currentIndex = 2),
        onSwitchToRequests: () => setState(() => _currentIndex = 3),
      ),
      const OperationsWorkScreen(),
      _managerView ? const OperationsManagerTeamScreen() : const OperationsDashboardScreen(),
      const OperationsRequestsScreen(),
      OperationsProfileScreen(
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
        backgroundColor: const Color(0xFF10B981),
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
              _buildNavItem(2, _managerView ? Icons.groups_rounded : Icons.precision_manufacturing_rounded, _managerView ? "Team" : "Operations"),
              _buildNavItem(3, Icons.all_inbox_rounded, "Requests"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSel = _currentIndex == index;
    Color col = isSel ? const Color(0xFF10B981) : const Color(0xFF94A3B8);
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
