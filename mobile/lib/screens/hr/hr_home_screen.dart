import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'onboarding_wizard_screen.dart';
import 'hr_attendance_screen.dart';
import 'hr_documents_screen.dart';
import 'hr_recruitment_screen.dart';
import 'hr_policies_screen.dart';
import 'hr_performance_screen.dart';
import 'hr_training_screen.dart';
import 'hr_offboarding_screen.dart';
import '../admin/add_employee_wizard_sheet.dart';

class HRHomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPeople;
  final VoidCallback? onNavigateToRequests;
  const HRHomeScreen({
    super.key,
    this.onNavigateToPeople,
    this.onNavigateToRequests,
  });

  @override
  State<HRHomeScreen> createState() => _HRHomeScreenState();
}

class _HRHomeScreenState extends State<HRHomeScreen> {
  final ApiClient _api = ApiClient();
  bool _isCheckedIn = true;
  final String _checkInTime = "09:15 AM";

  Map<String, dynamic> _telemetry = {
    'workforce': {
      'total': 124,
      'active': 118,
      'on_leave': 6,
      'onboarding': 5,
      'probation': 8,
    },
    'today_attendance': {
      'present': 118,
      'late': 9,
      'absent': 6,
      'pending_reports': 14,
      'total_scheduled': 124,
    },
    'needs_attention': {
      'attendance_corrections': 3,
      'onboarding_pending': 5,
      'expiring_docs': 2,
      'pending_requests': 4,
      'pending_leaves': 3,
    },
    'recruitment': {
      'open_jobs': 8,
      'active_candidates': 24,
    }
  };

  List<dynamic> _announcements = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final res = await _api.dio.get('/hr/telemetry/');
      if (res.statusCode == 200 && res.data != null && mounted) {
        setState(() {
          _telemetry = res.data;
        });
      }
    } catch (_) {}

    try {
      final resAnnounce = await _api.dio.get('/hr/announcements/');
      if (resAnnounce.statusCode == 200 && resAnnounce.data != null && mounted) {
        final list = resAnnounce.data is List ? resAnnounce.data : resAnnounce.data['results'] ?? [];
        setState(() {
          _announcements = list;
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
        onEmployeeCreated: _fetchDashboardData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: const Color(0xFFEC4899),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Radiant Clean Header Card
                  _buildHeader(isDesktop),
                  const SizedBox(height: 20),

                  // 2. Executive Responsive Grid
                  if (isDesktop) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Workforce & Attendance Analytics)
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildWorkforceOverview(),
                              const SizedBox(height: 16),
                              _buildTodayAttendanceCard(),
                              const SizedBox(height: 16),
                              _buildRecruitmentPipelineCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Right Column (Needs Attention & Quick Fast Actions)
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildNeedsAttentionSection(),
                              const SizedBox(height: 16),
                              _buildQuickActionsGrid(),
                              const SizedBox(height: 16),
                              _buildAnnouncementsSection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildWorkforceOverview(),
                    const SizedBox(height: 16),
                    _buildTodayAttendanceCard(),
                    const SizedBox(height: 16),
                    _buildNeedsAttentionSection(),
                    const SizedBox(height: 16),
                    _buildQuickActionsGrid(),
                    const SizedBox(height: 16),
                    _buildRecruitmentPipelineCard(),
                    const SizedBox(height: 16),
                    _buildAnnouncementsSection(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. RADIANT CLEAN SAAS HEADER (NO DARK BLUE VOID)
  // ===========================================================================
  Widget _buildHeader(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Radiant Accent Bar
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFF8B5CF6), Color(0xFF2563EB)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: isDesktop ? _buildDesktopHeaderContent() : _buildMobileHeaderContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopHeaderContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Executive Workforce & HR Command Center",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Real-time Enterprise HR Operations, Talent Roster, Leave Approvals & Department Governance",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isCheckedIn ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isCheckedIn ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isCheckedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isCheckedIn ? "ATTENDANCE LOGGED • CHECKED IN AT $_checkInTime" : "CURRENTLY CHECKED OUT",
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _isCheckedIn ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          icon: Icon(_isCheckedIn ? Icons.logout_rounded : Icons.login_rounded, size: 16),
          onPressed: () {
            setState(() => _isCheckedIn = !_isCheckedIn);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isCheckedIn ? "Checked in successfully" : "Checked out successfully"),
                backgroundColor: _isCheckedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isCheckedIn ? const Color(0xFF0F172A) : const Color(0xFFEC4899),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          label: Text(
            _isCheckedIn ? "CLOCK OUT" : "CLOCK IN",
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFBCFE8)),
              ),
              child: const Icon(Icons.people_alt_rounded, color: Color(0xFFEC4899), size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "HR Command Center",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "Workforce roster, attendance radar & leave approvals",
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _isCheckedIn ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isCheckedIn ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isCheckedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _isCheckedIn ? "LOGGED: $_checkInTime" : "OFF DUTY",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _isCheckedIn ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(_isCheckedIn ? Icons.logout_rounded : Icons.login_rounded, size: 14),
              onPressed: () {
                setState(() => _isCheckedIn = !_isCheckedIn);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCheckedIn ? const Color(0xFF0F172A) : const Color(0xFFEC4899),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
              ),
              label: Text(
                _isCheckedIn ? "OUT" : "IN",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. WORKFORCE OVERVIEW
  // ===========================================================================
  Widget _buildWorkforceOverview() {
    final wf = _telemetry['workforce'] ?? {};
    final total = wf['total'] ?? 124;
    final active = wf['active'] ?? 118;
    final onLeave = wf['on_leave'] ?? 6;
    final onboarding = wf['onboarding'] ?? 5;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.groups_rounded, color: Color(0xFF2563EB), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Workforce Composition",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: widget.onNavigateToPeople,
                  child: const Text('View Full Roster →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    count: "$total",
                    label: "Total Headcount",
                    color: const Color(0xFF2563EB),
                    icon: Icons.people_alt_rounded,
                    onTap: widget.onNavigateToPeople,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricBox(
                    count: "$active",
                    label: "Active On-Duty",
                    color: const Color(0xFF10B981),
                    icon: Icons.badge_rounded,
                    onTap: widget.onNavigateToPeople,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricBox(
                    count: "$onLeave",
                    label: "On Leave",
                    color: const Color(0xFFF59E0B),
                    icon: Icons.beach_access_rounded,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRAttendanceScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricBox(
                    count: "$onboarding",
                    label: "In Onboarding",
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.person_add_rounded,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingWizardScreen())),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox({
    required String count,
    required String label,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. TODAY'S ATTENDANCE RADAR
  // ===========================================================================
  Widget _buildTodayAttendanceCard() {
    final att = _telemetry['today_attendance'] ?? {};
    final present = att['present'] ?? 118;
    final late = att['late'] ?? 9;
    final absent = att['absent'] ?? 6;
    final total = att['total_scheduled'] ?? 124;
    final rate = total > 0 ? ((present / total) * 100).toInt() : 95;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.schedule_rounded, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Today's Attendance Radar",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    "$rate% Compliance",
                    style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w800, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: total > 0 ? (present / total) : 0.95,
                minHeight: 8,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttendanceStat("Present", "$present", const Color(0xFF10B981)),
                _buildAttendanceStat("Late Arrival", "$late", const Color(0xFFF59E0B)),
                _buildAttendanceStat("Absent / Unlogged", "$absent", const Color(0xFFEF4444)),
                _buildAttendanceStat("Total Expected", "$total", const Color(0xFF2563EB)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ===========================================================================
  // 4. ACTIONABLE NEEDS ATTENTION SECTION
  // ===========================================================================
  Widget _buildNeedsAttentionSection() {
    final na = _telemetry['needs_attention'] ?? {};
    final leaves = na['pending_leaves'] ?? 3;
    final reqs = na['pending_requests'] ?? 4;
    final docs = na['expiring_docs'] ?? 2;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
                SizedBox(width: 8),
                Text(
                  "Action Items & Pending Approvals",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAttentionItem(
              title: "$leaves Leave Approvals Pending",
              subtitle: "Staff awaiting manager/admin sign-off",
              color: const Color(0xFFF59E0B),
              icon: Icons.event_available_rounded,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRAttendanceScreen())),
            ),
            const SizedBox(height: 8),
            _buildAttentionItem(
              title: "$reqs HR Service Requests",
              subtitle: "Salary slips, certificates, and inquiries",
              color: const Color(0xFF2563EB),
              icon: Icons.assignment_turned_in_rounded,
              onTap: widget.onNavigateToRequests,
            ),
            const SizedBox(height: 8),
            _buildAttentionItem(
              title: "$docs Employee Documents Expiring",
              subtitle: "IDs and compliance renewals required",
              color: const Color(0xFFEF4444),
              icon: Icons.verified_user_rounded,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRDocumentsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionItem({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. QUICK OPERATIONS GRID
  // ===========================================================================
  Widget _buildQuickActionsGrid() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.dashboard_customize_rounded, color: Color(0xFF8B5CF6), size: 20),
                SizedBox(width: 8),
                Text(
                  "Workforce Fast Actions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _buildActionBtn(
                  label: "Add Employee",
                  icon: Icons.person_add_rounded,
                  color: const Color(0xFFEC4899),
                  onTap: _showAddEmployeeWizard,
                ),
                _buildActionBtn(
                  label: "Recruitment ATS",
                  icon: Icons.work_outline_rounded,
                  color: const Color(0xFF2563EB),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRRecruitmentScreen())),
                ),
                _buildActionBtn(
                  label: "Company Policies",
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRPoliciesScreen())),
                ),
                _buildActionBtn(
                  label: "Performance KPA",
                  icon: Icons.stars_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRPerformanceScreen())),
                ),
                _buildActionBtn(
                  label: "Training Programs",
                  icon: Icons.school_rounded,
                  color: const Color(0xFF06B6D4),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRTrainingScreen())),
                ),
                _buildActionBtn(
                  label: "Offboarding Clearance",
                  icon: Icons.exit_to_app_rounded,
                  color: const Color(0xFFEF4444),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HROffboardingScreen())),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. ATS RECRUITMENT PIPELINE CARD
  // ===========================================================================
  Widget _buildRecruitmentPipelineCard() {
    final rec = _telemetry['recruitment'] ?? {};
    final jobs = rec['open_jobs'] ?? 8;
    final candidates = rec['active_candidates'] ?? 24;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_rounded, color: Color(0xFFEC4899), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Talent Acquisition & Hiring Pipeline",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRRecruitmentScreen())),
                  child: const Text('Manage ATS →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2F8),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFBCFE8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$jobs", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFEC4899))),
                        const Text("Open Job Openings", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$candidates", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                        const Text("Active Candidates", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 7. ANNOUNCEMENTS & BULLETIN
  // ===========================================================================
  Widget _buildAnnouncementsSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.campaign_rounded, color: Color(0xFF06B6D4), size: 20),
                SizedBox(width: 8),
                Text(
                  "Company Announcements & Notices",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_announcements.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "All systems operational. No urgent company-wide bulletins today.",
                        style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _announcements.take(2).length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final a = _announcements[idx];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a['title'] ?? 'Company Notice', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534))),
                        const SizedBox(height: 2),
                        Text(a['content'] ?? '', style: const TextStyle(fontSize: 11.5, color: Color(0xFF15803D)), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
