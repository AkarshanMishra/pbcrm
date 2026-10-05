import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../tasks/create_task_screen.dart';
import '../tasks/task_detail_screen.dart';

class MarketingWorkScreen extends StatefulWidget {
  const MarketingWorkScreen({super.key});

  @override
  State<MarketingWorkScreen> createState() => _MarketingWorkScreenState();
}

class _MarketingWorkScreenState extends State<MarketingWorkScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _tasks = [];
  String _selectedCategory = 'All';
  late TabController _tabController;

  final List<String> _categories = [
    'All',
    '🎯 Lead Generation',
    '📞 Follow-up',
    '📍 Market Visit',
    '🏢 Venue Onboarding',
    '🤝 Vendor Onboarding',
    '👥 Partner Meeting',
    '📸 Photography',
    '📱 Social Media',
    '📊 Market Research',
    '📝 Reporting',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/v1/tasks/');
      if (mounted) {
        setState(() {
          _tasks = (res.data is List) ? res.data : (res.data['results'] ?? []);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getFilteredTasks(int tabIndex) {
    var list = _tasks;
    if (_selectedCategory != 'All') {
      final cleanCat = _selectedCategory.substring(2).trim();
      list = list.where((t) => (t['title'] ?? '').toString().toLowerCase().contains(cleanCat.toLowerCase()) || (t['description'] ?? '').toString().toLowerCase().contains(cleanCat.toLowerCase())).toList();
    }

    if (tabIndex == 0) {
      // Today / In Progress
      return list.where((t) => t['status'] == 'IN_PROGRESS' || t['status'] == 'TODO').toList();
    } else if (tabIndex == 1) {
      // Upcoming
      return list.where((t) => t['status'] == 'TODO').toList();
    } else if (tabIndex == 2) {
      // Overdue / Blocked
      return list.where((t) => t['status'] == 'BLOCKED' || t['priority'] == 'URGENT').toList();
    } else {
      // Completed
      return list.where((t) => t['status'] == 'DONE' || t['status'] == 'COMPLETED').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Marketing Work & Tasks', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Create Marketing Task',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateTaskScreen())),
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)), onPressed: _fetchTasks),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              // Predefined Category Chips
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (ctx, i) {
                    final cat = _categories[i];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF334155))),
                        selected: isSelected,
                        selectedColor: const Color(0xFF2563EB),
                        backgroundColor: const Color(0xFFF1F5F9),
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  },
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                indicatorColor: const Color(0xFF2563EB),
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Today'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Attention'),
                  Tab(text: 'Completed'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(0),
                _buildTaskList(1),
                _buildTaskList(2),
                _buildTaskList(3),
              ],
            ),
    );
  }

  Widget _buildTaskList(int tabIndex) {
    final tasks = _getFilteredTasks(tabIndex);
    if (tasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No tasks in this category.\nTap "+" to create a new task.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8))),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: tasks.length,
      itemBuilder: (ctx, i) {
        final t = tasks[i];
        final priority = (t['priority'] ?? 'MEDIUM').toString().toUpperCase();
        final isUrgent = priority == 'URGENT' || priority == 'HIGH';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(taskId: t['id']))),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isUrgent ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isUrgent ? '🔴 $priority' : '🟢 $priority',
                          style: TextStyle(color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF2563EB), fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        'Due: ${t['due_date'] ?? 'Today 5:00 PM'}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t['title'] ?? 'Marketing Task',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  if (t['description'] != null && t['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      t['description'],
                      style: const TextStyle(color: Color(0xFF475569), fontSize: 11.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                          child: LinearProgressIndicator(
                            value: 0.75,
                            backgroundColor: Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('75%', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
