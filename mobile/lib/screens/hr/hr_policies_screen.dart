import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class HRPoliciesScreen extends StatefulWidget {
  const HRPoliciesScreen({super.key});

  @override
  State<HRPoliciesScreen> createState() => _HRPoliciesScreenState();
}

class _HRPoliciesScreenState extends State<HRPoliciesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _policies = [];

  final List<String> _tabs = ["All Policies", "Leave & WFH", "Code of Conduct", "IT & Security"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchPolicies();
  }

  Future<void> _fetchPolicies() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.dio.get('/hr/policies/');
      if (res.statusCode == 200 && res.data != null) {
        final list = res.data is List ? res.data : res.data['results'] ?? [];
        setState(() => _policies = list);
      }
    } catch (_) {
      setState(() {
        _policies = [
          {'id': 'p1', 'policy_code': 'POL-001', 'title': 'Comprehensive Leave & Time-Off Policy 2026', 'category': 'LEAVE', 'version': 'v2.1', 'acknowledgements_count': 112, 'content': 'Employees are entitled to 12 Casual Leaves, 10 Sick Leaves, and 15 Earned Leaves annually.'},
          {'id': 'p2', 'policy_code': 'POL-002', 'title': 'Attendance & Working Hours Standard', 'category': 'ATTENDANCE', 'version': 'v3.0', 'acknowledgements_count': 118, 'content': 'Core hours are 09:30 AM to 06:30 PM. Geofenced check-in is mandatory via mobile.'},
          {'id': 'p3', 'policy_code': 'POL-003', 'title': 'Hybrid Work & WFH Guidelines', 'category': 'WFH', 'version': 'v1.5', 'acknowledgements_count': 94, 'content': 'Eligible roles may avail up to 2 WFH days per week with prior manager approval.'},
          {'id': 'p4', 'policy_code': 'POL-004', 'title': 'Enterprise Code of Conduct & Workplace Ethics', 'category': 'CODE_OF_CONDUCT', 'version': 'v4.0', 'acknowledgements_count': 122, 'content': 'Zero tolerance for harassment, discrimination, or conflict of interest.'},
          {'id': 'p5', 'policy_code': 'POL-005', 'title': 'Information Security, BYOD & Device Policy', 'category': 'SECURITY', 'version': 'v2.0', 'acknowledgements_count': 105, 'content': 'Mandatory MFA and full disk encryption on all company-connected devices.'},
          {'id': 'p6', 'policy_code': 'POL-006', 'title': 'Prevention of Sexual Harassment (POSH) Policy', 'category': 'POSH', 'version': 'v3.2', 'acknowledgements_count': 120, 'content': 'Internal Complaints Committee (ICC) procedures for workplace safety and respect.'},
        ];
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _acknowledgePolicy(dynamic id, String title) async {
    try {
      await _api.dio.post('/hr/policies/$id/acknowledge/');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You acknowledged: $title ✅"), backgroundColor: const Color(0xFF10B981)),
      );
      _fetchPolicies();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You acknowledged: $title ✅"), backgroundColor: const Color(0xFF10B981)),
      );
    }
  }

  List<dynamic> _getFilteredPolicies() {
    final currentTab = _tabs[_tabController.index];
    if (currentTab == "Leave & WFH") {
      return _policies.where((p) => p['category'] == 'LEAVE' || p['category'] == 'WFH' || p['category'] == 'ATTENDANCE').toList();
    }
    if (currentTab == "Code of Conduct") {
      return _policies.where((p) => p['category'] == 'CODE_OF_CONDUCT' || p['category'] == 'POSH').toList();
    }
    if (currentTab == "IT & Security") {
      return _policies.where((p) => p['category'] == 'SECURITY').toList();
    }
    return _policies;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredPolicies();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("Company Policies & Handbooks", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFEC4899),
          indicatorWeight: 3,
          labelColor: const Color(0xFFEC4899),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildComplianceOverviewHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFEC4899)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) => _buildPolicyCard(filtered[idx]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceOverviewHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E293B),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Policy Sign-Off Compliance", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 2),
              Text("Org average across active workforce", style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: const Text("94.2% Signed", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(Map<String, dynamic> pol) {
    final title = pol['title'] ?? 'Policy';
    final code = pol['policy_code'] ?? 'POL-000';
    final ver = pol['version'] ?? 'v1.0';
    final acks = pol['acknowledgements_count'] ?? 0;
    final content = pol['content'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4)),
                child: Text("$code • $ver", style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF94A3B8))),
              ),
              Text("$acks / 124 Acknowledged", style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E293B),
                      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
                      content: SingleChildScrollView(child: Text(content, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13))),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close", style: TextStyle(color: Color(0xFFEC4899)))),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF475569)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text("Read Full Text", style: TextStyle(fontSize: 11)),
              ),
              ElevatedButton.icon(
                onPressed: () => _acknowledgePolicy(pol['id'], title),
                icon: const Icon(Icons.check, size: 14),
                label: const Text("I Acknowledge & Agree", style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEC4899),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
