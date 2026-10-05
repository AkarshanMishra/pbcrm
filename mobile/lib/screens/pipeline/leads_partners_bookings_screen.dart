import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class LeadsPartnersBookingsScreen extends StatefulWidget {
  const LeadsPartnersBookingsScreen({super.key});

  @override
  State<LeadsPartnersBookingsScreen> createState() => _LeadsPartnersBookingsScreenState();
}

class _LeadsPartnersBookingsScreenState extends State<LeadsPartnersBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _partners = [
    {
      'id': 'PBV0000001',
      'name': 'Grand Heritage Banquet',
      'owner': 'Rajesh Sharma',
      'phone': '+91 98765 43210',
      'city': 'Lucknow (Gomti Nagar)',
      'capacity': '800 Guests',
      'commissionRate': '12.0%',
      'tier': 'PLATINUM',
      'status': 'ACTIVE',
      'totalBookings': 42,
      'rating': 4.9,
    },
    {
      'id': 'PBV0000002',
      'name': 'Royal Palms Resort & Lawns',
      'owner': 'Vikram Singh',
      'phone': '+91 91234 56789',
      'city': 'Kanpur (Civil Lines)',
      'capacity': '1500 Guests',
      'commissionRate': '12.0%',
      'tier': 'GOLD',
      'status': 'ACTIVE',
      'totalBookings': 29,
      'rating': 4.7,
    },
    {
      'id': 'PBV0000003',
      'name': 'Kuhu Espresso & Boutique Hall',
      'owner': 'Ananya Verma',
      'phone': '+91 99887 76655',
      'city': 'Lucknow (Hazratganj)',
      'capacity': '250 Guests',
      'commissionRate': '12.0%',
      'tier': 'SILVER',
      'status': 'ACTIVE',
      'totalBookings': 18,
      'rating': 4.8,
    },
  ];

  final List<Map<String, dynamic>> _bookings = [
    {
      'id': 'BK-2026-089',
      'clientName': 'Sharma Wedding Reception',
      'leadId': 'LD-902',
      'partnerId': 'PBV0000001',
      'partnerName': 'Grand Heritage Banquet',
      'eventDate': '12 Oct 2026',
      'amount': '₹ 1,85,000',
      'settlement12Pct': '₹ 22,200',
      'opsCoordinator': 'Kavita Nair',
      'stage': 'EVENT_PREPARATION',
      'readiness': '92%',
      'paymentStatus': 'PAID',
    },
    {
      'id': 'BK-2026-090',
      'clientName': 'TechCorp Annual Corporate Meet',
      'leadId': 'LD-905',
      'partnerId': 'PBV0000002',
      'partnerName': 'Royal Palms Resort',
      'eventDate': '18 Oct 2026',
      'amount': '₹ 3,40,000',
      'settlement12Pct': '₹ 40,800',
      'opsCoordinator': 'Amit Verma',
      'stage': 'LOGISTICS_DISPATCH',
      'readiness': '80%',
      'paymentStatus': 'PARTIAL (70%)',
    },
    {
      'id': 'BK-2026-091',
      'clientName': 'Verma 1st Birthday Celebration',
      'leadId': 'LD-910',
      'partnerId': 'PBV0000003',
      'partnerName': 'Kuhu Espresso Banquet',
      'eventDate': '24 Oct 2026',
      'amount': '₹ 45,000',
      'settlement12Pct': '₹ 5,400',
      'opsCoordinator': 'Ritu Saxena',
      'stage': 'BOOKING_CONFIRMED',
      'readiness': '50%',
      'paymentStatus': 'PAID',
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
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.handshake_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Leads, Partners & Bookings Pipeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'Onboard Partner',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✨ Partner onboarding wizard initiated')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_rounded),
            tooltip: 'New Booking',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📅 Create booking workflow initiated')),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          tabs: const [
            Tab(icon: Icon(Icons.timeline_rounded), text: '360° Traceability'),
            Tab(icon: Icon(Icons.store_rounded), text: 'Verified Partners'),
            Tab(icon: Icon(Icons.celebration_rounded), text: 'Active Bookings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTraceabilityTab(),
          _buildPartnersTab(),
          _buildBookingsTab(),
        ],
      ),
    );
  }

  Widget _buildTraceabilityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Search & Filter Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'END-TO-END WORKFLOW SEARCH & AUDIT TRACE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Trace by Booking ID (BK-2026-089), Partner (PBV0000001), or Client...',
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() {
                            _searchCtrl.clear();
                            _searchQuery = '';
                          }),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Visual Pipeline Lifecycle Stepper
        const Text(
          'PARTYBALA MASTER VALUE CHAIN',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(14),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPipelineStageNode('1. LEAD', 'Marketing', const Color(0xFF38BDF8), true),
                _buildPipelineArrow(),
                _buildPipelineStageNode('2. VISIT', 'Field Agent', const Color(0xFF38BDF8), true),
                _buildPipelineArrow(),
                _buildPipelineStageNode('3. PARTNER', 'Onboarding', const Color(0xFF34D399), true),
                _buildPipelineArrow(),
                _buildPipelineStageNode('4. BOOKING', 'Sales & Client', const Color(0xFFFBBF24), true),
                _buildPipelineArrow(),
                _buildPipelineStageNode('5. PAYMENT', 'Accounts (12%)', const Color(0xFF8B5CF6), true),
                _buildPipelineArrow(),
                _buildPipelineStageNode('6. OPERATIONS', 'Event Lead', const Color(0xFFF43F5E), true),
                _buildPipelineArrow(),
                _buildPipelineStageNode('7. EXECUTION', 'Venue Stage', const Color(0xFF10B981), true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Traceable Cards
        const Text(
          'LIVE CROSS-DEPARTMENT THREADS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        ..._bookings
            .where((b) =>
                _searchQuery.isEmpty ||
                b['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                b['clientName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                b['partnerId'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                b['partnerName'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
            .map((booking) => _buildTraceableThreadCard(booking)),
      ],
    );
  }

  Widget _buildPipelineStageNode(String title, String dept, Color color, bool isDone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 2),
          Text(dept, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5)),
        ],
      ),
    );
  }

  Widget _buildPipelineArrow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF64748B), size: 16),
    );
  }

  Widget _buildTraceableThreadCard(Map<String, dynamic> b) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_rounded, color: Color(0xFF2563EB), size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(b['id'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    b['stage'].toString().replaceAll('_', ' '),
                    style: const TextStyle(color: Color(0xFF059669), fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(b['clientName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text(
              'Partner: ${b['partnerName']} (${b['partnerId']}) · Date: ${b['eventDate']}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 12),

            // Cross-Department Nodes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildThreadNode('Financials', '${b['amount']} (12% = ${b['settlement12Pct']})', Icons.payments_rounded, const Color(0xFF8B5CF6)),
                _buildThreadNode('Operations', '${b['opsCoordinator']} (${b['readiness']})', Icons.precision_manufacturing_rounded, const Color(0xFFF59E0B)),
                _buildThreadNode('Payment', b['paymentStatus'], Icons.verified_user_rounded, const Color(0xFF10B981)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadNode(String label, String val, IconData icon, Color color) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(val, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _partners.length,
      itemBuilder: (context, index) {
        final p = _partners[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2563EB).withOpacity(0.12),
              radius: 22,
              child: const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB)),
            ),
            title: Row(
              children: [
                Expanded(child: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBBF24).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(p['tier'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${p['id']} · ${p['city']} · Capacity: ${p['capacity']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text('Owner: ${p['owner']} (${p['phone']}) · Commission: ${p['commissionRate']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B))),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    Text('${p['rating']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                Text('${p['totalBookings']} Bookings', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final b = _bookings[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF10B981).withOpacity(0.12),
              radius: 22,
              child: const Icon(Icons.celebration_rounded, color: Color(0xFF10B981)),
            ),
            title: Row(
              children: [
                Expanded(child: Text(b['clientName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5))),
                Text(b['amount'], style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 13.5)),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${b['id']} · ${b['partnerName']} · Date: ${b['eventDate']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                Text('Coordinator: ${b['opsCoordinator']} · Readiness: ${b['readiness']} · Status: ${b['paymentStatus']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        );
      },
    );
  }
}
