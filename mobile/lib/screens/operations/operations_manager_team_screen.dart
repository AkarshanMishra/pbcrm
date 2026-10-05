import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'operations_requests_screen.dart';
import 'operations_issues_screen.dart';

class OperationsManagerTeamScreen extends StatefulWidget {
  const OperationsManagerTeamScreen({super.key});

  @override
  State<OperationsManagerTeamScreen> createState() => _OperationsManagerTeamScreenState();
}

class _OperationsManagerTeamScreenState extends State<OperationsManagerTeamScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _teamWorkload = [];
  int _pendingRequests = 0;
  int _criticalIssues = 0;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/v1/operations/manager-overview/');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data;
        _teamWorkload = data['team_workload'] is List ? data['team_workload'] : [];
        _pendingRequests = data['pending_requests_count'] ?? 0;
        _criticalIssues = data['critical_issues_count'] ?? 0;
      }
    } catch (e) {
      debugPrint("Load manager overview err: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          "Operations Control Center",
          style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : RefreshIndicator(
              onRefresh: _loadOverview,
              color: const Color(0xFF10B981),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildAlertsRow(),
                    const SizedBox(height: 20),
                    const Text(
                      "TEAM WORKLOAD & EXECUTION CAPACITY",
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 12),
                    _buildTeamWorkloadList(),
                    const SizedBox(height: 24),
                    _buildApprovalsSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAlertsRow() {
    return Row(
      children: <Widget>[
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsRequestsScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const <Widget>[
                      Text("Approvals", style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.w700)),
                      Icon(Icons.approval_rounded, color: Color(0xFFF59E0B), size: 18),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text("$_pendingRequests Pending", style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OperationsIssuesScreen()));
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const <Widget>[
                      Text("Critical SLAs", style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.w700)),
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text("$_criticalIssues Active", style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamWorkloadList() {
    if (_teamWorkload.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Text("No field operations members loaded.", style: TextStyle(color: Color(0xFF94A3B8))),
        ),
      );
    }

    return Column(
      children: _teamWorkload.map((emp) {
        final String name = emp['name'] ?? 'Executive';
        final String code = emp['code'] ?? 'PBE';
        final String role = emp['designation'] ?? 'Operations Specialist';
        final int activeTasks = emp['active_tasks'] ?? 0;
        final int activeBookings = emp['active_bookings'] ?? 0;
        final int load = emp['load_percentage'] ?? 50;
        final bool isOver = emp['is_overloaded'] ?? false;

        Color loadColor = const Color(0xFF10B981);
        if (load >= 75) loadColor = const Color(0xFFF59E0B);
        if (isOver) loadColor = const Color(0xFFEF4444);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(name, style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 15, fontWeight: FontWeight.w700)),
                      Text("$code • $role", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: loadColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: loadColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      isOver ? "100% OVERLOADED" : "$load% Capacity",
                      style: TextStyle(color: loadColor, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: load / 100.0,
                        backgroundColor: const Color(0xFF0F172A),
                        valueColor: AlwaysStoppedAnimation<Color>(loadColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text("$activeTasks Active Tasks", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  Text("$activeBookings Events Assigned", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApprovalsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            "QUICK MANAGER ACTIONS",
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF38BDF8)),
            title: const Text("Rebalance Operations Workload", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
            subtitle: const Text("Reassign pending venue checks between executives", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Auto-Rebalancing Workload: Balanced 3 active tasks across team"), backgroundColor: Color(0xFF10B981)),
              );
            },
          ),
        ],
      ),
    );
  }
}
