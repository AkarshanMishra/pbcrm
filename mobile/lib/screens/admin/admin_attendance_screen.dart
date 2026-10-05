import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'ALL';
  DateTime _selectedDate = DateTime.now();

  List<dynamic> _employees = [];
  List<dynamic> _allAttendance = [];
  List<dynamic> _corrections = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAttendanceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() => _isLoading = true);
    try {
      final eRes = await _api.dio.get('/employees/');
      final aRes = await _api.dio.get('/attendance/');
      final cRes = await _api.dio.get('/attendance/corrections/');

      final allEmps = (eRes.data['results'] ?? eRes.data ?? []) as List<dynamic>;
      final allAtt = (aRes.data['results'] ?? aRes.data ?? []) as List<dynamic>;
      final allCorr = (cRes.data['results'] ?? cRes.data ?? []) as List<dynamic>;

      setState(() {
        _employees = allEmps;
        _allAttendance = allAtt;
        _corrections = allCorr;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ===================== CRUD FOR ATTENDANCE =====================

  void _showAddAttendanceDialog([dynamic initialEmployee]) {
    String? selectedEmpId = initialEmployee != null
        ? initialEmployee['id'].toString()
        : (_employees.isNotEmpty ? _employees.first['id'].toString() : null);

    DateTime attDate = _selectedDate;
    TimeOfDay inTime = const TimeOfDay(hour: 9, minute: 30);
    TimeOfDay outTime = const TimeOfDay(hour: 18, minute: 30);
    bool hasOutTime = true;
    String status = 'PRESENT';
    final notesCtrl = TextEditingController(text: 'Admin manual punch');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.more_time, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Manual Attendance Punch', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
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
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                    items: _employees.map((emp) {
                      final name = emp['full_name'] ?? emp['user']?['username'] ?? 'Employee';
                      final code = emp['employee_code'] ?? '';
                      return DropdownMenuItem<String>(
                        value: emp['id'].toString(),
                        child: Text('$name ($code)', overflow: TextOverflow.ellipsis),
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
                          title: const Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(attDate.toIso8601String().substring(0, 10)),
                          trailing: const Icon(Icons.calendar_today, size: 20),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: attDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setDlgState(() => attDate = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: status,
                          decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(value: 'PRESENT', child: Text('Present')),
                            DropdownMenuItem(value: 'LATE', child: Text('Late Punch')),
                            DropdownMenuItem(value: 'HALF_DAY', child: Text('Half Day')),
                            DropdownMenuItem(value: 'ABSENT', child: Text('Absent')),
                            DropdownMenuItem(value: 'ON_LEAVE', child: Text('On Leave')),
                          ],
                          onChanged: (val) => setDlgState(() => status = val ?? 'PRESENT'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Check-In Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(inTime.format(context)),
                          trailing: const Icon(Icons.login, size: 20, color: Colors.green),
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: inTime);
                            if (picked != null) setDlgState(() => inTime = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Check-Out Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(hasOutTime ? outTime.format(context) : 'None'),
                          trailing: const Icon(Icons.logout, size: 20, color: Colors.orange),
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: outTime);
                            if (picked != null) {
                              setDlgState(() {
                                outTime = picked;
                                hasOutTime = true;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Admin Notes / Reason',
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
              icon: const Icon(Icons.check),
              label: const Text('Save Punch Record'),
              onPressed: () async {
                if (selectedEmpId == null) return;
                try {
                  final dateStr = attDate.toIso8601String().substring(0, 10);
                  final inTimeFormatted = '${dateStr}T${inTime.hour.toString().padLeft(2, '0')}:${inTime.minute.toString().padLeft(2, '0')}:00Z';
                  final outTimeFormatted = hasOutTime
                      ? '${dateStr}T${outTime.hour.toString().padLeft(2, '0')}:${outTime.minute.toString().padLeft(2, '0')}:00Z'
                      : null;

                  await _api.dio.post('/attendance/', data: {
                    'employee': selectedEmpId,
                    'attendance_date': dateStr,
                    'server_check_in_time': inTimeFormatted,
                    'server_check_out_time': outTimeFormatted,
                    'status': status,
                    'notes': notesCtrl.text.trim(),
                  });
                  Navigator.pop(ctx);
                  _fetchAttendanceData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Attendance punch recorded successfully!'), backgroundColor: AppTheme.success),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving attendance: $e'), backgroundColor: AppTheme.error),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAttendanceDialog(dynamic att) {
    final attId = att['id'];
    final empName = att['employee_name'] ?? 'Employee';
    String status = att['status'] ?? 'PRESENT';
    final notesCtrl = TextEditingController(text: att['notes'] ?? '');

    String inTimeStr = att['server_check_in_time'] != null ? att['server_check_in_time'].toString().substring(11, 16) : '09:30';
    String outTimeStr = att['server_check_out_time'] != null ? att['server_check_out_time'].toString().substring(11, 16) : '18:30';

    final inParts = inTimeStr.split(':');
    final outParts = outTimeStr.split(':');

    TimeOfDay inTime = TimeOfDay(hour: int.tryParse(inParts[0]) ?? 9, minute: int.tryParse(inParts[1]) ?? 30);
    TimeOfDay outTime = TimeOfDay(hour: int.tryParse(outParts[0]) ?? 18, minute: int.tryParse(outParts[1]) ?? 30);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_calendar, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(child: Text('Edit Punch: $empName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Date: ${att['attendance_date']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('ID: #$attId', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: ['PRESENT', 'LATE', 'HALF_DAY', 'ABSENT', 'ON_LEAVE'].contains(status) ? status : 'PRESENT',
                    decoration: const InputDecoration(labelText: 'Status Override', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'PRESENT', child: Text('Present')),
                      DropdownMenuItem(value: 'LATE', child: Text('Late Punch')),
                      DropdownMenuItem(value: 'HALF_DAY', child: Text('Half Day')),
                      DropdownMenuItem(value: 'ABSENT', child: Text('Absent')),
                      DropdownMenuItem(value: 'ON_LEAVE', child: Text('On Leave')),
                    ],
                    onChanged: (val) => setDlgState(() => status = val ?? 'PRESENT'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Check-In Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(inTime.format(context)),
                          trailing: const Icon(Icons.login, size: 20, color: Colors.green),
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: inTime);
                            if (picked != null) setDlgState(() => inTime = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Check-Out Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(outTime.format(context)),
                          trailing: const Icon(Icons.logout, size: 20, color: Colors.orange),
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: outTime);
                            if (picked != null) setDlgState(() => outTime = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(labelText: 'Admin Notes / Modification Reason', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              onPressed: () async {
                try {
                  final dateStr = att['attendance_date'];
                  final inTimeFormatted = '${dateStr}T${inTime.hour.toString().padLeft(2, '0')}:${inTime.minute.toString().padLeft(2, '0')}:00Z';
                  final outTimeFormatted = '${dateStr}T${outTime.hour.toString().padLeft(2, '0')}:${outTime.minute.toString().padLeft(2, '0')}:00Z';

                  await _api.dio.patch('/attendance/$attId/', data: {
                    'status': status,
                    'server_check_in_time': inTimeFormatted,
                    'server_check_out_time': outTimeFormatted,
                    'notes': notesCtrl.text.trim(),
                  });
                  Navigator.pop(ctx);
                  _fetchAttendanceData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Attendance updated successfully!'), backgroundColor: AppTheme.success),
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

  void _showDeleteAttendanceDialog(dynamic att) {
    final attId = att['id'];
    final empName = att['employee_name'] ?? 'Employee';
    final date = att['attendance_date'] ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Attendance Record?'),
          ],
        ),
        content: Text('Are you sure you want to permanently delete the attendance record for $empName on $date?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                await _api.dio.delete('/attendance/$attId/');
                Navigator.pop(ctx);
                _fetchAttendanceData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Attendance record deleted.'), backgroundColor: Colors.red),
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

  Future<void> _handleReviewCorrection(String corrId, bool approve) async {
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(approve ? Icons.check_circle : Icons.cancel, color: approve ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Text(approve ? 'Approve Correction Request' : 'Reject Correction Request'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(approve ? 'Approve and correct server attendance records?' : 'Provide reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(labelText: 'Review Notes / Comment', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                await _api.dio.post('/attendance/corrections/$corrId/review/', data: {
                  'status': approve ? 'APPROVED' : 'REJECTED',
                  'review_notes': commentCtrl.text.trim(),
                });
                Navigator.pop(ctx);
                _fetchAttendanceData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(approve ? '✓ Correction request approved!' : '✕ Correction request rejected.'),
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

  @override
  Widget build(BuildContext context) {
    final dateStr = _selectedDate.toIso8601String().substring(0, 10);
    final dateAttendance = _allAttendance.where((a) => a['attendance_date'] == dateStr).toList();
    final totalEmployees = _employees.length;
    final presentCount = dateAttendance.where((a) => a['status'] == 'PRESENT').length;
    final lateCount = dateAttendance.where((a) => a['status'] == 'LATE').length;
    final onLeaveCount = dateAttendance.where((a) => a['status'] == 'HALF_DAY' || a['status'] == 'ON_LEAVE').length;
    final absentCount = (totalEmployees - (presentCount + lateCount + onLeaveCount)).clamp(0, totalEmployees);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance & Workforce Control'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppTheme.primary,
          tabs: [
            Tab(icon: const Icon(Icons.people_outline), text: "Daily Roster ($presentCount/$totalEmployees)"),
            Tab(icon: const Icon(Icons.pending_actions), text: "Correction Requests (${_corrections.length})"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchAttendanceData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAttendanceDialog(),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.more_time),
        label: const Text('+ Manual Punch'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLiveRosterTab(dateAttendance, totalEmployees, presentCount, lateCount, onLeaveCount, absentCount),
                _buildCorrectionsTab(),
              ],
            ),
    );
  }

  Widget _buildLiveRosterTab(List<dynamic> dateAttendance, int total, int present, int late, int leave, int absent) {
    final filteredEmployees = _employees.where((emp) {
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (emp['full_name'] ?? emp['user']?['username'] ?? '').toString().toLowerCase();
        final code = (emp['employee_code'] ?? '').toString().toLowerCase();
        final dept = (emp['department_name'] ?? '').toString().toLowerCase();
        if (!name.contains(q) && !code.contains(q) && !dept.contains(q)) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Date Selector & Overview Metrics
        Card(
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Date: ${_selectedDate.toIso8601String().substring(0, 10)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) setState(() => _selectedDate = picked);
                      },
                      icon: const Icon(Icons.edit_calendar, size: 16),
                      label: const Text('Change Date'),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Total', '$total', Colors.blueGrey),
                    _buildStatCol('Present', '$present', Colors.green),
                    _buildStatCol('Late', '$late', Colors.orange),
                    _buildStatCol('On Leave', '$leave', Colors.purple),
                    _buildStatCol('Absent', '$absent', Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search employee name, code, or department...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        const SizedBox(height: 8),

        // List of Employees with Attendance Status
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: filteredEmployees.length,
            itemBuilder: (ctx, i) {
              final emp = filteredEmployees[i];
              final empId = emp['id'];
              final att = dateAttendance.firstWhere(
                (a) => a['employee'] == empId || (a['employee_id'] != null && a['employee_id'] == empId),
                orElse: () => null,
              );

              final isRecorded = att != null;
              final status = isRecorded ? (att['status'] ?? 'PRESENT') : 'NOT PUNCHED';

              Color statusColor = Colors.grey;
              if (status == 'PRESENT') statusColor = Colors.green;
              if (status == 'LATE') statusColor = Colors.orange;
              if (status == 'HALF_DAY') statusColor = Colors.purple;
              if (status == 'ON_LEAVE') statusColor = Colors.blue;
              if (status == 'ABSENT') statusColor = Colors.red;

              final inTime = isRecorded && att['server_check_in_time'] != null
                  ? att['server_check_in_time'].toString().substring(11, 16)
                  : '--:--';
              final outTime = isRecorded && att['server_check_out_time'] != null
                  ? att['server_check_out_time'].toString().substring(11, 16)
                  : '--:--';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.15),
                        child: Text(
                          (emp['full_name'] ?? emp['user']?['username'] ?? 'E')[0].toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emp['full_name'] ?? emp['user']?['username'] ?? 'Employee',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '${emp['employee_code'] ?? ''} • ${emp['department_name'] ?? 'General'}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'In: $inTime | Out: $outTime',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (isRecorded) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                  tooltip: 'Edit Record',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showEditAttendanceDialog(att),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  tooltip: 'Delete Record',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _showDeleteAttendanceDialog(att),
                                ),
                              ] else ...[
                                TextButton.icon(
                                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
                                  icon: const Icon(Icons.add, size: 14),
                                  label: const Text('Punch', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _showAddAttendanceDialog(emp),
                                ),
                              ],
                            ],
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

  Widget _buildCorrectionsTab() {
    if (_corrections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('All attendance correction requests are up to date!', style: TextStyle(fontSize: 15, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _corrections.length,
      itemBuilder: (ctx, i) {
        final c = _corrections[i];
        final id = c['id'].toString();
        final status = c['status'] ?? 'PENDING';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      c['employee_name'] ?? 'Employee',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        status,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Date: ${c['requested_date'] ?? ''} • Type: ${c['correction_type'] ?? 'Punch Correction'}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Text('Reason: ${c['reason'] ?? 'No reason specified'}', style: const TextStyle(fontSize: 13)),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => _handleReviewCorrection(id, false),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      onPressed: () => _handleReviewCorrection(id, true),
                      child: const Text('Approve & Correct'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCol(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }
}
