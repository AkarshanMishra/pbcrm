import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'booking_detail_screen.dart';

class OperationsDashboardScreen extends StatefulWidget {
  const OperationsDashboardScreen({super.key});

  @override
  State<OperationsDashboardScreen> createState() => _OperationsDashboardScreenState();
}

class _OperationsDashboardScreenState extends State<OperationsDashboardScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  String _selectedFilter = "ALL";
  Map<String, dynamic> _stats = {
    'total_bookings': 4,
    'confirmed_partners': 3,
    'ready_for_service': 2,
    'in_progress': 2,
    'open_issues': 3,
    'at_risk_bookings': 1,
  };
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final statsRes = await _api.get('/api/v1/operations/bookings/dashboard_stats/');
      if (statsRes.statusCode == 200 && statsRes.data != null) {
        _stats = statsRes.data;
      }

      final bookingsRes = await _api.get('/api/v1/operations/bookings/');
      if (bookingsRes.statusCode == 200 && bookingsRes.data != null) {
        final results = bookingsRes.data['results'] ?? bookingsRes.data;
        if (results is List) {
          _bookings = results;
        }
      }
    } catch (e) {
      debugPrint("Load ops dashboard error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<dynamic> _getFilteredBookings() {
    if (_selectedFilter == "ALL") return _bookings;
    if (_selectedFilter == "READY") {
      return _bookings.where((b) => b['operations_status'] == 'READY').toList();
    }
    if (_selectedFilter == "IN_PROGRESS") {
      return _bookings.where((b) => b['operations_status'] == 'COORDINATION' || b['operations_status'] == 'READINESS_CHECK').toList();
    }
    if (_selectedFilter == "ISSUES") {
      return _bookings.where((b) => b['operations_status'] == 'ISSUE_REPORTED').toList();
    }
    return _bookings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          "Operations Execution Queue",
          style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: const Color(0xFF10B981),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildSummaryGrid(),
                    const SizedBox(height: 20),
                    _buildFilterChips(),
                    const SizedBox(height: 16),
                    _buildBookingsQueue(),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          "BOOKINGS & SERVICE STATUS",
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(child: _buildMetricTile("Total", "${_stats['total_bookings'] ?? 4}", const Color(0xFF38BDF8))),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricTile("Ready", "${_stats['ready_for_service'] ?? 2}", const Color(0xFF10B981))),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricTile("At Risk", "${_stats['at_risk_bookings'] ?? 1}", const Color(0xFFEF4444))),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ["ALL", "READY", "IN_PROGRESS", "ISSUES"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSel = _selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(f.replaceAll('_', ' ')),
              selected: isSel,
              selectedColor: const Color(0xFF10B981).withOpacity(0.2),
              backgroundColor: const Color(0xFF1E293B),
              labelStyle: TextStyle(
                color: isSel ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
              ),
              side: BorderSide(color: isSel ? const Color(0xFF10B981) : const Color(0xFF334155)),
              onSelected: (val) => setState(() => _selectedFilter = f),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingsQueue() {
    final filtered = _getFilteredBookings();
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const Text("No bookings in this filter category.", style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }

    return Column(
      children: filtered.map((b) {
        final String code = b['booking_code'] ?? 'PB-XXXX';
        final String partner = b['partner_name'] ?? 'Venue';
        final String customer = b['customer_name'] ?? 'Client';
        final String date = b['event_date'] ?? '';
        final int readiness = b['readiness_percentage'] ?? 0;
        final String status = b['operations_status'] ?? 'COORDINATION';

        Color statusColor = const Color(0xFF38BDF8);
        if (status == 'READY') statusColor = const Color(0xFF10B981);
        if (status == 'ISSUE_REPORTED') statusColor = const Color(0xFFEF4444);

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b['id'])),
            ).then((_) => _loadDashboardData());
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      code,
                      style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        status.replaceAll('_', ' '),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  partner,
                  style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  "Customer: $customer • Date: $date",
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: readiness / 100.0,
                          backgroundColor: const Color(0xFF0F172A),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            readiness >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "$readiness% Ready",
                      style: TextStyle(
                        color: readiness >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
