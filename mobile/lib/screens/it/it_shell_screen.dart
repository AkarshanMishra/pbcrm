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
  final int initialTabIndex;
  const ITShellScreen({super.key, this.isManager = false, this.initialTabIndex = 0});

  @override
  State<ITShellScreen> createState() => _ITShellScreenState();
}

class _ITShellScreenState extends State<ITShellScreen> with SingleTickerProviderStateMixin {
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
                  "IT & ENGINEERING QUICK ACTIONS",
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
                      label: "New Task",
                      icon: Icons.add_task_rounded,
                      color: const Color(0xFF0284C7),
                      onTap: () {
                        Navigator.pop(ctx);
                        _tabController.animateTo(1);
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Create Ticket",
                      icon: Icons.confirmation_number_outlined,
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(ctx);
                        _tabController.animateTo(2);
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Deploy Release",
                      icon: Icons.rocket_launch_rounded,
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDeploymentScreen()));
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Code Review",
                      icon: Icons.code_rounded,
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDevelopmentScreen()));
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Knowledge Base",
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF059669),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ITKnowledgeBaseScreen()));
                      },
                    ),
                    _buildActionItem(
                      ctx,
                      label: "Daily Report",
                      icon: Icons.edit_note_rounded,
                      color: const Color(0xFF0284C7),
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
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Icon(Icons.terminal_rounded, color: Color(0xFF0284C7), size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IT & Infrastructure Tower',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Sprint Backlog, DevOps, Deployments, Incidents & System Health',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded, color: Color(0xFF0284C7)),
            tooltip: 'IT Fast Actions',
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
              indicatorColor: const Color(0xFF0284C7),
              indicatorWeight: 3,
              labelColor: const Color(0xFF0284C7),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                _buildTab(Icons.dashboard_rounded, 'Overview'),
                _buildTab(Icons.assignment_rounded, 'Sprint Work'),
                _buildTab(_managerView ? Icons.groups_rounded : Icons.confirmation_number_rounded, _managerView ? 'Team Oversight' : 'Tickets'),
                _buildTab(Icons.dns_rounded, 'Systems Health'),
                _buildTab(Icons.person_outline_rounded, 'Profile & Settings'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ITHomeScreen(
            onSwitchToTickets: () => _tabController.animateTo(2),
            onSwitchToSystems: () => _tabController.animateTo(3),
            onSwitchToWork: () => _tabController.animateTo(1),
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
