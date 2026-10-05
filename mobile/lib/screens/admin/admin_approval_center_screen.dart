import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminApprovalCenterScreen extends StatefulWidget {
  const AdminApprovalCenterScreen({super.key});

  @override
  State<AdminApprovalCenterScreen> createState() => _AdminApprovalCenterScreenState();
}

class _AdminApprovalCenterScreenState extends State<AdminApprovalCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  bool _isLoading = true;

  List<dynamic> _attendanceCorrections = [];
  List<dynamic> _submittedWorkReports = [];
  List<Map<String, dynamic>> _crossDeptApprovals = [
    {
      'id': 'cd-1',
      'category': 'Access Requests',
      'requester': 'Akarshan Mishra',
      'code': 'PBE000001',
      'dept': 'IT',
      'title': 'Production DB Read Replica Access',
      'details': 'Required for query optimization and performance debugging.',
      'priority': 'HIGH',
      'status': 'PENDING',
      'date': 'Today'
    },
    {
      'id': 'cd-2',
      'category': 'Partner Approvals',
      'requester': 'Amitabh Sen',
      'code': 'PBE000006',
      'dept': 'Marketing',
      'title': 'Grand Heritage Banquet SLA Approval',
      'details': 'New partner banquet onboarding. Commission agreement 12%.',
      'priority': 'HIGH',
      'status': 'PENDING',
      'date': 'Yesterday'
    },
    {
      'id': 'cd-3',
      'category': 'Deployment Requests',
      'requester': 'Vikram Rathore',
      'code': 'PBE000008',
      'dept': 'IT',
      'title': 'Release Build v2.4 to Staging Cluster',
      'details': 'Contains Operations tracking fixes and HR document center enhancements.',
      'priority': 'CRITICAL',
      'status': 'PENDING',
      'date': 'Today'
    },
    {
      'id': 'cd-4',
      'category': 'Expense Reimbursement',
      'requester': 'Kavita Nair',
      'code': 'PBE000005',
      'dept': 'Operations',
      'title': 'Venue Inspection Fuel & Toll Reimbursement',
      'details': 'Claim amount: ₹ 4,250 for 6 site visits across Kanpur and Unnao.',
      'priority': 'LOW',
      'status': 'PENDING',
      'date': '02 Oct 2026'
    },
    {
      'id': 'cd-5',
      'category': 'Employee Transfers',
      'requester': 'Ananya Sharma',
      'code': 'PBH000001',
      'dept': 'HR',
      'title': 'Transfer Deepak Joshi from Support to IT QA',
      'details': 'Candidate successfully completed QA training and internal assessment.',
      'priority': 'MEDIUM',
      'status': 'PENDING',
      'date': '30 Sep 2026'
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchLiveApprovals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveApprovals() async {
    setState(() => _isLoading = true);
    try {
      final corRes = await _api.dio.get('/attendance/corrections/');
      final repRes = await _api.dio.get('/work/daily-reports/');

      final allCorr = (corRes.data['results'] ?? corRes.data ?? []) as List<dynamic>;
      final allRep = (repRes.data['results'] ?? repRes.data ?? []) as List<dynamic>;

      setState(() {
        _attendanceCorrections = allCorr.where((c) => c['status'] == 'PENDING').toList();
        _submittedWorkReports = allRep.where((r) => r['status'] == 'SUBMITTED').toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _reviewAttendanceCorrection(String id, bool approve) async {
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Approve Attendance Correction' : 'Reject Correction'),
        content: TextField(
          controller: commentCtrl,
          decoration: const InputDecoration(labelText: 'Review Notes / Justification', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: approve ? Colors.green : Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await _api.dio.post('/attendance/corrections/$id/review/', data: {
                  'status': approve ? 'APPROVED' : 'REJECTED',
                  'review_notes': commentCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                _fetchLiveApprovals();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(approve ? '✓ Correction request approved & attendance adjusted.' : '✕ Correction request rejected.'),
                    backgroundColor: approve ? AppTheme.success : AppTheme.error,
                  ),
                );
              } catch (_) {}
            },
            child: Text(approve ? 'Confirm Approve' : 'Confirm Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _reviewWorkReport(dynamic report, bool approve) async {
    final reportId = report['id'];
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(approve ? 'Approve Work Report' : 'Reject / Request Rework'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employee: ${report['employee_name'] ?? 'Employee'} (${report['report_date'] ?? ''})'),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(labelText: 'Manager / Admin Remarks', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: approve ? Colors.green : Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await _api.dio.patch('/work/daily-reports/$reportId/', data: {
                  'status': approve ? 'REVIEWED' : 'REJECTED',
                  'review_remarks': commentCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                _fetchLiveApprovals();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(approve ? '✓ Work report reviewed and approved!' : '✕ Work report rejected.'),
                    backgroundColor: approve ? AppTheme.success : AppTheme.error,
                  ),
                );
              } catch (_) {}
            },
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  void _handleCrossDeptAction(String id, bool approve) {
    setState(() {
      _crossDeptApprovals.removeWhere((item) => item['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approve ? '✓ Request approved by Super Admin!' : '✕ Request rejected.'),
        backgroundColor: approve ? AppTheme.success : AppTheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPending = _attendanceCorrections.length + _submittedWorkReports.length + _crossDeptApprovals.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Approvals Hub'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppTheme.primary,
          tabs: [
            Tab(icon: const Icon(Icons.all_inbox), text: "All Pending ($totalPending)"),
            Tab(icon: const Icon(Icons.alarm_on), text: "Attendance Corrections (${_attendanceCorrections.length})"),
            Tab(icon: const Icon(Icons.rate_review), text: "Work Reports (${_submittedWorkReports.length})"),
            Tab(icon: const Icon(Icons.hub), text: "Cross-Dept Requests (${_crossDeptApprovals.length})"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchLiveApprovals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllPendingTab(),
                _buildAttendanceTab(),
                _buildWorkReportsTab(),
                _buildCrossDeptTab(),
              ],
            ),
    );
  }

  Widget _buildAllPendingTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCol('Corrections', '${_attendanceCorrections.length}', Colors.orange),
                _buildMetricCol('Work Reports', '${_submittedWorkReports.length}', Colors.blue),
                _buildMetricCol('Cross-Dept', '${_crossDeptApprovals.length}', Colors.purple),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Items Awaiting Super Admin Decision', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),

        // List Attendance Corrections
        ..._attendanceCorrections.map((c) => _buildCorrectionCard(c)),

        // List Work Reports
        ..._submittedWorkReports.map((r) => _buildWorkReportCard(r)),

        // List Cross Dept
        ..._crossDeptApprovals.map((cd) => _buildCrossDeptCard(cd)),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    if (_attendanceCorrections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 12),
            const Text('No pending attendance correction requests!', style: TextStyle(fontSize: 15, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: _attendanceCorrections.map((c) => _buildCorrectionCard(c)).toList(),
    );
  }

  Widget _buildWorkReportsTab() {
    if (_submittedWorkReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 12),
            const Text('All daily work reports have been reviewed!', style: TextStyle(fontSize: 15, color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: _submittedWorkReports.map((r) => _buildWorkReportCard(r)).toList(),
    );
  }

  Widget _buildCrossDeptTab() {
    if (_crossDeptApprovals.isEmpty) {
      return const Center(child: Text('No pending cross-department requests.'));
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: _crossDeptApprovals.map((cd) => _buildCrossDeptCard(cd)).toList(),
    );
  }

  Widget _buildCorrectionCard(dynamic c) {
    final id = c['id'].toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(c['employee_name'] ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                  child: const Text('ATTENDANCE PUNCH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Date: ${c['requested_date'] ?? ''} • Type: ${c['correction_type'] ?? 'Punch'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text('Reason: ${c['reason'] ?? 'No reason provided'}', style: const TextStyle(fontSize: 13)),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _reviewAttendanceCorrection(id, false),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () => _reviewAttendanceCorrection(id, true),
                  child: const Text('Approve & Punch'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkReportCard(dynamic report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(report['employee_name'] ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                  child: const Text('DAILY WORK REPORT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Date: ${report['report_date'] ?? ''} • Dept: ${report['department_name'] ?? 'General'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            const SizedBox(height: 6),
            Text('Summary: ${report['summary_text'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if ((report['completed_summary'] ?? '').isNotEmpty)
              Text('Completed: ${report['completed_summary']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _reviewWorkReport(report, false),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () => _reviewWorkReport(report, true),
                  child: const Text('Approve Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrossDeptCard(Map<String, dynamic> cd) {
    final priority = cd['priority'] ?? 'MEDIUM';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${cd['requester']} (${cd['dept']})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priority == 'CRITICAL' ? Colors.red.shade50 : Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    cd['category'],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: priority == 'CRITICAL' ? Colors.red : Colors.indigo,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(cd['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Text(cd['details'], style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => _handleCrossDeptAction(cd['id'], false),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () => _handleCrossDeptAction(cd['id'], true),
                  child: const Text('Approve Request'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }
}
