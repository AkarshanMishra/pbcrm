class AttendanceRecord {
  final String id;
  final String employeeCode;
  final String employeeName;
  final String departmentName;
  final String attendanceDate;
  final String? serverCheckInTime;
  final String? serverCheckOutTime;
  final String status;
  final bool isCorrected;
  final String notes;

  AttendanceRecord({
    required this.id,
    required this.employeeCode,
    required this.employeeName,
    required this.departmentName,
    required this.attendanceDate,
    this.serverCheckInTime,
    this.serverCheckOutTime,
    required this.status,
    required this.isCorrected,
    required this.notes,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? '',
      employeeCode: json['employee_code'] ?? '',
      employeeName: json['employee_name'] ?? '',
      departmentName: json['department_name'] ?? '',
      attendanceDate: json['attendance_date'] ?? '',
      serverCheckInTime: json['server_check_in_time'],
      serverCheckOutTime: json['server_check_out_time'],
      status: json['status'] ?? 'PRESENT',
      isCorrected: json['is_corrected'] ?? false,
      notes: json['notes'] ?? '',
    );
  }
}
