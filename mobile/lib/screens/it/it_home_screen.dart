import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'it_work_screen.dart';
import 'it_tickets_screen.dart';
import 'it_systems_screen.dart';
import 'it_deployment_screen.dart';
import 'it_development_screen.dart';
import 'it_security_screen.dart';
import 'it_assets_screen.dart';
import 'it_knowledge_base_screen.dart';
import 'it_daily_report_screen.dart';

class ITHomeScreen extends StatefulWidget {
  final VoidCallback? onSwitchToTickets;
  final VoidCallback? onSwitchToSystems;
  final VoidCallback? onSwitchToWork;

  const ITHomeScreen({
    super.key,
    this.onSwitchToTickets,
    this.onSwitchToSystems,
    this.onSwitchToWork,
  });

  @override
  State<ITHomeScreen> createState() => _ITHomeScreenState();
}

class _ITHomeScreenState extends State<ITHomeScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  bool _isCheckedIn = true;
  String _checkInTime = "09:28 AM";
  
  Map<String, dynamic> _scorecard = {
    'total_tasks': 6,
    'completed_tasks': 3,
    'total_bugs': 2,
    'fixed_bugs': 1,
    'urgent_count': 1,
    'open_incidents': 3,
    'critical_incidents': 1,
    'pending_code_reviews': 2,
    'today_deployments': 1,
  };

  Map<String, dynamic> _systemsHealth = {
    'total': 6,
    'operational': 4,
    'warning': 1,
    'down': 1,
  };

  List<dynamic> _needsAttention = [];
  List<dynamic> _todaySchedule = [];

  @override
  void initState() {
    super.initState();
    _loadTelemetry();
  }

  Future<void> _loadTelemetry() async {
    try {
      final res = await _api.get('/api/v1/it/telemetry/');
      if (res.statusCode == 200 && res.data != null) {
        if (mounted) {
          setState(() {
            _scorecard = res.data['scorecard'] ?? _scorecard;
            _systemsHealth = res.data['systems'] ?? _systemsHealth;
            _needsAttention = res.data['needs_attention'] ?? [];
            _todaySchedule = res.data['today_work_schedule'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _needsAttention = [
            {
              'level': 'CRITICAL',
              'title': 'Production Payment API 502 High Latency',
              'type': 'INCIDENT',
              'time': '10 mins ago'
            },
            {
              'level': 'HIGH',
              'title': 'PR #248 (Payment Gateway Fix) awaiting code review',
              'type': 'CODE_REVIEW',
              'time': '1 hour ago'
            },
            {
              'level': 'WARNING',
              'title': 'SSL Wildcard Certificate expires in 12 days (*.partybala.com)',
              'type': 'SECURITY_CERT',
              'time': 'Exp: 16 Oct 2026'
            }
          ];
          _todaySchedule = [
            {'time': '09:30 AM', 'title': 'Fix Payment Webhook Timeout API', 'type': 'DEVELOPMENT', 'status': 'DONE'},
            {'time': '11:00 AM', 'title': 'Code Review: Auth MFA Token Validation', 'type': 'CODE_REVIEW', 'status': 'IN_PROGRESS'},
            {'time': '01:30 PM', 'title': 'Deploy Staging Candidate v2.8.4', 'type': 'DEPLOYMENT', 'status': 'TODO'},
            {'time': '04:00 PM', 'title': 'PostgreSQL Backup Consistency Verification', 'type': 'DATABASE', 'status': 'TODO'}
          ];
        });
      }
    }
  }

  void _toggleCheckIn() {
    setState(() {
      _isCheckedIn = !_isCheckedIn;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isCheckedIn ? "Checked in at 09:28 AM" : "Successfully Checked Out for Today!"),
        backgroundColor: _isCheckedIn ? Colors.green.shade700 : Colors.blueGrey.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
            : RefreshIndicator(
                color: const Color(0xFF38BDF8),
                onRefresh: _loadTelemetry,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildCheckInBanner(),
                    const SizedBox(height: 20),
                    _buildMyDayScorecard(),
                    const SizedBox(height: 24),
                    _buildNeedsAttentionSection(),
                    const SizedBox(height: 24),
                    _buildTodayScheduleSection(),
                    const SizedBox(height: 24),
                    _buildQuickActionGrid(),
                    const SizedBox(height: 24),
                    _buildEngineeringHubShortcuts(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Good Morning, Akarshan 👋",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                  ),
                  child: const Text(
                    "Software Developer (IT & Core Platform)",
                    style: TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDailyReportScreen()));
          },
          icon: const Icon(Icons.assessment_rounded, color: Colors.amberAccent, size: 28),
          tooltip: "Submit Daily IT Report",
        ),
      ],
    );
  }

  Widget _buildCheckInBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _isCheckedIn ? const Color(0xFF10B981).withOpacity(0.4) : const Color(0xFF64748B).withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isCheckedIn ? const Color(0xFF10B981) : Colors.grey,
                  boxShadow: _isCheckedIn ? [const BoxShadow(color: Color(0xFF10B981), blurRadius: 8)] : [],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCheckedIn ? "Checked In" : "Checked Out",
                    style: TextStyle(
                      color: _isCheckedIn ? const Color(0xFF10B981) : Colors.grey,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    _isCheckedIn ? "$_checkInTime • Office VPN Active" : "Shift Inactive",
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _toggleCheckIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCheckedIn ? const Color(0xFFEF4444).withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.2),
              foregroundColor: _isCheckedIn ? const Color(0xFFF87171) : const Color(0xFF34D399),
              side: BorderSide(color: _isCheckedIn ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
              shape: RoundedRectangleAppBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
            ),
            child: Text(
              _isCheckedIn ? "CHECK OUT" : "CHECK IN",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyDayScorecard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "MY DAY",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildScoreCard(
                title: "${_scorecard['total_tasks']} Tasks",
                subtitle: "${_scorecard['completed_tasks']} ✓ Done",
                icon: Icons.task_alt_rounded,
                color: const Color(0xFF38BDF8),
                onTap: widget.onSwitchToWork,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildScoreCard(
                title: "${_scorecard['total_bugs']} Bugs",
                subtitle: "${_scorecard['fixed_bugs']} ✓ Fixed",
                icon: Icons.bug_report_rounded,
                color: const Color(0xFFFB923C),
                onTap: widget.onSwitchToWork,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildScoreCard(
                title: "${_scorecard['urgent_count']} Urgent",
                subtitle: "Action Req ⚠",
                icon: Icons.warning_amber_rounded,
                color: const Color(0xFFF87171),
                onTap: widget.onSwitchToTickets,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedsAttentionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "NEEDS ATTENTION",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.1),
            ),
            Text(
              "${_needsAttention.length} Items",
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._needsAttention.map((item) => _buildAttentionCard(item)),
      ],
    );
  }

  Widget _buildAttentionCard(Map<String, dynamic> item) {
    Color indicatorColor;
    String prefix;
    if (item['level'] == 'CRITICAL') {
      indicatorColor = const Color(0xFFEF4444);
      prefix = "🔴";
    } else if (item['level'] == 'HIGH') {
      indicatorColor = const Color(0xFFF97316);
      prefix = "🟠";
    } else {
      indicatorColor = const Color(0xFFEAB308);
      prefix = "🟡";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(prefix, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? '',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  item['time'] ?? '',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (item['type'] == 'INCIDENT') {
                if (widget.onSwitchToTickets != null) widget.onSwitchToTickets!();
              } else if (item['type'] == 'CODE_REVIEW') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDevelopmentScreen()));
              } else {
                if (widget.onSwitchToSystems != null) widget.onSwitchToSystems!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: indicatorColor.withOpacity(0.2),
              foregroundColor: indicatorColor,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
              minimumSize: const Size(60, 28),
            ),
            child: const Text("VIEW", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "TODAY'S WORK",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            children: _todaySchedule.map((task) => _buildScheduleRow(task)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(Map<String, dynamic> task) {
    bool isDone = task['status'] == 'DONE';
    bool isInProg = task['status'] == 'IN_PROGRESS';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Text(
              task['time'] ?? '',
              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task['title'] ?? '',
              style: TextStyle(
                color: isDone ? const Color(0xFF94A3B8) : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (isDone)
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18)
          else if (isInProg)
            const Icon(Icons.sync_rounded, color: Color(0xFF38BDF8), size: 18)
          else
            const Icon(Icons.radio_button_unchecked_rounded, color: Color(0xFF64748B), size: 18),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "QUICK ACTIONS",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildActionChip(
              label: "+ Task",
              icon: Icons.add_task_rounded,
              color: const Color(0xFF38BDF8),
              onTap: () {
                if (widget.onSwitchToWork != null) widget.onSwitchToWork!();
              },
            ),
            _buildActionChip(
              label: "+ Ticket",
              icon: Icons.confirmation_number_outlined,
              color: const Color(0xFFFB923C),
              onTap: () {
                if (widget.onSwitchToTickets != null) widget.onSwitchToTickets!();
              },
            ),
            _buildActionChip(
              label: "Deploy",
              icon: Icons.rocket_launch_rounded,
              color: const Color(0xFFA78BFA),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDeploymentScreen()));
              },
            ),
            _buildActionChip(
              label: "Report Outage",
              icon: Icons.error_outline_rounded,
              color: const Color(0xFFF87171),
              onTap: () {
                if (widget.onSwitchToSystems != null) widget.onSwitchToSystems!();
              },
            ),
            _buildActionChip(
              label: "Knowledge Base",
              icon: Icons.menu_book_rounded,
              color: const Color(0xFF34D399),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ITKnowledgeBaseScreen()));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionChip({
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
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineeringHubShortcuts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ENGINEERING OPERATIONS",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                title: "Code Reviews & PRs",
                subtitle: "${_scorecard['pending_code_reviews']} Pending Review",
                icon: Icons.code_rounded,
                color: const Color(0xFF60A5FA),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDevelopmentScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFeatureCard(
                title: "Security & Audits",
                subtitle: "SSL Expiry Alert",
                icon: Icons.security_rounded,
                color: const Color(0xFFF43F5E),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ITSecurityScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                title: "Hardware Assets",
                subtitle: "Dell Latitude Assigned",
                icon: Icons.laptop_chromebook_rounded,
                color: const Color(0xFFFBBF24),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ITAssetsScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFeatureCard(
                title: "Daily IT Report",
                subtitle: "Auto Aggregated",
                icon: Icons.edit_note_rounded,
                color: const Color(0xFF10B981),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDailyReportScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class RoundedRectangleAppBorder extends RoundedRectangleBorder {
  const RoundedRectangleAppBorder({super.borderRadius});
}
