import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class OrganizationManagementScreen extends StatefulWidget {
  const OrganizationManagementScreen({super.key});

  @override
  State<OrganizationManagementScreen> createState() => _OrganizationManagementScreenState();
}

class _OrganizationManagementScreenState extends State<OrganizationManagementScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;

  bool _isLoading = true;
  List<dynamic> _departments = [];
  List<dynamic> _positions = [];
  List<dynamic> _roles = [];
  List<dynamic> _permissions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        _api.dio.get('/organization/departments/'),
        _api.dio.get('/organization/positions/'),
        _api.dio.get('/organization/roles/'),
        _api.dio.get('/organization/permissions/'),
      ]);

      setState(() {
        _departments = responses[0].data['results'] ?? responses[0].data ?? [];
        _positions = responses[1].data['results'] ?? responses[1].data ?? [];
        _roles = responses[2].data['results'] ?? responses[2].data ?? [];
        _permissions = responses[3].data['results'] ?? responses[3].data ?? [];
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load organization data: ${e.toString()}');
    }
    setState(() => _isLoading = false);
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

  // ==========================================
  // 1. DEPARTMENT ACTIONS & DIALOGS
  // ==========================================
  void _showAddDepartmentDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.business, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Create Department'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Department Name *',
                    hintText: 'e.g. Human Resources',
                    prefixIcon: Icon(Icons.apartment),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Department Code *',
                    hintText: 'e.g. HR or SALES',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Scope and function of the department',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Department Active'),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) {
                  _showErrorSnackBar('Department name and code are required.');
                  return;
                }
                try {
                  await _api.dio.post('/organization/departments/', data: {
                    'name': nameCtrl.text.trim(),
                    'code': codeCtrl.text.trim().toUpperCase(),
                    'description': descCtrl.text.trim(),
                    'is_active': isActive,
                  });
                  Navigator.pop(ctx);
                  _fetchAllData();
                  _showSuccessSnackBar('Department "${nameCtrl.text.trim()}" created successfully!');
                } catch (e) {
                  String msg = 'Failed to create department.';
                  if (e is DioException && e.response?.data != null) {
                    msg = e.response!.data.toString();
                  }
                  _showErrorSnackBar(msg);
                }
              },
              label: const Text('Create Department'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDepartmentDialog(Map<String, dynamic> dept) {
    final nameCtrl = TextEditingController(text: dept['name'] ?? '');
    final codeCtrl = TextEditingController(text: dept['code'] ?? '');
    final descCtrl = TextEditingController(text: dept['description'] ?? '');
    bool isActive = dept['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit ${dept['name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Department Name *', prefixIcon: Icon(Icons.apartment)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Department Code *', prefixIcon: Icon(Icons.tag)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes)),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Department Active'),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val),
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
                  await _api.dio.patch('/organization/departments/${dept['id']}/', data: {
                    'name': nameCtrl.text.trim(),
                    'code': codeCtrl.text.trim().toUpperCase(),
                    'description': descCtrl.text.trim(),
                    'is_active': isActive,
                  });
                  Navigator.pop(ctx);
                  _fetchAllData();
                  _showSuccessSnackBar('Department updated successfully!');
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

  void _showDeleteDepartmentDialog(Map<String, dynamic> dept) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error),
            SizedBox(width: 8),
            Text('Delete Department'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete department:\n\n'
          '• ${dept['name']} (${dept['code']})\n\n'
          'Note: Departments with assigned employees cannot be deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              try {
                await _api.dio.delete('/organization/departments/${dept['id']}/');
                Navigator.pop(ctx);
                _fetchAllData();
                _showSuccessSnackBar('Department deleted successfully.');
              } catch (e) {
                String msg = 'Deletion failed.';
                if (e is DioException && e.response?.data != null) {
                  msg = e.response!.data['error'] ?? e.response!.data.toString();
                }
                _showErrorSnackBar(msg);
              }
            },
            child: const Text('Delete Department', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. POSITION ACTIONS & DIALOGS
  // ==========================================
  void _showAddPositionDialog() {
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedDept = _departments.isNotEmpty ? _departments.first['id']?.toString() : null;
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.work, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Create Position'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_departments.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedDept,
                    decoration: const InputDecoration(labelText: 'Department *', prefixIcon: Icon(Icons.business)),
                    items: _departments.map((d) => DropdownMenuItem<String>(
                      value: d['id'].toString(),
                      child: Text(d['name'].toString()),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedDept = val),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Position Title *',
                    hintText: 'e.g. Senior Software Engineer',
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Position Code (Optional)',
                    hintText: 'e.g. IT_SR_DEV',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Job Description',
                    hintText: 'Roles and responsibilities',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Position Active'),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || selectedDept == null) {
                  _showErrorSnackBar('Position title and department are required.');
                  return;
                }
                try {
                  await _api.dio.post('/organization/positions/', data: {
                    'department': selectedDept,
                    'title': titleCtrl.text.trim(),
                    'code': codeCtrl.text.trim().toUpperCase(),
                    'description': descCtrl.text.trim(),
                    'is_active': isActive,
                  });
                  Navigator.pop(ctx);
                  _fetchAllData();
                  _showSuccessSnackBar('Position "${titleCtrl.text.trim()}" created successfully!');
                } catch (e) {
                  String msg = 'Failed to create position.';
                  if (e is DioException && e.response?.data != null) {
                    msg = e.response!.data.toString();
                  }
                  _showErrorSnackBar(msg);
                }
              },
              label: const Text('Create Position'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPositionDialog(Map<String, dynamic> pos) {
    final titleCtrl = TextEditingController(text: pos['title'] ?? '');
    final codeCtrl = TextEditingController(text: pos['code'] ?? '');
    final descCtrl = TextEditingController(text: pos['description'] ?? '');
    String? selectedDept = pos['department']?.toString();
    bool isActive = pos['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit ${pos['title']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_departments.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: selectedDept,
                    decoration: const InputDecoration(labelText: 'Department *', prefixIcon: Icon(Icons.business)),
                    items: _departments.map((d) => DropdownMenuItem<String>(
                      value: d['id'].toString(),
                      child: Text(d['name'].toString()),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedDept = val),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Position Title *', prefixIcon: Icon(Icons.badge)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Position Code', prefixIcon: Icon(Icons.tag)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Job Description', prefixIcon: Icon(Icons.notes)),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Position Active'),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val),
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
                  await _api.dio.patch('/organization/positions/${pos['id']}/', data: {
                    'department': selectedDept,
                    'title': titleCtrl.text.trim(),
                    'code': codeCtrl.text.trim().toUpperCase(),
                    'description': descCtrl.text.trim(),
                    'is_active': isActive,
                  });
                  Navigator.pop(ctx);
                  _fetchAllData();
                  _showSuccessSnackBar('Position updated successfully!');
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

  void _showDeletePositionDialog(Map<String, dynamic> pos) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error),
            SizedBox(width: 8),
            Text('Delete Position'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete position:\n\n'
          '• ${pos['title']} (${pos['department_name']})\n\n'
          'Note: Positions currently held by employees cannot be deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              try {
                await _api.dio.delete('/organization/positions/${pos['id']}/');
                Navigator.pop(ctx);
                _fetchAllData();
                _showSuccessSnackBar('Position deleted successfully.');
              } catch (e) {
                String msg = 'Deletion failed.';
                if (e is DioException && e.response?.data != null) {
                  msg = e.response!.data['error'] ?? e.response!.data.toString();
                }
                _showErrorSnackBar(msg);
              }
            },
            child: const Text('Delete Position', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. ROLE & PERMISSIONS ACTIONS & DIALOGS
  // ==========================================
  void _showAddRoleDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final Set<String> selectedPermIds = {};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Create System Role'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Role Display Name *',
                      hintText: 'e.g. HR Talent Specialist',
                      prefixIcon: Icon(Icons.shield),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Role Code *',
                      hintText: 'e.g. HR_SPECIALIST or SALES_LEAD',
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Role Scope Description',
                      hintText: 'Access privileges and scope for this role',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Assign Permissions:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _permissions.length,
                      itemBuilder: (context, idx) {
                        final p = _permissions[idx];
                        final pId = p['id'].toString();
                        final isSelected = selectedPermIds.contains(pId);
                        return CheckboxListTile(
                          dense: true,
                          title: Text(p['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('[${p['category']}] ${p['code']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          value: isSelected,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedPermIds.add(pId);
                              } else {
                                selectedPermIds.remove(pId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) {
                  _showErrorSnackBar('Role name and code are required.');
                  return;
                }
                try {
                  await _api.dio.post('/organization/roles/', data: {
                    'name': nameCtrl.text.trim(),
                    'code': codeCtrl.text.trim().toUpperCase(),
                    'description': descCtrl.text.trim(),
                    'permission_ids': selectedPermIds.toList(),
                  });
                  Navigator.pop(ctx);
                  _fetchAllData();
                  _showSuccessSnackBar('Role "${nameCtrl.text.trim()}" created successfully!');
                } catch (e) {
                  String msg = 'Failed to create role.';
                  if (e is DioException && e.response?.data != null) {
                    msg = e.response!.data.toString();
                  }
                  _showErrorSnackBar(msg);
                }
              },
              label: const Text('Create Role'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoleDialog(Map<String, dynamic> role) {
    final nameCtrl = TextEditingController(text: role['name'] ?? '');
    final descCtrl = TextEditingController(text: role['description'] ?? '');
    final existingPerms = (role['permissions'] as List<dynamic>?) ?? [];
    final Set<String> selectedPermIds = existingPerms.map((p) => p['id'].toString()).toSet();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Edit Role: ${role['name']}'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Role Display Name *', prefixIcon: Icon(Icons.shield)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.notes)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Manage Role Permissions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _permissions.length,
                      itemBuilder: (context, idx) {
                        final p = _permissions[idx];
                        final pId = p['id'].toString();
                        final isSelected = selectedPermIds.contains(pId);
                        return CheckboxListTile(
                          dense: true,
                          title: Text(p['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('[${p['category']}] ${p['code']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          value: isSelected,
                          onChanged: (val) {
                            setDialogState(() {
                              if (val == true) {
                                selectedPermIds.add(pId);
                              } else {
                                selectedPermIds.remove(pId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              onPressed: () async {
                try {
                  await _api.dio.patch('/organization/roles/${role['id']}/', data: {
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'permission_ids': selectedPermIds.toList(),
                  });
                  Navigator.pop(ctx);
                  _fetchAllData();
                  _showSuccessSnackBar('Role permissions updated successfully!');
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

  void _showDeleteRoleDialog(Map<String, dynamic> role) {
    if (role['is_system_reserved'] == true) {
      _showErrorSnackBar('System-reserved roles (e.g. Administrator) cannot be deleted.');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.error),
            SizedBox(width: 8),
            Text('Delete Role'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete role:\n\n'
          '• ${role['name']} (${role['code']})\n\n'
          'Note: Roles assigned to active employees cannot be deleted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              try {
                await _api.dio.delete('/organization/roles/${role['id']}/');
                Navigator.pop(ctx);
                _fetchAllData();
                _showSuccessSnackBar('Role deleted successfully.');
              } catch (e) {
                String msg = 'Deletion failed.';
                if (e is DioException && e.response?.data != null) {
                  msg = e.response!.data['error'] ?? e.response!.data.toString();
                }
                _showErrorSnackBar(msg);
              }
            },
            child: const Text('Delete Role', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB BUILDS
  // ==========================================
  Widget _buildDepartmentsTab() {
    if (_departments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No departments created yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _departments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final d = _departments[idx];
        final name = d['name'] ?? '';
        final code = d['code'] ?? '';
        final desc = d['description'] ?? 'No description provided';
        final posCount = d['position_count'] ?? 0;
        final empCount = d['employee_count'] ?? 0;
        final isActive = d['is_active'] ?? true;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        if (action == 'edit') {
                          _showEditDepartmentDialog(d);
                        } else if (action == 'delete') {
                          _showDeleteDepartmentDialog(d);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [Icon(Icons.edit, size: 18, color: AppTheme.primary), SizedBox(width: 8), Text('Edit')]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete, size: 18, color: AppTheme.error), SizedBox(width: 8), Text('Delete')]),
                        ),
                      ],
                    ),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Chip(
                      avatar: const Icon(Icons.work_outline, size: 16, color: Colors.blueGrey),
                      label: Text('$posCount Positions', style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey.shade100,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      avatar: const Icon(Icons.people_outline, size: 16, color: Colors.blueGrey),
                      label: Text('$empCount Employees', style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey.shade100,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? AppTheme.success : AppTheme.error,
                        ),
                      ),
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

  Widget _buildPositionsTab() {
    if (_positions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No positions created yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _positions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final p = _positions[idx];
        final title = p['title'] ?? '';
        final dept = p['department_name'] ?? 'Department';
        final code = p['code'] ?? '';
        final desc = p['description'] ?? '';
        final empCount = p['employee_count'] ?? 0;
        final isActive = p['is_active'] ?? true;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Dept: $dept ${code.isNotEmpty ? '• Code: $code' : ''}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        if (action == 'edit') {
                          _showEditPositionDialog(p);
                        } else if (action == 'delete') {
                          _showDeletePositionDialog(p);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [Icon(Icons.edit, size: 18, color: AppTheme.primary), SizedBox(width: 8), Text('Edit')]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [Icon(Icons.delete, size: 18, color: AppTheme.error), SizedBox(width: 8), Text('Delete')]),
                        ),
                      ],
                    ),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Chip(
                      avatar: const Icon(Icons.people_outline, size: 16, color: Colors.blueGrey),
                      label: Text('$empCount Employees', style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey.shade100,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'INACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? AppTheme.success : AppTheme.error,
                        ),
                      ),
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

  Widget _buildRolesTab() {
    if (_roles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No roles configured yet.', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _roles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final r = _roles[idx];
        final name = r['name'] ?? '';
        final code = r['code'] ?? '';
        final desc = r['description'] ?? '';
        final isReserved = r['is_system_reserved'] ?? false;
        final perms = (r['permissions'] as List<dynamic>?) ?? [];
        final empCount = r['employee_count'] ?? 0;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (isReserved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: const Text('SYSTEM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
                          ),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        if (action == 'edit') {
                          _showEditRoleDialog(r);
                        } else if (action == 'delete') {
                          _showDeleteRoleDialog(r);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [Icon(Icons.edit, size: 18, color: AppTheme.primary), SizedBox(width: 8), Text('Edit & Permissions')]),
                        ),
                        if (!isReserved)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(children: [Icon(Icons.delete, size: 18, color: AppTheme.error), SizedBox(width: 8), Text('Delete')]),
                          ),
                      ],
                    ),
                  ],
                ),
                Text('Code: $code', style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
                const SizedBox(height: 10),
                const Text('Permissions:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.neutralDark)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: perms.isEmpty
                      ? [const Text('No specific permissions assigned.', style: TextStyle(fontSize: 11, color: Colors.grey))]
                      : perms.take(6).map((p) => Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(p['name'] ?? '', style: const TextStyle(fontSize: 10)),
                            backgroundColor: Colors.blue.shade50,
                          )).toList(),
                ),
                if (perms.length > 6)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('+${perms.length - 6} more permissions', style: const TextStyle(fontSize: 11, color: AppTheme.primary)),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      avatar: const Icon(Icons.people_outline, size: 16, color: Colors.blueGrey),
                      label: Text('$empCount Employees with this role', style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey.shade100,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization & Roles'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: const Icon(Icons.business), text: 'Departments (${_departments.length})'),
            Tab(icon: const Icon(Icons.work), text: 'Positions (${_positions.length})'),
            Tab(icon: const Icon(Icons.admin_panel_settings), text: 'Roles (${_roles.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchAllData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final currentTab = _tabController.index;
          if (currentTab == 0) {
            _showAddDepartmentDialog();
          } else if (currentTab == 1) {
            _showAddPositionDialog();
          } else {
            _showAddRoleDialog();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(
          _tabController.index == 0
              ? 'New Department'
              : _tabController.index == 1
                  ? 'New Position'
                  : 'New Role',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAllData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDepartmentsTab(),
                  _buildPositionsTab(),
                  _buildRolesTab(),
                ],
              ),
            ),
    );
  }
}
