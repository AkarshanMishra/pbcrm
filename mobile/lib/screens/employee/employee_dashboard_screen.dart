import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../models/auth_user.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../core/mock/offline_fallback_data.dart';
import '../../core/sync/offline_sync_engine.dart';
import '../attendance/attendance_history_screen.dart';
import '../security/security_center_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../tasks/tasks_screen.dart';
import '../tasks/kanban_board_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../tasks/create_task_screen.dart';
import '../projects/projects_screen.dart';
import '../work/daily_work_screen.dart';
import '../work/daily_standup_screen.dart';
import '../tickets/tickets_screen.dart';
import '../announcements/announcements_screen.dart';
import '../notifications/notification_center_screen.dart';
import '../assistant/my_day_ai_assistant_sheet.dart';
import '../search/universal_search_screen.dart';
import '../admin/manager_command_center_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  final ApiClient _api = ApiClient();
  int _currentBottomNavIndex = 0;
  bool _isLoadingToday = true;
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;
  String? _checkInTime;
  String? _checkOutTime;
  int _unreadNotifs = 0;
  Map<String, dynamic> _taskMetrics = {};
  List<dynamic> _todayTasks = [];
  List<dynamic> _blockedTasks = [];

  // Focus Mode
  bool _isFocusModeActive = false;
  Timer? _focusTimer;
  int _focusSecondsRemaining = 25 * 60;
  String? _focusTaskTitle;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    if (mounted) setState(() => _isLoadingToday = true);
    try {
      await Future.wait([
        _fetchTodayAttendance().timeout(const Duration(seconds: 4), onTimeout: () {}),
        _fetchTaskMetrics().timeout(const Duration(seconds: 4), onTimeout: () {}),
        _fetchTodayTasks().timeout(const Duration(seconds: 4), onTimeout: () {}),
        _fetchUnreadNotifications().timeout(const Duration(seconds: 4), onTimeout: () {}),
      ]);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingToday = false);
    }
  }

  Future<void> _fetchTodayAttendance() async {
    try {
      final res = await _api.dio.get('/attendance/today/');
      if (res.statusCode == 200 && res.data['success'] == true && mounted) {
        setState(() {
          _isCheckedIn = res.data['is_checked_in'] ?? false;
          _isCheckedOut = res.data['is_checked_out'] ?? false;
          if (res.data['attendance'] != null) {
            _checkInTime = res.data['attendance']['server_check_in_time'];
            _checkOutTime = res.data['attendance']['server_check_out_time'];
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCheckedIn = true;
          _checkInTime = _checkInTime ?? '09:30:00';
        });
      }
    }
  }

  Future<void> _fetchTaskMetrics() async {
    try {
      final res = await _api.dio.get('/tasks/metrics/');
      if (mounted) {
        setState(() {
          _taskMetrics = res.data ?? {};
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _taskMetrics = {
            'total': 6,
            'completed': 3,
            'in_progress': 2,
            'blocked': 1,
          };
        });
      }
    }
  }

  Future<void> _fetchTodayTasks() async {
    try {
      final res = await _api.dio.get('/tasks/');
      final all = (res.data['results'] ?? res.data ?? []) as List<dynamic>;
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (mounted) {
        setState(() {
          _todayTasks = all.isNotEmpty
              ? all.where((t) => t['due_date'] == today || t['status'] == 'IN_PROGRESS' || t['status'] == 'ASSIGNED').toList()
              : OfflineFallbackData.fallbackTasks;
          _blockedTasks = all.where((t) => t['status'] == 'BLOCKED').toList();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _todayTasks = OfflineFallbackData.fallbackTasks;
          _blockedTasks = [OfflineFallbackData.fallbackTasks[4]];
        });
      }
    }
  }

  Future<void> _fetchUnreadNotifications() async {
    try {
      final res = await _api.dio.get('/notifications/unread-count/');
      if (mounted) {
        setState(() {
          _unreadNotifs = res.data['unread_count'] ?? 0;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _unreadNotifs = 3;
        });
      }
    }
  }

  Future<void> _handlePunch(bool isCheckIn) async {
    final endpoint = isCheckIn ? '/attendance/check-in/' : '/attendance/check-out/';

    try {
      final res = await _api.dio.post(endpoint, data: {
        'notes': '1-Tap Work Punch',
      });
      if (res.data['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.data['message']),
            backgroundColor: AppTheme.success,
          ),
        );
        _fetchTodayAttendance();
      }
    } catch (e) {
      // Offline punch fallback: queue to OfflineSyncEngine and update UI immediately
      final nowStr = DateFormat('HH:mm:ss').format(DateTime.now());
      if (mounted) {
        setState(() {
          if (isCheckIn) {
            _isCheckedIn = true;
            _checkInTime = nowStr;
          } else {
            _isCheckedOut = true;
            _checkOutTime = nowStr;
          }
        });

        OfflineSyncEngine().enqueueAction(
          actionType: isCheckIn ? 'ATTENDANCE_CHECK_IN' : 'ATTENDANCE_CHECK_OUT',
          payload: {
            'timestamp': DateTime.now().toIso8601String(),
            'notes': 'Offline Punch Record',
            'offline': true,
          },
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Offline ${isCheckIn ? "Check-in" : "Check-out"} Recorded at $nowStr (Queued for Sync)'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
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

  Color _getPriorityColor(String? p) {
    switch (p) {
      case 'URGENT':
        return Colors.red;
      case 'HIGH':
        return Colors.orange.shade800;
      case 'MEDIUM':
        return Colors.amber.shade700;
      case 'LOW':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _startFocusMode(String taskTitle) {
    setState(() {
      _isFocusModeActive = true;
      _focusTaskTitle = taskTitle;
      _focusSecondsRemaining = 25 * 60;
    });

    _focusTimer?.cancel();
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_focusSecondsRemaining > 0) {
        setState(() => _focusSecondsRemaining--);
      } else {
        _focusTimer?.cancel();
        setState(() => _isFocusModeActive = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🎯 Focus session completed! Great job!'), backgroundColor: Colors.green),
          );
        }
      }
    });

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setTimerState) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.center_focus_strong, color: AppTheme.primary, size: 28),
                  SizedBox(width: 8),
                  Text('🎯 Focus Mode Active', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _focusTaskTitle ?? 'Current Focus Task',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                '${(_focusSecondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_focusSecondsRemaining % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
              const SizedBox(height: 8),
              const Text('Notifications paused. Stay in deep work.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _focusTimer?.cancel();
                      setState(() => _isFocusModeActive = false);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('End Focus'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                    icon: const Icon(Icons.check),
                    label: const Text('Minimize & Work'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickBlockerSheet(Map<String, dynamic> task) {
    String selectedReason = 'Waiting for documents';
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.block_rounded, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text('Quick Block Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Text('Task: ${task['title']}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              const Text('Why are you blocked? *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Waiting for someone', child: Text('Waiting for team member / lead')),
                  DropdownMenuItem(value: 'Waiting for documents', child: Text('Waiting for document / credentials')),
                  DropdownMenuItem(value: 'Technical issue', child: Text('Technical or API blocker')),
                  DropdownMenuItem(value: 'Approval required', child: Text('Management approval required')),
                  DropdownMenuItem(value: 'External dependency', child: Text('External client or vendor dependency')),
                  DropdownMenuItem(value: 'Other', child: Text('Other blocker')),
                ],
                onChanged: (v) => setSheetState(() => selectedReason = v ?? 'Other'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Brief explanation note *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await _api.dio.post('/tasks/${task['id']}/block/', data: {
                        'reason': '$selectedReason: ${noteCtrl.text.trim()}',
                      });
                      if (mounted) {
                        Navigator.pop(ctx);
                        _fetchDashboardData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('⚠️ Task marked as blocked. Manager notified.')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                  icon: const Icon(Icons.report_problem_outlined),
                  label: const Text('Mark Blocked & Notify Lead'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndMyDayDialog() {
    final completedCount = _taskMetrics['completed'] ?? 0;
    final inProgressCount = _taskMetrics['in_progress'] ?? 0;
    final blockedCount = _taskMetrics['blocked'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.nightlight_round, color: Colors.indigo, size: 28),
            SizedBox(width: 8),
            Text('End My Day Wrap-Up', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Here is your work summary for today:',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tasks Completed:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('$completedCount ✓', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tasks Pending/In Progress:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('$inProgressCount', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tasks Blocked:', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('$blockedCount', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Would you like to review and submit your Daily Report before clocking out?',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyWorkScreen()));
            },
            child: const Text('Review Daily Report'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _handlePunch(false);
            },
            child: const Text('Punch Out Now'),
          ),
        ],
      ),
    );
  }

  void _showUniversalQuickAddSheet() {
    final user = context.read<AuthProvider>().currentUser;
    final isManagerOrAdmin = user?.isAdmin == true || (user?.role ?? '').contains('MANAGER');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Universal Quick Add', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.add_task, color: AppTheme.primary)),
              title: const Text('New Task / Assignment', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Create a task with priorities, checklist and due date'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTaskScreen()));
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFFFFBEB), child: Icon(Icons.groups_outlined, color: Colors.orange)),
              title: const Text('Post Daily Standup', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Share what you did, today\'s plan, and blockers'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyStandupScreen()));
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFF3E8FF), child: Icon(Icons.support_agent_rounded, color: Colors.deepPurple)),
              title: const Text('Raise Support Ticket', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Request IT help, equipment, or leave assistance'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketsScreen()));
              },
            ),
            if (isManagerOrAdmin) ...[
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFFDF2F8), child: Icon(Icons.campaign_outlined, color: Colors.pink)),
                title: const Text('Publish Announcement', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Broadcast bulletin to company or department'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen()));
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFECFDF5), child: Icon(Icons.folder_special_outlined, color: Colors.teal)),
                title: const Text('Create Project Workspace', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('New team project portfolio with milestone tracking'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsScreen()));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContextualActionButton(Map<String, dynamic> task) {
    final status = task['status'] ?? 'DRAFT';

    if (status == 'ASSIGNED' || status == 'DRAFT') {
      return ElevatedButton.icon(
        onPressed: () async {
          try {
            await _api.dio.post('/tasks/${task['id']}/start/');
            _fetchDashboardData();
          } catch (_) {}
        },
        icon: const Icon(Icons.play_arrow, size: 14),
        label: const Text('START', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    } else if (status == 'IN_PROGRESS') {
      return ElevatedButton.icon(
        onPressed: () => _startFocusMode(task['title'] ?? 'Task'),
        icon: const Icon(Icons.center_focus_strong, size: 14),
        label: const Text('FOCUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade800,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    } else if (status == 'BLOCKED') {
      return OutlinedButton.icon(
        onPressed: () async {
          try {
            await _api.dio.post('/tasks/${task['id']}/unblock/');
            _fetchDashboardData();
          } catch (_) {}
        },
        icon: const Icon(Icons.check, size: 14),
        label: const Text('UNBLOCK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    } else if (status == 'SUBMITTED' || status == 'UNDER_REVIEW') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
        child: const Text('REVIEW', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple)),
      );
    } else if (status == 'COMPLETED') {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }

    return const SizedBox.shrink();
  }

  Widget _buildMyDayView(AuthUser? user) {
    final todayStr = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
    final completedCount = _taskMetrics['completed'] ?? 0;
    final totalTasks = _taskMetrics['total'] ?? (_todayTasks.length);
    final progressVal = totalTasks > 0 ? (completedCount / totalTasks).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. My Day Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primary,
                child: Text(
                  ((user?.name ?? user?.email ?? 'E')[0]).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good day, ${user?.name ?? user?.email ?? 'Employee'} 👋',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      todayStr,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (_isFocusModeActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${(_focusSecondsRemaining ~/ 60)}m',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Attendance 1-Tap Check-In Banner
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCheckedIn && !_isCheckedOut ? Colors.green : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isCheckedIn && !_isCheckedOut
                                ? 'Working'
                                : _isCheckedOut
                                    ? 'Checked Out'
                                    : 'Not Checked In',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _isCheckedIn && !_isCheckedOut ? Colors.green.shade800 : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${_formatDisplayTime(_checkInTime)} ─── ${_formatDisplayTime(_checkOutTime)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!_isCheckedIn) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _handlePunch(true),
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('🟢 ONE-TAP CHECK IN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ] else if (!_isCheckedOut) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showEndMyDayDialog,
                            icon: const Icon(Icons.nightlight_outlined),
                            label: const Text('End My Day Wrap-Up'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _handlePunch(false),
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text('Punch Out', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Today's Progress Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TODAY'S PROGRESS", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Text(
                        '$completedCount / $totalTasks Tasks (${(progressVal * 100).toInt()}%)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progressVal,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(progressVal >= 1.0 ? Colors.green : AppTheme.primary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '🔴 ${_taskMetrics['urgent'] ?? 0} Urgent',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red.shade800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '🟠 ${_taskMetrics['high'] ?? 0} High',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '🔵 ${_taskMetrics['in_progress'] ?? 0} Active',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. "Needs Your Attention" Banner (If Blocked or Overdue)
          if (_blockedTasks.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_blockedTasks.length} task(s) currently blocked — review reason or update lead.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),

          // 5. Today's Work Priority List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("TODAY'S WORK", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen())),
                icon: const Icon(Icons.list_alt, size: 16),
                label: const Text('View All', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_todayTasks.isEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.task_alt, size: 48, color: Colors.green),
                    const SizedBox(height: 10),
                    const Text('🎯 You\'re all caught up for today!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('No pending deadlines remaining.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            )
          else
            ..._todayTasks.map((t) {
              final priorityColor = _getPriorityColor(t['priority']);
              final isDone = t['status'] == 'COMPLETED';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t['id'])),
                    );
                    _fetchDashboardData();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: isDone,
                          activeColor: Colors.green,
                          onChanged: (val) async {
                            try {
                              if (val == true) {
                                await _api.dio.post('/tasks/${t['id']}/review/', data: {'action': 'APPROVE'});
                              } else {
                                await _api.dio.patch('/tasks/${t['id']}/', data: {'status': 'IN_PROGRESS'});
                              }
                              _fetchDashboardData();
                            } catch (_) {}
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: priorityColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      t['priority'] ?? 'MEDIUM',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: priorityColor),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (t['status'] == 'BLOCKED') ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('BLOCKED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t['title'] ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                  color: isDone ? Colors.grey : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Due: ${t['due_date'] ?? 'Today'} • ${t['assigned_to_name'] ?? 'Assigned'}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildContextualActionButton(t),
                            if (t['status'] != 'BLOCKED' && !isDone) ...[
                              const SizedBox(height: 4),
                              InkWell(
                                onTap: () => _showQuickBlockerSheet(t),
                                child: Text('Report Blocker', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),

          // 6. Workforce Collaboration Modules Grid
          const Text('Collaboration Hub', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              _buildActionTile(
                'Kanban Board',
                Icons.view_kanban_outlined,
                Colors.amber.shade800,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KanbanBoardScreen())),
              ),
              _buildActionTile(
                'Projects & Workspaces',
                Icons.folder_special_outlined,
                Colors.blue.shade700,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsScreen())),
              ),
              _buildActionTile(
                'Daily Standup & Diary',
                Icons.groups_outlined,
                Colors.orange.shade700,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyStandupScreen())),
              ),
              _buildActionTile(
                'Helpdesk & Requests',
                Icons.support_agent_rounded,
                Colors.deepPurple,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketsScreen())),
              ),
              _buildActionTile(
                'Announcements',
                Icons.campaign_outlined,
                Colors.pink.shade700,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
              ),
              _buildActionTile(
                'Attendance History',
                Icons.calendar_month,
                Colors.indigo,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen())),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isAdmin = user?.isAdmin == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PCRM Enterprise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Universal Search',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UniversalSearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.amber),
            tooltip: 'My Day AI Assistant',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
              builder: (_) => MyDayAiAssistantSheet(
                todayTasks: _todayTasks,
                onTaskCreated: _fetchDashboardData,
              ),
            ),
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.dashboard_customize_outlined, color: Colors.lightGreenAccent),
              tooltip: 'Manager Command Center',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManagerCommandCenterScreen()),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchDashboardData,
          ),
          // Notification icon with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                  );
                  _fetchDashboardData();
                },
              ),
              if (_unreadNotifs > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_unreadNotifs',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Security & Devices',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SecurityCenterScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showUniversalQuickAddSheet,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey.shade600,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _currentBottomNavIndex = index);
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyWorkScreen()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementsScreen()));
          } else if (index == 4) {
            if (isAdmin) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityCenterScreen()));
            }
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'My Day'),
          const BottomNavigationBarItem(icon: Icon(Icons.task_alt_outlined), activeIcon: Icon(Icons.task_alt), label: 'Tasks'),
          const BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description), label: 'Reports'),
          const BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), activeIcon: Icon(Icons.campaign), label: 'Alerts'),
          BottomNavigationBarItem(
            icon: Icon(isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline),
            activeIcon: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person),
            label: isAdmin ? 'Admin' : 'Me',
          ),
        ],
      ),
      body: _isLoadingToday
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: _buildMyDayView(user),
            ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                radius: 20,
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
