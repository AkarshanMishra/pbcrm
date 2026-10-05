import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class AdminMasterWorkflowScreen extends StatefulWidget {
  final String? initialEntityId;
  final String? initialEntityType;

  const AdminMasterWorkflowScreen({
    super.key,
    this.initialEntityId,
    this.initialEntityType,
  });

  @override
  State<AdminMasterWorkflowScreen> createState() => _AdminMasterWorkflowScreenState();
}

class _AdminMasterWorkflowScreenState extends State<AdminMasterWorkflowScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  bool _isLoading = true;
  String _selectedFilter = 'ALL';

  List<dynamic> _workflows = [];
  List<dynamic> _events = [];

  // 360 Graph state
  String _searchEntityId = 'PBV0000001';
  String _searchEntityType = 'partner';
  Map<String, dynamic>? _graphData;
  bool _isGraphLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialEntityId != null) {
      _searchEntityId = widget.initialEntityId!;
      _searchEntityType = widget.initialEntityType ?? 'employee';
      _tabController.index = 1; // Jump to 360 Graph
    }
    _fetchWorkflows();
    _fetch360Graph();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkflows() async {
    setState(() => _isLoading = true);
    try {
      final wfRes = await _api.dio.get('/core/workflows/');
      final evRes = await _api.dio.get('/core/events/');

      final wfs = (wfRes.data['results'] ?? wfRes.data ?? []) as List<dynamic>;
      final evs = (evRes.data['results'] ?? evRes.data ?? []) as List<dynamic>;

      setState(() {
        _workflows = wfs;
        _events = evs;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetch360Graph() async {
    setState(() => _isGraphLoading = true);
    try {
      final res = await _api.dio.get('/core/360-graph/', queryParameters: {
        'entity_type': _searchEntityType,
        'entity_id': _searchEntityId.trim(),
      });
      setState(() {
        _graphData = res.data;
        _isGraphLoading = false;
      });
    } catch (_) {
      setState(() => _isGraphLoading = false);
    }
  }

  void _advanceWorkflowStep(String processId, String stepId, String action) async {
    try {
      await _api.dio.post('/core/workflows/$processId/advance-step/', data: {
        'step_id': stepId,
        'action': action,
        'comments': action == 'APPROVE' ? 'Approved by Super Admin.' : 'Step completed successfully.',
      });
      _fetchWorkflows();
      _fetch360Graph();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Process advanced and next department handoff triggered!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to advance step.'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Organization Workflow & 360° Graph'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Pipelines',
            onPressed: () {
              _fetchWorkflows();
              _fetch360Graph();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.account_tree_rounded), text: 'Active Workflows'),
            Tab(icon: Icon(Icons.hub_rounded), text: '360° Relationship Graph'),
            Tab(icon: Icon(Icons.event_note_rounded), text: 'Central Event Stream'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWorkflowsTab(),
                _build360GraphTab(),
                _buildEventStreamTab(),
              ],
            ),
    );
  }

  // ==========================================
  // TAB 1: ACTIVE WORKFLOW PIPELINES
  // ==========================================
  Widget _buildWorkflowsTab() {
    final filtered = _selectedFilter == 'ALL'
        ? _workflows
        : _workflows.where((w) => w['workflow_type'] == _selectedFilter).toList();

    return Column(
      children: [
        // Filter Pills
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFFF8FAFC),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Pipelines', 'ALL'),
                const SizedBox(width: 8),
                _buildFilterChip('PartyBala Partner', 'PARTNER_ONBOARDING'),
                const SizedBox(width: 8),
                _buildFilterChip('Employee Onboarding', 'EMPLOYEE_ONBOARDING'),
                const SizedBox(width: 8),
                _buildFilterChip('Booking Execution', 'BOOKING_OPERATIONS'),
                const SizedBox(width: 8),
                _buildFilterChip('IT Incidents', 'IT_INCIDENT'),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // Workflow Cards List
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No active workflows in this category.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) => _buildWorkflowCard(filtered[idx]),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: Colors.white,
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = value);
      },
    );
  }

  Widget _buildWorkflowCard(Map<String, dynamic> wf) {
    final steps = (wf['steps'] ?? []) as List<dynamic>;
    final code = wf['process_code'] ?? 'WF-000';
    final title = wf['title'] ?? 'Workflow';
    final dept = wf['current_department'] ?? 'General';
    final role = wf['current_role'] ?? 'Specialist';
    final stage = wf['current_stage_name'] ?? 'In Progress';
    final progress = wf['progress_percentage'] ?? 0;
    final entityId = wf['entity_id'] ?? '--';
    final entityType = wf['entity_type'] ?? 'entity';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
                  ),
                  child: Text(code, style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold, fontSize: 11)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$progress% Complete', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title & Entity ID
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.link, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Linked Entity: $entityId ($entityType)', style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _searchEntityId = entityId;
                      _searchEntityType = entityType;
                      _tabController.index = 1;
                    });
                    _fetch360Graph();
                  },
                  icon: const Icon(Icons.hub_outlined, size: 14),
                  label: const Text('View 360° Graph', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Current Active Stage Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CURRENT STAGE: $stage', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        Text('Responsible: $role ($dept)', style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Horizontal Step Progress Dots
            const Text('WORKFLOW STAGES & HANDOFFS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            ...steps.map((s) => _buildStepRow(wf['id'], s)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String processId, Map<String, dynamic> step) {
    final status = step['status'] ?? 'PENDING';
    final isCompleted = status == 'COMPLETED' || status == 'APPROVED';
    final isInProgress = status == 'IN_PROGRESS' || status == 'PENDING_APPROVAL';

    Color color = Colors.grey;
    IconData icon = Icons.radio_button_unchecked;
    if (isCompleted) {
      color = Colors.green;
      icon = Icons.check_circle_rounded;
    } else if (isInProgress) {
      color = Colors.blue;
      icon = Icons.play_circle_fill_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${step['step_order']}. ${step['title']}',
                  style: TextStyle(
                    fontWeight: isInProgress ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12.5,
                    color: isCompleted ? Colors.black87 : (isInProgress ? AppTheme.primary : Colors.grey.shade600),
                  ),
                ),
                Text('${step['department']} • ${step['responsible_role']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ],
            ),
          ),
          if (isInProgress)
            ElevatedButton(
              onPressed: () => _advanceWorkflowStep(processId, step['id'], step['action_type'] == 'APPROVAL' ? 'APPROVE' : 'COMPLETE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
              ),
              child: Text(step['action_type'] == 'APPROVAL' ? 'Approve' : 'Complete Step', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: 360° RELATIONSHIP GRAPH VIEWER
  // ==========================================
  Widget _build360GraphTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Entity Picker Bar
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  DropdownButton<String>(
                    value: _searchEntityType,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'partner', child: Text('Partner')),
                      DropdownMenuItem(value: 'employee', child: Text('Employee')),
                      DropdownMenuItem(value: 'booking', child: Text('Booking')),
                      DropdownMenuItem(value: 'issue', child: Text('IT Issue')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _searchEntityType = val);
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Entity ID (e.g. PBV0000001, PBE000003, BK-2026-001)...',
                        border: InputBorder.none,
                      ),
                      controller: TextEditingController(text: _searchEntityId)..selection = TextSelection.collapsed(offset: _searchEntityId.length),
                      onChanged: (val) => _searchEntityId = val,
                      onSubmitted: (_) => _fetch360Graph(),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _fetch360Graph,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                    icon: const Icon(Icons.hub_rounded, size: 16),
                    label: const Text('Generate Graph'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Graph Canvas
          if (_isGraphLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_graphData == null || (_graphData?['nodes'] as List?)?.isEmpty == true)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No cross-department relationships found for this ID.')))
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('360° Relationship Topology for ${_graphData?['entity_id']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('${_graphData?['total_nodes']} Nodes • ${_graphData?['total_edges']} Handoff Edges', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // Visual Tree of Connected Nodes
            ...((_graphData?['nodes'] ?? []) as List<dynamic>).map((node) {
              final type = node['type'] ?? 'NODE';
              final label = node['label'] ?? '';
              final dept = node['department'] ?? 'General';
              final status = node['status'] ?? 'ACTIVE';

              Color cardColor = Colors.white;
              IconData nodeIcon = Icons.circle;
              if (type == 'MASTER_ENTITY') {
                cardColor = const Color(0xFFEFF6FF);
                nodeIcon = Icons.star_rounded;
              } else if (type == 'WORKFLOW_PROCESS') {
                cardColor = const Color(0xFFFFFBEB);
                nodeIcon = Icons.account_tree_rounded;
              } else {
                cardColor = const Color(0xFFF8FAFC);
                nodeIcon = Icons.arrow_forward_rounded;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(nodeIcon, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          Text('Department: $dept • Status: $status', style: TextStyle(color: Colors.grey.shade700, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: CENTRAL EVENT STREAM
  // ==========================================
  Widget _buildEventStreamTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, idx) {
        final ev = _events[idx];
        final eventType = ev['event_type'] ?? 'EVENT';
        final entityId = ev['entity_id'] ?? '--';
        final entityType = ev['entity_type'] ?? 'entity';
        final actor = ev['actor_name'] ?? 'System Engine';
        final time = ev['created_at'] != null ? ev['created_at'].toString().substring(0, 16).replaceAll('T', ' ') : 'Just now';

        return ListTile(
          leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.bolt_rounded, color: Colors.blue)),
          title: Text(eventType.toString().replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          subtitle: Text('Target: $entityType #$entityId • Actor: $actor\n$time', style: TextStyle(color: Colors.grey.shade700, fontSize: 11.5)),
          isThreeLine: true,
          dense: true,
        );
      },
    );
  }
}
