class AuthUser {
  final String id;
  final String employeeCode;
  final String email;
  final String name;
  final String status;
  final bool isMfaEnabled;
  final bool isAdmin;
  final bool isManager;
  final String? role;
  final String? department;
  final String? position;
  final List<String> permissions;

  AuthUser({
    required this.id,
    required this.employeeCode,
    required this.email,
    String? name,
    required this.status,
    required this.isMfaEnabled,
    required this.isAdmin,
    required this.isManager,
    this.role,
    this.department,
    this.position,
    required this.permissions,
  }) : name = name ?? (email.isNotEmpty ? email.split('@')[0] : 'Employee');

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final email = json['email'] ?? '';
    final defaultName = email.contains('@') ? email.split('@')[0] : (json['employee_code'] ?? 'Employee');
    return AuthUser(
      id: json['id'] ?? '',
      employeeCode: json['employee_code'] ?? '',
      email: email,
      name: json['name'] ?? defaultName,
      status: json['status'] ?? 'ACTIVE',
      isMfaEnabled: json['is_mfa_enabled'] ?? false,
      isAdmin: json['is_admin'] ?? false,
      isManager: json['is_manager'] ?? false,
      role: json['role'],
      department: json['department'],
      position: json['position'],
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_code': employeeCode,
      'email': email,
      'name': name,
      'status': status,
      'is_mfa_enabled': isMfaEnabled,
      'is_admin': isAdmin,
      'is_manager': isManager,
      'role': role,
      'department': department,
      'position': position,
      'permissions': permissions,
    };
  }

  bool hasPermission(String code) {
    if (isAdmin) return true;
    return permissions.contains(code);
  }
}
