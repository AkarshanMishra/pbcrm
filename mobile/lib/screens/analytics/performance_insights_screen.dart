import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PerformanceInsightsScreen extends StatefulWidget {
  const PerformanceInsightsScreen({super.key});

  @override
  State<PerformanceInsightsScreen> createState() => _PerformanceInsightsScreenState();
}

class _PerformanceInsightsScreenState extends State<PerformanceInsightsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _topPerformers = [
    {
      'name': 'Akarshan Mishra',
      'dept': 'IT & Architecture',
      'code': 'PBE000001',
      'score': 98.4,
      'tasksCompleted': 48,
      'slaRating': '99.8%',
      'avatarColor': Color(0xFF2563EB),
    },
    {
      'name': 'Kavita Nair',
      'dept': 'Operations Lead',
      'code': 'PBE000004',
      'score': 96.2,
      'tasksCompleted': 54,
      'slaRating': '98.5%',
      'avatarColor': Color(0xFFF59E0B),
    },
    {
      'name': 'Rohan Gupta',
      'dept': 'Marketing Growth',
      'code': 'PBE000003',
      'score': 94.8,
      'tasksCompleted': 39,
      'slaRating': '97.2%',
      'avatarColor': Color(0xFF10B981),
    },
    {
      'name': 'Neha Sharma',
      'dept': 'Human Resources',
      'code': 'PBH000001',
      'score': 93.5,
      'tasksCompleted': 42,
      'slaRating': '98.0%',
      'avatarColor': Color(0xFFF43F5E),
    },
    {
      'name': 'Deepak Verma',
      'dept': 'Accounts & Finance',
      'code': 'PBE000005',
      'score': 92.1,
      'tasksCompleted': 31,
      'slaRating': '99.0%',
      'avatarColor': Color(0xFF8B5CF6),
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
            Icon(Icons.insights_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Performance & Insights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export Report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📊 Performance metrics exported successfully (Excel / CSV)')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recalculate Indices',
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          tabs: const [
            Tab(icon: Icon(Icons.speed_rounded), text: 'Productivity Index'),
            Tab(icon: Icon(Icons.leaderboard_rounded), text: 'Employee Leaderboard'),
            Tab(icon: Icon(Icons.summarize_rounded), text: 'Executive Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductivityTab(),
          _buildLeaderboardTab(),
          _buildExecutiveReportsTab(),
        ],
      ),
    );
  }

  Widget _buildProductivityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Overall Index Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: Color(0xFF60A5FA)),
                  SizedBox(width: 8),
                  Text(
                    'ORGANIZATIONAL PRODUCTIVITY INDEX',
                    style: TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('94.6 / 100', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                  Text('🟢 +3.2% vs last month', style: TextStyle(color: Color(0xFF34D399), fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  value: 0.946,
                  backgroundColor: Color(0xFF334155),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Department Velocity Breakdown
        const Text(
          'DEPARTMENTAL VELOCITY & OUTPUT',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        _buildDepartmentVelocityCard('IT & Engineering', '98.2%', '48 Tasks / Sprint', const Color(0xFF0284C7)),
        _buildDepartmentVelocityCard('Operations & Logistics', '95.4%', '112 Events / Month', const Color(0xFFF59E0B)),
        _buildDepartmentVelocityCard('Marketing & Field Visits', '91.8%', '84 Leads Converted', const Color(0xFF10B981)),
        _buildDepartmentVelocityCard('HR & Talent Acquisition', '94.0%', '8 Open Roles Filled', const Color(0xFFF43F5E)),
        _buildDepartmentVelocityCard('Accounts & Reconciliations', '96.5%', '100% Invoices Posted', const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _buildDepartmentVelocityCard(String dept, String score, String throughput, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 40,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dept, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text('Throughput: $throughput', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(score, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
                const Text('Efficiency', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _topPerformers.length,
      itemBuilder: (context, index) {
        final p = _topPerformers[index];
        final rank = index + 1;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: rank == 1 ? Colors.amber.shade700 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  backgroundColor: p['avatarColor'],
                  child: Text(p['name'][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('${p['code']} · ${p['dept']} · ${p['tasksCompleted']} Tasks', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${p['score']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF2563EB))),
                Text('SLA: ${p['slaRating']}', style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExecutiveReportsTab() {
    final reports = [
      {'title': 'Monthly Organization Productivity Audit', 'format': 'PDF & XLSX', 'size': '2.4 MB', 'date': '01 Oct 2026'},
      {'title': 'Department SLA Compliance & Exception Log', 'format': 'PDF', 'size': '1.1 MB', 'date': '04 Oct 2026'},
      {'title': '12% Partner Commission Settlement Summary', 'format': 'CSV & XLSX', 'size': '850 KB', 'date': '05 Oct 2026'},
      {'title': 'Workforce Attendance & Late Correction Matrix', 'format': 'PDF', 'size': '1.8 MB', 'date': '05 Oct 2026'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final r = reports[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF2563EB)),
            ),
            title: Text(r['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            subtitle: Text('Generated: ${r['date']} · Format: ${r['format']} · ${r['size']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
            trailing: IconButton(
              icon: const Icon(Icons.download_rounded, color: Color(0xFF2563EB)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('⬇️ Downloading "${r['title']}"')),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
