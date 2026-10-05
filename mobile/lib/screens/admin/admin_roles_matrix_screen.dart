import 'package:flutter/material.dart';

class AdminRolesMatrixScreen extends StatefulWidget {
  const AdminRolesMatrixScreen({super.key});

  @override
  State<AdminRolesMatrixScreen> createState() => _AdminRolesMatrixScreenState();
}

class _AdminRolesMatrixScreenState extends State<AdminRolesMatrixScreen> {
  String _selectedRole = "MARKETING MANAGER";

  final List<String> _roles = [
    "SUPER ADMIN",
    "ADMIN",
    "HR MANAGER",
    "IT MANAGER",
    "OPERATIONS MANAGER",
    "MARKETING MANAGER",
    "EMPLOYEE",
  ];

  final Map<String, Map<String, bool>> _permissionsMap = {
    "SUPER ADMIN": {
      "View All Organization Data": true,
      "Manage All Employees & Transfers": true,
      "Assign & Reassign Tasks Org-wide": true,
      "Full Security & Audit Center Control": true,
      "Approve All Workflows & Leaves": true,
      "Manage Roles, Permissions & Policies": true,
      "Impersonate Any User (View As)": true,
      "System Configuration & Feature Flags": true,
    },
    "ADMIN": {
      "View All Organization Data": true,
      "Manage All Employees & Transfers": true,
      "Assign & Reassign Tasks Org-wide": true,
      "Full Security & Audit Center Control": true,
      "Approve All Workflows & Leaves": true,
      "Manage Roles, Permissions & Policies": true,
      "Impersonate Any User (View As)": true,
      "System Configuration & Feature Flags": false,
    },
    "HR MANAGER": {
      "View All Organization Data": true,
      "Manage All Employees & Transfers": true,
      "Assign & Reassign Tasks Org-wide": false,
      "Full Security & Audit Center Control": false,
      "Approve All Workflows & Leaves": true,
      "Manage Roles, Permissions & Policies": false,
      "Impersonate Any User (View As)": false,
      "System Configuration & Feature Flags": false,
    },
    "IT MANAGER": {
      "View All Organization Data": false,
      "Manage All Employees & Transfers": false,
      "Assign & Reassign Tasks Org-wide": false,
      "Full Security & Audit Center Control": true,
      "Approve All Workflows & Leaves": false,
      "Manage Roles, Permissions & Policies": false,
      "Impersonate Any User (View As)": false,
      "System Configuration & Feature Flags": false,
    },
    "OPERATIONS MANAGER": {
      "View All Organization Data": false,
      "Manage All Employees & Transfers": false,
      "Assign & Reassign Tasks Org-wide": false,
      "Full Security & Audit Center Control": false,
      "Approve All Workflows & Leaves": true,
      "Manage Roles, Permissions & Policies": false,
      "Impersonate Any User (View As)": false,
      "System Configuration & Feature Flags": false,
    },
    "MARKETING MANAGER": {
      "View Team": true,
      "Assign Tasks": true,
      "View Team Visits": true,
      "Manage Leads": true,
      "Manage Partners": true,
      "View Reports": true,
      "Approve Onboarding": true,
      "System Settings": false,
      "Security Configuration": false,
    },
    "EMPLOYEE": {
      "View Own Work & Tasks": true,
      "Submit Attendance & Corrections": true,
      "Apply For Leaves": true,
      "Raise Helpdesk & HR Requests": true,
      "Manage Leads (Field Team)": true,
      "View Team Data": false,
      "Approve Requests": false,
      "System Configuration": false,
    }
  };

  @override
  Widget build(BuildContext context) {
    final perms = _permissionsMap[_selectedRole] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("Role & Permission Matrix", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Role selector list
          Container(
            width: 200,
            color: const Color(0xFF1E293B),
            child: ListView.builder(
              itemCount: _roles.length,
              itemBuilder: (ctx, idx) {
                final r = _roles[idx];
                final isSelected = r == _selectedRole;
                return ListTile(
                  title: Text(
                    r,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: const Color(0xFF0F172A),
                  onTap: () => setState(() => _selectedRole = r),
                );
              },
            ),
          ),
          // Right: Permission checkboxes & Scope
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedRole, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 2),
                          const Text("Role → Department → Position → Permissions → Scope", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Permissions saved for $_selectedRole ✅"), backgroundColor: const Color(0xFF10B981)),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                        child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("DATA VISIBILITY SCOPE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildScopeChip("All Organization", _selectedRole.contains("ADMIN") || _selectedRole.contains("SUPER")),
                            const SizedBox(width: 8),
                            _buildScopeChip("Department Only", _selectedRole.contains("MANAGER")),
                            const SizedBox(width: 8),
                            _buildScopeChip("Self Only", _selectedRole == "EMPLOYEE"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("ASSIGNED CAPABILITIES & PERMISSIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  const SizedBox(height: 10),
                  ...perms.keys.map((pName) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: SwitchListTile(
                          value: perms[pName] ?? false,
                          onChanged: (val) {
                            setState(() {
                              _permissionsMap[_selectedRole]![pName] = val;
                            });
                          },
                          title: Text(pName, style: const TextStyle(fontSize: 13, color: Colors.white)),
                          activeColor: const Color(0xFF3B82F6),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.2) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF334155)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
