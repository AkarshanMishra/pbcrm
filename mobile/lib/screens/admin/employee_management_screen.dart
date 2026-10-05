import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'organization_management_screen.dart';

class EmployeeManagementScreen extends StatefulWidget {
  const EmployeeManagementScreen({super.key});

  @override
  State<EmployeeManagementScreen> createState() => _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String _searchQuery = '';
  List<dynamic> _employees = [];
  List<dynamic> _departments = [];
  List<dynamic> _positions = [];
  List<dynamic> _roles = [];

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
    _fetchMetadata();
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/employees/');
      setState(() {
        _employees = res.data['results'] ?? res.data ?? [];
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load employee directory: ${e.toString()}');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchMetadata() async {
    try {
      final dRes = await _api.dio.get('/organization/departments/');
      final pRes = await _api.dio.get('/organization/positions/');
      final rRes = await _api.dio.get('/organization/roles/');
      setState(() {
        _departments = dRes.data['results'] ?? dRes.data ?? [];
        _positions = pRes.data['results'] ?? pRes.data ?? [];
        _roles = rRes.data['results'] ?? rRes.data ?? [];
      });
    } catch (_) {}
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.success),
    );
  }

  List<dynamic> get _filteredEmployees {
    if (_searchQuery.trim().isEmpty) return _employees;
    final q = _searchQuery.trim().toLowerCase();
    return _employees.where((emp) {
      final name = (emp['full_name'] ?? '').toString().toLowerCase();
      final code = (emp['employee_code'] ?? '').toString().toLowerCase();
      final email = (emp['email'] ?? '').toString().toLowerCase();
      final dept = (emp['department_name'] ?? '').toString().toLowerCase();
      final pos = (emp['position_title'] ?? '').toString().toLowerCase();
      return name.contains(q) || code.contains(q) || email.contains(q) || dept.contains(q) || pos.contains(q);
    }).toList();
  }

  // --- 1. ADD EMPLOYEE DIALOG ---
  void _showAddEmployeeDialog() {
    final fnController = TextEditingController();
    final lnController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final codeController = TextEditingController();
    final pwController = TextEditingController();

    String? selectedDept = _departments.isNotEmpty ? _departments.first['id']?.toString() : null;
    String? selectedPos = _positions.isNotEmpty ? _positions.first['id']?.toString() : null;
    String? selectedRole = _roles.isNotEmpty ? _roles.first['id']?.toString() : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Add New Employee'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: fnController,
                  decoration: const InputDecoration(labelText: 'First Name *', prefixIcon: Icon(Icons.badge)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: lnController,
                  decoration: const InputDecoration(labelText: 'Last Name *', prefixIcon: Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address *', prefixIcon: Icon(Icons.email)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Custom Employee ID (Optional)',
                    hintText: 'e.g. PBE000009 (auto-generated if empty)',
                    prefixIcon: Icon(Icons.fingerprint),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pwController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Initial Password (Optional)',
                    hintText: 'Set password or leave blank for auto',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 14),
                if (_departments.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedDept,
                    decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business)),
                    items: _departments.map((d) => DropdownMenuItem<String>(
                      value: d['id'].toString(),
                      child: Text(d['name'].toString()),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedDept = val),
                  ),
                const SizedBox(height: 10),
                if (_positions.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedPos,
                    decoration: const InputDecoration(labelText: 'Position / Job Title', prefixIcon: Icon(Icons.work)),
                    items: _positions.map((p) => DropdownMenuItem<String>(
                      value: p['id'].toString(),
                      child: Text(p['title'].toString()),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedPos = val),
                  ),
                const SizedBox(height: 10),
                if (_roles.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'System Security Role', prefixIcon: Icon(Icons.admin_panel_settings)),
                    items: _roles.map((r) => DropdownMenuItem<String>(
                      value: r['id'].toString(),
                      child: Text(r['name'].toString()),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedRole = val),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              onPressed: () async {
                if (fnController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
                  _showErrorSnackBar('First name and email are required.');
                  return;
                }
                try {
                  final payload = {
                    'first_name': fnController.text.trim(),
                    'last_name': lnController.text.trim(),
                    'email': emailController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'department_id': selectedDept,
                    'position_id': selectedPos,
                    'role_id': selectedRole,
                  };
                  if (codeController.text.trim().isNotEmpty) {
                    payload['employee_code'] = codeController.text.trim().toUpperCase();
                  }
                  if (pwController.text.trim().isNotEmpty) {
                    payload['password'] = pwController.text.trim();
                  }

                  await _api.dio.post('/employees/', data: payload);
                  Navigator.pop(ctx);
                  _fetchEmployees();
                  _showSuccessSnackBar('Employee created & credentials provisioned successfully!');
                } catch (e) {
                  String errMsg = 'Failed to create employee.';
                  if (e is DioException && e.response?.data != null) {
                    errMsg = e.response!.data.toString();
                  }
                  _showErrorSnackBar(errMsg);
                }
              },
              label: const Text('Create & Provision'),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. EDIT EMPLOYEE DIALOG ---
  void _showEditEmployeeDialog(Map<String, dynamic> emp) {
    final fnController = TextEditingController(text: emp['first_name'] ?? '');
    final lnController = TextEditingController(text: emp['last_name'] ?? '');
    final emailController = TextEditingController(text: emp['email'] ?? '');
    final phoneController = TextEditingController(text: emp['phone'] ?? '');

    String? selectedDept = emp['department']?.toString();
    String? selectedPos = emp['position']?.toString();
    String? selectedRole = emp['role']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit ${emp['full_name'] ?? 'Employee'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fnController,
                  decoration: const InputDecoration(labelText: 'First Name', prefixIcon: Icon(Icons.badge)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: lnController,
                  decoration: const InputDecoration(labelText: 'Last Name', prefixIcon: Icon(Icons.badge_outlined)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Company Email', prefixIcon: Icon(Icons.email)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                ),
                const SizedBox(height: 12),
                if (_departments.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedDept,
                    decoration: const InputDecoration(labelText: 'Department', prefixIcon: Icon(Icons.business)),
                    items: _departments.map((d) => DropdownMenuItem<String>(
                      value: d['id'].toString(),
                      child: Text(d['name'].toString()),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedDept = val),
                  ),
                const SizedBox(height: 10),
                if (_positions.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedPos,
                    decoration: const InputDecoration(labelText: 'Position', prefixIcon: Icon(Icons.work)),
                    items: _positions.map((p) => DropdownMenuItem<String>(
                      value: p['id'].toString(),
                      child: Text(p['title'].toString()),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedPos = val),
                  ),
                const SizedBox(height: 10),
                if (_roles.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'System Role', prefixIcon: Icon(Icons.admin_panel_settings)),
                    items: _roles.map((r) => DropdownMenuItem<String>(
                      value: r['id'].toString(),
                      child: Text(r['name'].toString()),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedRole = val),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              onPressed: () async {
                try {
                  await _api.dio.patch('/employees/${emp['id']}/', data: {
                    'first_name': fnController.text.trim(),
                    'last_name': lnController.text.trim(),
                    'email': emailController.text.trim(),
                    'phone': phoneController.text.trim(),
                    if (selectedDept != null) 'department_id': selectedDept,
                    if (selectedPos != null) 'position_id': selectedPos,
                    if (selectedRole != null) 'role_id': selectedRole,
                  });
                  Navigator.pop(ctx);
                  _fetchEmployees();
                  _showSuccessSnackBar('Employee profile updated successfully!');
                } catch (e) {
                  _showErrorSnackBar('Update failed: ${e.toString()}');
                }
              },
              label: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. RESET PASSWORD DIALOG ---
  void _showResetPasswordDialog(Map<String, dynamic> emp) {
    final pwController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.key, color: AppTheme.warning),
              const SizedBox(width: 8),
              Text('Reset Password'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set a new login password for:\n${emp['full_name']} (${emp['employee_code']})',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pwController,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'New Password *',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                  hintText: 'Minimum 8 characters',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: All active user sessions will be invalidated immediately.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
              onPressed: () async {
                final pw = pwController.text.trim();
                if (pw.length < 8) {
                  _showErrorSnackBar('Password must be at least 8 characters long.');
                  return;
                }
                try {
                  await _api.dio.post('/employees/${emp['id']}/reset-password/', data: {
                    'new_password': pw,
                  });
                  Navigator.pop(ctx);
                  _showSuccessSnackBar('Password for ${emp['employee_code']} reset successfully!');
                } catch (e) {
                  _showErrorSnackBar('Password reset failed: ${e.toString()}');
                }
              },
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. CHANGE STATUS DIALOG ---
  void _showChangeStatusDialog(Map<String, dynamic> emp) {
    String currentStatus = emp['status'] ?? 'ACTIVE';
    String selectedStatus = currentStatus;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Change Account Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Employee: ${emp['full_name']} (${emp['employee_code']})'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE (Full Access)')),
                  DropdownMenuItem(value: 'SUSPENDED', child: Text('SUSPENDED (Temporary Lock)')),
                  DropdownMenuItem(value: 'DEACTIVATED', child: Text('DEACTIVATED (Terminated)')),
                ],
                onChanged: (val) => setDialogState(() => selectedStatus = val!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason for status change'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _api.dio.post('/employees/${emp['id']}/change-status/', data: {
                    'status': selectedStatus,
                    'reason': reasonController.text.trim(),
                  });
                  Navigator.pop(ctx);
                  _fetchEmployees();
                  _showSuccessSnackBar('Account status updated to $selectedStatus');
                } catch (e) {
                  _showErrorSnackBar('Status change failed: ${e.toString()}');
                }
              },
              child: const Text('Update Status'),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. DELETE EMPLOYEE CONFIRMATION ---
  void _showDeleteEmployeeDialog(Map<String, dynamic> emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 28),
            SizedBox(width: 8),
            Text('Delete Employee'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete:\n\n'
          '• ${emp['full_name']}\n'
          '• ID: ${emp['employee_code']}\n'
          '• Email: ${emp['email']}\n\n'
          'This will permanently delete their account, permissions, and attendance logs.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              try {
                await _api.dio.delete('/employees/${emp['id']}/');
                Navigator.pop(ctx);
                _fetchEmployees();
                _showSuccessSnackBar('Employee ${emp['employee_code']} deleted permanently.');
              } catch (e) {
                _showErrorSnackBar('Deletion failed: ${e.toString()}');
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEmployees;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.apartment),
            tooltip: 'Departments, Positions & Roles',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrganizationManagementScreen()),
              );
              _fetchMetadata();
              _fetchEmployees();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: _fetchEmployees,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEmployeeDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
      body: Column(
        children: [
          // Search box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, ID, email, position...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Count banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} Employee${filtered.length == 1 ? '' : 's'} Found',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
                Text(
                  'Total in system: ${_employees.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          // Main list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty ? 'No employees provisioned yet.' : 'No matching employees found.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchEmployees,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final emp = filtered[idx];
                            final code = emp['employee_code'] ?? 'PBE000000';
                            final name = emp['full_name'] ?? 'Employee';
                            final pos = emp['position_title'] ?? 'Role';
                            final dept = emp['department_name'] ?? 'Department';
                            final email = emp['email'] ?? '';
                            final status = emp['status'] ?? 'ACTIVE';

                            Color statusBg = Colors.green.shade50;
                            Color statusColor = AppTheme.success;
                            if (status == 'DEACTIVATED') {
                              statusBg = Colors.red.shade50;
                              statusColor = AppTheme.error;
                            } else if (status == 'SUSPENDED') {
                              statusBg = Colors.amber.shade50;
                              statusColor = AppTheme.warning;
                            }

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                                    child: Text(
                                      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'E',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusBg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        '$code • $pos',
                                        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.neutralDark),
                                      ),
                                      Text(
                                        '$dept • $email',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (action) {
                                      if (action == 'edit') {
                                        _showEditEmployeeDialog(emp);
                                      } else if (action == 'reset_pw') {
                                        _showResetPasswordDialog(emp);
                                      } else if (action == 'status') {
                                        _showChangeStatusDialog(emp);
                                      } else if (action == 'delete') {
                                        _showDeleteEmployeeDialog(emp);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20, color: AppTheme.primary),
                                            SizedBox(width: 8),
                                            Text('Edit Details'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'reset_pw',
                                        child: Row(
                                          children: [
                                            Icon(Icons.lock_reset, size: 20, color: AppTheme.warning),
                                            SizedBox(width: 8),
                                            Text('Reset Password'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'status',
                                        child: Row(
                                          children: [
                                            Icon(Icons.swap_horiz, size: 20, color: Colors.indigo),
                                            SizedBox(width: 8),
                                            Text('Change Status'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_forever, size: 20, color: AppTheme.error),
                                            SizedBox(width: 8),
                                            Text('Delete Employee', style: TextStyle(color: AppTheme.error)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
