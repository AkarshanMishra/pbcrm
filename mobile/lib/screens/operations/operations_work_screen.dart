import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class OperationsWorkScreen extends StatefulWidget {
  const OperationsWorkScreen({super.key});

  @override
  State<OperationsWorkScreen> createState() => _OperationsWorkScreenState();
}

class _OperationsWorkScreenState extends State<OperationsWorkScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  bool _isLoading = true;
  String _searchQuery = "";
  String _selectedCategory = "ALL";

  final List<String> _categories = <String>[
    "ALL",
    "Booking Coordination",
    "Partner Coordination",
    "Venue Verification",
    "Vendor Verification",
    "Service Readiness",
    "Customer Support",
    "Issue Resolution",
    "Follow-up",
    "Quality Check",
    "Documentation",
    "Inventory",
    "Event Preparation",
    "Post-Event Check",
    "Process Audit"
  ];

  List<dynamic> _allTasks = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/v1/tasks/tasks/');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data['results'] ?? res.data;
        if (data is List) {
          _allTasks = data;
        }
      }
    } catch (e) {
      debugPrint("Load ops tasks error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNewTaskModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String category = "Booking Coordination";
    String priority = "HIGH";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      "CREATE OPERATIONS TASK",
                      style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Task Title",
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Category",
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _categories.where((c) => c != "ALL").map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (val) => setModalState(() => category = val!),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: priority,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Priority",
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: "LOW", child: Text("Low")),
                        DropdownMenuItem(value: "MEDIUM", child: Text("Medium")),
                        DropdownMenuItem(value: "HIGH", child: Text("High")),
                        DropdownMenuItem(value: "CRITICAL", child: Text("Critical")),
                      ],
                      onChanged: (val) => setModalState(() => priority = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Operational Details / Notes",
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (titleController.text.trim().isEmpty) return;
                          Navigator.pop(ctx);
                          try {
                            await _api.post('/api/v1/tasks/tasks/', {
                              'title': titleController.text.trim(),
                              'description': descController.text.trim(),
                              'priority': priority,
                              'task_type': 'STANDARD',
                            });
                            _loadTasks();
                          } catch (e) {
                            debugPrint("Create task err: $e");
                          }
                        },
                        child: const Text("CREATE TASK", style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _advanceTaskStage(dynamic task) async {
    final String currentStatus = task['status'] ?? 'ASSIGNED';
    String nextStatus = 'IN_PROGRESS';
    if (currentStatus == 'ASSIGNED') nextStatus = 'ACCEPTED';
    else if (currentStatus == 'ACCEPTED') nextStatus = 'IN_PROGRESS';
    else if (currentStatus == 'IN_PROGRESS') nextStatus = 'WAITING';
    else if (currentStatus == 'WAITING') nextStatus = 'COMPLETED';
    else if (currentStatus == 'COMPLETED') nextStatus = 'VERIFIED';

    try {
      await _api.patch('/api/v1/tasks/tasks/${task['id']}/', {'status': nextStatus});
      _loadTasks();
    } catch (e) {
      debugPrint("Update status err: $e");
    }
  }

  List<dynamic> _getFilteredTasks(int tabIndex) {
    return _allTasks.where((task) {
      final String title = (task['title'] ?? '').toString().toLowerCase();
      final String status = (task['status'] ?? '').toString().toUpperCase();

      if (_searchQuery.isNotEmpty && !title.contains(_searchQuery.toLowerCase())) {
        return false;
      }

      if (tabIndex == 0) return true; // My Tasks
      if (tabIndex == 1) return status == 'ASSIGNED' || status == 'ACCEPTED';
      if (tabIndex == 2) return status == 'IN_PROGRESS' || status == 'WAITING';
      if (tabIndex == 3) return status == 'COMPLETED' || status == 'VERIFIED';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          "Operations Work Hub",
          style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF10B981)),
            onPressed: _showNewTaskModal,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          indicatorWeight: 3,
          labelColor: const Color(0xFF10B981),
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: "All Tasks"),
            Tab(text: "Assigned"),
            Tab(text: "In Progress"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          _buildSearchAndFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTaskList(0),
                      _buildTaskList(1),
                      _buildTaskList(2),
                      _buildTaskList(3),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: <Widget>[
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: "Search operations tasks...",
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.take(8).map((cat) {
                final bool isSel = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSel,
                    selectedColor: const Color(0xFF10B981).withOpacity(0.2),
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(
                      color: isSel ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: isSel ? const Color(0xFF10B981) : const Color(0xFF334155),
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(int tabIndex) {
    final tasks = _getFilteredTasks(tabIndex);
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF475569), size: 48),
            SizedBox(height: 12),
            Text(
              "No tasks in this category",
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final String title = task['title'] ?? 'Operations Task';
        final String priority = task['priority'] ?? 'MEDIUM';
        final String status = task['status'] ?? 'ASSIGNED';

        Color prioColor = const Color(0xFF38BDF8);
        if (priority == 'CRITICAL' || priority == 'HIGH') prioColor = const Color(0xFFEF4444);
        if (priority == 'MEDIUM') prioColor = const Color(0xFFF59E0B);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: prioColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: prioColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      priority,
                      style: TextStyle(color: prioColor, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.replaceAll('_', ' '),
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 15, fontWeight: FontWeight.w700),
              ),
              if (task['description'] != null && task['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  task['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "Stage: $status",
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _advanceTaskStage(task),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text("Next Stage", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
