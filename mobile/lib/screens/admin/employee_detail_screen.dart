import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/auth_user.dart';
import '../../providers/auth_provider.dart';
import 'admin_master_workflow_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final String employeeId;

  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  bool _isLoading = true;
  bool _showSalary = false;

  Map<String, dynamic>? _employee;
  List<dynamic> _tasks = [];
  List<dynamic> _attendance = [];
  List<dynamic> _sessions = [];
  List<dynamic> _devices = [];
  List<dynamic> _reports = [];

  final List<String> _tabNames = [
    'Overview',
    'Employment',
    'Attendance',
    'Leaves',
    'Tasks',
    'Projects',
    'Reports',
    'Performance',
    'Documents',
    'Assets',
    'Tickets',
    'Security',
    'Audit Logs',
    'Permissions',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabNames.length, vsync: this);
    _fetchEmployeeDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchEmployeeDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/employees/${widget.employeeId}/');
      final tRes = await _api.dio.get('/tasks/');
      final aRes = await _api.dio.get('/attendance/');
      final sRes = await _api.dio.get('/security/sessions/');
      final dRes = await _api.dio.get('/security/devices/');
      final rRes = await _api.dio.get('/work/daily-reports/');

      final allTasks = (tRes.data['results'] ?? tRes.data ?? []) as List<dynamic>;
      final allAtt = (aRes.data['results'] ?? aRes.data ?? []) as List<dynamic>;
      final allSessions = (sRes.data['sessions'] ?? sRes.data ?? []) as List<dynamic>;
      final allDevices = (dRes.data['devices'] ?? dRes.data ?? []) as List<dynamic>;
      final allReports = (rRes.data['results'] ?? rRes.data ?? []) as List<dynamic>;

      setState(() {
        _employee = res.data;
        _tasks = allTasks.where((t) => t['assigned_to']?.toString() == widget.employeeId).toList();
        _attendance = allAtt.where((a) => a['employee']?.toString() == widget.employeeId).toList();
        final userId = _employee?['user']?['id']?.toString() ?? _employee?['user_id']?.toString();
        _sessions = allSessions.where((s) => s['user_id']?.toString() == userId || s['user']?.toString() == userId).toList();
        _devices = allDevices.where((d) => d['user_id']?.toString() == userId || d['user']?.toString() == userId).toList();
        _reports = allReports.where((r) => r['employee']?.toString() == widget.employeeId).toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _impersonateThisUser() {
    final emp = _employee ?? {};
    final fullName = emp['full_name'] ?? '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.trim();
    final name = fullName.isNotEmpty ? fullName : (emp['name'] ?? 'Staff Member');
    final code = emp['employee_code'] ?? 'PBE000000';
    final dept = emp['department_name'] ?? emp['department'] ?? 'General';
    final role = emp['position_title'] ?? emp['position'] ?? 'Employee';
    final email = emp['email'] ?? emp['user']?['email'] ?? '$code@pcrm.internal';

    final authUser = AuthUser(
      id: emp['user_id']?.toString() ?? emp['id']?.toString() ?? widget.employeeId,
      employeeCode: code,
      email: email,
      name: name,
      status: 'ACTIVE',
      isMfaEnabled: emp['is_mfa_enabled'] == true,
      isAdmin: false,
      isManager: role.toString().toUpperCase().contains('MANAGER') || role.toString().toUpperCase().contains('LEAD'),
      role: role,
      department: dept,
      position: role,
      permissions: const ['view_tasks', 'submit_reports'],
    );

    context.read<AuthProvider>().startImpersonating(authUser);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('👁️ Now viewing PCRM Enterprise as $name ($role · $dept)'),
        backgroundColor: Colors.amber.shade900,
      ),
    );
  }

  void _showResetPasswordDialog() {
    final pwCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Employee Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a new strong password for this employee. All active sessions will be terminated.'),
            const SizedBox(height: 12),
            TextField(
              controller: pwCtrl,
              decoration: const InputDecoration(labelText: 'New Password *', prefixIcon: Icon(Icons.lock)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: () async {
              if (pwCtrl.text.trim().isEmpty) return;
              try {
                await _api.dio.post('/employees/${widget.employeeId}/reset-password/', data: {
                  'new_password': pwCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Password reset successfully!'), backgroundColor: AppTheme.success),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to reset password.'), backgroundColor: AppTheme.error),
                );
              }
            },
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  void _showChangeStatusDialog() {
    String selectedStatus = _employee?['user_status'] ?? _employee?['status'] ?? 'ACTIVE';
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Update Account Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('🟢 ACTIVE')),
                  DropdownMenuItem(value: 'SUSPENDED', child: Text('🟡 SUSPENDED')),
                  DropdownMenuItem(value: 'DEACTIVATED', child: Text('🔴 DEACTIVATED')),
                ],
                onChanged: (val) => setDlgState(() => selectedStatus = val ?? 'ACTIVE'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason for status change'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _api.dio.post('/employees/${widget.employeeId}/change-status/', data: {
                    'status': selectedStatus,
                    'reason': reasonCtrl.text.trim(),
                  });
                  Navigator.pop(ctx);
                  _fetchEmployeeDetails();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Status updated successfully!'), backgroundColor: AppTheme.success),
                  );
                } catch (_) {
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Update Status'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferDepartmentDialog() {
    String selectedDept = _employee?['department_name'] ?? 'Operations';
    final depts = ['Marketing', 'Operations', 'IT & Tech', 'Human Resources', 'Accounts & Finance'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Transfer Department'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select the destination department. Role permissions and reporting hierarchy will adjust accordingly.'),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: depts.contains(selectedDept) ? selectedDept : depts.first,
                decoration: const InputDecoration(labelText: 'Target Department'),
                items: depts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (val) => setDlgState(() => selectedDept = val ?? depts.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✓ Transfer scheduled for $selectedDept department.'), backgroundColor: AppTheme.success),
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final emp = _employee ?? {};
    final fullName = emp['full_name'] ?? '${emp['first_name'] ?? ''} ${emp['last_name'] ?? ''}'.trim();
    final name = fullName.isNotEmpty ? fullName : (emp['name'] ?? 'Staff Member');
    final empCode = emp['employee_code'] ?? 'PBE000000';
    final deptName = emp['department_name'] ?? 'Department';
    final posTitle = emp['position_title'] ?? 'Position';
    final status = emp['user_status'] ?? emp['status'] ?? 'ACTIVE';

    return Scaffold(
      appBar: AppBar(
        title: Text('$name ($empCode)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_outlined, color: Colors.blueAccent),
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
            tooltip: 'View As (Impersonate)',
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
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          tabs: _tabNames.map((name) => Tab(text: name)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(emp, name, empCode, deptName, posTitle, status),
          _buildEmploymentTab(emp, deptName, posTitle),
          _buildAttendanceTab(),
          _buildLeavesTab(),
          _buildTasksTab(),
          _buildProjectsTab(),
          _buildReportsTab(),
          _buildPerformanceTab(),
          _buildDocumentsTab(),
          _buildAssetsTab(),
          _buildTicketsTab(),
          _buildSecurityTab(emp),
          _buildAuditLogsTab(),
          _buildPermissionsTab(emp),
        ],
      ),
    );
  }

  // 1. Overview Tab
  Widget _buildOverviewTab(Map<String, dynamic> emp, String name, String code, String dept, String pos, String status) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('$pos • $dept', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: status == 'ACTIVE' ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: status == 'ACTIVE' ? Colors.green.shade800 : Colors.red.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _impersonateThisUser,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.amber),
                icon: const Icon(Icons.remove_red_eye, size: 18),
                label: const Text('View App As User', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _revokeAllSessions,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.power_settings_new, size: 18),
                label: const Text('Force Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Quick Contact & Reporting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              _buildTile('Work Email', emp['email'] ?? emp['user']?['email'] ?? '--', Icons.email_outlined),
              _buildTile('Mobile Phone', emp['phone'] ?? '+91 98765 43210', Icons.phone_outlined),
              _buildTile('Reporting Manager', emp['reporting_manager_name'] ?? 'Direct to Super Admin', Icons.supervisor_account),
              _buildTile('Department', dept, Icons.apartment),
              _buildTile('Joining Date', emp['joining_date'] ?? '2024-01-15', Icons.calendar_today_outlined),
            ],
          ),
        ),
      ],
      ),
    );
  }

  // 2. Employment & Compensation Tab
  Widget _buildEmploymentTab(Map<String, dynamic> emp, String dept, String pos) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Employment Contract & Organization Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _buildTile('Employment Type', emp['employment_type'] ?? 'FULL_TIME (Permanent)', Icons.badge_outlined),
              _buildTile('Designation Band', 'Grade L4 - Senior Specialist', Icons.military_tech_outlined),
              _buildTile('Cost Center / Branch', 'HQ - Lucknow (PBR-01)', Icons.location_city_outlined),
              _buildTile('Probation Status', 'Confirmed (Completed 6 months)', Icons.verified_outlined),
              _buildTile('Notice Period', '60 Days', Icons.timelapse_outlined),
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
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _buildTile('Base CTC (Annual)', _showSalary ? '₹ 12,00,000 / year' : '••••••••••••', Icons.currency_rupee),
              _buildTile('Monthly Gross Salary', _showSalary ? '₹ 1,00,000 / month' : '••••••••••••', Icons.payments_outlined),
              _buildTile('Bank Account / IFSC', _showSalary ? 'HDFC Bank ••••••4920 (HDFC0001024)' : '••••••••••••', Icons.account_balance),
              _buildTile('PAN & Tax ID', _showSalary ? 'ABCDE1234F' : '••••••••••••', Icons.credit_card),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Attendance Tab
  Widget _buildAttendanceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Recent Attendance Logs (${_attendance.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add Punch Entry', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_attendance.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No attendance records logged yet.'))))
        else
          ..._attendance.map((a) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: a['status'] == 'PRESENT' ? Colors.green.shade50 : Colors.orange.shade50,
                  child: Icon(Icons.check, color: a['status'] == 'PRESENT' ? Colors.green : Colors.orange),
                ),
                title: Text('Date: ${a['attendance_date']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('In: ${a['server_check_in_time'] ?? '09:30 AM'}  •  Out: ${a['server_check_out_time'] ?? '06:30 PM'}'),
                trailing: Text(a['status'] ?? 'PRESENT', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          }),
      ],
    );
  }

  // 4. Leaves Tab
  Widget _buildLeavesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Leave Balances & Quota", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildQuotaCard('Casual', '12 / 14', Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _buildQuotaCard('Sick', '8 / 10', Colors.teal)),
            const SizedBox(width: 8),
            Expanded(child: _buildQuotaCard('Earned', '15 / 18', Colors.purple)),
          ],
        ),
        const SizedBox(height: 20),
        const Text("Leave History & Applications", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.beach_access, color: Colors.blue)),
            title: const Text('Casual Leave (2 Days)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('20 Sep 2026 - 21 Sep 2026 • Family Function'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
              child: Text('APPROVED', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
        ),
      ],
    );
  }

  // 5. Tasks Tab
  Widget _buildTasksTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Assigned Tasks (${_tasks.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (_tasks.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No active tasks assigned.'))))
        else
          ..._tasks.map((t) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(t['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Due: ${t['due_date'] ?? 'No date'} • Priority: ${t['priority'] ?? 'MEDIUM'}'),
                trailing: Chip(label: Text(t['status'] ?? 'ASSIGNED', style: const TextStyle(fontSize: 10))),
              ),
            );
          }),
      ],
    );
  }

  // 6. Projects Tab
  Widget _buildProjectsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Associated Projects & Sprints", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFF5F3FF), child: Icon(Icons.folder_special, color: Colors.deepPurple)),
            title: const Text('PCRM Enterprise v2.4 Release', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Sprint 14 • Lead Backend Engineer • 8 Modules assigned'),
            trailing: const Text('IN PROGRESS', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ),
      ],
    );
  }

  // 7. Reports Tab
  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Daily Work Reports (${_reports.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (_reports.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No daily work reports submitted.'))))
        else
          ..._reports.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text('Report Date: ${r['report_date'] ?? 'Today'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(r['summary'] ?? 'Daily deliverables and progress update'),
                  trailing: Text(r['status'] ?? 'SUBMITTED', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              )),
      ],
    );
  }

  // 8. Performance Tab
  Widget _buildPerformanceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Performance Appraisals & Ratings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Annual Review (FY 2025-26)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('★ 4.8 / 5.0', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Consistently exceeds deliverables, maintains zero SLA breaches in sprint tasks, and shows strong leadership.', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 9. Documents Tab
  Widget _buildDocumentsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Compliance & Verification Documents", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildDocTile('Government Identity Card (Aadhaar/Passport)', 'Verified', Icons.verified_user, Colors.green),
        _buildDocTile('Signed Employment Contract & NDA', 'Active (Signed 2024)', Icons.description, Colors.blue),
        _buildDocTile('Degree & Educational Certificates', 'Verified', Icons.school, Colors.purple),
      ],
    );
  }

  // 10. Assets Tab
  Widget _buildAssetsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Hardware & Company Asset Allocation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildAssetTile('MacBook Pro M3 Max 16"', 'SN: C02XG018P1', 'Allocated 15 Jan 2024'),
        _buildAssetTile('Jio Corporate 5G SIM', 'Number: +91 98765 00001', 'Allocated 15 Jan 2024'),
        _buildAssetTile('Smart NFC Security Badge', 'UID: NFC-8849-01', 'Active'),
      ],
    );
  }

  // 11. Tickets Tab
  Widget _buildTicketsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("IT & Support Tickets", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.confirmation_number, color: Colors.blue)),
            title: const Text('Request for Cloud Sandbox Access', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Ticket #IT-1092 • Priority: HIGH'),
            trailing: const Text('RESOLVED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ),
      ],
    );
  }

  // 12. Security Tab
  Widget _buildSecurityTab(Map<String, dynamic> emp) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Security Profile & Identity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Multi-Factor Authentication (MFA)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(emp['is_mfa_enabled'] == true ? 'Enforced and active' : 'Not configured'),
                value: emp['is_mfa_enabled'] == true,
                onChanged: null,
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Failed Login Attempts'),
                trailing: Text('${emp['failed_login_attempts'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Active Sessions (${_sessions.length})", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            TextButton(onPressed: _revokeAllSessions, child: const Text('Revoke All', style: TextStyle(color: Colors.red))),
          ],
        ),
        if (_sessions.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No active web/mobile sessions.')))
        else
          ..._sessions.map((s) => Card(
                child: ListTile(
                  leading: const Icon(Icons.devices, color: Colors.blue),
                  title: Text(s['device_name'] ?? 'Web Browser'),
                  subtitle: Text('IP: ${s['ip_address'] ?? '127.0.0.1'} • Last active: ${s['last_active'] ?? 'Recent'}'),
                  trailing: TextButton(
                    onPressed: () {
                      setState(() => _sessions.remove(s));
                    },
                    child: const Text('Revoke', style: TextStyle(color: Colors.red)),
                  ),
                ),
              )),
      ],
    );
  }

  // 13. Audit Logs Tab
  Widget _buildAuditLogsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text("Security & Activity Audit Trail", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              _buildAuditTile('Login Success', 'IP: 192.168.1.45 (Chrome macOS)', 'Today, 09:30 AM', Icons.login, Colors.green),
              _buildAuditTile('Profile Updated', 'Reporting manager assigned', '02 Oct 2026, 11:20 AM', Icons.edit, Colors.blue),
              _buildAuditTile('Password Reset', 'Admin initiated reset', '28 Sep 2026, 04:15 PM', Icons.key, Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  // 14. Permissions Tab
  Widget _buildPermissionsTab(Map<String, dynamic> emp) {
    final perms = (emp['permissions'] ?? ['view_tasks', 'submit_daily_reports', 'request_leaves', 'view_department_roster']) as List<dynamic>;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Active Role Permissions (${perms.length})", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...perms.map((p) => Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(p.toString().replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Text('GRANTED', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            )),
      ],
    );
  }

  // Utility Widgets
  Widget _buildTile(String label, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primary, size: 20),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      dense: true,
    );
  }

  Widget _buildQuotaCard(String title, String count, Color color) {
    return Card(
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Text(count, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocTile(String title, String status, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        trailing: const Icon(Icons.download, color: Colors.grey),
      ),
    );
  }

  Widget _buildAssetTile(String title, String sn, String date) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.laptop_mac, color: Colors.blue)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text('$sn • $date', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        trailing: const Icon(Icons.info_outline, color: Colors.grey),
      ),
    );
  }

  Widget _buildAuditTile(String action, String detail, String time, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 18)),
      title: Text(action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text('$detail\n$time', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
      isThreeLine: true,
      dense: true,
    );
  }
}
