import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ManagementOverviewScreen extends StatefulWidget {
  const ManagementOverviewScreen({super.key});

  @override
  State<ManagementOverviewScreen> createState() => _ManagementOverviewScreenState();
}

class _ManagementOverviewScreenState extends State<ManagementOverviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _strategicGoals = [
    {
      'title': 'Q4 Partner Expansion (Lucknow & Kanpur)',
      'department': 'Marketing & Sales',
      'owner': 'Rohan Gupta',
      'target': '150 Active Banquets',
      'current': '118 Banquets',
      'progress': 0.78,
      'status': 'ON_TRACK',
      'dueDate': '31 Dec 2026',
    },
    {
      'title': 'Event Execution Zero-Defect Initiative',
      'department': 'Operations',
      'owner': 'Kavita Nair',
      'target': '99.5% SLA Compliance',
      'current': '98.8% SLA',
      'progress': 0.92,
      'status': 'ON_TRACK',
      'dueDate': '15 Nov 2026',
    },
    {
      'title': 'Automated Multi-Channel Settlement V2',
      'department': 'Accounts & IT',
      'owner': 'Akarshan Mishra',
      'target': '100% Instant 12% Payouts',
      'current': '85% Implemented',
      'progress': 0.85,
      'status': 'NEEDS_ATTENTION',
      'dueDate': '25 Oct 2026',
    },
    {
      'title': 'Workforce Retention & Upskilling',
      'department': 'Human Resources',
      'owner': 'Neha Sharma',
      'target': '< 3% Quarterly Churn',
      'current': '1.8% Churn',
      'progress': 0.95,
      'status': 'EXCEEDED',
      'dueDate': '31 Dec 2026',
    },
  ];

  final List<Map<String, dynamic>> _deptScorecards = [
    {
      'name': 'Human Resources',
      'head': 'Neha Sharma',
      'headcount': 124,
      'attendance': '95.2%',
      'kpiScore': '92/100',
      'openPositions': 8,
      'status': 'HEALTHY',
      'color': Color(0xFFF43F5E),
      'icon': Icons.groups_rounded,
    },
    {
      'name': 'IT & Infrastructure',
      'head': 'Akarshan Mishra',
      'headcount': 18,
      'uptime': '99.98%',
      'kpiScore': '96/100',
      'openTickets': 4,
      'status': 'HEALTHY',
      'color': Color(0xFF0284C7),
      'icon': Icons.laptop_chromebook_rounded,
    },
    {
      'name': 'Marketing & Growth',
      'head': 'Rohan Gupta',
      'headcount': 24,
      'conversionRate': '28.4%',
      'kpiScore': '88/100',
      'pipelineLeads': 64,
      'status': 'NEEDS_ATTENTION',
      'color': Color(0xFF10B981),
      'icon': Icons.campaign_rounded,
    },
    {
      'name': 'Operations & Fulfillment',
      'head': 'Kavita Nair',
      'headcount': 31,
      'eventReadiness': '99.1%',
      'kpiScore': '94/100',
      'activeEvents': 19,
      'status': 'HEALTHY',
      'color': Color(0xFFF59E0B),
      'icon': Icons.settings_rounded,
    },
    {
      'name': 'Accounts & Finance',
      'head': 'Deepak Verma',
      'headcount': 10,
      'cashCollection': '98.5%',
      'kpiScore': '91/100',
      'pendingSettlements': 6,
      'status': 'HEALTHY',
      'color': Color(0xFF8B5CF6),
      'icon': Icons.monetization_on_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.military_tech_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Executive Management Overview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export Board Report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📄 Executive Board Report exported to PDF successfully')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Metrics',
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_customize_rounded), text: 'Executive KPIs'),
            Tab(icon: Icon(Icons.flag_rounded), text: 'Strategic Goals & OKRs'),
            Tab(icon: Icon(Icons.domain_verification_rounded), text: 'Department Scorecards'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExecutiveKPIsTab(),
          _buildStrategicGoalsTab(),
          _buildDepartmentScorecardsTab(),
        ],
      ),
    );
  }

  Widget _buildExecutiveKPIsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Revenue & Target Header Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_graph_rounded, color: Color(0xFF38BDF8), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'PARTYBALA ENTERPRISE VELOCITY',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Gross Bookings', style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13)),
                      SizedBox(height: 4),
                      Text('₹ 48,50,000', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Target: ₹ 50,00,000', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      SizedBox(height: 4),
                      Text('97.0% Achieved', style: TextStyle(color: Color(0xFF34D399), fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  value: 0.97,
                  backgroundColor: Color(0xFF334155),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 4 Core Executive Metric Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Active Workforce',
                '124',
                '+6 this month',
                Icons.people_alt_rounded,
                const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Bookings in Execution',
                '38',
                '100% on schedule',
                Icons.celebration_rounded,
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Verified Partners',
                '142',
                '12% Commission Model',
                Icons.handshake_rounded,
                const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Cross-Dept SLA',
                '98.4%',
                'Target > 95%',
                Icons.verified_rounded,
                const Color(0xFF8B5CF6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick Executive Decisions / Escalations
        const Text(
          'EXECUTIVE ESCALATIONS & APPROVAL GATE',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        _buildEscalationTile(
          'Custom Partner Commission Exception (9.5% vs Standard 12%)',
          'Requested by Rohan Gupta (Marketing) for Grand Hyatt Ballrooms',
          'HIGH PRIORITY',
          Colors.orange,
        ),
        _buildEscalationTile(
          'CapEx Budget Allocation for High-Density Mobile Fleet Devices',
          'Requested by Akarshan Mishra (IT) · ₹ 2,40,000 Total Outlay',
          'BOARD APPROVAL',
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStrategicGoalsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _strategicGoals.length,
      itemBuilder: (context, index) {
        final goal = _strategicGoals[index];
        final progress = (goal['progress'] as double);
        final statusColor = goal['status'] == 'EXCEEDED'
            ? const Color(0xFF10B981)
            : goal['status'] == 'ON_TRACK'
                ? const Color(0xFF2563EB)
                : const Color(0xFFF59E0B);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        goal['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        goal['status'].toString().replaceAll('_', ' '),
                        style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Owner: ${goal['owner']} · Dept: ${goal['department']} · Due: ${goal['dueDate']}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current: ${goal['current']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('Target: ${goal['target']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDepartmentScorecardsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _deptScorecards.length,
      itemBuilder: (context, index) {
        final scorecard = _deptScorecards[index];
        final Color deptColor = scorecard['color'];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: deptColor.withOpacity(0.12),
                  child: Icon(scorecard['icon'], color: deptColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            scorecard['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Score: ${scorecard['kpiScore']}',
                              style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Department Lead: ${scorecard['head']} · ${scorecard['headcount']} Employees',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          if (scorecard.containsKey('attendance'))
                            _buildScorecardMetric('Attendance', scorecard['attendance']),
                          if (scorecard.containsKey('uptime'))
                            _buildScorecardMetric('Infra Uptime', scorecard['uptime']),
                          if (scorecard.containsKey('conversionRate'))
                            _buildScorecardMetric('Conversion', scorecard['conversionRate']),
                          if (scorecard.containsKey('eventReadiness'))
                            _buildScorecardMetric('Readiness', scorecard['eventReadiness']),
                          if (scorecard.containsKey('cashCollection'))
                            _buildScorecardMetric('Collection', scorecard['cashCollection']),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScorecardMetric(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, String subtext, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtext, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEscalationTile(String title, String desc, String priority, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(Icons.gavel_rounded, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        trailing: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Decision recorded for "$title"')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F172A),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
