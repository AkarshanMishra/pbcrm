import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../hr/hr_shell_screen.dart';
import '../it/it_shell_screen.dart';
import '../marketing/marketing_shell_screen.dart';
import '../operations/operations_shell_screen.dart';
import '../accounts/accounts_finance_screen.dart';

class ManagementOverviewScreen extends StatefulWidget {
  const ManagementOverviewScreen({super.key});

  @override
  State<ManagementOverviewScreen> createState() => _ManagementOverviewScreenState();
}

class _ManagementOverviewScreenState extends State<ManagementOverviewScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _goalFilter = 'ALL';

  final List<Map<String, dynamic>> _strategicGoals = [
    {
      'id': 'OKR-101',
      'title': 'Q4 Partner Banquet Expansion (Lucknow & Kanpur)',
      'department': 'Marketing & Growth',
      'owner': 'Rohan Gupta',
      'target': '150 Active Banquets',
      'current': '118 Banquets',
      'progress': 0.78,
      'status': 'ON_TRACK',
      'dueDate': '31 Dec 2026',
      'confidence': 'High (95%)',
    },
    {
      'id': 'OKR-102',
      'title': 'Event Execution Zero-Defect Initiative',
      'department': 'Operations & Events',
      'owner': 'Kavita Nair',
      'target': '99.5% SLA Compliance',
      'current': '98.8% SLA',
      'progress': 0.92,
      'status': 'ON_TRACK',
      'dueDate': '15 Nov 2026',
      'confidence': 'High (90%)',
    },
    {
      'id': 'OKR-103',
      'title': 'Automated Multi-Channel Settlement Engine V2',
      'department': 'Accounts & IT',
      'owner': 'Akarshan Mishra',
      'target': '100% Instant 12% Payouts',
      'current': '85% Implemented',
      'progress': 0.85,
      'status': 'NEEDS_ATTENTION',
      'dueDate': '25 Oct 2026',
      'confidence': 'Medium (75%)',
    },
    {
      'id': 'OKR-104',
      'title': 'Workforce Retention & Upskilling Program',
      'department': 'Human Resources',
      'owner': 'Neha Sharma',
      'target': '< 3% Quarterly Churn',
      'current': '1.8% Churn',
      'progress': 0.95,
      'status': 'EXCEEDED',
      'dueDate': '31 Dec 2026',
      'confidence': 'High (98%)',
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
      'route': 'hr',
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
      'route': 'it',
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
      'route': 'marketing',
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
      'route': 'operations',
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
      'route': 'accounts',
    },
  ];

  final List<Map<String, dynamic>> _escalations = [
    {
      'id': 'ESC-401',
      'title': 'Custom Partner Commission Exception (9.5% vs Standard 12%)',
      'dept': 'Marketing',
      'requestedBy': 'Rohan Gupta for Grand Hyatt Ballrooms',
      'priority': 'HIGH PRIORITY',
      'status': 'PENDING',
      'color': Color(0xFFF59E0B),
    },
    {
      'id': 'ESC-402',
      'title': 'CapEx Budget Allocation for High-Density Mobile Fleet Devices',
      'dept': 'IT & Infra',
      'requestedBy': 'Akarshan Mishra · ₹ 2,40,000 Total Outlay',
      'priority': 'BOARD APPROVAL',
      'status': 'PENDING',
      'color': Color(0xFF2563EB),
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

  // --- CRUD MODALS ---

  void _showAddGoalDialog({Map<String, dynamic>? editGoal}) {
    final titleCtrl = TextEditingController(text: editGoal?['title'] ?? '');
    final ownerCtrl = TextEditingController(text: editGoal?['owner'] ?? 'Rohan Gupta');
    final targetCtrl = TextEditingController(text: editGoal?['target'] ?? '150 Banquets');
    final currentCtrl = TextEditingController(text: editGoal?['current'] ?? '118 Banquets');
    final dueCtrl = TextEditingController(text: editGoal?['dueDate'] ?? '31 Dec 2026');
    double progress = (editGoal?['progress'] as double?) ?? 0.75;
    String dept = editGoal?['department'] ?? 'Marketing & Growth';
    String status = editGoal?['status'] ?? 'ON_TRACK';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.flag_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                editGoal != null ? 'Edit Strategic OKR' : 'Add Strategic OKR',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Objective Title *',
                      prefixIcon: const Icon(Icons.title_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: dept,
                    decoration: InputDecoration(
                      labelText: 'Target Department',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Marketing & Growth', child: Text('Marketing & Growth')),
                      DropdownMenuItem(value: 'Operations & Events', child: Text('Operations & Events')),
                      DropdownMenuItem(value: 'IT & Infra', child: Text('IT & Infrastructure')),
                      DropdownMenuItem(value: 'Accounts & IT', child: Text('Accounts & IT')),
                      DropdownMenuItem(value: 'Human Resources', child: Text('Human Resources')),
                    ],
                    onChanged: (v) => setDialogState(() => dept = v ?? 'Marketing & Growth'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: ownerCtrl,
                          decoration: InputDecoration(
                            labelText: 'Owner / Lead *',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: dueCtrl,
                          decoration: InputDecoration(
                            labelText: 'Target Date',
                            prefixIcon: const Icon(Icons.event_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: currentCtrl,
                          decoration: InputDecoration(
                            labelText: 'Current Metric *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: targetCtrl,
                          decoration: InputDecoration(
                            labelText: 'Target Metric *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress: ${(progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(status, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  Slider(
                    value: progress,
                    min: 0.0,
                    max: 1.0,
                    divisions: 100,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (val) {
                      setDialogState(() {
                        progress = val;
                        if (val >= 1.0) {
                          status = 'EXCEEDED';
                        } else if (val < 0.6) {
                          status = 'NEEDS_ATTENTION';
                        } else {
                          status = 'ON_TRACK';
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() {
                  if (editGoal != null) {
                    editGoal['title'] = titleCtrl.text.trim();
                    editGoal['department'] = dept;
                    editGoal['owner'] = ownerCtrl.text.trim();
                    editGoal['target'] = targetCtrl.text.trim();
                    editGoal['current'] = currentCtrl.text.trim();
                    editGoal['progress'] = progress;
                    editGoal['status'] = status;
                    editGoal['dueDate'] = dueCtrl.text.trim();
                  } else {
                    _strategicGoals.insert(0, {
                      'id': 'OKR-${_strategicGoals.length + 105}',
                      'title': titleCtrl.text.trim(),
                      'department': dept,
                      'owner': ownerCtrl.text.trim(),
                      'target': targetCtrl.text.trim(),
                      'current': currentCtrl.text.trim(),
                      'progress': progress,
                      'status': status,
                      'dueDate': dueCtrl.text.trim(),
                      'confidence': 'High (92%)',
                    });
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(editGoal != null ? '✓ Strategic Goal updated!' : '✓ New Strategic OKR created!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              },
              child: Text(editGoal != null ? 'Save Changes' : 'Create OKR'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDepartment(String route) {
    Widget screen;
    switch (route) {
      case 'hr':
        screen = const HRShellScreen();
        break;
      case 'it':
        screen = const ITShellScreen();
        break;
      case 'marketing':
        screen = const MarketingShellScreen();
        break;
      case 'operations':
        screen = const OperationsShellScreen();
        break;
      case 'accounts':
        screen = const AccountsFinanceScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.military_tech_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text(
              'Executive Management Tower',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF334155)),
            tooltip: 'Export Board Report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📄 Executive Board Report exported to PDF successfully!'), backgroundColor: AppTheme.success),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)),
            tooltip: 'Refresh Metrics',
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_customize_rounded, size: 20), text: 'Executive KPIs'),
            Tab(icon: Icon(Icons.flag_rounded, size: 20), text: 'Strategic OKRs'),
            Tab(icon: Icon(Icons.domain_verification_rounded, size: 20), text: 'Department Control'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('+ Strategic OKR', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // --- EXECUTIVE KPIS TAB ---

  Widget _buildExecutiveKPIsTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
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
            borderRadius: BorderRadius.circular(18),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Q4 LIVE RUNRATE', style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Gross Bookings (GMV)', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
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
        const SizedBox(height: 16),

        // 4 Core Executive Metric Cards
        Row(
          children: [
            Expanded(
              child: _buildMetricCard('Active Workforce', '124', '100% Verified Staff', Icons.people_alt_rounded, const Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard('Live Bookings', '38', '100% on schedule', Icons.celebration_rounded, const Color(0xFF10B981)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard('Verified Partners', '142', '12% Revenue Share', Icons.handshake_rounded, const Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard('Cross-Dept SLA', '98.4%', 'Target > 95%', Icons.verified_rounded, const Color(0xFF8B5CF6)),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick Executive Escalations Gate
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'EXECUTIVE ESCALATIONS & APPROVAL GATE',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
            ),
            Text('${_escalations.where((e) => e['status'] == 'PENDING').length} Pending', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 10),

        ..._escalations.map((esc) {
          final isResolved = esc['status'] == 'APPROVED' || esc['status'] == 'RESOLVED';
          final Color color = esc['color'] as Color;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(esc['priority'], style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                      Text(esc['status'], style: TextStyle(color: isResolved ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(esc['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text(esc['requestedBy'], style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!isResolved) ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444), side: const BorderSide(color: Color(0xFFEF4444))),
                          onPressed: () {
                            setState(() => esc['status'] = 'REJECTED');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escalation rejected')));
                          },
                          child: const Text('Reject', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                          onPressed: () {
                            setState(() => esc['status'] = 'APPROVED');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Executive Approval granted!'), backgroundColor: AppTheme.success));
                          },
                          child: const Text('Approve Decision', style: TextStyle(fontSize: 11)),
                        ),
                      ] else ...[
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                            SizedBox(width: 4),
                            Text('Decision Enacted', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- STRATEGIC OKRS TAB ---

  Widget _buildStrategicGoalsTab() {
    final filtered = _strategicGoals.where((g) {
      if (_goalFilter != 'ALL' && g['status'] != _goalFilter) return false;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('ALL', 'All OKRs (${_strategicGoals.length})', _goalFilter, (v) => setState(() => _goalFilter = v)),
              _buildFilterChip('ON_TRACK', 'On Track', _goalFilter, (v) => setState(() => _goalFilter = v)),
              _buildFilterChip('NEEDS_ATTENTION', 'Needs Attention', _goalFilter, (v) => setState(() => _goalFilter = v)),
              _buildFilterChip('EXCEEDED', 'Exceeded', _goalFilter, (v) => setState(() => _goalFilter = v)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        ...filtered.map((goal) {
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
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(goal['id'], style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800, fontSize: 11)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          goal['status'].toString().replaceAll('_', ' '),
                          style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    goal['title'],
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lead: ${goal['owner']} • Dept: ${goal['department']} • Due: ${goal['dueDate']}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                  const SizedBox(height: 12),
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
                      minHeight: 8,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Confidence: ${goal['confidence'] ?? 'High'}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                            onPressed: () => _showAddGoalDialog(editGoal: goal),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                            onPressed: () {
                              setState(() => _strategicGoals.remove(goal));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OKR deleted')));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // --- DEPARTMENT SCORECARDS TAB ---

  Widget _buildDepartmentScorecardsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: _deptScorecards.length,
      itemBuilder: (context, index) {
        final scorecard = _deptScorecards[index];
        final Color deptColor = scorecard['color'];

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _navigateToDepartment(scorecard['route']),
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
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
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
                          'Head: ${scorecard['head']} • ${scorecard['headcount']} Employees',
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
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Open Command Tower →', style: TextStyle(color: deptColor, fontWeight: FontWeight.w800, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtext, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, String currentVal, Function(String) onSelect) {
    final isSelected = currentVal == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelect(value),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF2563EB).withOpacity(0.12),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
        ),
        showCheckmark: false,
      ),
    );
  }
}
