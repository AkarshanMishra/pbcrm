import 'package:flutter/material.dart';

class ITKnowledgeBaseScreen extends StatefulWidget {
  const ITKnowledgeBaseScreen({super.key});

  @override
  State<ITKnowledgeBaseScreen> createState() => _ITKnowledgeBaseScreenState();
}

class _ITKnowledgeBaseScreenState extends State<ITKnowledgeBaseScreen> {
  String _selectedCategory = 'ALL';
  String _searchQuery = '';

  final List<Map<String, dynamic>> _articles = [
    {
      'slug': 'troubleshoot-production-api-502-error',
      'title': 'How to Troubleshoot Production API 502 Bad Gateway Errors',
      'category': 'TROUBLESHOOTING',
      'summary': 'Standard operational runbook for diagnosing and restoring backend API 502/504 errors in production.',
      'views': 84,
      'steps': [
        'Verify Ingress & Edge Gateway status on Cloudflare / Nginx',
        'Inspect Kubernetes Gunicorn pod container logs (kubectl logs -n prod)',
        'Check PostgreSQL active connection saturation and thread pool',
        'Verify Redis queue throughput & memory eviction limits',
        'Execute graceful rolling restart if deadlock is observed',
        'Notify incident channel & page DevOps Lead on PagerDuty'
      ],
      'content': 'Detailed step-by-step recovery procedure for high latency and connection pool exhaustion.',
    },
    {
      'slug': 'staging-and-production-zero-downtime-deployment-sop',
      'title': 'Zero-Downtime Deployment SOP for Microservices & APIs',
      'category': 'DEPLOYMENT',
      'summary': 'Detailed guidelines on CI/CD pipelines, semantic tagging, database migrations, and canary deployments.',
      'views': 52,
      'steps': [
        'Ensure all unit and integration test suites pass (100% green)',
        'Verify database migrations are non-locking expand-contract schema changes',
        'Obtain IT Engineering Manager PR signoff',
        'Trigger deployment from PCRM Deployment Center',
        'Monitor APM telemetry dashboard for 15 minutes post-release'
      ],
      'content': 'Standard release management workflow for staging candidate to production rollout.',
    },
    {
      'slug': 'postgresql-backup-and-disaster-recovery-drill',
      'title': 'PostgreSQL Backup Consistency & Disaster Recovery SOP',
      'category': 'DATABASE',
      'summary': 'Verification protocol for nightly WAL differential snapshots and test restore procedures.',
      'views': 41,
      'steps': [
        'Check S3 Glacier cold backup bucket for latest snapshot hash',
        'Spin up temporary staging RDS instance from snapshot',
        'Execute integrity query test on test database',
        'Log drill completion report in Security & Audit center'
      ],
      'content': 'Monthly disaster recovery verification guidelines.',
    },
    {
      'slug': 'employee-vpn-and-mfa-troubleshooting-guide',
      'title': 'Employee VPN Setup & MFA Troubleshooting Guide',
      'category': 'SOPS',
      'summary': 'Guide for setting up WireGuard / OpenVPN client and troubleshooting TOTP hardware keys.',
      'views': 96,
      'steps': [
        'Download PartyBala IT VPN Profile (.ovpn)',
        'Import client certificate in OpenVPN Connect',
        'Verify multi-factor biometric push notification',
        'Test ping to internal gateway (10.0.0.1)'
      ],
      'content': 'Internal guide for employee connectivity and remote engineering access.',
    }
  ];

  void _openArticleDetail(Map<String, dynamic> art) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: const Color(0xFF475569), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF38BDF8).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(art['category'], style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                  Text("👁 ${art['views']} Views", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                art['title'],
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                art['summary'],
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              const Text(
                "RESOLUTION RUNBOOK & STEPS",
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1),
              ),
              const SizedBox(height: 10),
              ...((art['steps'] as List<dynamic>).asMap().entries.map((entry) {
                int idx = entry.key + 1;
                String step = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF38BDF8)),
                        child: Text("$idx", style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 11)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                );
              })),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var filtered = _articles.where((a) {
      bool catMatch = _selectedCategory == 'ALL' || a['category'] == _selectedCategory;
      bool queryMatch = _searchQuery.isEmpty || a['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return catMatch && queryMatch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("IT Knowledge Base & SOPs", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search runbooks, error codes (502, 504), SOPs...",
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF38BDF8)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['ALL', 'SOPS', 'TROUBLESHOOTING', 'DEPLOYMENT', 'DATABASE'].map((cat) {
                      bool sel = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: sel,
                          onSelected: (s) => setState(() => _selectedCategory = cat),
                          backgroundColor: const Color(0xFF0F172A),
                          selectedColor: const Color(0xFF38BDF8),
                          labelStyle: TextStyle(
                            color: sel ? const Color(0xFF0F172A) : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final art = filtered[i];
                return InkWell(
                  onTap: () => _openArticleDetail(art),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF38BDF8).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                              child: Text(art['category'], style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10, fontWeight: FontWeight.w800)),
                            ),
                            Text("👁 ${art['views']} Views", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          art['title'],
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          art['summary'],
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
