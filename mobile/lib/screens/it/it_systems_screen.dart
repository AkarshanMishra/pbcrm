import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class ITSystemsScreen extends StatefulWidget {
  const ITSystemsScreen({super.key});

  @override
  State<ITSystemsScreen> createState() => _ITSystemsScreenState();
}

class _ITSystemsScreenState extends State<ITSystemsScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _systems = [];
  Map<String, dynamic> _health = {
    'total_components': 6,
    'operational': 4,
    'warning': 1,
    'down': 1,
    'overall_health': 'CRITICAL',
  };

  @override
  void initState() {
    super.initState();
    _loadSystems();
  }

  Future<void> _loadSystems() async {
    try {
      final res = await _api.get('/api/v1/it/systems/');
      final healthRes = await _api.get('/api/v1/it/systems/health_overview/');
      if (res.statusCode == 200 && res.data != null) {
        if (mounted) {
          setState(() {
            _systems = (res.data is List) ? res.data : (res.data['results'] ?? []);
            if (healthRes.statusCode == 200 && healthRes.data != null) {
              _health = healthRes.data;
            }
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _systems = [
            {
              'name': 'Payment API & Webhook Service',
              'component_type': 'API',
              'status': 'DOWN',
              'endpoint_or_host': 'https://api.partybala.com/v1/payments/',
              'uptime_percentage': '94.20',
              'responsible_team': 'Payments & Core Backend',
              'dependencies_info': 'PostgreSQL Primary, Razorpay Gateway, Redis',
              'description': 'Handles payment gateway callbacks, customer checkout and partner payouts.',
            },
            {
              'name': 'API Gateway & Edge Router',
              'component_type': 'API',
              'status': 'OPERATIONAL',
              'endpoint_or_host': 'https://gateway.partybala.com',
              'uptime_percentage': '99.99',
              'responsible_team': 'DevOps / Infrastructure',
              'dependencies_info': 'Cloudflare Edge, Nginx Ingress',
              'description': 'Reverse proxy, rate limiting, JWT validation and SSL termination.',
            },
            {
              'name': 'PostgreSQL Primary Cluster',
              'component_type': 'DATABASE',
              'status': 'OPERATIONAL',
              'endpoint_or_host': 'db-prod.partybala.internal:5432',
              'uptime_percentage': '99.98',
              'responsible_team': 'DBA / Backend',
              'dependencies_info': 'AWS RDS Multi-AZ, Read Replica 1, Read Replica 2',
              'description': 'Primary transactional relational database cluster with automated failover.',
            },
            {
              'name': 'PartyBala Customer Mobile & Web App',
              'component_type': 'APPLICATION',
              'status': 'OPERATIONAL',
              'endpoint_or_host': 'https://partybala.com',
              'uptime_percentage': '99.95',
              'responsible_team': 'Frontend & Mobile Team',
              'dependencies_info': 'API Gateway, CDN, Firebase Notifications',
              'description': 'Customer facing venue booking, event packages and ticketing experience.',
            },
            {
              'name': 'Automated Backup Service',
              'component_type': 'BACKUP',
              'status': 'WARNING',
              'endpoint_or_host': 'backup-runner.prod.partybala.internal',
              'uptime_percentage': '98.40',
              'responsible_team': 'DevOps / Site Reliability',
              'dependencies_info': 'AWS S3 Glacier, GCS Archive',
              'description': 'Nightly differential and weekly full DB snapshots with cross-region replication.',
            },
            {
              'name': 'SSL Wildcard Certificate (*.partybala.com)',
              'component_type': 'SSL_CERT',
              'status': 'WARNING',
              'endpoint_or_host': '*.partybala.com',
              'uptime_percentage': '100.00',
              'ssl_expiry_date': '2026-10-16',
              'responsible_team': 'Security & SecOps',
              'dependencies_info': 'Let\'s Encrypt / DigiCert ACME',
              'description': 'Production edge wildcard certificate (renewal window active).',
            },
          ];
        });
      }
    }
  }

  void _showSystemDetails(Map<String, dynamic> sys) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
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
                _buildTypeBadge(sys['component_type'] ?? 'SERVICE'),
                _buildStatusBadge(sys['status'] ?? 'OPERATIONAL'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              sys['name'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _buildDetailTile("ENDPOINT / HOST", sys['endpoint_or_host'] ?? '-', Icons.link_rounded),
            _buildDetailTile("UPTIME", "${sys['uptime_percentage']}%", Icons.timelapse_rounded),
            _buildDetailTile("RESPONSIBLE TEAM", sys['responsible_team'] ?? 'DevOps', Icons.groups_rounded),
            _buildDetailTile("DEPENDENCIES", sys['dependencies_info'] ?? 'None', Icons.account_tree_rounded),
            if (sys['ssl_expiry_date'] != null)
              _buildDetailTile("SSL EXPIRY", sys['ssl_expiry_date'] ?? '-', Icons.lock_clock_rounded),
            const SizedBox(height: 20),
            const Text(
              "DESCRIPTION & SERVICE HEALTH",
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Text(
                sys['description'] ?? 'Operational and healthy.',
                style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w700)),
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

  Widget _buildStatusBadge(String status) {
    Color col;
    String label;
    if (status == 'OPERATIONAL') {
      col = const Color(0xFF10B981);
      label = "Operational";
    } else if (status == 'WARNING') {
      col = const Color(0xFFEAB308);
      label = "Warning";
    } else if (status == 'DEGRADED') {
      col = const Color(0xFFF97316);
      label = "Degraded";
    } else {
      col = const Color(0xFFEF4444);
      label = "Down";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: col.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: col.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: col)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
      ),
      child: Text(type, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text("Systems & Infrastructure", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
        actions: [
          IconButton(
            onPressed: _loadSystems,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF38BDF8)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSystemHealthBanner(),
                const SizedBox(height: 20),
                const Text(
                  "SYSTEM COMPONENTS",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.1),
                ),
                const SizedBox(height: 10),
                ..._systems.map((s) => _buildSystemCard(s)),
              ],
            ),
    );
  }

  Widget _buildSystemHealthBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("SYSTEM HEALTH", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, fontSize: 12)),
              Text(
                "Last check: Just now",
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHealthStat("${_health['operational'] ?? 4}", "Operational", const Color(0xFF10B981)),
              _buildHealthStat("${_health['warning'] ?? 1}", "Warning", const Color(0xFFEAB308)),
              _buildHealthStat("${_health['down'] ?? 1}", "Down", const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStat(String val, String label, Color col) {
    return Column(
      children: [
        Text(val, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 22)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSystemCard(Map<String, dynamic> sys) {
    return InkWell(
      onTap: () => _showSystemDetails(sys),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildTypeBadge(sys['component_type'] ?? 'API'),
                      const SizedBox(width: 8),
                      Text("Uptime: ${sys['uptime_percentage']}%", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sys['name'] ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sys['endpoint_or_host'] ?? '',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildStatusBadge(sys['status'] ?? 'OPERATIONAL'),
          ],
        ),
      ),
    );
  }
}
