import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _announcements = [];
  List<dynamic> _departments = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final aRes = await _api.dio.get('/announcements/');
      _announcements = aRes.data['results'] ?? aRes.data ?? [];
    } catch (_) {}

    try {
      final dRes = await _api.dio.get('/departments/');
      _departments = dRes.data['results'] ?? dRes.data ?? [];
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  void _showCreateAnnouncementDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String targetAudience = 'ALL';
    String priority = 'MEDIUM';
    bool isPinned = false;
    int? selectedDept;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.campaign_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Publish Announcement', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Announcement Title *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: targetAudience,
                    decoration: const InputDecoration(
                      labelText: 'Target Audience *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.people_alt_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('All Employees (Company-wide)')),
                      DropdownMenuItem(value: 'DEPARTMENT', child: Text('Specific Department')),
                      DropdownMenuItem(value: 'MANAGERS', child: Text('Managers & Leads')),
                    ],
                    onChanged: (val) => setDlgState(() => targetAudience = val ?? 'ALL'),
                  ),
                  if (targetAudience == 'DEPARTMENT') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedDept,
                      decoration: const InputDecoration(
                        labelText: 'Select Department *',
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
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.priority_high),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low / Normal')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium / Important')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High Priority')),
                      DropdownMenuItem(value: 'URGENT', child: Text('Urgent / Mandatory')),
                    ],
                    onChanged: (val) => setDlgState(() => priority = val ?? 'MEDIUM'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Pin to top of feed', style: TextStyle(fontSize: 14)),
                    value: isPinned,
                    activeColor: AppTheme.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setDlgState(() => isPinned = val),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Announcement Content *',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
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
                if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title and content are required')),
                  );
                  return;
                }
                try {
                  await _api.dio.post('/announcements/', data: {
                    'title': titleCtrl.text.trim(),
                    'content': contentCtrl.text.trim(),
                    'target_audience': targetAudience,
                    'priority': priority,
                    'is_pinned': isPinned,
                    'department': targetAudience == 'DEPARTMENT' ? selectedDept : null,
                  });
                  Navigator.pop(ctx);
                  _fetchData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcement published successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Publish failed: $e')));
                }
              },
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String? p) {
    switch (p) {
      case 'URGENT':
        return Colors.red;
      case 'HIGH':
        return Colors.orange.shade800;
      case 'MEDIUM':
        return AppTheme.primary;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team & Company Announcements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateAnnouncementDialog,
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Announcement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'No Announcements Active',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Company bulletins and department updates will appear here.',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _announcements.length,
                    itemBuilder: (ctx, i) {
                      final item = _announcements[i];
                      final isPinned = item['is_pinned'] == true;
                      final priorityColor = _getPriorityColor(item['priority']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: isPinned ? 3 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isPinned
                              ? BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 1.5)
                              : BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isPinned) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.push_pin, size: 13, color: Colors.amber.shade900),
                                          const SizedBox(width: 4),
                                          Text(
                                            'PINNED',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: priorityColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item['priority'] ?? 'MEDIUM',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    item['published_at'] != null ? item['published_at'].toString().substring(0, 10) : '',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item['title'] ?? '',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['content'] ?? '',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
                              ),
                              const SizedBox(height: 14),
                              Divider(color: Colors.grey.shade200),
                              Row(
                                children: [
                                  Icon(Icons.person_pin, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Published by: ${item['published_by_name'] ?? 'Admin'}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Audience: ${item['target_audience'] ?? 'ALL'}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
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
    );
  }
}
