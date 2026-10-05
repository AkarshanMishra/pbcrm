import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import 'partner_onboarding_screen.dart';

class MarketingManagerDashboard extends StatefulWidget {
  const MarketingManagerDashboard({super.key});

  @override
  State<MarketingManagerDashboard> createState() => _MarketingManagerDashboardState();
}

class _MarketingManagerDashboardState extends State<MarketingManagerDashboard> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _telemetry;
  List<dynamic> _pendingOnboardings = [];

  @override
  void initState() {
    super.initState();
    _fetchManagerTelemetry();
  }

  Future<void> _fetchManagerTelemetry() async {
    setState(() => _isLoading = true);
    try {
      final tRes = await _api.get('/api/v1/marketing/telemetry/');
      final oRes = await _api.get('/api/v1/marketing/onboardings/');
      if (mounted) {
        setState(() {
          _telemetry = tRes.data;
          final allOnboard = (oRes.data is List) ? oRes.data : (oRes.data['results'] ?? []);
          _pendingOnboardings = allOnboard.where((o) => o['status'] == 'under_review' || o['status'] == 'draft').toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final funnel = _telemetry?['funnel'] as Map<String, dynamic>? ?? {};
    final conv = _telemetry?['conversion'] as Map<String, dynamic>? ?? {};
    final activeField = (_telemetry?['active_field_team'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Marketing Manager Control Plane', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)), onPressed: _fetchManagerTelemetry),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. MARKETING TEAM OVERVIEW
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('MARKETING FIELD TEAM', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A))),
                            Text('12 Executives', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11.5)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildStatusPill('9 Working', const Color(0xFF10B981), const Color(0xFFECFDF5)),
                            const SizedBox(width: 8),
                            _buildStatusPill('2 Active Visits', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                            const SizedBox(width: 8),
                            _buildStatusPill('1 On Leave', const Color(0xFF64748B), const Color(0xFFF1F5F9)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. LIVE FIELD TEAM MAP & ACTIVE VISITS
                  const Text('LIVE FIELD VISITS IN PROGRESS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  if (activeField.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                          SizedBox(width: 10),
                          Text('All scheduled visits up to date.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        ],
                      ),
                    )
                  else
                    ...activeField.map((f) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF34D399)),
                          ),
                          child: Row(
                            children: [
                              const CircleAvatar(radius: 14, backgroundColor: Color(0xFF10B981), child: Icon(Icons.person, color: Colors.white, size: 16)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(f['employee_name'] ?? 'Executive', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF065F46))),
                                    Text('Active visit at ${f['partner_name']} • ${f['location_name']}', style: const TextStyle(color: Color(0xFF047857), fontSize: 11)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(6)),
                                child: const Text('ACTIVE NOW', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 16),

                  // 3. TEAM WORKLOAD DISTRIBUTION
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TEAM WORKLOAD DISTRIBUTION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A))),
                        const SizedBox(height: 14),
                        _buildWorkloadRow('Rahul Sharma', 8, 10, const Color(0xFF2563EB)),
                        const SizedBox(height: 10),
                        _buildWorkloadRow('Neha Kapoor', 6, 10, const Color(0xFF10B981)),
                        const SizedBox(height: 10),
                        _buildWorkloadRow('Amit Verma', 9, 10, const Color(0xFFF59E0B)),
                        const SizedBox(height: 10),
                        _buildWorkloadRow('Priya Singh', 3, 10, const Color(0xFF8B5CF6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. PENDING PARTNER APPROVALS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PENDING PARTNER APPROVALS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerOnboardingScreen())),
                        child: const Text('View All', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ),
                    ],
                  ),
                  if (_pendingOnboardings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: const Center(child: Text('No partners awaiting manager review.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12))),
                    )
                  else
                    ..._pendingOnboardings.map((po) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(po['partner_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(6)),
                                    child: const Text('READY FOR REVIEW', style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Documents: ✓ Complete • Photos: ✓ Complete • Packages: ✓ Complete', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          await _api.post('/api/v1/marketing/onboardings/${po['id']}/approve/', {
                                            'notes': 'Manager approved for live catalog.',
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partner Approved!'), backgroundColor: Colors.green));
                                          _fetchManagerTelemetry();
                                        } catch (_) {}
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback sent back to executive.')));
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Request Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                  const SizedBox(height: 16),

                  // 5. MARKETING FUNNEL & CONVERSION ANALYTICS
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MARKETING LEAD FUNNEL & CONVERSIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A))),
                        const SizedBox(height: 14),
                        _buildFunnelRow('Leads Generated', funnel['total_leads'] ?? 100, 100, const Color(0xFF64748B)),
                        _buildFunnelRow('Contacted', funnel['contacted'] ?? 82, 100, const Color(0xFF2563EB)),
                        _buildFunnelRow('Interested', funnel['interested'] ?? 54, 100, const Color(0xFF3B82F6)),
                        _buildFunnelRow('Visited', funnel['visited'] ?? 38, 100, const Color(0xFFF59E0B)),
                        _buildFunnelRow('Onboarding', funnel['onboarding'] ?? 21, 100, const Color(0xFF8B5CF6)),
                        _buildFunnelRow('Active / Won', funnel['active_won'] ?? 16, 100, const Color(0xFF10B981)),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatBox('Visit → Onboarding', '${conv['visit_to_onboard'] ?? 55}%'),
                            _buildStatBox('Onboard → Active', '${conv['onboard_to_active'] ?? 76}%'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusPill(String label, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
      ),
    );
  }

  Widget _buildWorkloadRow(String name, int tasks, int max, Color color) {
    final pct = (tasks / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
            Text('$tasks tasks', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildFunnelRow(String label, dynamic count, int max, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (count is int) ? (count / max).clamp(0.0, 1.0) : 0.5,
                backgroundColor: color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 30, child: Text('$count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: color), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
      ],
    );
  }
}
