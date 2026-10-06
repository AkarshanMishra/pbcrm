import 'package:flutter/material.dart';
import 'operations_home_screen.dart';
import 'operations_work_screen.dart';
import 'operations_issues_screen.dart';
import 'operations_requests_screen.dart';
import 'operations_profile_screen.dart';
import 'operations_manager_team_screen.dart';
import 'operations_inventory_screen.dart';
import 'quality_control_screen.dart';
import 'operations_daily_report_screen.dart';

class OperationsShellScreen extends StatefulWidget {
  final bool isManager;
  final int initialTabIndex;
  const OperationsShellScreen({super.key, this.isManager = false, this.initialTabIndex = 0});

  @override
  State<OperationsShellScreen> createState() => _OperationsShellScreenState();
}

class _OperationsShellScreenState extends State<OperationsShellScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late bool _managerView;

  @override
  void initState() {
    super.initState();
    _managerView = widget.isManager;
    _tabController = TabController(length: 5, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showQuickActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  "OPERATIONS FAST ACTIONS",
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    _buildActionItem(
                      ctx,
                      label: "Log Issue",
                      icon: Icons.report_problem_rounded,
                      color: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsIssuesScreen()));
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Inventory",
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFFD97706),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsInventoryScreen()));
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Quality Audit",
                      icon: Icons.verified_user_rounded,
                      color: const Color(0xFF059669),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const QualityControlScreen()));
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Daily Report",
                      icon: Icons.assignment_turned_in_rounded,
                      color: const Color(0xFF0284C7),
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
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Icon(Icons.settings_suggest_rounded, color: Color(0xFFD97706), size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operations Control Tower',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Event Staging, Venue Coordination, Logistics, Quality Audits & Daily Service',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded, color: Color(0xFFD97706)),
            tooltip: 'Fast Actions',
            onPressed: _showQuickActionSheet,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: Colors.white,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: const Color(0xFFD97706),
              indicatorWeight: 3,
              labelColor: const Color(0xFFD97706),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                _buildTab(Icons.dashboard_rounded, 'Operations Overview'),
                _buildTab(Icons.assignment_rounded, 'Field Work & Tasks'),
                _buildTab(_managerView ? Icons.groups_rounded : Icons.report_problem_rounded, _managerView ? 'Team Oversight' : 'Incidents & Issues'),
                _buildTab(Icons.inventory_2_rounded, 'Equipment & Logistics'),
                _buildTab(Icons.person_outline_rounded, 'Profile & Settings'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          OperationsHomeScreen(
            onSwitchToWork: () => _tabController.animateTo(1),
            onSwitchToOperations: () => _tabController.animateTo(2),
            onSwitchToRequests: () => _tabController.animateTo(3),
          ),
          const OperationsWorkScreen(),
          _managerView ? const OperationsManagerTeamScreen() : const OperationsIssuesScreen(),
          const OperationsInventoryScreen(),
          OperationsProfileScreen(
            onSwitchToManager: () {
              setState(() {
                _managerView = !_managerView;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
