import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'onboarding_wizard_screen.dart';
import 'hr_attendance_screen.dart';
import 'hr_documents_screen.dart';
import 'hr_requests_screen.dart';
import 'hr_recruitment_screen.dart';
import 'hr_policies_screen.dart';
import 'hr_daily_report_screen.dart';

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
  bool _isLoading = true;
  bool _isCheckedIn = true;
  String _checkInTime = "09:15 AM";

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
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/hr/telemetry/');
      if (res.statusCode == 200 && res.data != null) {
        setState(() {
          _telemetry = res.data;
        });
      }
    } catch (_) {}

    try {
      final resAnnounce = await _api.dio.get('/hr/announcements/');
      if (resAnnounce.statusCode == 200 && resAnnounce.data != null) {
        final list = resAnnounce.data is List ? resAnnounce.data : resAnnounce.data['results'] ?? [];
        setState(() {
          _announcements = list;
        });
      }
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          color: const Color(0xFFEC4899),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildWorkforceOverview(),
                const SizedBox(height: 16),
                _buildTodayAttendanceCard(),
                const SizedBox(height: 16),
                _buildNeedsAttentionSection(),
                const SizedBox(height: 20),
                _buildQuickActionsGrid(),
                const SizedBox(height: 20),
                _buildRecruitmentPipelineCard(),
                const SizedBox(height: 20),
                _buildAnnouncementsSection(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      "Good Morning, HR Team 👋",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "People & Workforce Management",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
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
                      _isCheckedIn ? "CHECKED IN • $_checkInTime" : "CHECKED OUT",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _isCheckedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isCheckedIn = !_isCheckedIn;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isCheckedIn ? "Checked in successfully" : "Checked out successfully"),
                  backgroundColor: _isCheckedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCheckedIn ? const Color(0xFF334155) : const Color(0xFFEC4899),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(
              _isCheckedIn ? "CHECK OUT" : "CHECK IN",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkforceOverview() {
    final wf = _telemetry['workforce'] ?? {};
    final total = wf['total'] ?? 124;
    final active = wf['active'] ?? 118;
    final onLeave = wf['on_leave'] ?? 6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "WORKFORCE OVERVIEW",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricBox(
                count: "$total",
                label: "Employees",
                color: const Color(0xFF3B82F6),
                icon: Icons.people,
                onTap: widget.onNavigateToPeople,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricBox(
                count: "$active",
                label: "Working Today",
                color: const Color(0xFF10B981),
                icon: Icons.badge,
                onTap: widget.onNavigateToPeople,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricBox(
                count: "$onLeave",
                label: "On Leave",
                color: const Color(0xFFF59E0B),
                icon: Icons.beach_access,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HRAttendanceScreen(initialTabIndex: 2)),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricBox({
    required String count,
    required String label,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayAttendanceCard() {
    final att = _telemetry['today_attendance'] ?? {};
    final present = att['present'] ?? 118;
    final total = att['total_scheduled'] ?? 124;
    final lateCount = att['late'] ?? 9;
    final absent = att['absent'] ?? 6;
    final pendingReports = att['pending_reports'] ?? 14;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TODAY'S ATTENDANCE TELEMETRY",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HRAttendanceScreen()),
                  );
                },
                child: const Text(
                  "View Live >",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEC4899),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAttendanceRow("Attendance Rate", "$present / $total", const Color(0xFF10B981)),
          const SizedBox(height: 8),
          _buildAttendanceRow("Late Arrivals", "$lateCount", const Color(0xFFF59E0B)),
          const SizedBox(height: 8),
          _buildAttendanceRow("Absents / Unaccounted", "$absent", const Color(0xFFEF4444)),
          const SizedBox(height: 8),
          _buildAttendanceRow("Pending Daily Reports", "$pendingReports", const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildNeedsAttentionSection() {
    final na = _telemetry['needs_attention'] ?? {};
    final corrections = na['attendance_corrections'] ?? 3;
    final onboarding = na['onboarding_pending'] ?? 5;
    final expiringDocs = na['expiring_docs'] ?? 2;
    final pendingReqs = na['pending_requests'] ?? 4;

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
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
              SizedBox(width: 8),
              Text(
                "NEEDS ATTENTION (EXCEPTIONS)",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAttentionItem(
            color: const Color(0xFFEF4444),
            text: "$corrections Attendance Corrections Pending",
            actionLabel: "Review",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HRAttendanceScreen(initialTabIndex: 1)),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildAttentionItem(
            color: const Color(0xFFF97316),
            text: "$onboarding Onboarding Checklists in Progress",
            actionLabel: "Open",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingWizardScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildAttentionItem(
            color: const Color(0xFFEAB308),
            text: "$expiringDocs Documents Expiring / Missing",
            actionLabel: "Verify",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HRDocumentsScreen()),
              );
            },
          ),
          const SizedBox(height: 8),
          _buildAttentionItem(
            color: const Color(0xFFA855F7),
            text: "$pendingReqs Pending HR Requests",
            actionLabel: "Process",
            onTap: widget.onNavigateToRequests,
          ),
        ],
      ),
    );
  }

  Widget _buildAttentionItem({
    required Color color,
    required String text,
    required String actionLabel,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "QUICK ACTIONS",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildActionIcon(
              icon: Icons.person_add_alt_1,
              label: "+ Employee",
              color: const Color(0xFFEC4899),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingWizardScreen()),
                );
              },
            ),
            _buildActionIcon(
              icon: Icons.event_available,
              label: "Leave Apprv",
              color: const Color(0xFF3B82F6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HRAttendanceScreen(initialTabIndex: 2)),
                );
              },
            ),
            _buildActionIcon(
              icon: Icons.campaign,
              label: "Announce",
              color: const Color(0xFF10B981),
              onTap: _showCreateAnnouncementDialog,
            ),
            _buildActionIcon(
              icon: Icons.assignment_add,
              label: "HR Request",
              color: const Color(0xFF8B5CF6),
              onTap: widget.onNavigateToRequests,
            ),
            _buildActionIcon(
              icon: Icons.work_outline,
              label: "+ Job",
              color: const Color(0xFFF59E0B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HRRecruitmentScreen()),
                );
              },
            ),
            _buildActionIcon(
              icon: Icons.menu_book,
              label: "Policies",
              color: const Color(0xFF06B6D4),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HRPoliciesScreen()),
                );
              },
            ),
            _buildActionIcon(
              icon: Icons.verified_user,
              label: "Verify Docs",
              color: const Color(0xFF14B8A6),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HRDocumentsScreen()),
                );
              },
            ),
            _buildActionIcon(
              icon: Icons.rate_review,
              label: "Daily Report",
              color: const Color(0xFFE11D48),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HRDailyReportScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecruitmentPipelineCard() {
    final rec = _telemetry['recruitment'] ?? {};
    final openJobs = rec['open_jobs'] ?? 8;
    final activeCandidates = rec['active_candidates'] ?? 24;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TALENT ACQUISITION & HIRING",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HRRecruitmentScreen()),
                  );
                },
                child: const Text(
                  "Pipeline >",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEC4899),
                  ),
                ),
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
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Active Openings", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 4),
                      Text("$openJobs Positions", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Candidates in Pipeline", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      const SizedBox(height: 4),
                      Text("$activeCandidates Applicants", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "COMPANY ANNOUNCEMENTS & EVENTS",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 10),
        if (_announcements.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "No current announcements. Tap + to create one.",
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          )
        else
          ..._announcements.take(3).map((ann) => Container(
                margin: const EdgeInsets.only(bottom: 10),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ann['category'] ?? 'GENERAL',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEC4899),
                            ),
                          ),
                        ),
                        if (ann['event_date'] != null)
                          Text(
                            ann['event_date'],
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ann['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ann['content'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFCBD5E1),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  void _showCreateAnnouncementDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String category = 'GENERAL';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text("Post HR Announcement", style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Title",
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF475569))),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Category",
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'GENERAL', child: Text("General Announcement")),
                    DropdownMenuItem(value: 'EVENT', child: Text("Company Event")),
                    DropdownMenuItem(value: 'HOLIDAY', child: Text("Holiday Schedule")),
                    DropdownMenuItem(value: 'MILESTONE', child: Text("Milestone Celebration")),
                  ],
                  onChanged: (val) {
                    if (val != null) setDState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Content Details",
                    labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF475569))),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel", style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.isNotEmpty && contentCtrl.text.isNotEmpty) {
                  try {
                    await _api.dio.post('/hr/announcements/', data: {
                      'title': titleCtrl.text,
                      'category': category,
                      'content': contentCtrl.text,
                    });
                    Navigator.pop(ctx);
                    _fetchDashboardData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Announcement published!"), backgroundColor: Color(0xFF10B981)),
                    );
                  } catch (_) {}
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899)),
              child: const Text("Publish", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
