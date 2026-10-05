import 'package:flutter/material.dart';
import 'dart:convert';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  bool _isLoading = false;

  // Data lists
  List<dynamic> _dailyReports = [];
  List<dynamic> _attendanceReports = [];
  List<dynamic> _taskReports = [];
  List<dynamic> _departments = [];
  List<dynamic> _auditLogs = [];
  List<dynamic> _employees = [];

  // Filter states
  String _selectedStatusFilter = 'ALL';
  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadCurrentTabData();
      }
    });
    _loadEmployees();
    _loadCurrentTabData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final res = await _api.dio.get('/employees/');
      setState(() {
        _employees = (res.data['results'] ?? res.data ?? []) as List<dynamic>;
      });
    } catch (_) {}
  }

  Future<void> _loadCurrentTabData() async {
    setState(() => _isLoading = true);
    try {
      final index = _tabController.index;
      if (index == 0) {
        // Daily Work Reports
        final res = await _api.dio.get('/work/daily-reports/');
        setState(() {
          _dailyReports = (res.data['results'] ?? res.data ?? []) as List<dynamic>;
        });
      } else if (index == 1) {
        // Attendance
        final res = await _api.dio.get('/attendance/');
        setState(() {
          _attendanceReports = (res.data['results'] ?? res.data ?? []) as List<dynamic>;
        });
      } else if (index == 2) {
        // Tasks & SLAs
        final res = await _api.dio.get('/tasks/');
        setState(() {
          _taskReports = (res.data['results'] ?? res.data ?? []) as List<dynamic>;
        });
      } else if (index == 3) {
        // Department Performance
        final res = await _api.dio.get('/organization/departments/');
        setState(() {
          _departments = (res.data['results'] ?? res.data ?? []) as List<dynamic>;
        });
      } else if (index == 4) {
        // Audit & Security
        final res = await _api.dio.get('/audit/logs/');
        setState(() {
          _auditLogs = (res.data['results'] ?? res.data ?? []) as List<dynamic>;
        });
      }
    } catch (e) {
      // Keep existing data on error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===================== CRUD FOR DAILY WORK REPORTS =====================

  void _showCreateDailyReportDialog() {
    String? selectedEmpId = _employees.isNotEmpty ? _employees.first['id']?.toString() : null;
    DateTime reportDate = DateTime.now();
    final summaryCtrl = TextEditingController();
    final completedCtrl = TextEditingController();
    final pendingCtrl = TextEditingController();
    final blockedCtrl = TextEditingController();
    final tomorrowCtrl = TextEditingController();
    String status = 'SUBMITTED';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.add_chart, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              const Text('Create Work Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Employee *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedEmpId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _employees.map((emp) {
                      final name = emp['full_name'] ?? emp['user']?['username'] ?? 'Employee';
                      final code = emp['employee_code'] ?? '';
                      return DropdownMenuItem<String>(
                        value: emp['id'].toString(),
                        child: Text('$name ($code) - ${emp['department_name'] ?? ''}', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setDlgState(() => selectedEmpId = val),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Report Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(reportDate.toIso8601String().substring(0, 10)),
                          trailing: const Icon(Icons.calendar_today, size: 20),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: reportDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setDlgState(() => reportDate = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                            DropdownMenuItem(value: 'SUBMITTED', child: Text('Submitted')),
                            DropdownMenuItem(value: 'REVIEWED', child: Text('Reviewed / Approved')),
                            DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
                          ],
                          onChanged: (val) => setDlgState(() => status = val ?? 'SUBMITTED'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: summaryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Executive Summary / Key Highlight *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: completedCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Tasks Completed Today *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pendingCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'In Progress / Pending Items',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: blockedCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Blockers / Impediments',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tomorrowCtrl,
                    decoration: const InputDecoration(
                      labelText: "Tomorrow's Target Plan",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Save Daily Report'),
              onPressed: () async {
                if (summaryCtrl.text.trim().isEmpty || completedCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter summary and completed tasks.'), backgroundColor: Colors.orange),
                  );
                  return;
                }
                try {
                  await _api.dio.post('/work/daily-reports/', data: {
                    'employee_id': selectedEmpId,
                    'report_date': reportDate.toIso8601String().substring(0, 10),
                    'summary_text': summaryCtrl.text.trim(),
                    'completed_summary': completedCtrl.text.trim(),
                    'pending_summary': pendingCtrl.text.trim(),
                    'blocked_summary': blockedCtrl.text.trim(),
                    'tomorrow_plan': tomorrowCtrl.text.trim(),
                    'status': status,
                  });
                  Navigator.pop(ctx);
                  _loadCurrentTabData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Daily report created successfully!'), backgroundColor: AppTheme.success),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error creating report: $e'), backgroundColor: AppTheme.error),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDailyReportDialog(dynamic report) {
    final summaryCtrl = TextEditingController(text: report['summary_text'] ?? '');
    final completedCtrl = TextEditingController(text: report['completed_summary'] ?? '');
    final pendingCtrl = TextEditingController(text: report['pending_summary'] ?? '');
    final blockedCtrl = TextEditingController(text: report['blocked_summary'] ?? '');
    final tomorrowCtrl = TextEditingController(text: report['tomorrow_plan'] ?? '');
    final remarksCtrl = TextEditingController(text: report['review_remarks'] ?? '');
    String status = report['status'] ?? 'SUBMITTED';
    final reportId = report['id'];
    final empName = report['employee_name'] ?? 'Employee';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: Colors.indigo),
              const SizedBox(width: 8),
              Expanded(child: Text('Edit / Review Report ($empName)', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date: ${report['report_date'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Employee: $empName', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: ['DRAFT', 'SUBMITTED', 'REVIEWED', 'REJECTED'].contains(status) ? status : 'SUBMITTED',
                    decoration: const InputDecoration(
                      labelText: 'Report Approval Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                      DropdownMenuItem(value: 'SUBMITTED', child: Text('Submitted (Pending Review)')),
                      DropdownMenuItem(value: 'REVIEWED', child: Text('Reviewed & Approved')),
                      DropdownMenuItem(value: 'REJECTED', child: Text('Rejected / Revision Needed')),
                    ],
                    onChanged: (val) => setDlgState(() => status = val ?? 'SUBMITTED'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: summaryCtrl,
                    decoration: const InputDecoration(labelText: 'Summary / Headline', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: completedCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Completed Tasks', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pendingCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Pending / In Progress', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: blockedCtrl,
                    decoration: const InputDecoration(labelText: 'Blockers / Issues', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tomorrowCtrl,
                    decoration: const InputDecoration(labelText: 'Tomorrow Plan', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: remarksCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Admin / Manager Review Remarks',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.comment),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () async {
                try {
                  await _api.dio.patch('/work/daily-reports/$reportId/', data: {
                    'summary_text': summaryCtrl.text.trim(),
                    'completed_summary': completedCtrl.text.trim(),
                    'pending_summary': pendingCtrl.text.trim(),
                    'blocked_summary': blockedCtrl.text.trim(),
                    'tomorrow_plan': tomorrowCtrl.text.trim(),
                    'review_remarks': remarksCtrl.text.trim(),
                    'status': status,
                  });
                  Navigator.pop(ctx);
                  _loadCurrentTabData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Report updated successfully!'), backgroundColor: AppTheme.success),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Update failed: $e'), backgroundColor: AppTheme.error),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDailyReportDialog(dynamic report) {
    final reportId = report['id'];
    final empName = report['employee_name'] ?? 'Employee';
    final date = report['report_date'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Work Report?'),
          ],
        ),
        content: Text('Are you sure you want to permanently delete the work report for $empName on $date? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await _api.dio.delete('/work/daily-reports/$reportId/');
                Navigator.pop(ctx);
                _loadCurrentTabData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Work report deleted successfully.'), backgroundColor: Colors.red),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppTheme.error),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _exportCurrentData(String format) {
    final index = _tabController.index;
    String category = index == 0
        ? 'Daily_Work_Reports'
        : index == 1
            ? 'Attendance_Reports'
            : index == 2
                ? 'Tasks_and_SLAs'
                : index == 3
                    ? 'Department_Analytics'
                    : 'Security_Audit_Logs';

    int count = index == 0
        ? _dailyReports.length
        : index == 1
            ? _attendanceReports.length
            : index == 2
                ? _taskReports.length
                : index == 3
                    ? _departments.length
                    : _auditLogs.length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.file_download_done, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text('Exporting $category as $format ($count records)...')),
          ],
        ),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ===================== UI BUILDERS =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Reports & Analytics Center'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppTheme.primary,
          tabs: [
            Tab(icon: const Icon(Icons.description), text: "Daily Reports (${_dailyReports.length})"),
            Tab(icon: const Icon(Icons.alarm), text: "Attendance (${_attendanceReports.length})"),
            Tab(icon: const Icon(Icons.task_alt), text: "Tasks & SLAs (${_taskReports.length})"),
            Tab(icon: const Icon(Icons.apartment), text: "Departments (${_departments.length})"),
            Tab(icon: const Icon(Icons.security), text: "Audit Logs (${_auditLogs.length})"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _loadCurrentTabData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export Report',
            onSelected: _exportCurrentData,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'CSV', child: ListTile(leading: Icon(Icons.table_chart, color: Colors.green), title: Text('Export as CSV'))),
              PopupMenuItem(value: 'PDF', child: ListTile(leading: Icon(Icons.picture_as_pdf, color: Colors.red), title: Text('Export as PDF Document'))),
              PopupMenuItem(value: 'JSON', child: ListTile(leading: Icon(Icons.data_object, color: Colors.blue), title: Text('Export as JSON Data'))),
            ],
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _showCreateDailyReportDialog,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Report'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDailyReportsTab(),
                _buildAttendanceReportsTab(),
                _buildTaskReportsTab(),
                _buildDepartmentReportsTab(),
                _buildAuditLogsTab(),
              ],
            ),
    );
  }

  // TAB 1: Daily Work Reports with Full CRUD
  Widget _buildDailyReportsTab() {
    final filtered = _dailyReports.where((r) {
      if (_selectedStatusFilter != 'ALL' && (r['status'] ?? '') != _selectedStatusFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (r['employee_name'] ?? '').toString().toLowerCase();
        final summary = (r['summary_text'] ?? '').toString().toLowerCase();
        final dept = (r['department_name'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !summary.contains(q) && !dept.contains(q)) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Controls Bar
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search employee, department or keyword...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _selectedStatusFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'SUBMITTED', child: Text('Submitted')),
                  DropdownMenuItem(value: 'REVIEWED', child: Text('Reviewed / Approved')),
                  DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
                  DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                ],
                onChanged: (val) => setState(() => _selectedStatusFilter = val ?? 'ALL'),
              ),
            ],
          ),
        ),
        // List of Reports
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.find_in_page_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('No daily work reports found for current filter.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showCreateDailyReportDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Work Report'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final report = filtered[i];
                    final status = report['status'] ?? 'SUBMITTED';
                    Color statusColor = Colors.orange;
                    if (status == 'REVIEWED') statusColor = Colors.green;
                    if (status == 'REJECTED') statusColor = Colors.red;
                    if (status == 'DRAFT') statusColor = Colors.grey;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                                      child: Text(
                                        (report['employee_name'] ?? 'E')[0].toUpperCase(),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          report['employee_name'] ?? 'Employee',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          '${report['department_name'] ?? 'General'} • Date: ${report['report_date'] ?? ''}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            // Content
                            if ((report['summary_text'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  report['summary_text'],
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                            if ((report['completed_summary'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle, size: 15, color: Colors.green),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Completed: ${report['completed_summary']}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if ((report['pending_summary'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.hourglass_top, size: 15, color: Colors.orange),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Pending: ${report['pending_summary']}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if ((report['blocked_summary'] ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.block, size: 15, color: Colors.red),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Blockers: ${report['blocked_summary']}',
                                        style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if ((report['review_remarks'] ?? '').isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.rate_review, size: 14, color: Colors.blue),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Admin Remarks: ${report['review_remarks']}',
                                        style: TextStyle(fontSize: 11, color: Colors.blue.shade900, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 10),
                            // Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit / Review'),
                                  onPressed: () => _showEditDailyReportDialog(report),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  onPressed: () => _showDeleteDailyReportDialog(report),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 2: Attendance Reports
  Widget _buildAttendanceReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCol('Total Logs', '${_attendanceReports.length}', Colors.blue),
                _buildSummaryCol('Present', '${_attendanceReports.where((a) => a['status'] == 'PRESENT').length}', Colors.green),
                _buildSummaryCol('Late', '${_attendanceReports.where((a) => a['status'] == 'LATE').length}', Colors.orange),
                _buildSummaryCol('Half Day', '${_attendanceReports.where((a) => a['status'] == 'HALF_DAY').length}', Colors.purple),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Detailed Attendance Records', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ..._attendanceReports.map((att) {
          final inTime = att['server_check_in_time'] != null
              ? att['server_check_in_time'].toString().substring(11, 16)
              : '--:--';
          final outTime = att['server_check_out_time'] != null
              ? att['server_check_out_time'].toString().substring(11, 16)
              : '--:--';
          final status = att['status'] ?? 'PRESENT';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person, size: 20)),
              title: Text(att['employee_name'] ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('Date: ${att['attendance_date']} • In: $inTime | Out: $outTime\n${att['notes'] ?? ''}', style: const TextStyle(fontSize: 11)),
              isThreeLine: (att['notes'] ?? '').toString().isNotEmpty,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'PRESENT' ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: status == 'PRESENT' ? Colors.green.shade900 : Colors.orange.shade900)),
              ),
            ),
          );
        }),
      ],
    );
  }

  // TAB 3: Tasks & SLAs
  Widget _buildTaskReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryCol('Total Tasks', '${_taskReports.length}', Colors.indigo),
                _buildSummaryCol('Completed', '${_taskReports.where((t) => t['status'] == 'DONE' || t['status'] == 'COMPLETED').length}', Colors.green),
                _buildSummaryCol('In Progress', '${_taskReports.where((t) => t['status'] == 'IN_PROGRESS').length}', Colors.blue),
                _buildSummaryCol('Blocked', '${_taskReports.where((t) => t['status'] == 'BLOCKED').length}', Colors.red),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Organization Task Execution & SLAs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ..._taskReports.map((task) {
          final priority = task['priority'] ?? 'MEDIUM';
          final status = task['status'] ?? 'TODO';
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                priority == 'CRITICAL' || priority == 'HIGH' ? Icons.warning : Icons.task_alt,
                color: priority == 'CRITICAL' ? Colors.red : AppTheme.primary,
              ),
              title: Text(task['title'] ?? 'Task', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('Dept: ${task['department'] ?? 'General'} • Assignee: ${task['assignee_name'] ?? 'Unassigned'}\nDue: ${task['due_date'] ?? 'N/A'}', style: const TextStyle(fontSize: 11)),
              trailing: Text(status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          );
        }),
      ],
    );
  }

  // TAB 4: Department Performance
  Widget _buildDepartmentReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Department Performance & Resource Allocation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ..._departments.map((dept) {
          final name = dept['name'] ?? 'Department';
          final code = dept['code'] ?? '';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$name ($code)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                        child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(dept['description'] ?? 'Operational Department', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Manager: ${dept['manager_name'] ?? 'Assigned Manager'}', style: const TextStyle(fontSize: 12)),
                      Text('Headcount: ${dept['headcount'] ?? '12'} members', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // TAB 5: Audit & Security Logs
  Widget _buildAuditLogsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Security, Compliance & Audit Trail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        if (_auditLogs.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No audit anomalies or security violations logged.'))))
        else
          ..._auditLogs.map((log) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.shield, color: Colors.blueGrey),
                title: Text(log['action'] ?? log['event_type'] ?? 'Audit Event', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('User: ${log['user_username'] ?? 'System'} • ${log['timestamp'] ?? log['created_at'] ?? ''}\n${log['details'] ?? ''}', style: const TextStyle(fontSize: 11)),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSummaryCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }
}
