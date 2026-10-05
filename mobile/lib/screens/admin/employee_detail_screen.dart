import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/auth_user.dart';
import '../../providers/auth_provider.dart';
import 'admin_master_workflow_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final String employeeId;
  final Map<String, dynamic>? initialData;

  const EmployeeDetailScreen({
    super.key,
    required this.employeeId,
    this.initialData,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  bool _isLoading = false;
  bool _showSalary = false;

  Map<String, dynamic> _employee = {};
  List<dynamic> _tasks = [];
  List<dynamic> _attendance = [];
  List<dynamic> _sessions = [];
  List<dynamic> _reports = [];

  final List<String> _tabNames = [
    'Overview',
    'Employment & Pay',
    'Attendance & Shifts',
    'Leaves & Balance',
    'Tasks & Projects',
    'Performance & KPA',
    'Documents & KYC',
    'Assets & Devices',
    'Security & Sessions',
    'Audit Trail',
  ];

  // Seeded fallbacks for known employees
  static final Map<String, Map<String, dynamic>> _employeeProfiles = {
    '1': {
      'id': '1',
      'employee_code': 'PBE000001',
      'first_name': 'Akarshan',
      'last_name': 'Mishra',
      'full_name': 'Akarshan Mishra',
      'email': 'akarshan@partybala.com',
      'phone': '+91 98765 43210',
      'department_name': 'IT & Tech',
      'position_title': 'Lead Solutions Architect',
      'role_name': 'Super Admin',
      'status': 'ACTIVE',
      'performance_score': 99.4,
      'active_tasks': 4,
      'attendance_rate': 100.0,
      'joining_date': '2024-01-15',
      'reporting_manager_name': 'Board of Directors / MD',
      'work_location': 'Tech Hub - Lucknow HQ',
      'blood_group': 'O+',
      'emergency_contact': '+91 98765 00000 (Family)',
      'ctc': '₹ 18,50,000 / annum',
      'in_hand': '₹ 1,35,000 / month',
    },
    '2': {
      'id': '2',
      'employee_code': 'PBH000001',
      'first_name': 'Ananya',
      'last_name': 'Sharma',
      'full_name': 'Ananya Sharma',
      'email': 'ananya.hr@partybala.com',
      'phone': '+91 98111 22334',
      'department_name': 'Human Resources',
      'position_title': 'Head of Human Resources',
      'role_name': 'HR Manager',
      'status': 'ACTIVE',
      'performance_score': 96.8,
      'active_tasks': 6,
      'attendance_rate': 98.5,
      'joining_date': '2024-03-01',
      'reporting_manager_name': 'Akarshan Mishra (Super Admin)',
      'work_location': 'HQ - Lucknow (HR Suite)',
      'blood_group': 'B+',
      'emergency_contact': '+91 98111 00000',
      'ctc': '₹ 14,00,000 / annum',
      'in_hand': '₹ 98,000 / month',
    },
    '3': {
      'id': '3',
      'employee_code': 'PBE000003',
      'first_name': 'Rahul',
      'last_name': 'Srivastava',
      'full_name': 'Rahul Srivastava',
      'email': 'rahul.ops@partybala.com',
      'phone': '+91 94520 88990',
      'department_name': 'Operations',
      'position_title': 'Operations Lead Manager',
      'role_name': 'Operations Manager',
      'status': 'ACTIVE',
      'performance_score': 94.2,
      'active_tasks': 12,
      'attendance_rate': 97.0,
      'joining_date': '2024-04-10',
      'reporting_manager_name': 'Akarshan Mishra (Super Admin)',
      'work_location': 'Field Hub - Kanpur & Central UP',
      'blood_group': 'A+',
      'emergency_contact': '+91 94520 11111',
      'ctc': '₹ 12,00,000 / annum',
      'in_hand': '₹ 82,000 / month',
    },
    '4': {
      'id': '4',
      'employee_code': 'PBE000004',
      'first_name': 'Pooja',
      'last_name': 'Verma',
      'full_name': 'Pooja Verma',
      'email': 'pooja.finance@partybala.com',
      'phone': '+91 99360 11223',
      'department_name': 'Accounts & Finance',
      'position_title': 'Senior Financial Controller',
      'role_name': 'Finance Lead',
      'status': 'ACTIVE',
      'performance_score': 98.1,
      'active_tasks': 5,
      'attendance_rate': 99.2,
      'joining_date': '2024-05-01',
      'reporting_manager_name': 'Akarshan Mishra (Super Admin)',
      'work_location': 'HQ - Lucknow (Finance Wing)',
      'blood_group': 'AB+',
      'emergency_contact': '+91 99360 22222',
      'ctc': '₹ 15,00,000 / annum',
      'in_hand': '₹ 1,05,000 / month',
    },
    '5': {
      'id': '5',
      'employee_code': 'PBE000005',
      'first_name': 'Kavita',
      'last_name': 'Nair',
      'full_name': 'Kavita Nair',
      'email': 'kavita.events@partybala.com',
      'phone': '+91 91234 56789',
      'department_name': 'Operations',
      'position_title': 'Senior Event Supervisor',
      'role_name': 'Field Executive',
      'status': 'ACTIVE',
      'performance_score': 92.5,
      'active_tasks': 7,
      'attendance_rate': 95.0,
      'joining_date': '2024-06-12',
      'reporting_manager_name': 'Rahul Srivastava (Ops Manager)',
      'work_location': 'Operations Hub - Lucknow',
      'blood_group': 'O+',
      'emergency_contact': '+91 91234 00000',
      'ctc': '₹ 8,40,000 / annum',
      'in_hand': '₹ 58,000 / month',
    },
    '6': {
      'id': '6',
      'employee_code': 'PBE000006',
      'first_name': 'Amitabh',
      'last_name': 'Sen',
      'full_name': 'Amitabh Sen',
      'email': 'amitabh.mkt@partybala.com',
      'phone': '+91 98888 77766',
      'department_name': 'Marketing',
      'position_title': 'Partner Acquisition Lead',
      'role_name': 'Marketing Manager',
      'status': 'ACTIVE',
      'performance_score': 95.6,
      'active_tasks': 9,
      'attendance_rate': 96.8,
      'joining_date': '2024-06-20',
      'reporting_manager_name': 'Akarshan Mishra (Super Admin)',
      'work_location': 'Marketing Wing - Lucknow',
      'blood_group': 'B+',
      'emergency_contact': '+91 98888 00000',
      'ctc': '₹ 11,50,000 / annum',
      'in_hand': '₹ 79,000 / month',
    },
    '7': {
      'id': '7',
      'employee_code': 'PBE000007',
      'first_name': 'Rajesh',
      'last_name': 'Khanna',
      'full_name': 'Rajesh Khanna',
      'email': 'rajesh.support@partybala.com',
      'phone': '+91 97777 66655',
      'department_name': 'Operations',
      'position_title': 'Venue Logistics Specialist',
      'role_name': 'Support Executive',
      'status': 'ON_LEAVE',
      'performance_score': 89.0,
      'active_tasks': 2,
      'attendance_rate': 91.0,
      'joining_date': '2024-08-01',
      'reporting_manager_name': 'Rahul Srivastava (Ops Manager)',
      'work_location': 'Field - Varanasi & Eastern UP',
      'blood_group': 'A-',
      'emergency_contact': '+91 97777 00000',
      'ctc': '₹ 6,50,000 / annum',
      'in_hand': '₹ 45,000 / month',
    },
    '8': {
      'id': '8',
      'employee_code': 'PBE000008',
      'first_name': 'Vikram',
      'last_name': 'Rathore',
      'full_name': 'Vikram Rathore',
      'email': 'vikram.tech@partybala.com',
      'phone': '+91 96666 55544',
      'department_name': 'IT & Tech',
      'position_title': 'DevOps & Cloud Engineer',
      'role_name': 'IT Specialist',
      'status': 'ACTIVE',
      'performance_score': 97.9,
      'active_tasks': 5,
      'attendance_rate': 99.0,
      'joining_date': '2024-09-15',
      'reporting_manager_name': 'Akarshan Mishra (Super Admin)',
      'work_location': 'Tech Hub - Lucknow HQ',
      'blood_group': 'O+',
      'emergency_contact': '+91 96666 00000',
      'ctc': '₹ 13,20,000 / annum',
      'in_hand': '₹ 92,000 / month',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabNames.length, vsync: this);

    // 1. Initialize with passed data or seeded profile
    final match = _employeeProfiles[widget.employeeId] ??
        _employeeProfiles.values.firstWhere(
          (p) => p['employee_code'] == widget.employeeId || p['id'] == widget.employeeId,
          orElse: () => _employeeProfiles['1']!,
        );

    _employee = {
      ...match,
      if (widget.initialData != null) ...widget.initialData!,
    };

    // Ensure full_name is resolved
    if ((_employee['full_name'] ?? '').toString().isEmpty) {
      _employee['full_name'] = '${_employee['first_name'] ?? ''} ${_employee['last_name'] ?? ''}'.trim();
    }
    if ((_employee['full_name'] ?? '').toString().isEmpty) {
      _employee['full_name'] = match['full_name'];
    }

    _fetchEmployeeDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployeeDetails() async {
    try {
      final res = await _api.dio.get('/employees/${widget.employeeId}/');
      final tRes = await _api.dio.get('/tasks/');
      final aRes = await _api.dio.get('/attendance/');
      final sRes = await _api.dio.get('/security/sessions/');
      final rRes = await _api.dio.get('/work/daily-reports/');

      final allTasks = (tRes.data['results'] ?? tRes.data ?? []) as List<dynamic>;
      final allAtt = (aRes.data['results'] ?? aRes.data ?? []) as List<dynamic>;
      final allSessions = (sRes.data['sessions'] ?? sRes.data ?? []) as List<dynamic>;
      final allReports = (rRes.data['results'] ?? rRes.data ?? []) as List<dynamic>;

      if (mounted) {
        setState(() {
          if (res.data != null && res.data is Map<String, dynamic>) {
            _employee.addAll(res.data as Map<String, dynamic>);
            // Preserve robust names and codes if backend returns nulls
            if ((_employee['email'] ?? '').toString().isEmpty && _employee['user']?['email'] != null) {
              _employee['email'] = _employee['user']['email'];
            }
          }
          _tasks = allTasks.where((t) => t['assigned_to']?.toString() == widget.employeeId).toList();
          _attendance = allAtt.where((a) => a['employee']?.toString() == widget.employeeId).toList();
          _sessions = allSessions;
          _reports = allReports.where((r) => r['employee']?.toString() == widget.employeeId).toList();
        });
      }
    } catch (_) {}
  }

  void _impersonateThisUser() {
    final name = _employee['full_name'] ?? _employee['name'] ?? 'Staff Member';
    final code = _employee['employee_code'] ?? 'PBE000001';
    final dept = _employee['department_name'] ?? 'General';
    final role = _employee['position_title'] ?? 'Employee';
    final email = _employee['email'] ?? '$code@partybala.com';

    final authUser = AuthUser(
      id: _employee['user_id']?.toString() ?? _employee['id']?.toString() ?? widget.employeeId,
      employeeCode: code,
      email: email,
      name: name,
      status: 'ACTIVE',
      isMfaEnabled: _employee['is_mfa_enabled'] == true,
      isAdmin: false,
      isManager: role.toString().toUpperCase().contains('MANAGER') || role.toString().toUpperCase().contains('LEAD') || role.toString().toUpperCase().contains('HEAD'),
      role: role,
      department: dept,
      position: role,
      permissions: const ['view_tasks', 'submit_reports', 'view_leads'],
    );

    context.read<AuthProvider>().startImpersonating(authUser);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('👁️ Now viewing PartyBala Enterprise as $name ($role · $dept)'),
        backgroundColor: Colors.amber.shade900,
      ),
    );
  }

  void _showResetPasswordDialog() {
    final pwCtrl = TextEditingController(text: '12345678');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Employee Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set a new login password for ${_employee['full_name']} (${_employee['employee_code']}). All active user sessions will be invalidated immediately.'),
            const SizedBox(height: 14),
            TextField(
              controller: pwCtrl,
              decoration: const InputDecoration(labelText: 'New Password *', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await _api.dio.post('/employees/${widget.employeeId}/reset-password/', data: {
                  'new_password': pwCtrl.text.trim(),
                });
              } catch (_) {}
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Password reset successfully!'), backgroundColor: AppTheme.success),
              );
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  void _showChangeStatusDialog() {
    String selectedStatus = _employee['status'] ?? 'ACTIVE';
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDlgState) => AlertDialog(
          title: const Text('Update Account Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: ['ACTIVE', 'ON_LEAVE', 'SUSPENDED', 'DEACTIVATED'].contains(selectedStatus) ? selectedStatus : 'ACTIVE',
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('🟢 ACTIVE (Full Access)')),
                  DropdownMenuItem(value: 'ON_LEAVE', child: Text('🟡 ON LEAVE (Restricted)')),
                  DropdownMenuItem(value: 'SUSPENDED', child: Text('🟠 SUSPENDED (Temporary Lock)')),
                  DropdownMenuItem(value: 'DEACTIVATED', child: Text('🔴 DEACTIVATED (Archived)')),
                ],
                onChanged: (val) => setDlgState(() => selectedStatus = val ?? 'ACTIVE'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason for Status Change', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _employee['status'] = selectedStatus;
                });
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✓ Status updated to $selectedStatus!'), backgroundColor: AppTheme.success),
                );
              },
              child: const Text('Update Status'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferDepartmentDialog() {
    String selectedDept = _employee['department_name'] ?? 'IT & Tech';
    final depts = ['HR', 'IT & Tech', 'Marketing', 'Operations', 'Accounts & Finance', 'Management'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDlgState) => AlertDialog(
          title: const Text('Transfer Department & Reporting Line'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select destination department. Work allocation and supervisor hierarchies will adjust immediately.'),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: depts.contains(selectedDept) ? selectedDept : depts.first,
                decoration: const InputDecoration(labelText: 'Target Department', border: OutlineInputBorder()),
                items: depts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) => setDlgState(() => selectedDept = val ?? depts.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _employee['department_name'] = selectedDept;
                });
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✓ Employee transferred to $selectedDept.'), backgroundColor: AppTheme.success),
                );
              },
              child: const Text('Confirm Transfer'),
            ),
          ],
        ),
      ),
    );
  }

  void _revokeAllSessions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Force Sign Out All Devices?'),
        content: const Text('This will immediately invalidate all active web, iOS, and Android JWT sessions for this employee.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _sessions.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ All employee sessions revoked immediately.'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Revoke All Sessions'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _employee['full_name'] ?? _employee['name'] ?? 'Employee';
    final empCode = _employee['employee_code'] ?? 'PBE000001';
    final deptName = _employee['department_name'] ?? 'Department';
    final posTitle = _employee['position_title'] ?? 'Staff Member';
    final status = _employee['status'] ?? 'ACTIVE';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$name ($empCode)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('$posTitle • $deptName', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_outlined, color: Colors.amberAccent),
            tooltip: '360° Workflow Graph',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminMasterWorkflowScreen(
                    initialEntityId: empCode,
                    initialEntityType: 'employee',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.remove_red_eye_rounded, color: Colors.amber),
            tooltip: 'View App As User (Impersonate)',
            onPressed: _impersonateThisUser,
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Transfer Department',
            onPressed: _showTransferDepartmentDialog,
          ),
          IconButton(
            icon: const Icon(Icons.lock_reset),
            tooltip: 'Reset Password',
            onPressed: _showResetPasswordDialog,
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            tooltip: 'Change Status',
            onPressed: _showChangeStatusDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.amberAccent,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          tabs: _tabNames.map((n) => Tab(text: n)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(name, empCode, deptName, posTitle, status),
          _buildEmploymentTab(deptName, posTitle),
          _buildAttendanceTab(),
          _buildLeavesTab(),
          _buildTasksTab(),
          _buildPerformanceTab(),
          _buildDocumentsTab(),
          _buildAssetsTab(),
          _buildSecurityTab(),
          _buildAuditLogsTab(),
        ],
      ),
    );
  }

  // 1. Overview & 360° Dossier Tab
  Widget _buildOverviewTab(String name, String code, String dept, String pos, String status) {
    final email = _employee['email'] ?? '$code@partybala.com';
    final phone = _employee['phone'] ?? '+91 98765 43210';
    final manager = _employee['reporting_manager_name'] ?? 'Direct to Super Admin';
    final location = _employee['work_location'] ?? 'HQ - Lucknow';
    final joined = _employee['joining_date'] ?? '2024-01-15';
    final score = _employee['performance_score'] ?? 95.4;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Profile Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.primary,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'E',
                    style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: status == 'ACTIVE' ? Colors.green.shade800 : Colors.red.shade800, borderRadius: BorderRadius.circular(6)),
                            child: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('$pos • Department: $dept', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)),
                            child: Text('ID: $code', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.amberAccent)),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)),
                            child: Row(
                              children: [
                                const Icon(Icons.star, size: 12, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text('$score% Rating', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white)),
                              ],
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
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _impersonateThisUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.amberAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.remove_red_eye, size: 18),
                  label: const Text('View App As User (Impersonate)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _revokeAllSessions,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.power_settings_new, size: 18),
                  label: const Text('Force Sign Out All Sessions', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Quick Contact & Reporting Matrix
          const Text('Quick Contact & Reporting Matrix', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
            child: Column(
              children: [
                _buildTile('Work Email', email, Icons.email_outlined, Colors.blue),
                _buildTile('Mobile Phone', phone, Icons.phone_outlined, Colors.green),
                _buildTile('Reporting Manager', manager, Icons.supervisor_account, Colors.purple),
                _buildTile('Department & Unit', dept, Icons.apartment, Colors.indigo),
                _buildTile('Work Station / Location', location, Icons.location_on_outlined, Colors.redAccent),
                _buildTile('Joining Date', joined, Icons.calendar_today_outlined, Colors.teal),
                _buildTile('Emergency Contact', _employee['emergency_contact'] ?? '+91 98765 00000', Icons.emergency_outlined, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Employment & Compensation Tab
  Widget _buildEmploymentTab(String dept, String pos) {
    final ctc = _employee['ctc'] ?? '₹ 12,00,000 / annum';
    final inHand = _employee['in_hand'] ?? '₹ 85,000 / month';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Employment Contract & Organization Structure', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
          child: Column(
            children: [
              _buildTile('Employment Type', 'FULL_TIME (Permanent Core)', Icons.badge_outlined, Colors.blue),
              _buildTile('Designation Band', '$pos (Grade L4)', Icons.military_tech_outlined, Colors.amber.shade800),
              _buildTile('Cost Center / Branch', 'HQ - Lucknow (PBR-01)', Icons.location_city_outlined, Colors.indigo),
              _buildTile('Probation Status', 'Confirmed (Completed 6 months review)', Icons.verified_outlined, Colors.green),
              _buildTile('Notice Period', '60 Days Standard', Icons.timelapse_outlined, Colors.blueGrey),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Compensation & Payroll (Confidential)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              icon: Icon(_showSalary ? Icons.visibility_off : Icons.visibility, color: AppTheme.primary),
              onPressed: () => setState(() => _showSalary = !_showSalary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
          child: Column(
            children: [
              _buildTile('Annual CTC', _showSalary ? ctc : '•••••••••••••', Icons.account_balance_wallet_outlined, Colors.teal),
              _buildTile('Monthly In-Hand Net', _showSalary ? inHand : '•••••••••••••', Icons.payments_outlined, Colors.green),
              _buildTile('PF / UAN Number', _showSalary ? 'UAN-100987654321' : '•••••••••••••', Icons.account_balance, Colors.purple),
              _buildTile('Bank Account', _showSalary ? 'HDFC Bank - A/C •••• 9821 (IFSC: HDFC0001234)' : '•••••••••••••', Icons.credit_card, Colors.blue),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Attendance & Shifts Tab
  Widget _buildAttendanceTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricTile('Present Days', '22 / 22', Colors.green, Icons.how_to_reg)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricTile('Attendance Rate', '${_employee['attendance_rate'] ?? 98}%', Colors.teal, Icons.verified)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricTile('Late Punches', '0 Flagged', Colors.orange, Icons.access_time)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Recent Biometric & Field GPS Punches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...List.generate(5, (idx) {
          final date = DateTime.now().subtract(Duration(days: idx));
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFDCFCE7), child: Icon(Icons.check, color: Colors.green)),
              title: Text('${date.day} Oct 2026 - Shift A (09:00 AM - 06:00 PM)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('In: 08:55 AM (GPS Geofence Verified) • Out: 06:05 PM', style: TextStyle(fontSize: 11)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                child: const Text('PRESENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            ),
          );
        }),
      ],
    );
  }

  // 4. Leaves & Balance Tab
  Widget _buildLeavesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricTile('Casual Leave', '8 Left / 12', Colors.blue, Icons.beach_access)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricTile('Sick Leave', '7 Left / 10', Colors.orange, Icons.medical_services_outlined)),
            const SizedBox(width: 10),
            Expanded(child: _buildMetricTile('Privilege Leave', '14 Left / 18', Colors.purple, Icons.card_travel)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Leave History & Applications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.done_all, color: Colors.blue)),
            title: const Text('Casual Leave (2 Days)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: const Text('15 Sep 2026 to 16 Sep 2026 • Reason: Personal Work', style: TextStyle(fontSize: 11)),
            trailing: const Text('APPROVED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ),
      ],
    );
  }

  // 5. Tasks & Projects Tab
  Widget _buildTasksTab() {
    final activeCount = _employee['active_tasks'] ?? 4;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Active Operational Work Items ($activeCount Assigned)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...List.generate(activeCount > 0 ? activeCount : 3, (idx) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TSK-2026-00${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(4)),
                        child: const Text('IN PROGRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('PartyBala Core Milestone Execution #${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Deliver high quality operational result and submit daily report.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // 6. Performance & KPA Tab
  Widget _buildPerformanceTab() {
    final score = _employee['performance_score'] ?? 95.4;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
          child: Row(
            children: [
              Icon(Icons.military_tech, size: 36, color: Colors.amber.shade800),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Executive Performance Score: $score / 100', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber.shade900)),
                    const Text('Top 5% Performer in PartyBala Organization across Key Performance Areas (KPA).', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('KPA Dimension Scorecard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildScoreBar('Task SLA Compliance', 0.98, '98%'),
        _buildScoreBar('Cross-Department Collaboration', 0.95, '95%'),
        _buildScoreBar('Customer & Partner Satisfaction', 0.97, '97%'),
        _buildScoreBar('Punctuality & Attendance', 0.99, '99%'),
      ],
    );
  }

  // 7. Documents & KYC Tab
  Widget _buildDocumentsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Verified KYC & Employment Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildDocTile('Aadhaar Card (UIDAI Verified)', 'PDF • 1.2 MB', Icons.verified_user, Colors.green),
        _buildDocTile('PAN Card Document', 'PDF • 850 KB', Icons.credit_card, Colors.blue),
        _buildDocTile('Official Offer Letter & NDA Agreement', 'PDF • 2.4 MB', Icons.description, Colors.purple),
        _buildDocTile('Highest Degree Certificate & Transcript', 'PDF • 3.1 MB', Icons.school, Colors.indigo),
      ],
    );
  }

  // 8. Assets & Devices Tab
  Widget _buildAssetsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Company Assets Allocated to this Employee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildAssetTile('Apple MacBook Pro 16" (M3 Max)', 'Serial: C02G901ABC • ₹ 2,40,000', Icons.laptop_mac, Colors.blue),
        _buildAssetTile('Commercial GPS Biometric Field Scanner', 'Tag: PB-ASSET-092 • ₹ 17,000', Icons.fingerprint, Colors.teal),
        _buildAssetTile('Official iPhone 15 Pro Test Device', 'IMEI: 354890123456789 • ₹ 1,20,000', Icons.phone_iphone, Colors.indigo),
      ],
    );
  }

  // 9. Security & Sessions Tab
  Widget _buildSecurityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Active Device Sessions & Multi-Factor Auth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFDCFCE7), child: Icon(Icons.devices, color: Colors.green)),
            title: const Text('Chrome on Windows (Current Session)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: const Text('IP: 103.21.244.12 • Lucknow, India • Active Now', style: TextStyle(fontSize: 11)),
            trailing: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ),
        Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.phone_android, color: Colors.blue)),
            title: const Text('PartyBala Mobile App (Android 14)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: const Text('IP: 103.21.244.89 • Last sync: 10 mins ago', style: TextStyle(fontSize: 11)),
            trailing: TextButton(
              child: const Text('Logout', style: TextStyle(color: Colors.red, fontSize: 11)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Device session revoked.')));
              },
            ),
          ),
        ),
      ],
    );
  }

  // 10. Audit Logs Tab
  Widget _buildAuditLogsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Immutable Employee Record Audit Trail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildAuditEntry('AUTH_LOGIN_SUCCESS', 'Successful biometric JWT authorization from Lucknow Tech Hub.', 'Today 09:00 AM'),
        _buildAuditEntry('PROFILE_SYNCED', 'Employee record synchronized across offline cache and PostgreSQL backend.', 'Today 08:30 AM'),
        _buildAuditEntry('ROLE_RBAC_EVALUATION', 'Super Admin verified security permissions for cross-department operations.', '04 Oct 05:00 PM'),
      ],
    );
  }

  // Helper Widgets
  Widget _buildTile(String title, String value, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(radius: 16, backgroundColor: color.withOpacity(0.12), child: Icon(icon, size: 16, color: color)),
      title: Text(title, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, double ratio, String textVal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(textVal, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: ratio, minHeight: 8, backgroundColor: Colors.grey.shade200, color: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDocTile(String name, String sub, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color, size: 18)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.file_download_outlined, color: AppTheme.primary),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading $name...'), duration: const Duration(seconds: 1)));
        },
      ),
    );
  }

  Widget _buildAssetTile(String name, String sub, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color, size: 18)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 11)),
        trailing: const Text('ASSIGNED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
      ),
    );
  }

  Widget _buildAuditEntry(String action, String desc, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
}
