import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../models/attendance.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<AttendanceRecord> _records = [];

  @override
  void initState() {
    super.initState();
    _fetchAttendanceHistory();
  }

  Future<void> _fetchAttendanceHistory() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/attendance/records/');
      final rawList = (res.data['results'] ?? res.data) as List<dynamic>;
      setState(() {
        _records = rawList.map((j) => AttendanceRecord.fromJson(j)).toList();
      });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _showCorrectionDialog(AttendanceRecord record) {
    final reasonController = TextEditingController();
    TimeOfDay? selectedCheckOut;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Correction: ${record.attendanceDate}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Submit an attendance adjustment request to your manager.'),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  selectedCheckOut == null
                      ? 'Select Missing Check-out Time'
                      : 'Check-out: ${selectedCheckOut!.format(context)}',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 18, minute: 0),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedCheckOut = picked);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for correction',
                  hintText: 'e.g. Forgot checkout after client meeting',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a reason for correction.'), backgroundColor: AppTheme.warning),
                  );
                  return;
                }
                try {
                  final formattedTime = selectedCheckOut != null
                      ? '${selectedCheckOut!.hour.toString().padLeft(2, '0')}:${selectedCheckOut!.minute.toString().padLeft(2, '0')}:00'
                      : null;

                  await _api.dio.post('/attendance/corrections/', data: {
                    'attendance_id': record.id,
                    if (formattedTime != null) 'requested_check_out_time': formattedTime,
                    'reason': reasonController.text.trim(),
                  });

                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Correction request submitted for manager approval.'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                    _fetchAttendanceHistory();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to submit correction: ${e.toString()}'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              },
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDisplayTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty || timeStr == '--:--') return '--:--';
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1].split('.')[0]);
        final period = hour >= 12 ? 'PM' : 'AM';
        int displayHour = hour % 12;
        if (displayHour == 0) displayHour = 12;
        final minStr = minute.toString().padLeft(2, '0');
        return '$displayHour:$minStr $period';
      }
    } catch (_) {}
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAttendanceHistory,
              child: _records.isEmpty
                  ? const Center(child: Text('No attendance records found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _records.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, idx) {
                        final rec = _records[idx];
                        return Card(
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(rec.attendanceDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                if (rec.isCorrected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('CORRECTED', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    rec.status,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.success, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                'In: ${_formatDisplayTime(rec.serverCheckInTime)}   •   Out: ${_formatDisplayTime(rec.serverCheckOutTime)}',
                                style: const TextStyle(color: Color(0xFF475569)),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_calendar_outlined),
                              tooltip: 'Request Correction',
                              onPressed: () => _showCorrectionDialog(rec),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
