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
    return Container(
      color: const Color(0xFFF8FAFC),
      child: RefreshIndicator(
        onRefresh: _loadOperationsData,
        color: const Color(0xFFD97706),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(),
              const SizedBox(height: 16),
              _buildAttendanceCard(),
              const SizedBox(height: 16),
              _buildScorecardGrid(),
              const SizedBox(height: 20),
              _buildSectionHeader("TODAY'S OPERATIONS TIMELINE", () => widget.onSwitchToOperations?.call()),
              const SizedBox(height: 10),
              _buildTodayOperationsTimeline(),
              const SizedBox(height: 20),
              _buildSectionHeader("ACTION REQUIRED & INCIDENTS", () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsIssuesScreen()));
              }),
              const SizedBox(height: 10),
              _buildNeedsAttentionSection(),
              const SizedBox(height: 20),
              _buildQuickActionsRow(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      "Operations & Event Execution ⚡",
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Text(
                    "Field Execution • Venue Prep • Logistics & Quality Control",
                    style: TextStyle(color: Color(0xFFB45309), fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsDailyReportScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.assignment_turned_in_rounded, size: 16),
            label: const Text("Daily Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isCheckedIn ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
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
                  color: _isCheckedIn ? const Color(0xFF10B981) : Colors.grey,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    if (_isCheckedIn) const BoxShadow(color: Color(0xFF10B981), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _isCheckedIn ? "ACTIVE ON DUTY" : "CURRENTLY OFF DUTY",
                    style: TextStyle(
                      color: _isCheckedIn ? const Color(0xFF065F46) : const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _isCheckedIn ? "Since $_checkInTime • Venue Assigned" : "Currently not checked in",
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _toggleAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isCheckedIn ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
              foregroundColor: _isCheckedIn ? const Color(0xFFDC2626) : const Color(0xFF059669),
              side: BorderSide(color: _isCheckedIn ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(
              _isCheckedIn ? "CLOCK OUT" : "CLOCK IN",
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScorecardGrid() {
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
          children: <Widget>[
            const Row(
              children: [
                Icon(Icons.dashboard_rounded, color: Color(0xFFD97706), size: 20),
                SizedBox(width: 8),
                Text(
                  "Operations Daily Scorecard",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(child: _buildMetricTile("8 Tasks", "5 Done", const Color(0xFF0284C7), Icons.task_alt_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _buildMetricTile("4 Events", "2 Ready", const Color(0xFF10B981), Icons.event_available_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _buildMetricTile("2 Urgent", "1 Blocker", const Color(0xFFEF4444), Icons.warning_amber_rounded)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String mainText, String subText, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
                  color: color.withValues(alpha: 0.2),
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
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        InkWell(
          onTap: onTap,
          child: const Text(
            "View All →",
            style: TextStyle(color: Color(0xFFD97706), fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayOperationsTimeline() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTimelineItem("11:00 AM", "Banquet Hall Setup & Sound System Test", "Grand Orchid Ballroom", "READY"),
            const Divider(height: 16),
            _buildTimelineItem("02:30 PM", "Catering & Beverage Staging Inspection", "VIP Lounge 2", "IN_PROGRESS"),
            const Divider(height: 16),
            _buildTimelineItem("06:00 PM", "Evening Gala Event Kickoff & Stage Control", "Main Arena", "UPCOMING"),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String time, String title, String venue, String status) {
    Color badgeColor = status == "READY" ? const Color(0xFF10B981) : (status == "IN_PROGRESS" ? const Color(0xFFF59E0B) : const Color(0xFF0284C7));
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(time, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF475569))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
              Text(venue, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(status, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w800)),
        ),
      ],
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildIssueItem("Main Generator Voltage Fluctuation", "Critical", const Color(0xFFEF4444)),
            const SizedBox(height: 8),
            _buildIssueItem("Projector HDMI Cable Replacement in Hall B", "Medium", const Color(0xFFF59E0B)),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueItem(String title, String priority, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF0F172A))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            child: Text(priority, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.inventory_2_rounded, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsInventoryScreen())),
            label: const Text("Equipment & Inventory", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.verified_user_rounded, size: 16),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QualityControlScreen())),
            label: const Text("Quality Audit QC", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}
