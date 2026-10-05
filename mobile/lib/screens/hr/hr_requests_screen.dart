import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class HRRequestsScreen extends StatefulWidget {
  const HRRequestsScreen({super.key});

  @override
  State<HRRequestsScreen> createState() => _HRRequestsScreenState();
}

class _HRRequestsScreenState extends State<HRRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _requests = [];

  final List<String> _tabs = ["All", "Pending HR", "Manager Review", "Approved", "Completed"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/hr/requests/');
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data is List ? res.data : res.data['results'] ?? [];
        setState(() => _requests = list);
      }
    } catch (_) {
      // Demo fallback
      setState(() {
        _requests = [
          {
            'id': 'r1',
            'request_code': 'HRR-0001',
            'request_type': 'ATTENDANCE_CORRECTION',
            'requester_name': 'Akarshan Mishra',
            'title': 'Forgot Geofence Check-in on 3rd Oct',
            'details': 'Phone battery died at client location. Arrived 09:30 AM.',
            'status': 'SUBMITTED'
          },
          {
            'id': 'r2',
            'request_code': 'HRR-0002',
            'request_type': 'LEAVE',
            'requester_name': 'Rahul Verma',
            'title': 'Family Emergency Leave (2 Days)',
            'details': 'Need casual leave for 8th and 9th Oct.',
            'status': 'HR_REVIEW'
          },
          {
            'id': 'r3',
            'request_code': 'HRR-0003',
            'request_type': 'EMPLOYMENT_LETTER',
            'requester_name': 'Pooja Sharma',
            'title': 'Bank Home Loan Verification Letter',
            'details': 'Applying for home loan, need stamped verification letter.',
            'status': 'APPROVED'
          },
          {
            'id': 'r4',
            'request_code': 'HRR-0004',
            'request_type': 'ASSET_REQUEST',
            'requester_name': 'Vikram Rathore',
            'title': 'Secondary Monitor Request for Dev Work',
            'details': 'Require 27-inch 4K monitor for multi-screen debugging.',
            'status': 'COMPLETED'
          },
          {
            'id': 'r5',
            'request_code': 'HRR-0005',
            'request_type': 'DOC_UPDATE',
            'requester_name': 'Sneha Kapoor',
            'title': 'Updated Aadhaar with Married Name',
            'details': 'Attached updated Aadhaar card copy for records.',
            'status': 'SUBMITTED'
          },
        ];
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _updateRequestStatus(dynamic id, String newStatus) async {
    try {
      await _api.dio.post('/hr/requests/$id/update_status/', data: {
        'status': newStatus,
        'admin_notes': 'Processed by HR Operations',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request status updated to $newStatus"), backgroundColor: const Color(0xFF10B981)),
      );
      _fetchRequests();
    } catch (_) {
      setState(() {
        for (var r in _requests) {
          if (r['id'] == id) r['status'] = newStatus;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request marked as $newStatus"), backgroundColor: const Color(0xFF10B981)),
      );
    }
  }

  List<dynamic> _getFilteredRequests() {
    final currentTab = _tabs[_tabController.index];
    if (currentTab == "Pending HR") {
      return _requests.where((r) => r['status'] == 'SUBMITTED' || r['status'] == 'HR_REVIEW').toList();
    }
    if (currentTab == "Manager Review") {
      return _requests.where((r) => r['status'] == 'MANAGER_REVIEW').toList();
    }
    if (currentTab == "Approved") {
      return _requests.where((r) => r['status'] == 'APPROVED').toList();
    }
    if (currentTab == "Completed") {
      return _requests.where((r) => r['status'] == 'COMPLETED').toList();
    }
    return _requests;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredRequests();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("HR Requests Hub", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task, color: Color(0xFFEC4899)),
            onPressed: _showCreateRequestModal,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFEC4899),
          indicatorWeight: 3,
          labelColor: const Color(0xFFEC4899),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)))
          : filtered.isEmpty
              ? const Center(child: Text("No requests in this category", style: TextStyle(color: Color(0xFF94A3B8))))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) => _buildRequestCard(filtered[idx]),
                ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final code = req['request_code'] ?? 'HRR-0000';
    final type = req['request_type'] ?? 'GENERAL';
    final name = req['requester_name'] ?? 'Employee';
    final title = req['title'] ?? 'Request Title';
    final details = req['details'] ?? '';
    final status = req['status'] ?? 'SUBMITTED';

    Color statusColor = const Color(0xFF3B82F6);
    if (status == 'SUBMITTED') statusColor = const Color(0xFFEC4899);
    if (status == 'HR_REVIEW') statusColor = const Color(0xFFF97316);
    if (status == 'MANAGER_REVIEW') statusColor = const Color(0xFFF59E0B);
    if (status == 'APPROVED') statusColor = const Color(0xFF10B981);
    if (status == 'COMPLETED') statusColor = const Color(0xFF6366F1);
    if (status == 'REJECTED') statusColor = const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(code, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 2),
          Text("By $name • Category: $type", style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 8),
          Text(details, style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
          const SizedBox(height: 12),
          if (status == 'SUBMITTED' || status == 'HR_REVIEW')
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _updateRequestStatus(req['id'], 'REJECTED'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text("Reject", style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _updateRequestStatus(req['id'], 'MANAGER_REVIEW'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF59E0B),
                    side: const BorderSide(color: Color(0xFFF59E0B)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text("Send to Manager", style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _updateRequestStatus(req['id'], 'APPROVED'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text("Approve", style: TextStyle(fontSize: 11, color: Colors.white)),
                ),
              ],
            )
          else if (status == 'APPROVED')
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _updateRequestStatus(req['id'], 'COMPLETED'),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text("Mark Completed / Fulfilled", style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showCreateRequestModal() {
    final titleCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    String reqType = 'ATTENDANCE_CORRECTION';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Raise New HR Request", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: reqType,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Request Category",
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'ATTENDANCE_CORRECTION', child: Text("Attendance Correction")),
                  DropdownMenuItem(value: 'LEAVE', child: Text("Leave Request")),
                  DropdownMenuItem(value: 'DOC_UPDATE', child: Text("Document / ID Update")),
                  DropdownMenuItem(value: 'ADDRESS_UPDATE', child: Text("Address / Contact Update")),
                  DropdownMenuItem(value: 'BANK_UPDATE', child: Text("Bank Details Update")),
                  DropdownMenuItem(value: 'EMPLOYMENT_LETTER', child: Text("Employment Verification Letter")),
                  DropdownMenuItem(value: 'SALARY_QUERY', child: Text("Salary / Compensation Query")),
                  DropdownMenuItem(value: 'ASSET_REQUEST', child: Text("Device / ID Badge Re-issue")),
                  DropdownMenuItem(value: 'GRIEVANCE', child: Text("Confidential Grievance")),
                ],
                onChanged: (val) {
                  if (val != null) setMState(() => reqType = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Title / Summary",
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Detailed Explanation",
                  labelStyle: TextStyle(color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.isNotEmpty && detailsCtrl.text.isNotEmpty) {
                      try {
                        await _api.dio.post('/hr/requests/', data: {
                          'request_type': reqType,
                          'title': titleCtrl.text,
                          'details': detailsCtrl.text,
                        });
                        Navigator.pop(ctx);
                        _fetchRequests();
                      } catch (_) {
                        Navigator.pop(ctx);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEC4899), padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text("Submit HR Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
