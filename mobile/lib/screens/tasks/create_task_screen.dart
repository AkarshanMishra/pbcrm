import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final ApiClient _api = ApiClient();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _checklistInputController = TextEditingController();

  String _priority = 'MEDIUM';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String? _selectedEmployeeId;
  String? _selectedDeptId;

  List<dynamic> _employees = [];
  List<dynamic> _departments = [];
  List<dynamic> _templates = [];
  final List<String> _checklistItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFormData();
  }

  Future<void> _fetchFormData() async {
    setState(() => _isLoading = true);
    try {
      final empRes = await _api.dio.get('/employees/');
      final deptRes = await _api.dio.get('/organization/departments/');
      final tmplRes = await _api.dio.get('/tasks/templates/');
      setState(() {
        _employees = empRes.data['results'] ?? empRes.data ?? [];
        _departments = deptRes.data['results'] ?? deptRes.data ?? [];
        _templates = tmplRes.data['results'] ?? tmplRes.data ?? [];
        if (_employees.isNotEmpty) _selectedEmployeeId = _employees.first['id'];
        if (_departments.isNotEmpty) _selectedDeptId = _departments.first['id'];
      });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _applyTemplate(Map<String, dynamic> tmpl) {
    setState(() {
      _titleController.text = tmpl['name'] ?? '';
      _descController.text = tmpl['description'] ?? '';
      _priority = tmpl['default_priority'] ?? 'MEDIUM';
      _checklistItems.clear();
      final items = (tmpl['checklist_template'] ?? []) as List<dynamic>;
      _checklistItems.addAll(items.map((e) => e.toString()));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Template '${tmpl['name']}' applied!"), backgroundColor: AppTheme.success),
    );
  }

  void _addChecklistItem() {
    final text = _checklistInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _checklistItems.add(text);
        _checklistInputController.clear();
      });
    }
  }

  Future<void> _submitTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task Title is required.'), backgroundColor: AppTheme.warning),
      );
      return;
    }
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee to assign.'), backgroundColor: AppTheme.warning),
      );
      return;
    }

    try {
      final payload = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'department': _selectedDeptId,
        'assigned_to': _selectedEmployeeId,
        'priority': _priority,
        if (_dueDate != null) 'due_date': DateFormat('yyyy-MM-dd').format(_dueDate!),
        if (_dueTime != null) 'due_time': '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}:00',
        'checklist': _checklistItems,
      };

      await _api.dio.post('/tasks/', data: payload);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created and assigned successfully!'), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create task: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Task')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Template Selector
                  if (_templates.isNotEmpty) ...[
                    const Text('Quick Fill with Template', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _templates.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final tmpl = _templates[i];
                          return ActionChip(
                            avatar: const Icon(Icons.flash_on, size: 16, color: Colors.amber),
                            label: Text(tmpl['name'] ?? '', style: const TextStyle(fontSize: 12)),
                            onPressed: () => _applyTemplate(tmpl),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 24),
                  ],

                  // Form Fields
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Task Title *', prefixIcon: Icon(Icons.title)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description *', prefixIcon: Icon(Icons.description)),
                  ),
                  const SizedBox(height: 14),

                  // Assign To Employee
                  DropdownButtonFormField<String>(
                    value: _selectedEmployeeId,
                    decoration: const InputDecoration(labelText: 'Assign To Employee *', prefixIcon: Icon(Icons.person)),
                    items: _employees.map((e) {
                      final name = e['full_name'] ?? e['email'];
                      final code = e['employee_code'] ?? '';
                      return DropdownMenuItem<String>(
                        value: e['id'].toString(),
                        child: Text('$name ($code)'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedEmployeeId = val),
                  ),
                  const SizedBox(height: 12),

                  // Priority Selector
                  DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: 'Priority Level', prefixIcon: Icon(Icons.flag)),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('🟢 Low Priority')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('🟡 Medium Priority')),
                      DropdownMenuItem(value: 'HIGH', child: Text('🟠 High Priority')),
                      DropdownMenuItem(value: 'URGENT', child: Text('🔴 Urgent Priority')),
                    ],
                    onChanged: (val) => setState(() => _priority = val!),
                  ),
                  const SizedBox(height: 14),

                  // Due Date & Time
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
                          title: Text(_dueDate == null ? 'Set Due Date' : DateFormat('dd MMM yyyy').format(_dueDate!)),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 1)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) setState(() => _dueDate = picked);
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.access_time, color: AppTheme.primary),
                          title: Text(_dueTime == null ? 'Set Due Time' : _dueTime!.format(context)),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 18, minute: 0),
                            );
                            if (picked != null) setState(() => _dueTime = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Checklist Builder
                  const Text('Task Checklist Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _checklistInputController,
                          decoration: const InputDecoration(hintText: 'Add checklist step...'),
                          onSubmitted: (_) => _addChecklistItem(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: _addChecklistItem,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._checklistItems.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final text = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(radius: 12, child: Text('${idx + 1}', style: const TextStyle(fontSize: 10))),
                        title: Text(text),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                          onPressed: () => setState(() => _checklistItems.removeAt(idx)),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // Submit Button
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Create & Assign Task'),
                    onPressed: _submitTask,
                  ),
                ],
              ),
            ),
    );
  }
}
