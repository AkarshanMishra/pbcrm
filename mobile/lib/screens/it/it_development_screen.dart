import 'package:flutter/material.dart';

class ITDevelopmentScreen extends StatefulWidget {
  const ITDevelopmentScreen({super.key});

  @override
  State<ITDevelopmentScreen> createState() => _ITDevelopmentScreenState();
}

class _ITDevelopmentScreenState extends State<ITDevelopmentScreen> {
  List<Map<String, dynamic>> _pullRequests = [
    {
      'pr_number': 248,
      'title': 'Payment Gateway Fix & Webhook Connection Pooling',
      'repository': 'partybala/backend-core',
      'source_branch': 'feat/payment-gateway-fix',
      'target_branch': 'main',
      'author': 'Akarshan Mishra',
      'reviewer': 'IT Engineering Manager',
      'build_passed': true,
      'tests_passed': true,
      'review_status': 'PENDING',
      'commit': 'e4a7b19',
      'summary': 'Increases DB pool size from 10 to 40 for payment webhooks, adds exponential backoff retry.',
    },
    {
      'pr_number': 247,
      'title': 'Auth MFA Token Refresh & Biometric Validation',
      'repository': 'partybala/backend-core',
      'source_branch': 'feat/mfa-jwt-refresh',
      'target_branch': 'main',
      'author': 'Akarshan Mishra',
      'reviewer': 'IT Engineering Manager',
      'build_passed': true,
      'tests_passed': true,
      'review_status': 'APPROVED',
      'commit': 'c91a02d',
      'summary': 'Implements secure refresh token rotation and biometric hardware key fallback.',
    },
    {
      'pr_number': 246,
      'title': 'Marketing Field Route Navigation Integration',
      'repository': 'partybala/mobile-client',
      'source_branch': 'feat/marketing-route',
      'target_branch': 'main',
      'author': 'Developer Team',
      'reviewer': 'Akarshan Mishra',
      'build_passed': true,
      'tests_passed': true,
      'review_status': 'APPROVED',
      'commit': 'a10b42f',
      'summary': 'Integrates Google Maps direction intents for field sales visit itineraries.',
    }
  ];

  void _showPRDetail(Map<String, dynamic> pr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.4,
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
                  Text("PR #${pr['pr_number']}", style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 16, fontWeight: FontWeight.w800)),
                  _buildReviewStatusBadge(pr['review_status']),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pr['title'],
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _buildPRRow("Repository", pr['repository'], Icons.source_rounded),
              _buildPRRow("Branch", "${pr['source_branch']} -> ${pr['target_branch']}", Icons.alt_route_rounded),
              _buildPRRow("Author", pr['author'], Icons.person_rounded),
              _buildPRRow("Reviewer", pr['reviewer'], Icons.rate_review_rounded),
              _buildPRRow("Commit", pr['commit'], Icons.commit_rounded),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("CI/CD Checks", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 6),
                        const Text("Build Passed", style: TextStyle(color: Colors.white, fontSize: 13)),
                        const SizedBox(width: 16),
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 6),
                        const Text("Unit Tests (100%)", style: TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setMState(() => pr['review_status'] = 'CHANGES_REQUESTED');
                        setState(() {});
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Changes Requested on PR!")));
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF87171),
                        side: const BorderSide(color: Color(0xFFF87171)),
                      ),
                      child: const Text("Request Changes"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setMState(() => pr['review_status'] = 'APPROVED');
                        setState(() {});
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("PR Approved! Ready to Merge."), backgroundColor: Color(0xFF10B981)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Approve PR"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPRRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStatusBadge(String status) {
    Color col = status == 'APPROVED' ? const Color(0xFF10B981) : (status == 'PENDING' ? const Color(0xFFEAB308) : const Color(0xFFEF4444));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: col.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: col)),
      child: Text(
        status == 'APPROVED' ? "Approved" : (status == 'PENDING' ? "Review Pending" : "Changes Req"),
        style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 11),
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
        title: const Text("Development & Code Reviews", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pullRequests.length,
        itemBuilder: (ctx, i) {
          final pr = _pullRequests[i];
          return InkWell(
            onTap: () => _showPRDetail(pr),
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
                      Text("PR #${pr['pr_number']}", style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 13, fontWeight: FontWeight.w800)),
                      _buildReviewStatusBadge(pr['review_status']),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pr['title'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 4),
                      const Text("Build Passed", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      const SizedBox(width: 14),
                      const Icon(Icons.person_rounded, color: Color(0xFF94A3B8), size: 14),
                      const SizedBox(width: 4),
                      Text("Reviewer: ${pr['reviewer']}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
