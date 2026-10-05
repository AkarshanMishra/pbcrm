import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class ITDeploymentScreen extends StatefulWidget {
  const ITDeploymentScreen({super.key});

  @override
  State<ITDeploymentScreen> createState() => _ITDeploymentScreenState();
}

class _ITDeploymentScreenState extends State<ITDeploymentScreen> {
  final ApiClient _api = ApiClient();
  bool _isDeploying = false;
  String _selectedEnv = 'Staging';
  String _versionTag = 'v2.8.4-rc1';
  String _application = 'PartyBala Enterprise CRM';
  
  List<Map<String, dynamic>> _deployHistory = [
    {
      'version': 'v2.8.4-rc1',
      'env': 'Staging',
      'status': 'SUCCESS',
      'triggered_by': 'Akarshan Mishra',
      'deployed_at': 'Today, 01:30 PM',
      'commit': 'e4a7b19',
      'notes': 'Added IT role view and dynamic ticketing.',
    },
    {
      'version': 'v2.8.3',
      'env': 'Production',
      'status': 'SUCCESS',
      'triggered_by': 'Akarshan Mishra',
      'deployed_at': 'Yesterday',
      'commit': 'a8f9c12',
      'notes': 'Phase 2 workforce execution & marketing hub launch.',
    },
    {
      'version': 'v2.8.2',
      'env': 'Production',
      'status': 'SUCCESS',
      'triggered_by': 'IT Manager',
      'deployed_at': '02 Oct 2026',
      'commit': '99fcb10',
      'notes': 'Auth security patches and MFA token rotation.',
    }
  ];

  Future<void> _triggerDeployment() async {
    setState(() => _isDeploying = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    setState(() {
      _isDeploying = false;
      _deployHistory.insert(0, {
        'version': _versionTag,
        'env': _selectedEnv,
        'status': 'SUCCESS',
        'triggered_by': 'Akarshan Mishra',
        'deployed_at': 'Just now',
        'commit': 'c8f12a3',
        'notes': 'Live release pipeline verified with code 0.',
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("🚀 Successfully deployed $_versionTag to $_selectedEnv!"),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("Deployment Center", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDeployConsoleCard(),
          const SizedBox(height: 24),
          const Text(
            "RECENT DEPLOYMENT HISTORY",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          ..._deployHistory.map((d) => _buildDeployHistoryCard(d)),
        ],
      ),
    );
  }

  Widget _buildDeployConsoleCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA78BFA).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("DEPLOY PIPELINE", style: TextStyle(color: Color(0xFFA78BFA), fontWeight: FontWeight.w800, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: const Text("Ready to Release", style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Application: $_application",
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          const Text("Target Environment", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          const SizedBox(height: 6),
          Row(
            children: ['Development', 'Staging', 'Production'].map((env) {
              bool sel = _selectedEnv == env;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(env),
                  selected: sel,
                  onSelected: (s) => setState(() => _selectedEnv = env),
                  backgroundColor: const Color(0xFF0F172A),
                  selectedColor: const Color(0xFFA78BFA),
                  labelStyle: TextStyle(color: sel ? const Color(0xFF0F172A) : Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          _buildCheckRow("Build Status", "✓ Passed (Docker Image Ready)", const Color(0xFF34D399)),
          _buildCheckRow("Unit & Integration Tests", "✓ 31/31 Passed", const Color(0xFF34D399)),
          _buildCheckRow("Approval", "✓ IT Engineering Manager", const Color(0xFF60A5FA)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isDeploying ? null : _triggerDeployment,
              icon: _isDeploying
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.rocket_launch_rounded),
              label: Text(
                _isDeploying ? "Deploying & Verifying..." : "EXECUTE DEPLOYMENT TO $_selectedEnv",
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA78BFA),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String label, String val, Color col) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          Text(val, style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildDeployHistoryCard(Map<String, dynamic> d) {
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
          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${d['version']} • ${d['env']}",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                    Text(d['deployed_at'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  d['notes'],
                  style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
