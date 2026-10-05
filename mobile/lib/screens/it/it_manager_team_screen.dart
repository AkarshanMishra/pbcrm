import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class ITManagerTeamScreen extends StatefulWidget {
  const ITManagerTeamScreen({super.key});

  @override
  State<ITManagerTeamScreen> createState() => _ITManagerTeamScreenState();
}

class _ITManagerTeamScreenState extends State<ITManagerTeamScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = false;

  List<Map<String, dynamic>> _teamWorkload = [
    {
      'name': 'Akarshan Mishra (SDE-2)',
      'code': 'PBE000003',
      'tasks': 4,
      'load_pct': 80,
      'is_overloaded': false,
      'status': 'Working (Payment API)',
    },
    {
      'name': 'Developer B (DevOps)',
      'code': 'PBE000004',
      'tasks': 3,
      'load_pct': 60,
      'is_overloaded': false,
      'status': 'Working (Redis Cluster)',
    },
    {
      'name': 'Developer C (Frontend / Mobile)',
      'code': 'PBE000005',
      'tasks': 5,
      'load_pct': 100,
      'is_overloaded': true,
      'status': 'Working (Customer App v2.8.4)',
    },
    {
      'name': 'Developer D (QA / Testing)',
      'code': 'PBE000006',
      'tasks': 2,
      'load_pct': 40,
      'is_overloaded': false,
      'status': 'Working (Automation)',
    },
  ];

  List<Map<String, dynamic>> _pendingApprovals = [
    {
      'id': '1',
      'title': 'Production Deployment Signoff: v2.8.4',
      'type': 'DEPLOYMENT',
      'requested_by': 'Akarshan Mishra',
      'target': 'Production Cluster',
      'time': '10 mins ago',
    },
    {
      'id': '2',
      'title': 'Staging Database Read/Write IAM Access',
      'type': 'ACCESS_REQUEST',
      'requested_by': 'Developer B',
      'target': 'RDS Staging Instance',
      'time': '1 hour ago',
    },
    {
      'id': '3',
      'title': 'Developer Hardware Allocation (Monitor 4K)',
      'type': 'ASSET_ALLOCATION',
      'requested_by': 'Developer C',
      'target': 'Dell UltraSharp 27" U2723QE',
      'time': 'Yesterday',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("IT Manager Team Control Plane", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTeamOperationsCard(),
          const SizedBox(height: 20),
          const Text(
            "TEAM WORKLOAD DISTRIBUTION",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          ..._teamWorkload.map((m) => _buildWorkloadRow(m)),
          const SizedBox(height: 24),
          const Text(
            "MANAGER APPROVALS QUEUE",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          ..._pendingApprovals.map((appr) => _buildApprovalCard(appr)),
        ],
      ),
    );
  }

  Widget _buildTeamOperationsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("IT OPERATIONS OVERVIEW", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w800, fontSize: 12)),
              const Text("12 Team Members", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOpStat("10", "Working", const Color(0xFF10B981)),
              _buildOpStat("1", "On Leave", const Color(0xFFEAB308)),
              _buildOpStat("32", "Active Tasks", const Color(0xFF38BDF8)),
              _buildOpStat("3", "Critical Tickets", const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpStat(String val, String label, Color col) {
    return Column(
      children: [
        Text(val, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildWorkloadRow(Map<String, dynamic> m) {
    int pct = m['load_pct'] as int;
    bool overloaded = m['is_overloaded'] as bool;
    Color barColor = overloaded ? const Color(0xFFEF4444) : (pct >= 80 ? const Color(0xFFF97316) : const Color(0xFF38BDF8));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: overloaded ? const Color(0xFFEF4444).withOpacity(0.4) : const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(m['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
              Row(
                children: [
                  if (overloaded)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Text("⚠ OVERLOADED", style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  Text("$pct%", style: TextStyle(color: barColor, fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: const Color(0xFF0F172A),
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Active: ${m['tasks']} Tasks", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              Text(m['status'], style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> appr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF38BDF8).withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appr['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text("Req by: ${appr['requested_by']} • ${appr['time']}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _pendingApprovals.removeWhere((x) => x['id'] == appr['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Approved: ${appr['title']}"), backgroundColor: const Color(0xFF10B981)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(60, 28),
              elevation: 0,
            ),
            child: const Text("APPROVE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
