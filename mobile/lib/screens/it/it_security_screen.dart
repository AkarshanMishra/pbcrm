import 'package:flutter/material.dart';

class ITSecurityScreen extends StatefulWidget {
  const ITSecurityScreen({super.key});

  @override
  State<ITSecurityScreen> createState() => _ITSecurityScreenState();
}

class _ITSecurityScreenState extends State<ITSecurityScreen> {
  List<Map<String, dynamic>> _alerts = [
    {
      'level': 'CRITICAL',
      'title': 'Unusual SSH Login Attempt from Unrecognized IP',
      'server': 'Production API Worker (10.0.4.12)',
      'time': '03:21 AM Today',
      'details': 'Failed password attempts exceeding rate limit from 194.26.29.112.',
      'status': 'Investigating',
    },
    {
      'level': 'HIGH',
      'title': 'Wildcard SSL Certificate Renewal Required',
      'server': '*.partybala.com',
      'time': 'Expires in 12 Days (16 Oct 2026)',
      'details': 'Let\'s Encrypt ACME automated DNS challenge requires TXT record verification.',
      'status': 'Action Required',
    },
    {
      'level': 'HIGH',
      'title': 'Failed MFA Verification Burst Alert',
      'server': 'Auth Gateway',
      'time': 'Yesterday, 11:40 PM',
      'details': '5 incorrect TOTP code submissions on account admin@partybala.local. Account auto-locked for 30m.',
      'status': 'Mitigated',
    },
    {
      'level': 'WARNING',
      'title': 'PostgreSQL Backup Storage Retention Warning',
      'server': 'AWS S3 Vault',
      'time': '02 Oct 2026',
      'details': 'Bucket lifecycle policy archiving older snapshots to Glacier Deep Archive.',
      'status': 'Healthy',
    }
  ];

  void _showInvestigateDialog(Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(alert['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Target: ${alert['server']}", style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(alert['details'], style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8)),
              child: const Text("Automated Action: Origin IP automatically blocked on Cloudflare WAF firewall rule #401.", style: TextStyle(color: Color(0xFF34D399), fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Audit record created & IP blacklisted!"), backgroundColor: Color(0xFF10B981)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text("Blacklist & Dismiss"),
          ),
        ],
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
        title: const Text("Security Center & Audit", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSecurityScorecard(),
          const SizedBox(height: 20),
          const Text(
            "ACTIVE SECURITY ALERTS",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.1),
          ),
          const SizedBox(height: 10),
          ..._alerts.map((a) => _buildAlertCard(a)),
        ],
      ),
    );
  }

  Widget _buildSecurityScorecard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSecStat("1", "Critical", const Color(0xFFEF4444)),
          _buildSecStat("2", "High", const Color(0xFFF97316)),
          _buildSecStat("4", "Warnings", const Color(0xFFEAB308)),
          _buildSecStat("100%", "MFA Active", const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildSecStat(String val, String label, Color col) {
    return Column(
      children: [
        Text(val, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> a) {
    Color col = a['level'] == 'CRITICAL' ? const Color(0xFFEF4444) : (a['level'] == 'HIGH' ? const Color(0xFFF97316) : const Color(0xFFEAB308));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: col.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                child: Text(a['level'], style: TextStyle(color: col, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
              Text(a['time'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(a['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Text(a['server'], style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _showInvestigateDialog(a),
              style: ElevatedButton.styleFrom(
                backgroundColor: col.withOpacity(0.2),
                foregroundColor: col,
                side: BorderSide(color: col),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                elevation: 0,
              ),
              child: const Text("INVESTIGATE", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}
