import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class AddEmployeeWizardSheet extends StatefulWidget {
  final VoidCallback onEmployeeCreated;

  const AddEmployeeWizardSheet({super.key, required this.onEmployeeCreated});

  @override
  State<AddEmployeeWizardSheet> createState() => _AddEmployeeWizardSheetState();
}

class _AddEmployeeWizardSheetState extends State<AddEmployeeWizardSheet> {
  final ApiClient _api = ApiClient();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isFetchingMetadata = true;

  // Metadata
  List<dynamic> _departments = [];
  List<dynamic> _positions = [];
  List<dynamic> _roles = [];
  List<dynamic> _managers = [];

  // Step 1: Personal
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  String _gender = 'MALE';
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  // Step 2: Organization
  final _empCodeCtrl = TextEditingController();
  String? _selectedDeptId;
  String? _selectedPosId;
  String? _selectedRoleId;
  String? _selectedManagerId;
  final _joiningDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  String _branch = 'Headquarters (HQ)';

  // Step 3: Account & Credentials
  final _usernameCtrl = TextEditingController();
  final _tempPasswordCtrl = TextEditingController(text: 'Welcome@123!');
  bool _mfaRequired = true;
  String _accountStatus = 'ACTIVE';

  // Step 4: Custom Permissions
  final Map<String, bool> _permissions = {
    'VIEW_TASKS': true,
    'CREATE_TASKS': true,
    'EDIT_TASKS': false,
    'DELETE_TASKS': false,
    'VIEW_REPORTS': true,
    'APPROVE_REPORTS': false,
    'MANAGE_ATTENDANCE': false,
    'CORRECT_ATTENDANCE': false,
    'MANAGE_EMPLOYEES': false,
    'VIEW_AUDIT_LOGS': false,
    'SECURITY_ADMIN': false,
  };

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  Future<void> _fetchMetadata() async {
    try {
      final dRes = await _api.dio.get('/organization/departments/');
      final pRes = await _api.dio.get('/organization/positions/');
      final rRes = await _api.dio.get('/organization/roles/');
      final mRes = await _api.dio.get('/employees/');

      setState(() {
        _departments = dRes.data['results'] ?? dRes.data ?? [];
        _positions = pRes.data['results'] ?? pRes.data ?? [];
        _roles = rRes.data['results'] ?? rRes.data ?? [];
        _managers = (mRes.data['results'] ?? mRes.data ?? []).where((e) => e['is_manager'] == true || e['is_admin'] == true).toList();

        if (_departments.isNotEmpty) _selectedDeptId = _departments.first['id']?.toString();
        if (_positions.isNotEmpty) _selectedPosId = _positions.first['id']?.toString();
        if (_roles.isNotEmpty) _selectedRoleId = _roles.first['id']?.toString();
        _isFetchingMetadata = false;
      });
    } catch (_) {
      setState(() => _isFetchingMetadata = false);
    }
  }

  Future<void> _handleCreateEmployee() async {
    if (_firstNameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required personal details.'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      'user': {
        'email': _emailCtrl.text.trim(),
        'phone': _mobileCtrl.text.trim(),
        'password': _tempPasswordCtrl.text.trim(),
        if (_empCodeCtrl.text.trim().isNotEmpty) 'employee_code': _empCodeCtrl.text.trim(),
        'is_mfa_enabled': _mfaRequired,
        'status': _accountStatus,
      },
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'department_id': _selectedDeptId,
      'position_id': _selectedPosId,
      'role_id': _selectedRoleId,
      if (_selectedManagerId != null) 'reporting_manager_id': _selectedManagerId,
      'joining_date': _joiningDateCtrl.text.trim(),
      'employment_type': 'FULL_TIME',
    };

    try {
      final res = await _api.dio.post('/employees/', data: payload);
      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pop(context);
        widget.onEmployeeCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Employee ${res.data['full_name'] ?? _firstNameCtrl.text} created successfully!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } on DioException catch (e) {
      setState(() => _isLoading = false);
      final msg = e.response?.data?['message'] ?? e.response?.data?.toString() ?? 'Failed to create employee';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Provision New Employee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Step ${_currentStep + 1} of 5 — ${_getStepTitle(_currentStep)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),

          // Stepper Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: List.generate(5, (index) {
                final isActive = index <= _currentStep;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primary : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Content
          Expanded(
            child: _isFetchingMetadata
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildStepContent(),
                  ),
          ),

          // Footer Navigation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _currentStep--),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                if (_currentStep < 4)
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_currentStep == 0 && (_firstNameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill First Name and Email.'), backgroundColor: AppTheme.warning),
                        );
                        return;
                      }
                      setState(() => _currentStep++);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleCreateEmployee,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                    icon: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.person_add),
                    label: const Text('CONFIRM & CREATE'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Personal Info';
      case 1:
        return 'Organization Details';
      case 2:
        return 'Account & Security';
      case 3:
        return 'Custom Permissions';
      case 4:
        return 'Summary & Confirmation';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Personal();
      case 1:
        return _buildStep2Organization();
      case 2:
        return _buildStep3Account();
      case 3:
        return _buildStep4Permissions();
      case 4:
        return _buildStep5Confirmation();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1 — PERSONAL
  Widget _buildStep1Personal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(labelText: 'First Name *', prefixIcon: Icon(Icons.person)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Last Name', prefixIcon: Icon(Icons.person_outline)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Work Email *', prefixIcon: Icon(Icons.email_outlined), hintText: 'name@company.com'),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _mobileCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Mobile Number', prefixIcon: Icon(Icons.phone_outlined), hintText: '+91 9876543210'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'MALE', child: Text('Male')),
                  DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: (val) => setState(() => _gender = val ?? 'MALE'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _dobCtrl,
                decoration: const InputDecoration(labelText: 'Date of Birth', prefixIcon: Icon(Icons.cake_outlined), hintText: 'YYYY-MM-DD'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 2 — ORGANIZATION
  Widget _buildStep2Organization() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Organization Placement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _empCodeCtrl,
          decoration: const InputDecoration(
            labelText: 'Employee ID (Leave blank to auto-generate)',
            prefixIcon: Icon(Icons.badge_outlined),
            hintText: 'e.g. PBE000004',
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedDeptId,
          decoration: const InputDecoration(labelText: 'Department *', prefixIcon: Icon(Icons.apartment)),
          items: _departments.map((d) => DropdownMenuItem(value: d['id'].toString(), child: Text(d['name']))).toList(),
          onChanged: (val) => setState(() => _selectedDeptId = val),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedPosId,
          decoration: const InputDecoration(labelText: 'Position / Job Title *', prefixIcon: Icon(Icons.work_outline)),
          items: _positions.map((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(p['title']))).toList(),
          onChanged: (val) => setState(() => _selectedPosId = val),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedRoleId,
          decoration: const InputDecoration(labelText: 'System Access Role *', prefixIcon: Icon(Icons.admin_panel_settings_outlined)),
          items: _roles.map((r) => DropdownMenuItem(value: r['id'].toString(), child: Text('${r['name']} (${r['code']})'))).toList(),
          onChanged: (val) => setState(() => _selectedRoleId = val),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedManagerId,
          decoration: const InputDecoration(labelText: 'Reporting Manager (Optional)', prefixIcon: Icon(Icons.supervisor_account)),
          items: [
            const DropdownMenuItem(value: null, child: Text('-- None (Direct to Admin) --')),
            ..._managers.map((m) => DropdownMenuItem(value: m['id'].toString(), child: Text('${m['full_name']} (${m['department_name'] ?? 'Mgmt'})'))),
          ],
          onChanged: (val) => setState(() => _selectedManagerId = val),
        ),
      ],
    );
  }

  // STEP 3 — ACCOUNT & CREDENTIALS
  Widget _buildStep3Account() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Login Credentials & Security Policy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _tempPasswordCtrl,
          decoration: const InputDecoration(
            labelText: 'Temporary Password *',
            prefixIcon: Icon(Icons.lock_outline),
            helperText: 'Must contain uppercase, lowercase, number & symbol.',
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Mandatory MFA / TOTP Enrollment', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Requires 2FA setup on first login for heightened security.'),
          value: _mfaRequired,
          activeColor: AppTheme.primary,
          onChanged: (val) => setState(() => _mfaRequired = val),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _accountStatus,
          decoration: const InputDecoration(labelText: 'Initial Account Status'),
          items: const [
            DropdownMenuItem(value: 'ACTIVE', child: Text('🟢 ACTIVE (Can Login Immediately)')),
            DropdownMenuItem(value: 'SUSPENDED', child: Text('🟡 SUSPENDED (Pending Onboarding)')),
            DropdownMenuItem(value: 'DEACTIVATED', child: Text('🔴 DEACTIVATED')),
          ],
          onChanged: (val) => setState(() => _accountStatus = val ?? 'ACTIVE'),
        ),
      ],
    );
  }

  // STEP 4 — PERMISSIONS
  Widget _buildStep4Permissions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Custom Permission Overrides', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Fine-tune what modules this employee can access:', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 14),
        ..._permissions.keys.map((permKey) {
          final isChecked = _permissions[permKey] ?? false;
          return CheckboxListTile(
            dense: true,
            title: Text(permKey.replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            value: isChecked,
            activeColor: AppTheme.primary,
            onChanged: (val) => setState(() => _permissions[permKey] = val ?? false),
          );
        }),
      ],
    );
  }

  // STEP 5 — CONFIRMATION & SUMMARY
  Widget _buildStep5Confirmation() {
    final deptName = _departments.firstWhere((d) => d['id'].toString() == _selectedDeptId, orElse: () => {'name': 'Default'})['name'];
    final posTitle = _positions.firstWhere((p) => p['id'].toString() == _selectedPosId, orElse: () => {'title': 'Default'})['title'];
    final roleName = _roles.firstWhere((r) => r['id'].toString() == _selectedRoleId, orElse: () => {'name': 'Employee'})['name'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Employee Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Full Name', '${_firstNameCtrl.text} ${_lastNameCtrl.text}'),
              _buildSummaryRow('Work Email', _emailCtrl.text),
              _buildSummaryRow('Department', deptName),
              _buildSummaryRow('Position', posTitle),
              _buildSummaryRow('System Role', roleName),
              _buildSummaryRow('Joining Date', _joiningDateCtrl.text),
              _buildSummaryRow('MFA Policy', _mfaRequired ? 'Mandatory' : 'Optional'),
              _buildSummaryRow('Status', _accountStatus),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            Icon(Icons.shield, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Audit log event EMPLOYEE_CREATED will be automatically generated and cryptographically signed.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }
}
