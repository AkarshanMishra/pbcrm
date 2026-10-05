import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'booking_detail_screen.dart';
import 'operations_issues_screen.dart';
import 'quality_control_screen.dart';
import 'operations_inventory_screen.dart';
import 'operations_daily_report_screen.dart';

class OperationsHomeScreen extends StatefulWidget {
  final VoidCallback? onSwitchToWork;
  final VoidCallback? onSwitchToOperations;
  final VoidCallback? onSwitchToRequests;

  const OperationsHomeScreen({
    super.key,
    this.onSwitchToWork,
    this.onSwitchToOperations,
    this.onSwitchToRequests,
  });

  @override
  State<OperationsHomeScreen> createState() => _OperationsHomeScreenState();
}

class _OperationsHomeScreenState extends State<OperationsHomeScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  bool _isCheckedIn = true;
  String _checkInTime = "09:12 AM";

  Map<String, dynamic> _scorecard = {
    'total_tasks': 8,
    'completed_tasks': 5,
    'urgent_tasks': 2,
    'total_bookings': 4,
    'ready_bookings': 2,
    'open_issues': 3,
  };

  List<dynamic> _todayTimeline = [];
  List<dynamic> _needsAttention = [];

  @override
  void initState() {
    super.initState();
    _loadOperationsData();
  }

  Future<void> _loadOperationsData() async {
    setState(() => _isLoading = true);
    try {
      final statsRes = await _api.get('/api/v1/operations/bookings/dashboard_stats/');
      if (statsRes.statusCode == 200 && statsRes.data != null) {
        final data = statsRes.data;
        _scorecard['total_bookings'] = data['total_bookings'] ?? 4;
        _scorecard['ready_bookings'] = data['ready_for_service'] ?? 2;
        _scorecard['open_issues'] = data['open_issues'] ?? 3;
      }

      final timelineRes = await _api.get('/api/v1/operations/bookings/today_timeline/');
      if (timelineRes.statusCode == 200 && timelineRes.data != null) {
        _todayTimeline = timelineRes.data is List ? timelineRes.data : [];
      }

      final issuesRes = await _api.get('/api/v1/operations/issues/?status=OPEN,ASSIGNED,IN_PROGRESS,ESCALATED');
      if (issuesRes.statusCode == 200 && issuesRes.data != null) {
        final results = issuesRes.data['results'] ?? issuesRes.data;
        if (results is List) {
          _needsAttention = results;
        }
      }
    } catch (e) {
      debugPrint("Operations telemetry load error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleAttendance() {
    setState(() {
      _isCheckedIn = !_isCheckedIn;
      if (_isCheckedIn) {
        _checkInTime = "09:12 AM";
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isCheckedIn ? "Checked In Successfully" : "Checked Out Successfully"),
        backgroundColor: _isCheckedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadOperationsData,
          color: const Color(0xFF10B981),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildHeader(),
                const SizedBox(height: 16),
                _buildAttendanceCard(),
                const SizedBox(height: 16),
                _buildScorecardGrid(),
                const SizedBox(height: 20),
                _buildSectionHeader("TODAY'S OPERATIONS", () => widget.onSwitchToOperations?.call()),
                const SizedBox(height: 10),
                _buildTodayOperationsTimeline(),
                const SizedBox(height: 20),
                _buildSectionHeader("NEEDS ATTENTION", () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsIssuesScreen()));
                }),
                const SizedBox(height: 10),
                _buildNeedsAttentionSection(),
                const SizedBox(height: 20),
                _buildQuickActionsRow(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const <Widget>[
            Text(
              "Good Morning, Rahul 👋",
              style: TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Operations Executive • Field & Venue Hub",
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: const Icon(Icons.notifications_none_rounded, color: Color(0xFFF8FAFC), size: 22),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCheckedIn ? const Color(0xFF10B981).withOpacity(0.4) : const Color(0xFFEF4444).withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _isCheckedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: (_isCheckedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _isCheckedIn ? "CHECKED IN" : "CHECKED OUT",
                    style: TextStyle(
                      color: _isCheckedIn ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _isCheckedIn ? "Since $_checkInTime" : "Currently off-duty",
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _toggleAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCheckedIn ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              _isCheckedIn ? "CHECK OUT" : "CHECK IN",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorecardGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          "MY DAY SCORECARD",
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(child: _buildMetricTile("8 Tasks", "5 Done", const Color(0xFF38BDF8), Icons.task_alt_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricTile("4 Events", "2 Ready", const Color(0xFF10B981), Icons.event_available_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricTile("2 Urgent", "1 Blocker", const Color(0xFFEF4444), Icons.warning_amber_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile(String mainText, String subText, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Icon(icon, color: color, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subText,
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mainText,
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        InkWell(
          onTap: onViewAll,
          child: const Text(
            "View All →",
            style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayOperationsTimeline() {
    if (_todayTimeline.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          children: const <Widget>[
            Icon(Icons.event_note_rounded, color: Color(0xFF64748B), size: 36),
            SizedBox(height: 8),
            Text(
              "No live operations scheduled right now.",
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _todayTimeline.map((item) {
        return _buildTimelineCard(item);
      }).toList(),
    );
  }

  Widget _buildTimelineCard(dynamic booking) {
    final String code = booking['booking_code'] ?? 'PB-XXXX';
    final String partner = booking['partner_name'] ?? 'Venue';
    final String timeSlot = booking['event_time_slot'] ?? '10:00 AM';
    final String status = booking['operations_status'] ?? 'COORDINATION';
    final int readiness = booking['readiness_percentage'] ?? 0;

    Color statusColor = const Color(0xFF10B981);
    if (status == 'ISSUE_REPORTED') statusColor = const Color(0xFFEF4444);
    else if (status == 'COORDINATION') statusColor = const Color(0xFF38BDF8);
    else if (status == 'READINESS_CHECK') statusColor = const Color(0xFFF59E0B);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(bookingId: booking['id'] ?? ''),
          ),
        ).then((_) => _loadOperationsData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF475569)),
              ),
              child: Text(
                timeSlot.split(' - ').first,
                style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        partner,
                        style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: statusColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          status.replaceAll('_', ' '),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$code • ${booking['customer_name'] ?? 'Client'} (${booking['guest_count'] ?? 50} guests)",
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: readiness / 100.0,
                            backgroundColor: const Color(0xFF334155),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              readiness >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$readiness% Ready",
                        style: TextStyle(
                          color: readiness >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedsAttentionSection() {
    if (_needsAttention.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        ),
        child: Row(
          children: const <Widget>[
            Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 12),
            Text(
              "No active blockers or SLA breaches!",
              style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _needsAttention.take(3).map((issue) {
        final String code = issue['issue_code'] ?? 'OP-XXXX';
        final String problem = issue['problem_statement'] ?? 'Operational defect';
        final String prio = issue['priority'] ?? 'HIGH';
        final String category = issue['category'] ?? 'OTHER';

        Color cardColor = const Color(0xFFEF4444);
        if (prio == 'MEDIUM') cardColor = const Color(0xFFF59E0B);
        if (prio == 'LOW') cardColor = const Color(0xFF38BDF8);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardColor.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.error_outline_rounded, color: cardColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          "$code • $category",
                          style: TextStyle(color: cardColor, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            prio,
                            style: TextStyle(color: cardColor, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      problem,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          "QUICK ACTIONS",
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildQuickBtn(
                "QC Audit",
                Icons.verified_rounded,
                const Color(0xFF10B981),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QualityControlScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickBtn(
                "Inventory",
                Icons.inventory_2_rounded,
                const Color(0xFFA78BFA),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsInventoryScreen())),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickBtn(
                "Report",
                Icons.edit_note_rounded,
                const Color(0xFF38BDF8),
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsDailyReportScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: <Widget>[
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
