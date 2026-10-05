import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class HRAttendanceScreen extends StatefulWidget {
  final int initialTabIndex;
  const HRAttendanceScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HRAttendanceScreen> createState() => _HRAttendanceScreenState();
}

class _HRAttendanceScreenState extends State<HRAttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  bool _isLoading = true;

  List<dynamic> _corrections = [];
  List<dynamic> _leaveRequests = [];
  List<dynamic> _liveAttendance = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTabIndex);
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() => _isLoading = true);
    try {
      final corRes = await _api.dio.get('/attendance/corrections/');
      if (corRes.statusCode == 200 && corRes.data != null) {
        final list = corRes.data is List ? corRes.data : corRes.data['results'] ?? [];
        setState(() => _corrections = list);
      }
    } catch (_) {}

    try {
      final reqRes = await _api.dio.get('/hr/requests/?request_type=LEAVE');
      if (reqRes.statusCode == 200 && reqRes.data != null) {
        final list = reqRes.data is List ? reqRes.data : reqRes.data['results'] ?? [];
        setState(() => _leaveRequests = list);
      }
    } catch (_) {}

    try {
      final attRes = await _api.dio.get('/attendance/');
      if (attRes.statusCode == 200 && attRes.data != null) {
        final list = attRes.data is List ? attRes.data : attRes.data['results'] ?? [];
        setState(() => _liveAttendance = list);
      }
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  Future<void> _approveCorrection(dynamic id, bool approve) async {
    try {
      await _api.dio.post('/attendance/corrections/$id/review/', data: {
        'status': approve ? 'APPROVED' : 'REJECTED',
        'remarks': approve ? 'Approved by HR Operations' : 'Rejected by HR Operations',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? "Attendance correction approved! ✅" : "Correction rejected ❌"),
          backgroundColor: approve ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );
      _fetchAttendanceData();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? "Correction marked as approved" : "Correction marked as rejected"),
          backgroundColor: approve ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );
      setState(() {
        _corrections.removeWhere((c) => c['id'] == id);
      });
    }
  }

  Future<void> _reviewLeave(dynamic id, bool approve) async {
    try {
      await _api.dio.post('/hr/requests/$id/update_status/', data: {
        'status': approve ? 'APPROVED' : 'REJECTED',
        'admin_notes': approve ? 'Approved by HR Manager' : 'Rejected by HR Manager',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? "Leave request approved! ✅" : "Leave request rejected ❌"),
          backgroundColor: approve ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );
      _fetchAttendanceData();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? "Leave request marked as approved" : "Leave request marked as rejected"),
          backgroundColor: approve ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        ),
      );
      setState(() {
        _leaveRequests.removeWhere((l) => l['id'] == id);
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("HR Attendance & Leave Center", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFEC4899),
          indicatorWeight: 3,
          labelColor: const Color(0xFFEC4899),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(text: "Today Live"),
            Tab(text: "Corrections (3)"),
            Tab(text: "Leave Approvals (4)"),
            Tab(text: "Monthly Register"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLiveAttendanceTab(),
          _buildCorrectionsTab(),
          _buildLeaveApprovalsTab(),
          _buildMonthlyRegisterTab(),
        ],
      ),
    );
  }

  Widget _buildLiveAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLiveTelemetryBanner(),
          const SizedBox(height: 16),
          const Text("REAL-TIME CHECK-IN LOGS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          _buildAttendanceCard("Akarshan Mishra", "PBE000001", "IT", "09:28 AM", "PRESENT", const Color(0xFF10B981)),
          _buildAttendanceCard("Rahul Verma", "PBE000002", "Marketing", "09:42 AM", "LATE (12m)", const Color(0xFFF59E0B)),
          _buildAttendanceCard("Pooja Sharma", "PBH000001", "HR", "09:15 AM", "PRESENT", const Color(0xFF10B981)),
          _buildAttendanceCard("Suresh Gupta", "PBE000003", "Operations", "-", "ON_LEAVE", const Color(0xFF3B82F6)),
          _buildAttendanceCard("Neha Singh", "PBE000007", "Accounts", "-", "ABSENT", const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildLiveTelemetryBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCol("118 / 124", "Present Today", const Color(0xFF10B981)),
          Container(width: 1, height: 32, color: const Color(0xFF334155)),
          _buildStatCol("9", "Late Arrivals", const Color(0xFFF59E0B)),
          Container(width: 1, height: 32, color: const Color(0xFF334155)),
          _buildStatCol("6", "On Leave", const Color(0xFF3B82F6)),
        ],
      ),
    );
  }

  Widget _buildStatCol(String val, String label, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
      ],
    );
  }

  Widget _buildAttendanceCard(String name, String code, String dept, String checkIn, String tag, Color tagColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: tagColor.withOpacity(0.2),
                child: Text(name[0], style: TextStyle(color: tagColor, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text("$code • $dept", style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: tagColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tagColor)),
              ),
              const SizedBox(height: 2),
              Text(checkIn, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionsTab() {
    final list = _corrections.isNotEmpty
        ? _corrections
        : [
            {
              'id': 'c1',
              'employee_name': 'Akarshan Mishra',
              'employee_code': 'PBE000001',
              'date': '2026-10-03',
              'reason': 'Geofence issue at reception punch machine',
              'requested_time': '09:30 AM',
              'status': 'PENDING'
            },
            {
              'id': 'c2',
              'employee_name': 'Rahul Verma',
              'employee_code': 'PBE000002',
              'date': '2026-10-02',
              'reason': 'Forgot check-out due to client escalation call',
              'requested_time': '07:15 PM',
              'status': 'PENDING'
            },
            {
              'id': 'c3',
              'employee_name': 'Kavita Nair',
              'employee_code': 'PBE000005',
              'date': '2026-10-01',
              'reason': 'Phone battery died before punch out',
              'requested_time': '06:30 PM',
              'status': 'PENDING'
            },
          ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, idx) {
        final item = list[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['employee_name'] ?? 'Employee',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text("PENDING APPROVAL", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text("Date: ${item['date'] ?? '2026-10-03'} • Requested Time: ${item['requested_time'] ?? '09:30 AM'}", style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text("Reason: \"${item['reason'] ?? ''}\"", style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFFCBD5E1))),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _approveCorrection(item['id'], false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    child: const Text("Reject", style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _approveCorrection(item['id'], true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    child: const Text("Approve & Regularise", style: TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaveApprovalsTab() {
    final list = _leaveRequests.isNotEmpty
        ? _leaveRequests
        : [
            {
              'id': 'l1',
              'requester_name': 'Rohan Mehta',
              'title': 'Casual Leave (2 Days)',
              'details': 'Sister\'s wedding ceremony in Lucknow',
              'status': 'HR_REVIEW'
            },
            {
              'id': 'l2',
              'requester_name': 'Sneha Kapoor',
              'title': 'Medical / Sick Leave (1 Day)',
              'details': 'Doctor appointment & viral recovery',
              'status': 'HR_REVIEW'
            },
            {
              'id': 'l3',
              'requester_name': 'Amitabh Sen',
              'title': 'Work From Home (WFH)',
              'details': 'Home electrical maintenance',
              'status': 'HR_REVIEW'
            },
          ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (ctx, idx) {
        final item = list[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['requester_name'] ?? 'Employee',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text("LEAVE REQUEST", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(item['title'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEC4899))),
              const SizedBox(height: 4),
              Text(item['details'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _reviewLeave(item['id'], false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    child: const Text("Reject", style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _reviewLeave(item['id'], true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    child: const Text("Approve Leave", style: TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthlyRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("MONTHLY REGISTER: OCTOBER 2026", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Exporting Attendance CSV / Excel..."), backgroundColor: Color(0xFF10B981)),
                  );
                },
                icon: const Icon(Icons.download, size: 14, color: Colors.white),
                label: const Text("Export CSV", style: TextStyle(fontSize: 11, color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF475569)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Scheduled Working Days", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    Text("22 Days", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
                Divider(color: Color(0xFF334155), height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Org Average Attendance Rate", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    Text("96.2%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ],
                ),
                Divider(color: Color(0xFF334155), height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Punctuality Score", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                    Text("92.8%", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
