import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _projects = [];
  List<dynamic> _departments = [];
  List<dynamic> _employees = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final pRes = await _api.dio.get('/projects/');
      _projects = pRes.data['results'] ?? pRes.data ?? [];
    } catch (_) {}

    try {
      final dRes = await _api.dio.get('/departments/');
      _departments = dRes.data['results'] ?? dRes.data ?? [];
    } catch (_) {}

    try {
      final eRes = await _api.dio.get('/employees/');
      _employees = eRes.data['results'] ?? eRes.data ?? [];
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  void _showCreateProjectDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int? selectedDept;
    int? selectedManager;
    String status = 'PLANNING';
    DateTime? startDate = DateTime.now();
    DateTime? endDate = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.folder_special_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Create New Project', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Project Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Project Code (e.g. PRJ-MKT-01) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedDept,
                    decoration: const InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.domain),
                    ),
                    items: _departments.map<DropdownMenuItem<int>>((d) {
                      return DropdownMenuItem<int>(
                        value: d['id'],
                        child: Text(d['name'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) => setDlgState(() => selectedDept = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedManager,
                    decoration: const InputDecoration(
                      labelText: 'Project Manager',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_pin_rounded),
                    ),
                    items: _employees.map<DropdownMenuItem<int>>((e) {
                      return DropdownMenuItem<int>(
                        value: e['id'],
                        child: Text('${e['full_name']} (${e['employee_id']})'),
                      );
                    }).toList(),
                    onChanged: (val) => setDlgState(() => selectedManager = val),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'PLANNING', child: Text('Planning')),
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Active / In Progress')),
                      DropdownMenuItem(value: 'ON_HOLD', child: Text('On Hold')),
                      DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                    ],
                    onChanged: (val) => setDlgState(() => status = val ?? 'PLANNING'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || codeCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name and Code are required')),
                  );
                  return;
                }
                try {
                  await _api.dio.post('/projects/', data: {
                    'name': nameCtrl.text.trim(),
                    'code': codeCtrl.text.trim().toUpperCase(),
                    'description': descCtrl.text.trim(),
                    'department': selectedDept,
                    'manager': selectedManager,
                    'status': status,
                    'start_date': startDate?.toIso8601String().substring(0, 10),
                    'target_end_date': endDate?.toIso8601String().substring(0, 10),
                  });
                  Navigator.pop(ctx);
                  _fetchData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Project created successfully!')),
                  );
                } catch (err) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create project: $err')),
                  );
                }
              },
              child: const Text('Create Project'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? s) {
    switch (s) {
      case 'ACTIVE':
        return Colors.green;
      case 'PLANNING':
        return Colors.blue;
      case 'ON_HOLD':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.teal;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects & Workspaces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProjectDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open_outlined, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'No Projects Found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Organize team operations with structured projects.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _showCreateProjectDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Project'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _projects.length,
                    itemBuilder: (ctx, i) {
                      final p = _projects[i];
                      final progress = (p['progress_percentage'] ?? 0).toDouble() / 100.0;
                      final total = p['total_tasks'] ?? 0;
                      final completed = p['completed_tasks'] ?? 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.folder_special_rounded, color: AppTheme.primary, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['name'] ?? '',
                                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade200,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                p['code'] ?? '',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            if (p['department_name'] != null) ...[
                                              const SizedBox(width: 8),
                                              Icon(Icons.domain, size: 14, color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                p['department_name'],
                                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(p['status']).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      p['status'] ?? 'PLANNING',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(p['status']),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if ((p['description'] ?? '').toString().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  p['description'],
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tasks: $completed / $total completed',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    progress >= 1.0 ? Colors.green : AppTheme.primary,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Divider(color: Colors.grey.shade200),
                              Row(
                                children: [
                                  Icon(Icons.person_pin, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Manager: ${p['manager_name'] ?? 'Not Assigned'}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                  ),
                                  const Spacer(),
                                  if (p['target_end_date'] != null) ...[
                                    Icon(Icons.event, size: 15, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Due: ${p['target_end_date']}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
