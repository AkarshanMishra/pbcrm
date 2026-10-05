import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'partner_onboarding_screen.dart';
import 'visit_management_screen.dart';

class LeadsPipelineScreen extends StatefulWidget {
  const LeadsPipelineScreen({super.key});

  @override
  State<LeadsPipelineScreen> createState() => _LeadsPipelineScreenState();
}

class _LeadsPipelineScreenState extends State<LeadsPipelineScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  bool _isKanbanView = false;
  List<dynamic> _leads = [];
  Map<String, dynamic> _pipeline = {};
  String _searchQuery = '';

  late TabController _tabController;
  final List<String> _stages = [
    'all',
    'new',
    'contacted',
    'interested',
    'visit_scheduled',
    'visited',
    'negotiation',
    'onboarding',
    'active',
    'lost',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _stages.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchLeads();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeads() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/v1/marketing/leads/');
      final pipeRes = await _api.get('/api/v1/marketing/leads/pipeline/');
      if (mounted) {
        setState(() {
          _leads = (res.data is List) ? res.data : (res.data['results'] ?? []);
          _pipeline = pipeRes.data ?? {};
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredLeads {
    final currentStage = _stages[_tabController.index];
    return _leads.filter((lead) {
      if (currentStage != 'all' && lead['status'] != currentStage) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = (lead['business_name'] ?? '').toString().toLowerCase();
        final contact = (lead['contact_person'] ?? '').toString().toLowerCase();
        final phone = (lead['phone'] ?? '').toString().toLowerCase();
        final area = (lead['area'] ?? '').toString().toLowerCase();
        return name.contains(query) || contact.contains(query) || phone.contains(query) || area.contains(query);
      }
      return true;
    }).toList();
  }

  void _showLeadDetailSheet(dynamic lead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final timeline = (lead['activity_timeline'] as List<dynamic>?) ?? [];
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header & Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lead['business_name'] ?? 'Unnamed Business',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 3),
                            Text('${lead['lead_code'] ?? ''} • ${lead['lead_type']?.toString().toUpperCase() ?? 'VENUE'}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(lead['status']).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getStatusColor(lead['status']).withOpacity(0.3)),
                        ),
                        child: Text(
                          (lead['status'] ?? 'NEW').toString().replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(color: _getStatusColor(lead['status']), fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Primary Contact Info Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildContactRow(Icons.person_rounded, 'Contact Person', lead['contact_person'] ?? 'N/A'),
                        const SizedBox(height: 8),
                        _buildContactRow(Icons.phone_rounded, 'Phone Number', lead['phone'] ?? 'N/A'),
                        const SizedBox(height: 8),
                        _buildContactRow(Icons.place_rounded, 'Location', '${lead['area'] ?? ''}, ${lead['city'] ?? 'Kanpur'}'),
                        if (lead['notes'] != null && lead['notes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildContactRow(Icons.notes_rounded, 'Notes', lead['notes']),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons Matrix
                  const Text('QUICK ACTIONS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dialing ${lead['phone']}...')));
                            _logLeadActivity(lead['id'], 'call', 'Called partner contact person');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening WhatsApp for ${lead['phone']}...')));
                            _logLeadActivity(lead['id'], 'whatsapp', 'Initiated WhatsApp conversation');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.chat_rounded, size: 16),
                          label: const Text('WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitManagementScreen()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.place_rounded, size: 16),
                          label: const Text('Start Visit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerOnboardingScreen()));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5CF6),
                        side: const BorderSide(color: Color(0xFF8B5CF6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.handshake_rounded, size: 17),
                      label: const Text('Convert to Partner Onboarding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stage Progression Dropdown
                  Row(
                    children: [
                      const Text('Pipeline Stage:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: lead['status'],
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'new', child: Text('New Lead')),
                            DropdownMenuItem(value: 'contacted', child: Text('Contacted')),
                            DropdownMenuItem(value: 'interested', child: Text('Interested')),
                            DropdownMenuItem(value: 'visit_scheduled', child: Text('Visit Scheduled')),
                            DropdownMenuItem(value: 'visited', child: Text('Visited')),
                            DropdownMenuItem(value: 'negotiation', child: Text('In Negotiation')),
                            DropdownMenuItem(value: 'onboarding', child: Text('Onboarding')),
                            DropdownMenuItem(value: 'active', child: Text('Active / Won')),
                            DropdownMenuItem(value: 'lost', child: Text('Lost / Dropped')),
                          ],
                          onChanged: (newVal) async {
                            if (newVal != null && newVal != lead['status']) {
                              try {
                                await _api.post('/api/v1/marketing/leads/${lead['id']}/quick-status/', {'status': newVal});
                                lead['status'] = newVal;
                                setModalState(() {});
                                _fetchLeads();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status changed to $newVal'), backgroundColor: Colors.green));
                              } catch (_) {}
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Activity Timeline
                  const Text('ACTIVITY TIMELINE', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  if (timeline.isEmpty)
                    const Text('No logged activities yet.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))
                  else
                    ...timeline.map((act) => _buildTimelineItem(act)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 16),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(dynamic act) {
    final type = act['type'] ?? 'note';
    final note = act['note'] ?? '';
    final by = act['by'] ?? 'User';
    final time = (act['timestamp'] ?? '').toString().substring(0, 10);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.history_rounded, size: 14, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(note, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                Text('$by • $time', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logLeadActivity(String leadId, String type, String note) async {
    try {
      await _api.post('/api/v1/marketing/leads/$leadId/add-activity/', {
        'type': type,
        'note': note,
      });
      _fetchLeads();
    } catch (_) {}
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'active':
        return const Color(0xFF10B981);
      case 'onboarding':
      case 'negotiation':
        return const Color(0xFF8B5CF6);
      case 'interested':
      case 'visited':
        return const Color(0xFF2563EB);
      case 'visit_scheduled':
      case 'contacted':
        return const Color(0xFFF59E0B);
      case 'lost':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Leads & Deals Pipeline', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(
            icon: Icon(_isKanbanView ? Icons.view_list_rounded : Icons.view_kanban_rounded, color: const Color(0xFF2563EB)),
            tooltip: _isKanbanView ? 'Switch to List View' : 'Switch to Pipeline Board',
            onPressed: () => setState(() => _isKanbanView = !_isKanbanView),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)),
            tooltip: 'Refresh Leads',
            onPressed: _fetchLeads,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: const InputDecoration(
                      hintText: 'Search leads, contacts, areas, phone...',
                      prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                indicatorColor: const Color(0xFF2563EB),
                indicatorWeight: 3,
                tabs: _stages.map((st) => Tab(text: st.replaceAll('_', ' ').toUpperCase())).toList(),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isKanbanView
              ? _buildKanbanPipelineView()
              : _buildListView(),
    );
  }

  Widget _buildListView() {
    final leads = _filteredLeads;
    if (leads.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No leads found in this pipeline stage.\nTap "+" to create a new lead.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8))),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: leads.length,
      itemBuilder: (ctx, i) {
        final lead = leads[i];
        final statusColor = _getStatusColor(lead['status']);
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
            onTap: () => _showLeadDetailSheet(lead),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          lead['business_name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (lead['status'] ?? 'NEW').toString().replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lead['contact_person'] ?? ''} • 📞 ${lead['phone'] ?? ''}',
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text('${lead['area'] ?? ''}, ${lead['city'] ?? 'Kanpur'}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                      const Spacer(),
                      if (lead['priority'] == 'urgent' || lead['priority'] == 'high')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(4)),
                          child: Text(lead['priority'].toString().toUpperCase(), style: const TextStyle(color: Color(0xFFDC2626), fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ),
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

  Widget _buildKanbanPipelineView() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      itemCount: _stages.length - 1, // Exclude 'all'
      itemBuilder: (ctx, i) {
        final stageKey = _stages[i + 1];
        final stageData = _pipeline[stageKey] as Map<String, dynamic>?;
        final count = stageData?['count'] ?? 0;
        final stageLeads = (stageData?['leads'] as List<dynamic>?) ?? [];

        return Container(
          width: 260,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column Header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stageKey.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF1E293B)),
                    ),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: const Color(0xFF2563EB),
                      child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Column Leads
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: stageLeads.length,
                  itemBuilder: (ctx, li) {
                    final l = stageLeads[li];
                    return Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        dense: true,
                        title: Text(l['business_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                        subtitle: Text(l['contact_person'] ?? '', style: const TextStyle(fontSize: 11)),
                        onTap: () => _showLeadDetailSheet(l),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

extension IterableExtension<E> on Iterable<E> {
  Iterable<E> filter(bool Function(E element) test) => where(test);
}
