import 'package:flutter/material.dart';

class ITAssetsScreen extends StatefulWidget {
  const ITAssetsScreen({super.key});

  @override
  State<ITAssetsScreen> createState() => _ITAssetsScreenState();
}

class _ITAssetsScreenState extends State<ITAssetsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _myAssets = [
    {
      'asset_tag': 'IT-LAP-00248',
      'name': 'Dell Latitude 7420 Developer Workstation',
      'type': 'Laptop',
      'assigned_to': 'Akarshan Mishra',
      'status': 'Active / Assigned',
      'brand': 'Dell',
      'model': 'Latitude 7420 (Intel Core i7-1185G7)',
      'serial': 'DL-7420-99410A',
      'warranty': 'Expires in 530 days',
      'specs': '32 GB DDR4 • 1 TB NVMe SSD • Ubuntu 24.04 / Windows 11 Dual',
      'installed_software': 'VS Code, Docker Desktop, Postman, Flutter SDK, Python 3.12, DBeaver',
      'history': '04-May-2026: Battery diagnostic passed. Software patches verified.',
    },
    {
      'asset_tag': 'IT-MON-00109',
      'name': 'Dell UltraSharp 27" 4K USB-C Hub Monitor (U2723QE)',
      'type': 'Monitor',
      'assigned_to': 'Akarshan Mishra',
      'status': 'Active / Assigned',
      'brand': 'Dell',
      'model': 'U2723QE 4K IPS',
      'serial': 'MON-U27-33120B',
      'warranty': 'Expires in 550 days',
      'specs': '3840 x 2160 • 60Hz • USB-C 90W Power Delivery',
      'installed_software': '-',
      'history': 'Assigned on joining.',
    }
  ];

  List<Map<String, dynamic>> _requests = [
    {
      'req_number': 'REQ-IT-2026-0014',
      'type': 'Database Read/Write Access',
      'status': 'Resolved / Provisioned',
      'justification': 'Required to test payment webhook idempotency keys on staging PostgreSQL.',
      'requester': 'Akarshan Mishra',
      'approver': 'IT Engineering Manager',
      'details': 'Granted temporary RDS staging IAM credentials (valid for 30 days).'
    },
    {
      'req_number': 'REQ-IT-2026-0015',
      'type': 'AWS IAM CloudWatch Logs Access',
      'status': 'Under IT Review',
      'justification': 'Need log stream permission for production incident postmortem analysis.',
      'requester': 'Developer Team',
      'approver': 'Pending Lead Review',
      'details': 'Request under security review.'
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _showAssetDetail(Map<String, dynamic> a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
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
                Text(a['asset_tag'], style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 16, fontWeight: FontWeight.w800)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                  child: Text(a['status'], style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(a['name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _buildAssetTile("Brand / Model", "${a['brand']} ${a['model']}", Icons.devices_rounded),
            _buildAssetTile("Serial Number", a['serial'], Icons.qr_code_rounded),
            _buildAssetTile("Assigned To", a['assigned_to'], Icons.person_rounded),
            _buildAssetTile("Warranty", a['warranty'], Icons.verified_user_rounded),
            const SizedBox(height: 16),
            const Text("HARDWARE SPECS", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF334155))),
              child: Text(a['specs'], style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4)),
            ),
            const SizedBox(height: 16),
            const Text("INSTALLED SOFTWARE", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF334155))),
              child: Text(a['installed_software'], style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetTile(String label, String val, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 16),
          const SizedBox(width: 8),
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12))),
          Expanded(child: Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
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
        title: const Text("IT Assets & Access", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelColor: const Color(0xFF38BDF8),
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(text: "My Technology Assets"),
            Tab(text: "IT Access Requests"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF38BDF8),
        onPressed: _showRaiseRequestDialog,
        icon: const Icon(Icons.add, color: Color(0xFF0F172A)),
        label: const Text("Request Access / Hardware", style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAssetsList(),
          _buildRequestsList(),
        ],
      ),
    );
  }

  Widget _buildAssetsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myAssets.length,
      itemBuilder: (ctx, i) {
        final a = _myAssets[i];
        return InkWell(
          onTap: () => _showAssetDetail(a),
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
                    Text(a['asset_tag'], style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w800)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: Text(a['status'], style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(a['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 6),
                Text(a['specs'], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      itemBuilder: (ctx, i) {
        final r = _requests[i];
        bool isResolved = r['status'].toString().contains('Resolved');
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isResolved ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFEAB308).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(r['req_number'], style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.w800)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isResolved ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFEAB308).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r['status'],
                      style: TextStyle(color: isResolved ? const Color(0xFF34D399) : const Color(0xFFEAB308), fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(r['type'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 6),
              Text("Justification: ${r['justification']}", style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
              const SizedBox(height: 6),
              Text("Details: ${r['details']}", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  void _showRaiseRequestDialog() {
    final typeCtrl = TextEditingController();
    final justCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Raise IT Access / Hardware Request", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Request Type (e.g. VPN, DB Access, RAM Upgrade)", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: justCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Business Justification", labelStyle: TextStyle(color: Color(0xFF94A3B8))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (typeCtrl.text.isNotEmpty) {
                setState(() {
                  _requests.insert(0, {
                    'req_number': 'REQ-IT-2026-0016',
                    'type': typeCtrl.text,
                    'status': 'Requested',
                    'justification': justCtrl.text,
                    'requester': 'Akarshan Mishra',
                    'approver': 'Pending IT Manager',
                    'details': 'Submitted for review.'
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("IT Request Submitted!"), backgroundColor: Color(0xFF10B981)));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: const Color(0xFF0F172A)),
            child: const Text("Submit Request"),
          ),
        ],
      ),
    );
  }
}
