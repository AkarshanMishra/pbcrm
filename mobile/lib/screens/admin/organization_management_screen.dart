import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import 'employee_detail_screen.dart';
import 'add_employee_wizard_sheet.dart';
import '../hr/hr_recruitment_screen.dart';
import '../hr/hr_policies_screen.dart';
import '../hr/hr_performance_screen.dart';
import '../hr/hr_training_screen.dart';
import '../hr/onboarding_wizard_screen.dart';
import '../hr/hr_offboarding_screen.dart';
import '../hr/hr_attendance_screen.dart';

class OrganizationManagementScreen extends StatefulWidget {
  final int initialTabIndex;
  const OrganizationManagementScreen({super.key, this.initialTabIndex = 0});

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
  List<dynamic> _allEmployees = [];

  // Search & Filters
  String _deptSearchQuery = '';
  String _deptStatusFilter = 'ALL'; // 'ALL', 'ACTIVE', 'INACTIVE'
  String _posSearchQuery = '';
  String? _posDeptFilter;
  String _roleSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTabIndex);
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
        _api.dio.get('/employees/'),
      ]);

      if (mounted) {
        setState(() {
          _departments = responses[0].data['results'] ?? responses[0].data ?? [];
          _positions = responses[1].data['results'] ?? responses[1].data ?? [];
          _roles = responses[2].data['results'] ?? responses[2].data ?? [];
          _permissions = responses[3].data['results'] ?? responses[3].data ?? [];
          _allEmployees = responses[4].data['results'] ?? responses[4].data ?? [];
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load organization data: ${e.toString()}');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Color _getDeptColor(int index) {
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFEC4899), // Pink
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFF97316), // Orange
      const Color(0xFF6366F1), // Indigo
    ];
    return colors[index % colors.length];
  }

  // ===========================================================================
  // 1. DEPARTMENT CRUD & 360° COCKPIT
  // ===========================================================================

  void _showAddDepartmentDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.business_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Create New Department',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DEPARTMENT IDENTITY',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Department Name *',
                      hintText: 'e.g. Human Resources, IT Operations',
                      prefixIcon: const Icon(Icons.apartment_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    onChanged: (val) {
                      if (codeCtrl.text.isEmpty && val.isNotEmpty) {
                        final autoCode = val.trim().replaceAll(' ', '_').toUpperCase();
                        if (autoCode.length <= 8) {
                          codeCtrl.text = autoCode;
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Department Code *',
                      hintText: 'e.g. HR, IT_OPS, MKTG',
                      prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('SCOPE & FUNCTIONS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description & Responsibilities',
                      hintText: 'Briefly define the core mission and scope of this department',
                      prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Department Active', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Inactive departments cannot have new employees assigned', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    value: isActive,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
                  if (ctx.mounted) Navigator.pop(ctx);
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
              label: const Text('Create Department', style: TextStyle(fontWeight: FontWeight.bold)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.edit_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Edit Department: ${dept['name']}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Department Name *',
                      prefixIcon: const Icon(Icons.apartment_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Department Code *',
                      prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Department Active', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Inactive departments are hidden from employee selection', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    value: isActive,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                try {
                  await _api.dio.patch('/organization/departments/${dept['id']}/', data: {
                    'name': nameCtrl.text.trim(),
                    'code': codeCtrl.text.trim().toUpperCase(),
                    'description': descCtrl.text.trim(),
                    'is_active': isActive,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchAllData();
                  _showSuccessSnackBar('Department updated successfully!');
                } catch (e) {
                  _showErrorSnackBar('Update failed: ${e.toString()}');
                }
              },
              label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDepartmentDialog(Map<String, dynamic> dept) {
    final empCount = dept['employee_count'] ?? 0;
    final posCount = dept['position_count'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFEE2E2),
              child: Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
            ),
            SizedBox(width: 12),
            Text('Delete Department', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete department "${dept['name']}" (${dept['code']})?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (empCount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This department has $empCount active employee(s) and $posCount position(s). Reassign employees or deactivate the department instead of deleting.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          if (empCount > 0)
            ElevatedButton.icon(
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _showTransferEmployeesDialog(preselectedSourceDeptId: dept['id']?.toString());
              },
              label: const Text('Transfer Employees First'),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                try {
                  await _api.dio.delete('/organization/departments/${dept['id']}/');
                  if (ctx.mounted) Navigator.pop(ctx);
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
              child: const Text('Delete Permanently', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. 360° DEPARTMENT COCKPIT INSPECTOR (MODAL SHEET)
  // ===========================================================================
  void _openDepartmentCockpit(Map<String, dynamic> dept) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DepartmentCockpitModal(
        deptId: dept['id'].toString(),
        deptSummary: dept,
        allDepartments: _departments,
        onRefreshParent: _fetchAllData,
        onTransferRequested: (deptId) {
          Navigator.pop(ctx);
          _showTransferEmployeesDialog(preselectedSourceDeptId: deptId);
        },
        onAddPositionRequested: (deptId) {
          Navigator.pop(ctx);
          _showAddPositionDialog(preselectedDeptId: deptId);
        },
        onAddEmployeeRequested: () {
          Navigator.pop(ctx);
          _showAddEmployeeWizard();
        },
      ),
    );
  }

  void _showAddEmployeeWizard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddEmployeeWizardSheet(
        onEmployeeCreated: _fetchAllData,
      ),
    );
  }

  // ===========================================================================
  // 3. BULK EMPLOYEE TRANSFER ACROSS DEPARTMENTS
  // ===========================================================================
  void _showTransferEmployeesDialog({String? preselectedSourceDeptId}) {
    String? sourceDeptId = preselectedSourceDeptId ?? (_departments.isNotEmpty ? _departments.first['id']?.toString() : null);
    String? targetDeptId;
    String? targetPosId;
    final Set<String> selectedEmployeeIds = {};
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final eligibleEmployees = _allEmployees.where((e) {
            final deptId = e['department']?.toString() ?? e['department_id']?.toString();
            return deptId == sourceDeptId;
          }).toList();

          final targetDeptPositions = _positions.where((p) {
            final deptId = p['department']?.toString() ?? p['department_id']?.toString();
            return deptId == targetDeptId;
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.swap_horiz_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                SizedBox(width: 12),
                Text('Transfer Employees Between Departments', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SOURCE & DESTINATION',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: sourceDeptId,
                            decoration: InputDecoration(
                              labelText: 'From Department *',
                              prefixIcon: const Icon(Icons.apartment_rounded, color: Color(0xFF64748B)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            items: _departments.map((d) => DropdownMenuItem<String>(
                              value: d['id'].toString(),
                              child: Text(d['name'].toString(), overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                sourceDeptId = val;
                                selectedEmployeeIds.clear();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: targetDeptId,
                            decoration: InputDecoration(
                              labelText: 'To Department *',
                              prefixIcon: const Icon(Icons.login_rounded, color: Color(0xFF10B981)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                            ),
                            items: _departments.where((d) => d['id'].toString() != sourceDeptId).map((d) => DropdownMenuItem<String>(
                              value: d['id'].toString(),
                              child: Text(d['name'].toString(), overflow: TextOverflow.ellipsis),
                            )).toList(),
                            onChanged: (val) {
                              setDialogState(() {
                                targetDeptId = val;
                                targetPosId = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (targetDeptId != null && targetDeptPositions.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: targetPosId,
                        decoration: InputDecoration(
                          labelText: 'Assign New Position in Destination (Optional)',
                          prefixIcon: const Icon(Icons.business_center_rounded, color: Color(0xFF64748B)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                        ),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('Keep Existing / Unassigned')),
                          ...targetDeptPositions.map((p) => DropdownMenuItem<String>(
                            value: p['id'].toString(),
                            child: Text(p['title'].toString()),
                          )),
                        ],
                        onChanged: (val) => setDialogState(() => targetPosId = val),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SELECT EMPLOYEES (${selectedEmployeeIds.length}/${eligibleEmployees.length})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                        ),
                        if (eligibleEmployees.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                if (selectedEmployeeIds.length == eligibleEmployees.length) {
                                  selectedEmployeeIds.clear();
                                } else {
                                  selectedEmployeeIds.addAll(eligibleEmployees.map((e) => e['id'].toString()));
                                }
                              });
                            },
                            child: Text(selectedEmployeeIds.length == eligibleEmployees.length ? 'Deselect All' : 'Select All',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: eligibleEmployees.isEmpty
                          ? const Center(
                              child: Text('No employees found in this department', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                            )
                          : ListView.separated(
                              itemCount: eligibleEmployees.length,
                              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              itemBuilder: (context, idx) {
                                final emp = eligibleEmployees[idx];
                                final empId = emp['id'].toString();
                                final name = emp['name'] ?? emp['user']?['name'] ?? 'Employee';
                                final code = emp['employee_code'] ?? 'EMP#$idx';
                                final pos = emp['position_title'] ?? emp['position'] ?? 'Staff';
                                final isSelected = selectedEmployeeIds.contains(empId);

                                return CheckboxListTile(
                                  dense: true,
                                  value: isSelected,
                                  activeColor: const Color(0xFF2563EB),
                                  title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                  subtitle: Text('$code · $pos', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        selectedEmployeeIds.add(empId);
                                      } else {
                                        selectedEmployeeIds.remove(empId);
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
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton.icon(
                icon: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isSubmitting || selectedEmployeeIds.isEmpty || targetDeptId == null
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        try {
                          await _api.dio.post('/organization/departments/$sourceDeptId/transfer-employees/', data: {
                            'target_department_id': targetDeptId,
                            'target_position_id': targetPosId,
                            'employee_ids': selectedEmployeeIds.toList(),
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          _fetchAllData();
                          _showSuccessSnackBar('Transferred ${selectedEmployeeIds.length} employee(s) successfully!');
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          String msg = 'Transfer failed.';
                          if (e is DioException && e.response?.data != null) {
                            msg = e.response!.data['error'] ?? e.response!.data.toString();
                          }
                          _showErrorSnackBar(msg);
                        }
                      },
                label: Text(isSubmitting ? 'Transferring...' : 'Execute Transfer (${selectedEmployeeIds.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 4. POSITION CRUD
  // ===========================================================================
  void _showAddPositionDialog({String? preselectedDeptId}) {
    final titleCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedDept = preselectedDeptId ?? (_departments.isNotEmpty ? _departments.first['id']?.toString() : null);
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.business_center_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              SizedBox(width: 12),
              Text('Create Job Position', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_departments.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedDept,
                      decoration: InputDecoration(
                        labelText: 'Assign to Department *',
                        prefixIcon: const Icon(Icons.apartment_rounded, color: Color(0xFF64748B)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      items: _departments.map((d) => DropdownMenuItem<String>(
                        value: d['id'].toString(),
                        child: Text(d['name'].toString()),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedDept = val),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Position Title *',
                      hintText: 'e.g. Senior Software Architect, HR Manager',
                      prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Position Code (Optional)',
                      hintText: 'e.g. SR_DEV, HR_MGR',
                      prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Job Description / Responsibilities',
                      prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Position Active', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    value: isActive,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
                  if (ctx.mounted) Navigator.pop(ctx);
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
              label: const Text('Create Position', style: TextStyle(fontWeight: FontWeight.bold)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.edit_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Edit Position: ${pos['title']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_departments.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: selectedDept,
                      decoration: InputDecoration(
                        labelText: 'Department *',
                        prefixIcon: const Icon(Icons.apartment_rounded, color: Color(0xFF64748B)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      items: _departments.map((d) => DropdownMenuItem<String>(
                        value: d['id'].toString(),
                        child: Text(d['name'].toString()),
                      )).toList(),
                      onChanged: (val) => setDialogState(() => selectedDept = val),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Position Title *',
                      prefixIcon: const Icon(Icons.badge_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Position Code',
                      prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Job Description',
                      prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Position Active', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    value: isActive,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                try {
                  await _api.dio.patch('/organization/positions/${pos['id']}/', data: {
                    'department': selectedDept,
                    'title': titleCtrl.text.trim(),
                    'code': codeCtrl.text.trim().toUpperCase(),
                    'description': descCtrl.text.trim(),
                    'is_active': isActive,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchAllData();
                  _showSuccessSnackBar('Position updated successfully!');
                } catch (e) {
                  _showErrorSnackBar('Update failed: ${e.toString()}');
                }
              },
              label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFEE2E2),
              child: Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
            ),
            SizedBox(width: 12),
            Text('Delete Position', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete position "${pos['title']}"?\n\n'
          'Positions with assigned employees cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              try {
                await _api.dio.delete('/organization/positions/${pos['id']}/');
                if (ctx.mounted) Navigator.pop(ctx);
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
            child: const Text('Delete Position', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. ROLE & RBAC CRUD
  // ===========================================================================
  void _showAddRoleDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final Set<String> selectedPermIds = {};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.security_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              SizedBox(width: 12),
              Text('Create System Role', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Role Display Name *',
                      hintText: 'e.g. Senior HR Specialist',
                      prefixIcon: const Icon(Icons.shield_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Role Code *',
                      hintText: 'e.g. HR_SPECIALIST',
                      prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Role Scope & Responsibilities',
                      prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ASSIGN PERMISSIONS (${selectedPermIds.length}/${_permissions.length})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            if (selectedPermIds.length == _permissions.length) {
                              selectedPermIds.clear();
                            } else {
                              selectedPermIds.addAll(_permissions.map((p) => p['id'].toString()));
                            }
                          });
                        },
                        child: Text(selectedPermIds.length == _permissions.length ? 'Deselect All' : 'Select All',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: ListView.builder(
                      itemCount: _permissions.length,
                      itemBuilder: (context, idx) {
                        final p = _permissions[idx];
                        final pId = p['id'].toString();
                        final isSelected = selectedPermIds.contains(pId);
                        return CheckboxListTile(
                          dense: true,
                          activeColor: const Color(0xFF2563EB),
                          title: Text(p['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('[${p['category']}] ${p['code']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
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
                  if (ctx.mounted) Navigator.pop(ctx);
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
              label: const Text('Create Role', style: TextStyle(fontWeight: FontWeight.bold)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.edit_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Edit Role: ${role['name']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Role Display Name *',
                      prefixIcon: const Icon(Icons.shield_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      prefixIcon: const Icon(Icons.notes_rounded, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'MANAGE PERMISSIONS (${selectedPermIds.length}/${_permissions.length})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            if (selectedPermIds.length == _permissions.length) {
                              selectedPermIds.clear();
                            } else {
                              selectedPermIds.addAll(_permissions.map((p) => p['id'].toString()));
                            }
                          });
                        },
                        child: Text(selectedPermIds.length == _permissions.length ? 'Deselect All' : 'Select All',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: ListView.builder(
                      itemCount: _permissions.length,
                      itemBuilder: (context, idx) {
                        final p = _permissions[idx];
                        final pId = p['id'].toString();
                        final isSelected = selectedPermIds.contains(pId);
                        return CheckboxListTile(
                          dense: true,
                          activeColor: const Color(0xFF2563EB),
                          title: Text(p['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('[${p['category']}] ${p['code']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                try {
                  await _api.dio.patch('/organization/roles/${role['id']}/', data: {
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'permission_ids': selectedPermIds.toList(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchAllData();
                  _showSuccessSnackBar('Role updated successfully!');
                } catch (e) {
                  _showErrorSnackBar('Update failed: ${e.toString()}');
                }
              },
              label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFEE2E2),
              child: Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
            ),
            SizedBox(width: 12),
            Text('Delete Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete role "${role['name']}" (${role['code']})?\n\n'
          'Roles assigned to active employees cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              try {
                await _api.dio.delete('/organization/roles/${role['id']}/');
                if (ctx.mounted) Navigator.pop(ctx);
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
            child: const Text('Delete Role', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. MAIN UI BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final totalEmployees = _departments.fold<int>(0, (sum, d) => sum + ((d['employee_count'] as int?) ?? 0));
    final totalPositions = _positions.length;
    final totalDepts = _departments.length;
    final activeDepts = _departments.where((d) => d['is_active'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Organization & HR Control Center',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            Text(
              'Departments, Positions, RBAC Matrix & Workforce Towers',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Refresh Data',
            onPressed: _fetchAllData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Quick Add',
            onSelected: (val) {
              if (val == 'dept') _showAddDepartmentDialog();
              if (val == 'pos') _showAddPositionDialog();
              if (val == 'role') _showAddRoleDialog();
              if (val == 'transfer') _showTransferEmployeesDialog();
              if (val == 'employee') _showAddEmployeeWizard();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'dept',
                child: Row(children: [Icon(Icons.apartment_rounded, size: 18, color: Color(0xFF2563EB)), SizedBox(width: 8), Text('New Department')]),
              ),
              const PopupMenuItem(
                value: 'pos',
                child: Row(children: [Icon(Icons.business_center_rounded, size: 18, color: Color(0xFF10B981)), SizedBox(width: 8), Text('New Position')]),
              ),
              const PopupMenuItem(
                value: 'role',
                child: Row(children: [Icon(Icons.security_rounded, size: 18, color: Color(0xFF8B5CF6)), SizedBox(width: 8), Text('New Role & RBAC')]),
              ),
              const PopupMenuItem(
                value: 'transfer',
                child: Row(children: [Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFFF59E0B)), SizedBox(width: 8), Text('Transfer Employees')]),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'employee',
                child: Row(children: [Icon(Icons.person_add_rounded, size: 18, color: Color(0xFFEC4899)), SizedBox(width: 8), Text('Add Employee (Wizard)')]),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2563EB),
              indicatorWeight: 3,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.apartment_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Departments ($totalDepts)'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.business_center_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Positions ($totalPositions)'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.security_rounded, size: 16),
                      const SizedBox(width: 6),
                      Text('Roles & RBAC (${_roles.length})'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hub_rounded, size: 16),
                      SizedBox(width: 6),
                      Text('HR Command Hub'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : Column(
              children: [
                // Top Quick KPI Summary Cards
                _buildKPISummaryHeader(totalDepts, activeDepts, totalPositions, totalEmployees),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDepartmentsTab(),
                      _buildPositionsTab(),
                      _buildRolesTab(),
                      _buildHRHubTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // ===========================================================================
  // KPI METRICS HEADER
  // ===========================================================================
  Widget _buildKPISummaryHeader(int totalDepts, int activeDepts, int totalPos, int totalEmp) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          _buildMetricPill(
            label: 'Departments',
            value: '$activeDepts / $totalDepts',
            icon: Icons.apartment_rounded,
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 12),
          _buildMetricPill(
            label: 'Job Positions',
            value: '$totalPos',
            icon: Icons.business_center_rounded,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(width: 12),
          _buildMetricPill(
            label: 'Total Workforce',
            value: '$totalEmp',
            icon: Icons.groups_rounded,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _showTransferEmployeesDialog(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swap_horiz_rounded, color: Color(0xFF2563EB), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Bulk Staff Transfer',
                      style: TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: DEPARTMENTS DIRECTORY & 360° MANAGEMENT
  // ===========================================================================
  Widget _buildDepartmentsTab() {
    final filtered = _departments.where((d) {
      final name = (d['name'] ?? '').toString().toLowerCase();
      final code = (d['code'] ?? '').toString().toLowerCase();
      final desc = (d['description'] ?? '').toString().toLowerCase();
      final matchesSearch = _deptSearchQuery.isEmpty ||
          name.contains(_deptSearchQuery.toLowerCase()) ||
          code.contains(_deptSearchQuery.toLowerCase()) ||
          desc.contains(_deptSearchQuery.toLowerCase());

      final isActive = d['is_active'] ?? true;
      final matchesStatus = _deptStatusFilter == 'ALL' ||
          (_deptStatusFilter == 'ACTIVE' && isActive) ||
          (_deptStatusFilter == 'INACTIVE' && !isActive);

      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      children: [
        // Search & Filter Toolbar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search department by name, code, or description...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                    suffixIcon: _deptSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _deptSearchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _deptSearchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ALL', label: Text('All')),
                  ButtonSegment(value: 'ACTIVE', label: Text('Active')),
                  ButtonSegment(value: 'INACTIVE', label: Text('Inactive')),
                ],
                selected: {_deptStatusFilter},
                onSelectionChanged: (val) => setState(() => _deptStatusFilter = val.first),
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showAddDepartmentDialog,
                label: const Text('Add Department', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // Department Cards Grid / List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apartment_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('No departments matching criteria.', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded),
                        onPressed: _showAddDepartmentDialog,
                        label: const Text('Create First Department'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final d = filtered[idx];
                    final name = d['name'] ?? '';
                    final code = d['code'] ?? '';
                    final desc = d['description'] ?? 'No scope or description specified.';
                    final posCount = d['position_count'] ?? 0;
                    final empCount = d['employee_count'] ?? 0;
                    final activeEmpCount = d['active_employee_count'] ?? empCount;
                    final openJobsCount = d['open_jobs_count'] ?? 0;
                    final isActive = d['is_active'] ?? true;
                    final deptColor = _getDeptColor(idx);

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openDepartmentCockpit(d),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Department Badge
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: deptColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: deptColor.withValues(alpha: 0.3)),
                                    ),
                                    child: Center(
                                      child: Icon(Icons.apartment_rounded, color: deptColor, size: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Name and Code
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 16.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                              ),
                                              child: Text(
                                                code,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                  color: Color(0xFF334155),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          desc,
                                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Status Indicator & Action Menu
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isActive ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                                      ),
                                    ),
                                    child: Text(
                                      isActive ? 'ACTIVE' : 'INACTIVE',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        color: isActive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                                    onSelected: (action) {
                                      if (action == 'cockpit') _openDepartmentCockpit(d);
                                      if (action == 'edit') _showEditDepartmentDialog(d);
                                      if (action == 'add_pos') _showAddPositionDialog(preselectedDeptId: d['id'].toString());
                                      if (action == 'transfer') _showTransferEmployeesDialog(preselectedSourceDeptId: d['id'].toString());
                                      if (action == 'delete') _showDeleteDepartmentDialog(d);
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'cockpit',
                                        child: Row(children: [Icon(Icons.visibility_rounded, size: 18, color: Color(0xFF2563EB)), SizedBox(width: 8), Text('Inspect 360° Cockpit')]),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(children: [Icon(Icons.edit_rounded, size: 18, color: Color(0xFF334155)), SizedBox(width: 8), Text('Edit Department')]),
                                      ),
                                      const PopupMenuItem(
                                        value: 'add_pos',
                                        child: Row(children: [Icon(Icons.add_circle_outline_rounded, size: 18, color: Color(0xFF10B981)), SizedBox(width: 8), Text('Add Position to Dept')]),
                                      ),
                                      const PopupMenuItem(
                                        value: 'transfer',
                                        child: Row(children: [Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFFF59E0B)), SizedBox(width: 8), Text('Transfer Staff Out')]),
                                      ),
                                      const PopupMenuDivider(),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(children: [Icon(Icons.delete_forever_rounded, size: 18, color: Color(0xFFEF4444)), SizedBox(width: 8), Text('Delete Department')]),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 12),

                              // Bottom Metrics Chips & Quick Cockpit Action
                              Row(
                                children: [
                                  _buildDeptPill(
                                    icon: Icons.business_center_rounded,
                                    label: '$posCount Positions',
                                    color: const Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildDeptPill(
                                    icon: Icons.groups_rounded,
                                    label: '$activeEmpCount / $empCount Staff',
                                    color: const Color(0xFF10B981),
                                  ),
                                  if (openJobsCount > 0) ...[
                                    const SizedBox(width: 8),
                                    _buildDeptPill(
                                      icon: Icons.work_outline_rounded,
                                      label: '$openJobsCount Open Requisitions',
                                      color: const Color(0xFFEC4899),
                                    ),
                                  ],
                                  const Spacer(),
                                  TextButton.icon(
                                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                    onPressed: () => _openDepartmentCockpit(d),
                                    label: const Text('Open Cockpit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDeptPill({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: POSITIONS & JOB ROLES DIRECTORY
  // ===========================================================================
  Widget _buildPositionsTab() {
    final filtered = _positions.where((p) {
      final title = (p['title'] ?? '').toString().toLowerCase();
      final code = (p['code'] ?? '').toString().toLowerCase();
      final deptName = (p['department_name'] ?? '').toString().toLowerCase();
      final deptId = p['department']?.toString() ?? p['department_id']?.toString();

      final matchesSearch = _posSearchQuery.isEmpty ||
          title.contains(_posSearchQuery.toLowerCase()) ||
          code.contains(_posSearchQuery.toLowerCase()) ||
          deptName.contains(_posSearchQuery.toLowerCase());

      final matchesDept = _posDeptFilter == null || deptId == _posDeptFilter;

      return matchesSearch && matchesDept;
    }).toList();

    return Column(
      children: [
        // Search and Department Filter Toolbar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search position title, code, or department...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                    suffixIcon: _posSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _posSearchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _posSearchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String?>(
                  value: _posDeptFilter,
                  decoration: InputDecoration(
                    labelText: 'Filter by Department',
                    prefixIcon: const Icon(Icons.filter_list_rounded, color: Color(0xFF64748B)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('All Departments')),
                    ..._departments.map((d) => DropdownMenuItem<String?>(
                      value: d['id'].toString(),
                      child: Text(d['name'].toString(), overflow: TextOverflow.ellipsis),
                    )),
                  ],
                  onChanged: (val) => setState(() => _posDeptFilter = val),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showAddPositionDialog,
                label: const Text('Add Position', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // Positions List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_center_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('No positions matching criteria.', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded),
                        onPressed: _showAddPositionDialog,
                        label: const Text('Create First Position'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final p = filtered[idx];
                    final title = p['title'] ?? '';
                    final dept = p['department_name'] ?? 'Department';
                    final code = p['code'] ?? '';
                    final desc = p['description'] ?? '';
                    final empCount = p['employee_count'] ?? 0;
                    final isActive = p['is_active'] ?? true;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: Color(0xFFEFF6FF),
                              child: Icon(Icons.business_center_rounded, color: Color(0xFF2563EB), size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      if (code.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                          child: Text(code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.apartment_rounded, size: 14, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Text(dept, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5, fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.groups_rounded, size: 14, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text('$empCount Staff Holding', style: const TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  if (desc.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(desc, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isActive ? 'ACTIVE' : 'INACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                              onSelected: (action) {
                                if (action == 'edit') _showEditPositionDialog(p);
                                if (action == 'delete') _showDeletePositionDialog(p);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [Icon(Icons.edit_rounded, size: 18, color: Color(0xFF2563EB)), SizedBox(width: 8), Text('Edit Position')]),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)), SizedBox(width: 8), Text('Delete Position')]),
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

  // ===========================================================================
  // TAB 3: ROLES & RBAC MATRIX
  // ===========================================================================
  Widget _buildRolesTab() {
    final filtered = _roles.where((r) {
      final name = (r['name'] ?? '').toString().toLowerCase();
      final code = (r['code'] ?? '').toString().toLowerCase();
      final desc = (r['description'] ?? '').toString().toLowerCase();
      return _roleSearchQuery.isEmpty ||
          name.contains(_roleSearchQuery.toLowerCase()) ||
          code.contains(_roleSearchQuery.toLowerCase()) ||
          desc.contains(_roleSearchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search roles by title, code, or description...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                    suffixIcon: _roleSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () => setState(() => _roleSearchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (val) => setState(() => _roleSearchQuery = val),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_moderator_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showAddRoleDialog,
                label: const Text('Add Role', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // Roles List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final r = filtered[idx];
              final name = r['name'] ?? '';
              final code = r['code'] ?? '';
              final desc = r['description'] ?? '';
              final perms = (r['permissions'] as List<dynamic>?) ?? [];
              final empCount = r['employee_count'] ?? 0;
              final isReserved = r['is_system_reserved'] ?? false;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                color: Colors.white,
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
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: isReserved ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                                child: Icon(
                                  isReserved ? Icons.lock_rounded : Icons.shield_rounded,
                                  color: isReserved ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                                        child: Text(code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                      ),
                                    ],
                                  ),
                                  if (isReserved)
                                    const Text('SYSTEM RESERVED ROLE', style: TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B)),
                            onSelected: (action) {
                              if (action == 'edit') _showEditRoleDialog(r);
                              if (action == 'delete') _showDeleteRoleDialog(r);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(children: [Icon(Icons.edit_rounded, size: 18, color: Color(0xFF2563EB)), SizedBox(width: 8), Text('Edit Permissions')]),
                              ),
                              if (!isReserved)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)), SizedBox(width: 8), Text('Delete Role')]),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(desc, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Chip(
                            avatar: const Icon(Icons.lock_open_rounded, size: 14, color: Color(0xFF2563EB)),
                            label: Text('${perms.length} Permissions', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            backgroundColor: const Color(0xFFEFF6FF),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            avatar: const Icon(Icons.people_outline_rounded, size: 14, color: Color(0xFF10B981)),
                            label: Text('$empCount Assigned Staff', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            backgroundColor: const Color(0xFFECFDF5),
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

  // ===========================================================================
  // TAB 4: HR OPERATIONS HUB
  // ===========================================================================
  Widget _buildHRHubTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workforce & HR Operations Command',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Direct access to all specialized HR modules and workflow engines',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildHRActionCard(
                title: 'Recruitment & Jobs',
                subtitle: 'Manage job postings, applicant pipeline, and candidate stages',
                icon: Icons.work_outline_rounded,
                color: const Color(0xFFEC4899),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRRecruitmentScreen())),
              ),
              _buildHRActionCard(
                title: 'Onboarding Wizard',
                subtitle: '8-step employee provisioning and document verification flow',
                icon: Icons.person_add_alt_1_rounded,
                color: const Color(0xFF2563EB),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingWizardScreen())),
              ),
              _buildHRActionCard(
                title: 'Company Policies',
                subtitle: 'HR policies, employee handbooks, and acknowledgements tracking',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRPoliciesScreen())),
              ),
              _buildHRActionCard(
                title: 'Attendance & Leaves',
                subtitle: 'Real-time clock-in logs, geofenced tracking, and leave approvals',
                icon: Icons.alarm_rounded,
                color: const Color(0xFF10B981),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRAttendanceScreen())),
              ),
              _buildHRActionCard(
                title: 'Performance Reviews',
                subtitle: 'KPA scorecards, review cycles, and 360 appraisal ratings',
                icon: Icons.stars_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRPerformanceScreen())),
              ),
              _buildHRActionCard(
                title: 'Training & Skills',
                subtitle: 'Mandatory compliance courses, skill modules, and completion stats',
                icon: Icons.school_rounded,
                color: const Color(0xFF06B6D4),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HRTrainingScreen())),
              ),
              _buildHRActionCard(
                title: 'Offboarding & Exits',
                subtitle: 'Resignation tracking, asset clearance, and exit interviews',
                icon: Icons.exit_to_app_rounded,
                color: const Color(0xFFF97316),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HROffboardingScreen())),
              ),
              _buildHRActionCard(
                title: 'Bulk Staff Transfer',
                subtitle: 'Reorganize staff between departments and assign new roles',
                icon: Icons.swap_horiz_rounded,
                color: const Color(0xFF6366F1),
                onTap: () => _showTransferEmployeesDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHRActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// DEPARTMENT 360° COCKPIT MODAL SHEET
// =============================================================================
class _DepartmentCockpitModal extends StatefulWidget {
  final String deptId;
  final Map<String, dynamic> deptSummary;
  final List<dynamic> allDepartments;
  final VoidCallback onRefreshParent;
  final Function(String) onTransferRequested;
  final Function(String) onAddPositionRequested;
  final VoidCallback onAddEmployeeRequested;

  const _DepartmentCockpitModal({
    required this.deptId,
    required this.deptSummary,
    required this.allDepartments,
    required this.onRefreshParent,
    required this.onTransferRequested,
    required this.onAddPositionRequested,
    required this.onAddEmployeeRequested,
  });

  @override
  State<_DepartmentCockpitModal> createState() => _DepartmentCockpitModalState();
}

class _DepartmentCockpitModalState extends State<_DepartmentCockpitModal> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _cockpitTabCtrl;
  bool _isLoading = true;

  Map<String, dynamic>? _deptDetails;
  List<dynamic> _employees = [];
  List<dynamic> _positions = [];
  List<dynamic> _jobs = [];
  String _employeeSearch = '';

  @override
  void initState() {
    super.initState();
    _cockpitTabCtrl = TabController(length: 3, vsync: this);
    _fetchCockpitDetails();
  }

  @override
  void dispose() {
    _cockpitTabCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCockpitDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/organization/departments/${widget.deptId}/details/');
      if (res.statusCode == 200 && res.data != null) {
        setState(() {
          _deptDetails = res.data['department'] ?? widget.deptSummary;
          _employees = res.data['employees'] ?? [];
          _positions = res.data['positions'] ?? [];
          _jobs = res.data['jobs'] ?? [];
        });
      }
    } catch (_) {
      // Fallback
      setState(() {
        _deptDetails = widget.deptSummary;
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final deptName = _deptDetails?['name'] ?? widget.deptSummary['name'] ?? 'Department';
    final deptCode = _deptDetails?['code'] ?? widget.deptSummary['code'] ?? '';
    final deptDesc = _deptDetails?['description'] ?? widget.deptSummary['description'] ?? '';
    final totalStaff = _employees.length;
    final activeStaff = _employees.where((e) => e['is_active'] == true).length;
    final totalPositions = _positions.length;
    final openJobs = _jobs.where((j) => j['status'] == 'OPEN').length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Handle & Title
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 20, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(Icons.apartment_rounded, color: Color(0xFF2563EB), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(deptName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                child: Text(deptCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF334155))),
                              ),
                            ],
                          ),
                          if (deptDesc.isNotEmpty)
                            Text(deptDesc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => widget.onTransferRequested(widget.deptId),
                      label: const Text('Transfer Staff', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Quick Metric Counter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                _buildCockpitStatPill('Workforce', '$activeStaff / $totalStaff Active', Icons.groups_rounded, const Color(0xFF2563EB)),
                const SizedBox(width: 12),
                _buildCockpitStatPill('Positions', '$totalPositions Defined', Icons.business_center_rounded, const Color(0xFF10B981)),
                const SizedBox(width: 12),
                _buildCockpitStatPill('Hiring', '$openJobs Open Jobs', Icons.work_outline_rounded, const Color(0xFFEC4899)),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _cockpitTabCtrl,
              indicatorColor: const Color(0xFF2563EB),
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Staff Roster ($totalStaff)'),
                Tab(text: 'Positions Hierarchy ($totalPositions)'),
                Tab(text: 'Open Requisitions ($openJobs)'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _cockpitTabCtrl,
                    children: [
                      _buildStaffRosterTab(),
                      _buildPositionsHierarchyTab(),
                      _buildJobsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCockpitStatPill(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(val, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12.5), overflow: TextOverflow.ellipsis),
                  Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffRosterTab() {
    final filtered = _employees.where((e) {
      final name = (e['name'] ?? '').toString().toLowerCase();
      final code = (e['employee_code'] ?? '').toString().toLowerCase();
      final pos = (e['position_title'] ?? '').toString().toLowerCase();
      final email = (e['email'] ?? '').toString().toLowerCase();
      final q = _employeeSearch.toLowerCase();
      return _employeeSearch.isEmpty || name.contains(q) || code.contains(q) || pos.contains(q) || email.contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search employee by name, code, or position...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (val) => setState(() => _employeeSearch = val),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add_rounded, size: 16),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: widget.onAddEmployeeRequested,
                label: const Text('Add Staff'),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No employees assigned to this department yet.', style: TextStyle(color: Color(0xFF94A3B8))))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final emp = filtered[idx];
                    final name = emp['name'] ?? 'Employee';
                    final code = emp['employee_code'] ?? '';
                    final pos = emp['position_title'] ?? 'Staff';
                    final email = emp['email'] ?? '';
                    final phone = emp['phone'] ?? '';

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF3B82F6),
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'E', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('$code · $pos\n$email ${phone.isNotEmpty ? "· $phone" : ""}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EmployeeDetailScreen(employeeId: emp['id']?.toString() ?? '')),
                            );
                          },
                          child: const Text('View 360° Profile', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPositionsHierarchyTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('POSITIONS IN THIS DEPARTMENT (${_positions.length})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => widget.onAddPositionRequested(widget.deptId),
                label: const Text('Add Position'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _positions.isEmpty
              ? const Center(child: Text('No positions created for this department.', style: TextStyle(color: Color(0xFF94A3B8))))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _positions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final pos = _positions[idx];
                    final title = pos['title'] ?? '';
                    final code = pos['code'] ?? '';
                    final empCount = pos['employee_count'] ?? 0;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE2E8F0))),
                      color: Colors.white,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEFF6FF),
                          child: Icon(Icons.business_center_rounded, color: Color(0xFF2563EB), size: 18),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(code.isNotEmpty ? 'Code: $code' : 'General Position', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                          child: Text('$empCount Staff', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildJobsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('JOB REQUISITIONS & VACANCIES (${_jobs.length})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_box_outlined, size: 16),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HRRecruitmentScreen()));
                },
                label: const Text('Open Requisition'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _jobs.isEmpty
              ? const Center(child: Text('No job openings active for this department.', style: TextStyle(color: Color(0xFF94A3B8))))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _jobs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final job = _jobs[idx];
                    final title = job['title'] ?? '';
                    final code = job['code'] ?? '';
                    final status = job['status'] ?? 'OPEN';
                    final apps = job['applications_count'] ?? 0;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE2E8F0))),
                      color: Colors.white,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFDF2F8),
                          child: Icon(Icons.work_rounded, color: Color(0xFFEC4899), size: 18),
                        ),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Code: $code · Exp: ${job['experience_required'] ?? "1-3 Years"}\n$apps Applications received',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        isThreeLine: true,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'OPEN' ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(status, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: status == 'OPEN' ? const Color(0xFF059669) : const Color(0xFF64748B))),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
