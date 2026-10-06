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
  final String _checkInTime = "09:28 AM";
  
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
        backgroundColor: _isCheckedIn ? const Color(0xFF10B981) : const Color(0xFF475569),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
          : RefreshIndicator(
              color: const Color(0xFF0284C7),
              onRefresh: _loadTelemetry,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 900;
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(isDesktop),
                        const SizedBox(height: 16),
                        _buildCheckInBanner(),
                        const SizedBox(height: 20),
                        
                        if (isDesktop) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: Column(
                                  children: [
                                    _buildMyDayScorecard(),
                                    const SizedBox(height: 20),
                                    _buildTodayScheduleSection(),
                                    const SizedBox(height: 20),
                                    _buildSystemsHealthCard(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  children: [
                                    _buildNeedsAttentionSection(),
                                    const SizedBox(height: 20),
                                    _buildQuickActionGrid(),
                                    const SizedBox(height: 20),
                                    _buildEngineeringHubShortcuts(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          _buildMyDayScorecard(),
                          const SizedBox(height: 20),
                          _buildNeedsAttentionSection(),
                          const SizedBox(height: 20),
                          _buildTodayScheduleSection(),
                          const SizedBox(height: 20),
                          _buildSystemsHealthCard(),
                          const SizedBox(height: 20),
                          _buildQuickActionGrid(),
                          const SizedBox(height: 20),
                          _buildEngineeringHubShortcuts(),
                        ],
                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
                      "Engineering & DevOps Command Tower ⚡",
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Text(
                    "IT Infrastructure • Sprint Backlog • Incident Response & Releases",
                    style: TextStyle(color: Color(0xFF0284C7), fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDailyReportScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.assessment_rounded, size: 16),
            label: const Text("Daily Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _isCheckedIn ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
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
                  boxShadow: _isCheckedIn ? [const BoxShadow(color: Color(0xFF10B981), blurRadius: 6)] : [],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isCheckedIn ? "Attendance Active • Checked In" : "Currently Checked Out",
                    style: TextStyle(
                      color: _isCheckedIn ? const Color(0xFF065F46) : const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _isCheckedIn ? "$_checkInTime • Office Gateway Connected" : "Shift Inactive",
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _toggleCheckIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCheckedIn ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
              foregroundColor: _isCheckedIn ? const Color(0xFFDC2626) : const Color(0xFF059669),
              side: BorderSide(color: _isCheckedIn ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
            ),
            child: Text(
              _isCheckedIn ? "CLOCK OUT" : "CLOCK IN",
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyDayScorecard() {
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
                Icon(Icons.insights_rounded, color: Color(0xFF0284C7), size: 20),
                SizedBox(width: 8),
                Text(
                  "Today's Engineering Scorecard",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildScoreCard(
                    title: "${_scorecard['total_tasks']} Tasks",
                    subtitle: "${_scorecard['completed_tasks']} Done",
                    icon: Icons.task_alt_rounded,
                    color: const Color(0xFF0284C7),
                    onTap: widget.onSwitchToWork,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildScoreCard(
                    title: "${_scorecard['total_bugs']} Bugs",
                    subtitle: "${_scorecard['fixed_bugs']} Fixed",
                    icon: Icons.bug_report_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: widget.onSwitchToWork,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildScoreCard(
                    title: "${_scorecard['urgent_count']} Urgent",
                    subtitle: "Action Req ⚠",
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFEF4444),
                    onTap: widget.onSwitchToTickets,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedsAttentionSection() {
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
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Critical Attention Items",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Text(
                  "${_needsAttention.length} Items",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._needsAttention.map((item) => _buildAttentionCard(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttentionCard(Map<String, dynamic> item) {
    Color indicatorColor;
    if (item['level'] == 'CRITICAL') {
      indicatorColor = const Color(0xFFEF4444);
    } else if (item['level'] == 'HIGH') {
      indicatorColor = const Color(0xFFF97316);
    } else {
      indicatorColor = const Color(0xFFEAB308);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: indicatorColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: indicatorColor.withValues(alpha: 0.2),
            child: Icon(Icons.bolt_rounded, size: 14, color: indicatorColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? '',
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                const SizedBox(height: 2),
                Text(
                  item['time'] ?? '',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
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
              backgroundColor: indicatorColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
              minimumSize: const Size(56, 26),
            ),
            child: const Text("VIEW", style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayScheduleSection() {
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
                Icon(Icons.schedule_rounded, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 8),
                Text(
                  "Today's Sprint Tasks",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._todaySchedule.map((s) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s['time'] ?? '',
                          style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF0F172A)),
                        ),
                      ),
                      Icon(
                        s['status'] == 'DONE' ? Icons.check_circle_rounded : Icons.pending_rounded,
                        color: s['status'] == 'DONE' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        size: 18,
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemsHealthCard() {
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
                    Icon(Icons.dns_rounded, color: Color(0xFF0284C7), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Systems & Server Telemetry",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: widget.onSwitchToSystems,
                  child: const Text("View All Systems →", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      children: [
                        Text("${_systemsHealth['operational']}", style: const TextStyle(color: Color(0xFF059669), fontSize: 18, fontWeight: FontWeight.w900)),
                        const Text("Operational", style: TextStyle(color: Color(0xFF065F46), fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      children: [
                        Text("${_systemsHealth['warning']}", style: const TextStyle(color: Color(0xFFD97706), fontSize: 18, fontWeight: FontWeight.w900)),
                        const Text("High Load", style: TextStyle(color: Color(0xFF92400E), fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      children: [
                        Text("${_systemsHealth['down']}", style: const TextStyle(color: Color(0xFFDC2626), fontSize: 18, fontWeight: FontWeight.w900)),
                        const Text("Incidents", style: TextStyle(color: Color(0xFF991B1B), fontSize: 11, fontWeight: FontWeight.w600)),
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

  Widget _buildQuickActionGrid() {
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
                Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 20),
                SizedBox(width: 8),
                Text(
                  "IT Fast Actions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _buildActionBtn(
                  label: "Deploy Staging",
                  icon: Icons.rocket_launch_rounded,
                  color: const Color(0xFF0284C7),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDeploymentScreen())),
                ),
                _buildActionBtn(
                  label: "Code Review",
                  icon: Icons.code_rounded,
                  color: const Color(0xFF8B5CF6),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ITDevelopmentScreen())),
                ),
                _buildActionBtn(
                  label: "Security Audit",
                  icon: Icons.shield_rounded,
                  color: const Color(0xFF10B981),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ITSecurityScreen())),
                ),
                _buildActionBtn(
                  label: "IT Assets",
                  icon: Icons.inventory_2_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ITAssetsScreen())),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngineeringHubShortcuts() {
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
                Icon(Icons.hub_rounded, color: Color(0xFF8B5CF6), size: 20),
                SizedBox(width: 8),
                Text(
                  "Engineering Knowledge & Repos",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF3E8FF),
                child: Icon(Icons.menu_book_rounded, color: Color(0xFF9333EA), size: 18),
              ),
              title: const Text("Internal IT Runbooks & API Docs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text("Troubleshooting guides & system architectures", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ITKnowledgeBaseScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
