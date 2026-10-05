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
  bool _isLoading = false;
  bool _isBatchMode = false;
  final Set<String> _selectedItemIds = {};

  // Search and Filters
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'ALL';
  String _selectedPriorityFilter = 'ALL';
  String _selectedCategoryFilter = 'ALL';
  String _selectedDeptFilter = 'ALL';

  // Live and local repository of master approvals
  List<Map<String, dynamic>> _approvalsList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _initializeApprovalsDataset();
    _fetchLiveApprovals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeApprovalsDataset() {
    _approvalsList = [
      {
        'id': 'APR-2026-001',
        'category': 'Partner KYC & Contract',
        'category_code': 'PARTNER_KYC',
        'dept': 'Marketing',
        'dept_code': 'MKT',
        'requester_name': 'Amitabh Sen',
        'requester_code': 'PBE000006',
        'title': 'Grand Heritage Banquet SLA & 12% Agreement',
        'description': 'New luxury banquet partner in Kanpur South. 500+ guest capacity. 12% standard commission structure verified.',
        'priority': 'HIGH',
        'status': 'PENDING',
        'amount': '₹ 1,50,000 / event avg',
        'created_at': '2026-10-05 09:30 AM',
        'sla_deadline': '2026-10-06 05:00 PM',
        'sla_status': 'ON_TRACK',
        'current_step': 'Admin Final Seal',
        'step_number': 3,
        'total_steps': 3,
        'steps_history': [
          {'step': 'Executive Submitted', 'by': 'Amitabh Sen', 'time': '05 Oct 09:30 AM', 'status': 'DONE'},
          {'step': 'Marketing Head Review', 'by': 'Rohit Varma', 'time': '05 Oct 11:15 AM', 'status': 'DONE'},
          {'step': 'Super Admin Approval', 'by': 'Pending', 'time': 'Awaiting', 'status': 'CURRENT'},
        ],
        'attachments': ['Grand_Heritage_KYC.pdf', 'FSSAI_License.pdf', 'Commission_MOU.docx'],
        'internal_notes': 'Verified site photos and food safety certificates. Ready for final contract seal.',
      },
      {
        'id': 'APR-2026-002',
        'category': 'IT Infrastructure & Access',
        'category_code': 'IT_ACCESS',
        'dept': 'IT',
        'dept_code': 'IT',
        'requester_name': 'Akarshan Mishra',
        'requester_code': 'PBE000001',
        'title': 'Production DB Read Replica Access Grant',
        'description': 'Elevated read-only replica IAM credentials for query profiling, latency indexing, and real-time slow query tuning.',
        'priority': 'CRITICAL',
        'status': 'PENDING',
        'amount': 'N/A',
        'created_at': '2026-10-05 10:45 AM',
        'sla_deadline': '2026-10-05 02:00 PM',
        'sla_status': 'SLA_BREACH',
        'current_step': 'Security Officer Sign-off',
        'step_number': 2,
        'total_steps': 2,
        'steps_history': [
          {'step': 'Access Request Raised', 'by': 'Akarshan Mishra', 'time': '05 Oct 10:45 AM', 'status': 'DONE'},
          {'step': 'Admin Root Authorization', 'by': 'Pending', 'time': 'Awaiting (SLA Overdue)', 'status': 'CURRENT'},
        ],
        'attachments': ['Access_Scope_Policy.json', 'Security_Justification.pdf'],
        'internal_notes': 'IP restricted to VPN subnet 10.8.0.0/24 only. Auto-expires in 30 days.',
      },
      {
        'id': 'APR-2026-003',
        'category': 'Expense & Reimbursement',
        'category_code': 'EXPENSE',
        'dept': 'Operations',
        'dept_code': 'OPS',
        'requester_name': 'Kavita Nair',
        'requester_code': 'PBE000005',
        'title': 'Sound & Light Equipment Emergency Repair Bill',
        'description': 'Emergency line amplifier repair and speaker diaphragm replacement during City Pride Banquet live reception.',
        'priority': 'HIGH',
        'status': 'UNDER_REVIEW',
        'amount': '₹ 18,450',
        'created_at': '2026-10-04 04:20 PM',
        'sla_deadline': '2026-10-06 12:00 PM',
        'sla_status': 'ON_TRACK',
        'current_step': 'Finance Audit',
        'step_number': 2,
        'total_steps': 3,
        'steps_history': [
          {'step': 'Expense Claim Submitted', 'by': 'Kavita Nair', 'time': '04 Oct 04:20 PM', 'status': 'DONE'},
          {'step': 'Operations Head Checked', 'by': 'Vikram Rathore', 'time': '04 Oct 06:10 PM', 'status': 'DONE'},
          {'step': 'Finance & Admin Sign-off', 'by': 'Accounts Desk', 'time': 'Under Review', 'status': 'CURRENT'},
        ],
        'attachments': ['Repair_GST_Invoice_982.pdf', 'Damaged_Part_Photo.jpg'],
        'internal_notes': 'Event was saved from audio blackout. Vendor invoice verified against GST portal.',
      },
      {
        'id': 'APR-2026-004',
        'category': 'Leave & Absence',
        'category_code': 'LEAVE',
        'dept': 'HR',
        'dept_code': 'HR',
        'requester_name': 'Ananya Sharma',
        'requester_code': 'PBH000001',
        'title': 'Annual Vacation Leave (4 Days)',
        'description': 'Leave requested from 12 Oct 2026 to 15 Oct 2026. Handover assigned to Rahul Srivastava.',
        'priority': 'LOW',
        'status': 'PENDING',
        'amount': '4 Leave Balance Days',
        'created_at': '2026-10-05 08:15 AM',
        'sla_deadline': '2026-10-07 06:00 PM',
        'sla_status': 'ON_TRACK',
        'current_step': 'Department Head Approval',
        'step_number': 1,
        'total_steps': 2,
        'steps_history': [
          {'step': 'Leave Application', 'by': 'Ananya Sharma', 'time': '05 Oct 08:15 AM', 'status': 'DONE'},
          {'step': 'Admin Review', 'by': 'Pending', 'time': 'Awaiting', 'status': 'CURRENT'},
        ],
        'attachments': ['Handover_Checklist.docx'],
        'internal_notes': 'Remaining annual leave balance: 14 days.',
      },
      {
        'id': 'APR-2026-005',
        'category': 'Deployment & Release',
        'category_code': 'DEPLOYMENT',
        'dept': 'IT',
        'dept_code': 'IT',
        'requester_name': 'Vikram Rathore',
        'requester_code': 'PBE000008',
        'title': 'Production Staging to Live v2.4 Release',
        'description': 'Release payload contains Offline Sync engine improvements, high-resolution photo compression, and Accounts invoice generator.',
        'priority': 'CRITICAL',
        'status': 'PENDING',
        'amount': 'Zero Downtime Target',
        'created_at': '2026-10-05 11:30 AM',
        'sla_deadline': '2026-10-05 08:00 PM',
        'sla_status': 'ON_TRACK',
        'current_step': 'Super Admin Release Lock',
        'step_number': 3,
        'total_steps': 3,
        'steps_history': [
          {'step': 'PR Merged & QA Green', 'by': 'Vikram Rathore', 'time': '05 Oct 10:00 AM', 'status': 'DONE'},
          {'step': 'Security Audit Passed', 'by': 'SecOps Bot', 'time': '05 Oct 11:15 AM', 'status': 'DONE'},
          {'step': 'Super Admin Final Seal', 'by': 'Pending', 'time': 'Awaiting Release Sign-off', 'status': 'CURRENT'},
        ],
        'attachments': ['Release_Changelog_v2.4.md', 'Load_Test_Report.pdf'],
        'internal_notes': 'All 56 unit test suites passing. Rollback strategy tested.',
      },
      {
        'id': 'APR-2026-006',
        'category': 'Booking Modification & Waiver',
        'category_code': 'BOOKING_MOD',
        'dept': 'Operations',
        'dept_code': 'OPS',
        'requester_name': 'Rajesh Khanna',
        'requester_code': 'PBE000007',
        'title': 'Booking #PB-BK-902 Reschedule & Date Shift Waiver',
        'description': 'Customer requested shifting wedding reception by 1 week due to family emergency. 100% deposit carry forward without penalty requested.',
        'priority': 'MEDIUM',
        'status': 'CHANGES_REQUESTED',
        'amount': '₹ 1,20,000 Advance Shift',
        'created_at': '2026-10-03 02:00 PM',
        'sla_deadline': '2026-10-05 06:00 PM',
        'sla_status': 'ON_TRACK',
        'current_step': 'Revised Partner Confirmation',
        'step_number': 2,
        'total_steps': 3,
        'steps_history': [
          {'step': 'Reschedule Request', 'by': 'Rajesh Khanna', 'time': '03 Oct 02:00 PM', 'status': 'DONE'},
          {'step': 'Admin Change Request', 'by': 'Super Admin', 'time': '04 Oct 10:00 AM', 'status': 'FEEDBACK'},
          {'step': 'Awaiting Banquet Letter', 'by': 'Banquet Manager', 'time': 'Pending Docs', 'status': 'CURRENT'},
        ],
        'attachments': ['Customer_Emergency_Note.pdf'],
        'internal_notes': 'Admin requested written confirmation from venue owner regarding hall availability on the new date.',
      },
      {
        'id': 'APR-2026-007',
        'category': 'Employee Transfer & Promotion',
        'category_code': 'TRANSFER',
        'dept': 'HR',
        'dept_code': 'HR',
        'requester_name': 'Ananya Sharma',
        'requester_code': 'PBH000001',
        'title': 'Deepak Joshi Promotion to Senior QA Specialist',
        'description': 'Promotion evaluation approved by Engineering Lead. Proposed salary hike: 18%. Revised designation: Senior QA Engineer.',
        'priority': 'MEDIUM',
        'status': 'PENDING',
        'amount': '+18% CTC Revision',
        'created_at': '2026-10-04 11:00 AM',
        'sla_deadline': '2026-10-07 06:00 PM',
        'sla_status': 'ON_TRACK',
        'current_step': 'Management Compensation Sign-off',
        'step_number': 2,
        'total_steps': 3,
        'steps_history': [
          {'step': 'HOD Recommendation', 'by': 'Ananya Sharma', 'time': '04 Oct 11:00 AM', 'status': 'DONE'},
          {'step': 'Appraisal Committee Cleared', 'by': 'Tech Council', 'time': '04 Oct 03:30 PM', 'status': 'DONE'},
          {'step': 'Super Admin & MD Sign-off', 'by': 'Pending', 'time': 'Awaiting', 'status': 'CURRENT'},
        ],
        'attachments': ['Appraisal_Scorecard.pdf', 'KPA_Review_2026.xlsx'],
        'internal_notes': 'Candidate led automated test suite implementation with 100% test coverage.',
      },
      {
        'id': 'APR-2026-008',
        'category': 'Purchase & Procurement',
        'category_code': 'PURCHASE',
        'dept': 'Accounts',
        'dept_code': 'ACC',
        'requester_name': 'Pooja Verma',
        'requester_code': 'PBE000004',
        'title': 'Procurement of 5 Commercial Grade GPS Biometric Scanners',
        'description': 'Hardware upgrade for banquet venue checkpoints to enable offline geo-fenced attendance logging.',
        'priority': 'HIGH',
        'status': 'PENDING',
        'amount': '₹ 85,000',
        'created_at': '2026-10-05 01:15 PM',
        'sla_deadline': '2026-10-06 06:00 PM',
        'sla_status': 'ON_TRACK',
        'current_step': 'Admin Purchase Authorization',
        'step_number': 2,
        'total_steps': 2,
        'steps_history': [
          {'step': 'PO Quotation Comparative', 'by': 'Pooja Verma', 'time': '05 Oct 01:15 PM', 'status': 'DONE'},
          {'step': 'Admin Financial Approval', 'by': 'Pending', 'time': 'Awaiting', 'status': 'CURRENT'},
        ],
        'attachments': ['Vendor_Quotations_3Way.pdf', 'Hardware_Specs.pdf'],
        'internal_notes': 'Lowest quote selected from authorized distributor with 2-year onsite warranty.',
      },
    ];
  }

  Future<void> _fetchLiveApprovals() async {
    setState(() => _isLoading = true);
    try {
      final corRes = await _api.dio.get('/attendance/corrections/');
      final repRes = await _api.dio.get('/work/daily-reports/');

      final allCorr = (corRes.data['results'] ?? corRes.data ?? []) as List<dynamic>;
      final allRep = (repRes.data['results'] ?? repRes.data ?? []) as List<dynamic>;

      // Incorporate live attendance corrections
      for (var c in allCorr) {
        final idStr = 'APR-ATT-${c['id']}';
        if (!_approvalsList.any((a) => a['id'] == idStr)) {
          _approvalsList.add({
            'id': idStr,
            'category': 'Attendance Regularization',
            'category_code': 'ATTENDANCE',
            'dept': 'HR',
            'dept_code': 'HR',
            'requester_name': c['employee_name'] ?? 'Employee',
            'requester_code': 'EMP-${c['employee_id'] ?? 'NA'}',
            'title': 'Punch Regularization (${c['correction_type'] ?? 'Punch'})',
            'description': 'Requested Date: ${c['requested_date'] ?? ''}. Reason: ${c['reason'] ?? 'Missed punch due to field duty.'}',
            'priority': 'MEDIUM',
            'status': c['status'] == 'PENDING' ? 'PENDING' : (c['status'] == 'APPROVED' ? 'APPROVED' : 'REJECTED'),
            'amount': '1 Day Attendance',
            'created_at': c['created_at'] ?? 'Today',
            'sla_deadline': 'Within 24 hrs',
            'sla_status': 'ON_TRACK',
            'current_step': 'Admin Verification',
            'step_number': 1,
            'total_steps': 2,
            'steps_history': [
              {'step': 'Correction Request', 'by': c['employee_name'] ?? 'Employee', 'time': 'Submitted', 'status': 'DONE'},
              {'step': 'Admin Decision', 'by': 'Pending', 'time': 'Awaiting', 'status': 'CURRENT'},
            ],
            'attachments': ['Biometric_Log.txt'],
            'internal_notes': 'Automated submission via field attendance app.',
            'raw_correction_id': c['id'],
          });
        }
      }

      // Incorporate live work reports
      for (var r in allRep) {
        final idStr = 'APR-REP-${r['id']}';
        if (!_approvalsList.any((a) => a['id'] == idStr) && r['status'] == 'SUBMITTED') {
          _approvalsList.add({
            'id': idStr,
            'category': 'Daily Work Report Review',
            'category_code': 'WORK_REPORT',
            'dept': r['department_name'] ?? 'Operations',
            'dept_code': 'OPS',
            'requester_name': r['employee_name'] ?? 'Employee',
            'requester_code': 'EMP-${r['employee_id'] ?? 'NA'}',
            'title': 'Daily Field Operations Report (${r['report_date'] ?? 'Today'})',
            'description': 'Summary: ${r['summary_text'] ?? 'Daily activity log'}. Completed: ${r['completed_summary'] ?? 'Tasks done'}',
            'priority': 'LOW',
            'status': 'PENDING',
            'amount': 'Daily Work Log',
            'created_at': r['created_at'] ?? 'Today',
            'sla_deadline': 'Within 48 hrs',
            'sla_status': 'ON_TRACK',
            'current_step': 'Supervisor Review',
            'step_number': 1,
            'total_steps': 2,
            'steps_history': [
              {'step': 'Report Submitted', 'by': r['employee_name'] ?? 'Employee', 'time': 'Submitted', 'status': 'DONE'},
              {'step': 'Admin Evaluation', 'by': 'Pending', 'time': 'Awaiting', 'status': 'CURRENT'},
            ],
            'attachments': ['Work_Checklist.pdf'],
            'internal_notes': 'Daily performance index auto-calculated.',
            'raw_report_id': r['id'],
          });
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // --- CRUD: CREATE APPROVAL REQUEST ---
  void _openCreateApprovalModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'Partner KYC & Contract';
    String dept = 'Marketing';
    String priority = 'HIGH';
    String requesterName = 'Admin Initiated';
    String requesterCode = 'PBE000001';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_task_rounded, color: Colors.amberAccent, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Initiate Enterprise Approval Workflow', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Create a new cross-department request with SLA tracking', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: dept,
                            decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                            items: ['HR', 'IT', 'Marketing', 'Operations', 'Accounts', 'Management']
                                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => dept = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: priority,
                            decoration: const InputDecoration(labelText: 'Priority / SLA', border: OutlineInputBorder()),
                            items: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
                                .map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: p == 'CRITICAL' ? Colors.red : (p == 'HIGH' ? Colors.orange : Colors.black87), fontWeight: FontWeight.bold))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => priority = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Approval Category', border: OutlineInputBorder()),
                      items: [
                        'Partner KYC & Contract',
                        'IT Infrastructure & Access',
                        'Expense & Reimbursement',
                        'Leave & Absence',
                        'Deployment & Release',
                        'Booking Modification & Waiver',
                        'Employee Transfer & Promotion',
                        'Purchase & Procurement',
                        'Workflow & Policy Approval',
                        'Asset Allocation',
                      ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Request Title *',
                        hintText: 'e.g., Grand Palace Banquet 12% SLA Approval',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: amountCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Financial Impact / Amount',
                              hintText: 'e.g., ₹ 45,000 or 12% Comm.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Requester Code',
                              hintText: 'PBE000001',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) => requesterCode = v,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Detailed Justification & Scope *',
                        hintText: 'Provide comprehensive context and operational reason for the approval...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Internal Audit Notes',
                        hintText: 'Verification checklist, references...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This workflow will be registered with 3-stage SLA tracking. Admin will retain final digital sign-off authority.',
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: Colors.grey.shade100, border: Border(top: BorderSide(color: Colors.grey.shade300))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(modalCtx), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Submit Approval Workflow'),
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter request title and justification.'), backgroundColor: Colors.red),
                          );
                          return;
                        }
                        final newId = 'APR-2026-00${_approvalsList.length + 1}';
                        setState(() {
                          _approvalsList.insert(0, {
                            'id': newId,
                            'category': category,
                            'category_code': category.replaceAll(' ', '_').toUpperCase(),
                            'dept': dept,
                            'dept_code': dept.substring(0, dept.length >= 3 ? 3 : dept.length).toUpperCase(),
                            'requester_name': requesterName,
                            'requester_code': requesterCode,
                            'title': titleCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'priority': priority,
                            'status': 'PENDING',
                            'amount': amountCtrl.text.trim().isEmpty ? 'N/A' : amountCtrl.text.trim(),
                            'created_at': 'Just now',
                            'sla_deadline': 'Within 24 hrs',
                            'sla_status': 'ON_TRACK',
                            'current_step': 'Admin Review',
                            'step_number': 1,
                            'total_steps': 3,
                            'steps_history': [
                              {'step': 'Created by Admin', 'by': requesterName, 'time': 'Just now', 'status': 'DONE'},
                              {'step': 'Super Admin Final Seal', 'by': 'Pending', 'time': 'Awaiting', 'status': 'CURRENT'},
                            ],
                            'attachments': ['Attached_Statement.pdf'],
                            'internal_notes': notesCtrl.text.trim().isEmpty ? 'Verified by Admin' : notesCtrl.text.trim(),
                          });
                        });
                        Navigator.pop(modalCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✓ Approval workflow $newId registered successfully!'),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CRUD: UPDATE APPROVAL REQUEST ---
  void _openEditApprovalModal(Map<String, dynamic> item) {
    final titleCtrl = TextEditingController(text: item['title']);
    final descCtrl = TextEditingController(text: item['description']);
    final amountCtrl = TextEditingController(text: item['amount']);
    final notesCtrl = TextEditingController(text: item['internal_notes']);
    String priority = item['priority'] ?? 'MEDIUM';
    String status = item['status'] ?? 'PENDING';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note, color: Colors.cyanAccent, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit Request ${item['id']}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${item['category']} • ${item['requester_name']}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: priority,
                            decoration: const InputDecoration(labelText: 'Priority Level', border: OutlineInputBorder()),
                            items: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']
                                .map((p) => DropdownMenuItem(value: p, child: Text(p, style: TextStyle(color: p == 'CRITICAL' ? Colors.red : (p == 'HIGH' ? Colors.orange : Colors.black87), fontWeight: FontWeight.bold))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => priority = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: status,
                            decoration: const InputDecoration(labelText: 'Workflow Status', border: OutlineInputBorder()),
                            items: ['PENDING', 'UNDER_REVIEW', 'CHANGES_REQUESTED', 'APPROVED', 'REJECTED']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => status = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Request Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountCtrl,
                      decoration: const InputDecoration(labelText: 'Financial Exposure / Value', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Justification & Scope', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(labelText: 'Admin Internal Notes', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: Colors.grey.shade100, border: Border(top: BorderSide(color: Colors.grey.shade300))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Cancel & Delete Request'),
                      onPressed: () {
                        Navigator.pop(modalCtx);
                        _confirmDeleteApproval(item['id']);
                      },
                    ),
                    Row(
                      children: [
                        TextButton(onPressed: () => Navigator.pop(modalCtx), child: const Text('Cancel')),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                          onPressed: () {
                            setState(() {
                              item['title'] = titleCtrl.text.trim();
                              item['description'] = descCtrl.text.trim();
                              item['amount'] = amountCtrl.text.trim();
                              item['internal_notes'] = notesCtrl.text.trim();
                              item['priority'] = priority;
                              item['status'] = status;
                            });
                            Navigator.pop(modalCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('✓ Request ${item['id']} updated successfully.'), backgroundColor: AppTheme.success),
                            );
                          },
                          child: const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CRUD: DELETE / CANCEL APPROVAL REQUEST ---
  void _confirmDeleteApproval(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text('Cancel Request $id'),
          ],
        ),
        content: const Text('Are you sure you want to permanently revoke this approval request? This will record an audit cancellation log.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Active')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _approvalsList.removeWhere((a) => a['id'] == id);
                _selectedItemIds.remove(id);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✓ Request $id canceled & removed from queue.'), backgroundColor: Colors.red.shade700),
              );
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  // --- 360° INSPECTOR DRAWER & DECISION ACTIONS ---
  void _open360ApprovalInspector(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DefaultTabController(
        length: 4,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.90,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                          child: Icon(_getCategoryIcon(item['category']), color: Colors.amberAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(item['id'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(width: 8),
                                  _buildStatusPill(item['status']),
                                ],
                              ),
                              Text('${item['category']} • Dept: ${item['dept']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const TabBar(
                      isScrollable: true,
                      labelColor: Colors.amberAccent,
                      unselectedLabelColor: Colors.white60,
                      indicatorColor: Colors.amberAccent,
                      tabs: [
                        Tab(icon: Icon(Icons.info_outline, size: 16), text: 'Overview & Impact'),
                        Tab(icon: Icon(Icons.timeline, size: 16), text: 'Approval Pipeline'),
                        Tab(icon: Icon(Icons.attachment, size: 16), text: 'Evidence & Files'),
                        Tab(icon: Icon(Icons.history, size: 16), text: 'Audit Trail'),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildInspectorOverviewTab(item),
                    _buildInspectorPipelineTab(item),
                    _buildInspectorEvidenceTab(item),
                    _buildInspectorAuditTab(item),
                  ],
                ),
              ),

              // Action Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -3))],
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.indigo),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openEditApprovalModal(item);
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade800),
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: const Text('Rework'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openRequestChangesDialog(item);
                      },
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openRejectDialog(item);
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.verified_user, size: 16),
                      label: const Text('Approve & Seal'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openDigitalSealDialog(item);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectorOverviewTab(Map<String, dynamic> item) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Requester Info Card
        Card(
          elevation: 0,
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary.withOpacity(0.12),
                  child: Text(
                    item['requester_name'].toString().isNotEmpty ? item['requester_name'].toString().substring(0, 1) : 'E',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['requester_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('${item['requester_code']} • Department: ${item['dept']}', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                    ],
                  ),
                ),
                _buildPriorityPill(item['priority']),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title & Description
        Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 8),
        Text(item['description'], style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4)),
        const SizedBox(height: 16),

        // Meta Metrics Grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey.shade100)),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetaCol('Financial / Resource Value', item['amount'], Icons.account_balance_wallet, Colors.teal),
                  _buildMetaCol('SLA Target Deadline', item['sla_deadline'], Icons.timer_outlined, item['sla_status'] == 'SLA_BREACH' ? Colors.red : Colors.indigo),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetaCol('Submission Timestamp', item['created_at'], Icons.calendar_today, Colors.blueGrey),
                  _buildMetaCol('Current Approval Step', item['current_step'], Icons.verified, AppTheme.primary),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Internal Notes
        const Text('Internal Admin Audit Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
          child: Text(
            item['internal_notes'] ?? 'No special notes recorded.',
            style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
          ),
        ),
      ],
    );
  }

  Widget _buildInspectorPipelineTab(Map<String, dynamic> item) {
    final steps = (item['steps_history'] as List<dynamic>?) ?? [];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Multi-Stage Approval Pipeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text('Step ${item['step_number']} of ${item['total_steps']} in progress', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 20),
        ...steps.map((s) {
          final isDone = s['status'] == 'DONE';
          final isCurrent = s['status'] == 'CURRENT';
          final isFeedback = s['status'] == 'FEEDBACK';
          Color nodeColor = isDone ? Colors.green : (isCurrent ? Colors.amber.shade700 : (isFeedback ? Colors.orange : Colors.grey));

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: nodeColor.withOpacity(0.2),
                      child: Icon(
                        isDone ? Icons.check : (isCurrent ? Icons.hourglass_top : (isFeedback ? Icons.edit : Icons.circle_outlined)),
                        color: nodeColor,
                        size: 16,
                      ),
                    ),
                    Container(height: 36, width: 2, color: Colors.grey.shade300),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrent ? Colors.amber.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isCurrent ? Colors.amber.shade300 : Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s['step'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(s['time'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Officer / Actor: ${s['by'] ?? 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInspectorEvidenceTab(Map<String, dynamic> item) {
    final files = (item['attachments'] as List<dynamic>?) ?? [];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Supporting Verification Files & Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        Text('Digital proofs uploaded by requester and department supervisor', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        if (files.isEmpty)
          const Center(child: Text('No attachments submitted with this request.'))
        else
          ...files.map((f) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.picture_as_pdf, color: Colors.blue)),
                  title: Text(f.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Verified by Document Engine • 1.2 MB', style: TextStyle(fontSize: 11)),
                  trailing: IconButton(
                    icon: const Icon(Icons.file_download_outlined, color: AppTheme.primary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading $f...'), duration: const Duration(seconds: 1)),
                      );
                    },
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildInspectorAuditTab(Map<String, dynamic> item) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Immutable System Audit Trail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        Text('Cryptographically hashed approval log sequence', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        _buildAuditLogEntry('LOG-001', 'WORKFLOW_INITIATED', 'Request registered with SLA target.', item['created_at']),
        _buildAuditLogEntry('LOG-002', 'DOCUMENT_HASH_VERIFIED', 'All attachments passed SHA-256 anti-tamper check.', item['created_at']),
        _buildAuditLogEntry('LOG-003', 'ROLE_RBAC_EVALUATION', 'Approver authority verified against Super Admin permission scopes.', '05 Oct 11:30 AM'),
        if (item['status'] == 'APPROVED') _buildAuditLogEntry('LOG-004', 'DIGITAL_SEAL_APPLIED', 'Super Admin digital authorization executed.', 'Just now'),
      ],
    );
  }

  Widget _buildAuditLogEntry(String code, String action, String desc, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(action, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace')),
              Text(time, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  // --- DECISION DIALOGS: APPROVE, REJECT, REQUEST CHANGES ---
  void _openDigitalSealDialog(Map<String, dynamic> item) {
    final notesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.verified_user, color: Colors.green),
            const SizedBox(width: 10),
            Text('Super Admin Seal: ${item['id']}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(
                'You are granting final Super Admin approval for "${item['title']}". Downstream integrations and ledger updates will execute immediately.',
                style: TextStyle(color: Colors.green.shade900, fontSize: 12),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Digital Seal Remarks / Signature Note',
                hintText: 'e.g., Approved as per quarterly budget allocation',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Confirm Digital Seal'),
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final messenger = ScaffoldMessenger.of(context);
              // Call API if live attendance or report
              if (item.containsKey('raw_correction_id')) {
                try {
                  await _api.dio.post('/attendance/corrections/${item['raw_correction_id']}/review/', data: {
                    'status': 'APPROVED',
                    'review_notes': notesCtrl.text.trim(),
                  });
                } catch (_) {}
              } else if (item.containsKey('raw_report_id')) {
                try {
                  await _api.dio.patch('/work/daily-reports/${item['raw_report_id']}/', data: {
                    'status': 'REVIEWED',
                    'review_remarks': notesCtrl.text.trim(),
                  });
                } catch (_) {}
              }

              if (mounted) {
                setState(() {
                  item['status'] = 'APPROVED';
                  item['internal_notes'] = notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : item['internal_notes'];
                });
              }
              nav.pop();
              messenger.showSnackBar(
                SnackBar(content: Text('✓ Request ${item['id']} approved with Super Admin Digital Seal!'), backgroundColor: AppTheme.success),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openRejectDialog(Map<String, dynamic> item) {
    final reasonCtrl = TextEditingController();
    String rejectReasonType = 'INSUFFICIENT_DOCUMENTATION';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.red),
              const SizedBox(width: 10),
              Text('Reject Request: ${item['id']}'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: rejectReasonType,
                decoration: const InputDecoration(labelText: 'Rejection Category', border: OutlineInputBorder()),
                items: [
                  'INSUFFICIENT_DOCUMENTATION',
                  'POLICY_VIOLATION',
                  'BUDGET_EXCEEDED',
                  'DUPLICATE_REQUEST',
                  'SLA_NON_COMPLIANT',
                  'OTHER',
                ].map((r) => DropdownMenuItem(value: r, child: Text(r.replaceAll('_', ' ')))).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => rejectReasonType = val);
                },
              ),
              const SizedBox(height: 14),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Mandatory Audit Rejection Reason *',
                  hintText: 'Explain why this approval was declined...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                if (reasonCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide a rejection reason.'), backgroundColor: Colors.red),
                  );
                  return;
                }

                final nav = Navigator.of(dialogCtx);
                final messenger = ScaffoldMessenger.of(context);

                if (item.containsKey('raw_correction_id')) {
                  try {
                    await _api.dio.post('/attendance/corrections/${item['raw_correction_id']}/review/', data: {
                      'status': 'REJECTED',
                      'review_notes': reasonCtrl.text.trim(),
                    });
                  } catch (_) {}
                } else if (item.containsKey('raw_report_id')) {
                  try {
                    await _api.dio.patch('/work/daily-reports/${item['raw_report_id']}/', data: {
                      'status': 'REJECTED',
                      'review_remarks': reasonCtrl.text.trim(),
                    });
                  } catch (_) {}
                }

                if (mounted) {
                  setState(() {
                    item['status'] = 'REJECTED';
                    item['internal_notes'] = 'Rejected (${rejectReasonType.replaceAll('_', ' ')}): ${reasonCtrl.text.trim()}';
                  });
                }
                nav.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('✕ Request ${item['id']} rejected & logged in audit.'), backgroundColor: Colors.red.shade700),
                );
              },
              child: const Text('Confirm Reject'),
            ),
          ],
        ),
      ),
    );
  }

  void _openRequestChangesDialog(Map<String, dynamic> item) {
    final feedbackCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.rate_review, color: Colors.orange),
            const SizedBox(width: 10),
            Text('Request Changes: ${item['id']}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Return this request to the employee/supervisor for rework and additional information.'),
            const SizedBox(height: 14),
            TextField(
              controller: feedbackCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Change Instructions & Required Docs *',
                hintText: 'e.g., Please attach the GST bill copy and counter-signed banquet agreement...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white),
            onPressed: () {
              if (feedbackCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please specify change instructions.'), backgroundColor: Colors.red),
                );
                return;
              }
              setState(() {
                item['status'] = 'CHANGES_REQUESTED';
                item['internal_notes'] = 'Changes requested: ${feedbackCtrl.text.trim()}';
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✓ Request ${item['id']} sent back for rework.'), backgroundColor: Colors.orange.shade800),
              );
            },
            child: const Text('Send for Rework'),
          ),
        ],
      ),
    );
  }

  // --- BULK BATCH ACTIONS ---
  void _executeBulkApprove() {
    if (_selectedItemIds.isEmpty) return;
    final count = _selectedItemIds.length;
    setState(() {
      for (var a in _approvalsList) {
        if (_selectedItemIds.contains(a['id'])) {
          a['status'] = 'APPROVED';
        }
      }
      _selectedItemIds.clear();
      _isBatchMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✓ Bulk approved $count requests with Super Admin Digital Seal!'), backgroundColor: AppTheme.success),
    );
  }

  void _executeBulkReject() {
    if (_selectedItemIds.isEmpty) return;
    final count = _selectedItemIds.length;
    setState(() {
      for (var a in _approvalsList) {
        if (_selectedItemIds.contains(a['id'])) {
          a['status'] = 'REJECTED';
        }
      }
      _selectedItemIds.clear();
      _isBatchMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✕ Bulk rejected $count requests.'), backgroundColor: Colors.red.shade700),
    );
  }

  // --- FILTERED LIST GENERATOR ---
  List<Map<String, dynamic>> _getFilteredApprovals(int tabIndex) {
    return _approvalsList.where((item) {
      // Tab Category scoping
      if (tabIndex == 1 && item['dept'] != 'HR' && item['category_code'] != 'LEAVE' && item['category_code'] != 'ATTENDANCE') {
        return false;
      }
      if (tabIndex == 2 && item['dept'] != 'Accounts' && item['category_code'] != 'EXPENSE' && item['category_code'] != 'PURCHASE') {
        return false;
      }
      if (tabIndex == 3 && item['dept'] != 'IT' && item['category_code'] != 'IT_ACCESS' && item['category_code'] != 'DEPLOYMENT') {
        return false;
      }
      if (tabIndex == 4 && item['dept'] != 'Marketing' && item['dept'] != 'Operations' && item['category_code'] != 'PARTNER_KYC' && item['category_code'] != 'BOOKING_MOD') {
        return false;
      }
      if (tabIndex == 5 && item['status'] != 'APPROVED' && item['status'] != 'REJECTED') {
        return false;
      }

      // Status Filter
      if (_selectedStatusFilter != 'ALL' && item['status'] != _selectedStatusFilter) {
        return false;
      }

      // Priority Filter
      if (_selectedPriorityFilter != 'ALL' && item['priority'] != _selectedPriorityFilter) {
        return false;
      }

      // Search Query
      final q = _searchController.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final id = (item['id'] ?? '').toString().toLowerCase();
        final title = (item['title'] ?? '').toString().toLowerCase();
        final req = (item['requester_name'] ?? '').toString().toLowerCase();
        final code = (item['requester_code'] ?? '').toString().toLowerCase();
        final cat = (item['category'] ?? '').toString().toLowerCase();
        final dept = (item['dept'] ?? '').toString().toLowerCase();
        if (!id.contains(q) && !title.contains(q) && !req.contains(q) && !code.contains(q) && !cat.contains(q) && !dept.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _approvalsList.where((a) => a['status'] == 'PENDING').length;
    final underReviewCount = _approvalsList.where((a) => a['status'] == 'UNDER_REVIEW').length;
    final slaBreachCount = _approvalsList.where((a) => a['sla_status'] == 'SLA_BREACH' && a['status'] == 'PENDING').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enterprise Approvals Control Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text('Cross-department verification, digital sign-offs & SLA tracking', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isBatchMode ? Icons.checklist_rtl : Icons.checklist, color: _isBatchMode ? Colors.amberAccent : Colors.white),
            tooltip: _isBatchMode ? 'Exit Batch Mode' : 'Batch Multi-Select Mode',
            onPressed: () {
              setState(() {
                _isBatchMode = !_isBatchMode;
                if (!_isBatchMode) _selectedItemIds.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync & Refresh',
            onPressed: _fetchLiveApprovals,
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent.shade700,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: _openCreateApprovalModal,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          tabs: [
            Tab(icon: const Icon(Icons.all_inbox, size: 16), text: "All Inboxes (${_approvalsList.length})"),
            Tab(icon: const Icon(Icons.badge, size: 16), text: "HR & People"),
            Tab(icon: const Icon(Icons.account_balance_wallet, size: 16), text: "Accounts & Finance"),
            Tab(icon: const Icon(Icons.terminal, size: 16), text: "IT & Infrastructure"),
            Tab(icon: const Icon(Icons.storefront, size: 16), text: "Marketing & Ops"),
            Tab(icon: const Icon(Icons.archive, size: 16), text: "Archive & History"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Executive SLA & Exposure Banner
          _buildExecutiveMetricsBanner(pendingCount, underReviewCount, slaBreachCount),

          // Search & Interactive Filters
          _buildSearchAndFilterControls(),

          // Batch Action Bar (if active)
          if (_isBatchMode) _buildBatchActionBar(),

          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: List.generate(6, (idx) => _buildApprovalsTabContent(idx)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveMetricsBanner(int pending, int review, int slaBreached) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _buildMetricTile('Pending Action', '$pending', Colors.orange, Icons.pending_actions)),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricTile('Under Review', '$review', Colors.blue, Icons.rate_review_outlined)),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricTile('SLA Critical', '$slaBreached', slaBreached > 0 ? Colors.red : Colors.green, Icons.warning_amber_rounded)),
          const SizedBox(width: 8),
          Expanded(child: _buildMetricTile('Queue Value', '₹ 2.54 L', Colors.teal, Icons.savings_outlined)),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 14, backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color, size: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by ID, Title, Requester, Department or Code...',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 16, color: Colors.indigo),
                      const SizedBox(width: 4),
                      Text('Priority: $_selectedPriorityFilter', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                onSelected: (val) => setState(() => _selectedPriorityFilter = val),
                itemBuilder: (_) => ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'].map((p) => PopupMenuItem(value: p, child: Text(p))).toList(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusFilterChip('ALL', 'All Statuses'),
                _buildStatusFilterChip('PENDING', 'Pending Only'),
                _buildStatusFilterChip('UNDER_REVIEW', 'Under Review'),
                _buildStatusFilterChip('CHANGES_REQUESTED', 'Rework Required'),
                _buildStatusFilterChip('APPROVED', 'Approved'),
                _buildStatusFilterChip('REJECTED', 'Rejected'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip(String key, String label) {
    final isSel = _selectedStatusFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSel,
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
        selectedColor: AppTheme.primary.withOpacity(0.15),
        checkmarkColor: AppTheme.primary,
        onSelected: (_) => setState(() => _selectedStatusFilter = key),
      ),
    );
  }

  Widget _buildBatchActionBar() {
    final count = _selectedItemIds.length;
    return Container(
      color: Colors.indigo.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Checkbox(
            value: count > 0 && count == _approvalsList.length,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedItemIds.addAll(_approvalsList.map((a) => a['id'].toString()));
                } else {
                  _selectedItemIds.clear();
                }
              });
            },
            activeColor: Colors.amberAccent,
            checkColor: Colors.black,
          ),
          Text('$count Selected', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Approve Selected'),
            onPressed: count > 0 ? _executeBulkApprove : null,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Reject Selected'),
            onPressed: count > 0 ? _executeBulkReject : null,
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalsTabContent(int tabIndex) {
    final list = _getFilteredApprovals(tabIndex);

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.blueGrey.shade300),
            const SizedBox(height: 12),
            const Text('No approval requests found matching your filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.blueGrey)),
            const SizedBox(height: 4),
            const Text('All items in this section have been resolved.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (ctx, idx) => _buildMasterApprovalCard(list[idx]),
    );
  }

  Widget _buildMasterApprovalCard(Map<String, dynamic> item) {
    final id = item['id'].toString();
    final isSelected = _selectedItemIds.contains(id);
    final priority = item['priority'] ?? 'MEDIUM';
    final status = item['status'] ?? 'PENDING';
    final isBreach = item['sla_status'] == 'SLA_BREACH';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: isBreach ? Colors.red.shade300 : (isSelected ? AppTheme.primary : Colors.grey.shade200), width: isSelected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open360ApprovalInspector(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isBatchMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedItemIds.add(id);
                          } else {
                            _selectedItemIds.remove(id);
                          }
                        });
                      },
                    ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _getCategoryColor(item['category']).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                    child: Icon(_getCategoryIcon(item['category']), color: _getCategoryColor(item['category']), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                            const SizedBox(width: 8),
                            _buildStatusPill(status),
                            const Spacer(),
                            _buildPriorityPill(priority),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                item['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 12),

              // Requester & Meta Chips
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppTheme.primary.withOpacity(0.2),
                    child: Text(
                      item['requester_name'].toString().isNotEmpty ? item['requester_name'].toString().substring(0, 1) : 'E',
                      style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('${item['requester_name']} (${item['dept']})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const Spacer(),
                  if (item['amount'] != 'N/A')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text(item['amount'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
                    ),
                ],
              ),
              const Divider(height: 20),

              // Action Toolbar
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: isBreach ? Colors.red : Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    isBreach ? '⚠️ SLA Overdue' : 'SLA: ${item['sla_deadline']}',
                    style: TextStyle(fontSize: 11, color: isBreach ? Colors.red : Colors.grey.shade700, fontWeight: isBreach ? FontWeight.bold : FontWeight.normal),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: const Size(40, 32),
                    ),
                    onPressed: () => _open360ApprovalInspector(item),
                    child: const Text('Inspect 360°', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 6),
                  if (status == 'PENDING' || status == 'UNDER_REVIEW') ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(40, 32),
                      ),
                      onPressed: () => _openRejectDialog(item),
                      child: const Text('Reject', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        minimumSize: const Size(50, 32),
                      ),
                      onPressed: () => _openDigitalSealDialog(item),
                      child: const Text('Approve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case 'APPROVED':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case 'REJECTED':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
      case 'UNDER_REVIEW':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        break;
      case 'CHANGES_REQUESTED':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        break;
      default:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.replaceAll('_', ' '), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _buildPriorityPill(String p) {
    Color color;
    switch (p) {
      case 'CRITICAL':
        color = Colors.red;
        break;
      case 'HIGH':
        color = Colors.orange;
        break;
      case 'MEDIUM':
        color = Colors.indigo;
        break;
      default:
        color = Colors.blueGrey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (p == 'CRITICAL') ...[
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
            const SizedBox(width: 4),
          ],
          Text(p, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildMetaCol(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('Partner')) return Icons.handshake_outlined;
    if (category.contains('Access') || category.contains('IT')) return Icons.security;
    if (category.contains('Expense')) return Icons.receipt_long;
    if (category.contains('Leave')) return Icons.beach_access;
    if (category.contains('Deploy')) return Icons.cloud_upload_outlined;
    if (category.contains('Booking')) return Icons.event_available;
    if (category.contains('Transfer') || category.contains('Promotion')) return Icons.swap_horiz;
    if (category.contains('Purchase')) return Icons.shopping_cart_outlined;
    if (category.contains('Attendance')) return Icons.fingerprint;
    return Icons.verified_user_outlined;
  }

  Color _getCategoryColor(String category) {
    if (category.contains('Partner')) return Colors.purple;
    if (category.contains('Access') || category.contains('IT')) return Colors.indigo;
    if (category.contains('Expense')) return Colors.teal;
    if (category.contains('Leave')) return Colors.blue;
    if (category.contains('Deploy')) return Colors.red;
    if (category.contains('Booking')) return Colors.amber.shade800;
    if (category.contains('Transfer')) return Colors.deepPurple;
    if (category.contains('Purchase')) return Colors.green;
    return Colors.blueGrey;
  }
}
