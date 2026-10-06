import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'hr_home_screen.dart';
import 'hr_attendance_screen.dart';
import 'hr_requests_screen.dart';
import 'hr_recruitment_screen.dart';
import 'hr_documents_screen.dart';
import 'hr_policies_screen.dart';
import 'hr_performance_screen.dart';
import 'hr_training_screen.dart';
import 'hr_daily_report_screen.dart';
import '../admin/organization_management_screen.dart';
import '../admin/employee_management_screen.dart';
import '../admin/add_employee_wizard_sheet.dart';

class HRShellScreen extends StatefulWidget {
  final bool isManager;
  final int initialTabIndex;
  const HRShellScreen({super.key, this.isManager = false, this.initialTabIndex = 0});

  @override
  State<HRShellScreen> createState() => _HRShellScreenState();
}

class _HRShellScreenState extends State<HRShellScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;

  Map<String, dynamic> _telemetry = {
    'workforce': {'total': 124, 'active': 118, 'on_leave': 6, 'onboarding': 5},
    'today_attendance': {'present': 118, 'late': 9, 'absent': 6, 'total_scheduled': 124},
    'recruitment': {'open_jobs': 8, 'active_candidates': 24},
    'needs_attention': {'pending_requests': 4, 'pending_leaves': 3, 'expiring_docs': 2},
  };


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this, initialIndex: widget.initialTabIndex);
    _fetchTelemetry();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTelemetry() async {
    try {
      final res = await _api.dio.get('/hr/telemetry/');
      if (res.statusCode == 200 && res.data != null && mounted) {
        setState(() {
          _telemetry = res.data;
        });
      }
    } catch (_) {}
  }


  void _showAddEmployeeWizard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEmployeeWizardSheet(
        onEmployeeCreated: () {
          _fetchTelemetry();
          setState(() {});
        },
      ),
    );
  }

  void _showQuickActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFFDF2F8),
                      child: Icon(Icons.flash_on_rounded, color: Color(0xFFEC4899), size: 18),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "HR Operations Fast-Action Hub",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 12,
                  children: [
                    _buildModalItem(
                      icon: Icons.person_add_alt_1_rounded,
                      label: "+ Employee",
                      color: const Color(0xFFEC4899),
                      onTap: () {
                        Navigator.pop(ctx);
                        _showAddEmployeeWizard();
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.apartment_rounded,
                      label: "+ Dept",
                      color: const Color(0xFF2563EB),
                      onTap: () {
                        Navigator.pop(ctx);
                        _tabController.animateTo(1);
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.work_outline_rounded,
                      label: "+ Job Opening",
                      color: const Color(0xFFF59E0B),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HRRecruitmentScreen()));
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.event_available_rounded,
                      label: "Leave Approvals",
                      color: const Color(0xFF10B981),
                      onTap: () {
                        Navigator.pop(ctx);
                        _tabController.animateTo(4);
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.verified_user_rounded,
                      label: "Verify Docs",
                      color: const Color(0xFF06B6D4),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HRDocumentsScreen()));
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.menu_book_rounded,
                      label: "Policies",
                      color: const Color(0xFF8B5CF6),
                      onTap: () {
                        Navigator.pop(ctx);
                        _tabController.animateTo(6);
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.school_rounded,
                      label: "Training",
                      color: const Color(0xFF6366F1),
                      onTap: () {
                        Navigator.pop(ctx);
                        _tabController.animateTo(7);
                      },
                    ),
                    _buildModalItem(
                      icon: Icons.rate_review_rounded,
                      label: "Daily Reports",
                      color: const Color(0xFFE11D48),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const HRDailyReportScreen()));
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

  Widget _buildModalItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalWf = _telemetry['workforce']?['total'] ?? 124;
    final activeWf = _telemetry['workforce']?['active'] ?? 118;
    final onLeaveWf = _telemetry['workforce']?['on_leave'] ?? 6;
    final openJobs = _telemetry['recruitment']?['open_jobs'] ?? 8;
    final pendingLeaves = _telemetry['needs_attention']?['pending_leaves'] ?? 3;
    final pendingRequests = _telemetry['needs_attention']?['pending_requests'] ?? 4;

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
                color: const Color(0xFFFDF2F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFBCFE8)),
              ),
              child: const Icon(Icons.people_alt_rounded, color: Color(0xFFEC4899), size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Human Resources Control Center',
                  style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                Text(
                  'Workforce Operations, Departments Hierarchy, Recruitment, Approvals & KPA',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Refresh HR Telemetry',
            onPressed: () {
              _fetchTelemetry();
              setState(() {});
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.flash_on_rounded, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC4899),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _showQuickActionSheet,
            label: const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add_rounded, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _showAddEmployeeWizard,
            label: const Text('+ New Employee', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: const Color(0xFFEC4899),
              indicatorWeight: 3,
              labelColor: const Color(0xFFEC4899),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                _buildTabItem(Icons.dashboard_rounded, 'HR Overview'),
                _buildTabItem(Icons.apartment_rounded, 'Departments & Hierarchy'),
                _buildTabItem(Icons.groups_rounded, 'Workforce Roster ($totalWf)'),
                _buildTabItem(Icons.work_outline_rounded, 'Recruitment & ATS ($openJobs)'),
                _buildTabItem(Icons.alarm_rounded, 'Attendance & Leaves ($onLeaveWf)'),
                _buildTabItem(Icons.stars_rounded, 'Performance & KPA'),
                _buildTabItem(Icons.menu_book_rounded, 'Company Policies'),
                _buildTabItem(Icons.school_rounded, 'Training & Skills'),
                _buildTabItem(Icons.assignment_turned_in_rounded, 'Requests & Helpdesk (${pendingLeaves + pendingRequests})'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Top KPI Metrics Banner
          _buildTopKPICarousel(totalWf, activeWf, onLeaveWf, openJobs, pendingLeaves + pendingRequests),

          // Main Tab View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. HR Overview Dashboard
                HRHomeScreen(
                  onNavigateToPeople: () => _tabController.animateTo(2),
                  onNavigateToRequests: () => _tabController.animateTo(8),
                ),

                // 2. Departments & Hierarchy (Full CRUD + 360 Cockpit)
                const OrganizationManagementScreen(initialTabIndex: 0),

                // 3. Workforce Roster (Directory + CTC + 360 Profile)
                const EmployeeManagementScreen(),

                // 4. Recruitment & ATS Pipeline
                const HRRecruitmentScreen(),

                // 5. Attendance & Leaves Hub
                const HRAttendanceScreen(),

                // 6. Performance Reviews & KPA
                const HRPerformanceScreen(),

                // 7. Company Policies & Handbooks
                const HRPoliciesScreen(),

                // 8. Training & Skills
                const HRTrainingScreen(),

                // 9. Requests & Helpdesk
                const HRRequestsScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(IconData icon, String label) {
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

  Widget _buildTopKPICarousel(int total, int active, int onLeave, int jobs, int pendingReqs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatCard('Total Workforce', '$total Staff', Icons.groups_rounded, const Color(0xFF2563EB)),
            const SizedBox(width: 10),
            _buildStatCard('Active On-Duty', '$active Working', Icons.badge_rounded, const Color(0xFF10B981)),
            const SizedBox(width: 10),
            _buildStatCard('On Leave Today', '$onLeave Staff', Icons.beach_access_rounded, const Color(0xFFF59E0B)),
            const SizedBox(width: 10),
            _buildStatCard('Open Requisitions', '$jobs Vacancies', Icons.work_outline_rounded, const Color(0xFFEC4899)),
            const SizedBox(width: 10),
            _buildStatCard('Pending Approvals', '$pendingReqs Requests', Icons.pending_actions_rounded, const Color(0xFF8B5CF6)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
              Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
