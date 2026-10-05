import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  // Notification Rules
  bool _notifyNewTask = true;
  bool _notifyTaskOverdue = true;
  bool _notifyReportPending = true;
  bool _notifyReportApproved = true;
  bool _notifySecurityAlert = true;
  bool _notifyAttendanceException = true;

  // Channels
  bool _channelPush = true;
  bool _channelEmail = true;
  bool _channelInApp = true;

  // Policies
  final _workHoursCtrl = TextEditingController(text: '8.5');
  final _graceMinutesCtrl = TextEditingController(text: '15');
  final _autoCheckoutHoursCtrl = TextEditingController(text: '12');

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ System settings and notification rules saved successfully!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Configuration & Policies'),
        actions: [
          IconButton(icon: const Icon(Icons.save), tooltip: 'Save', onPressed: _saveSettings),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Attendance & Work Policy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _workHoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Standard Shift Duration (Hours)', prefixIcon: Icon(Icons.schedule)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _graceMinutesCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Late Punch Grace Period (Minutes)', prefixIcon: Icon(Icons.timelapse)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _autoCheckoutHoursCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Auto Check-Out Safety Window (Hours)', prefixIcon: Icon(Icons.safety_check)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Notification Dispatch Rules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('New Task Assignment Alerts'),
                  value: _notifyNewTask,
                  onChanged: (val) => setState(() => _notifyNewTask = val),
                ),
                SwitchListTile(
                  title: const Text('Task SLA Breach / Overdue Escalation'),
                  value: _notifyTaskOverdue,
                  onChanged: (val) => setState(() => _notifyTaskOverdue = val),
                ),
                SwitchListTile(
                  title: const Text('Daily Work Report Pending Review'),
                  value: _notifyReportPending,
                  onChanged: (val) => setState(() => _notifyReportPending = val),
                ),
                SwitchListTile(
                  title: const Text('Attendance Correction & Approval Notices'),
                  value: _notifyAttendanceException,
                  onChanged: (val) => setState(() => _notifyAttendanceException = val),
                ),
                SwitchListTile(
                  title: const Text('Security Alerts & Unauthorized Login Warnings'),
                  value: _notifySecurityAlert,
                  onChanged: (val) => setState(() => _notifySecurityAlert = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('Active Dispatch Channels', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Mobile Push Notifications (FCM)'),
                  value: _channelPush,
                  onChanged: (val) => setState(() => _channelPush = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Corporate Email Dispatch (SMTP)'),
                  value: _channelEmail,
                  onChanged: (val) => setState(() => _channelEmail = val ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Real-time In-App Notification Center'),
                  value: _channelInApp,
                  onChanged: (val) => setState(() => _channelInApp = val ?? false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              icon: const Icon(Icons.save),
              label: const Text('SAVE ALL CONFIGURATIONS'),
            ),
          ),
        ],
      ),
    );
  }
}
