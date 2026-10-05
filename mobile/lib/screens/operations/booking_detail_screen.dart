import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import 'event_readiness_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _booking;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/v1/operations/bookings/${widget.bookingId}/');
      if (res.statusCode == 200 && res.data != null) {
        _booking = res.data;
      }
    } catch (e) {
      debugPrint("Load booking err: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showStatusDialog() {
    if (_booking == null) return;
    final List<String> statuses = [
      'PREPARATION_PENDING',
      'COORDINATION',
      'READINESS_CHECK',
      'IN_PROGRESS',
      'READY',
      'EXECUTING',
      'COMPLETED',
      'ISSUE_REPORTED',
      'CANCELLED',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Update Operations Status", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((st) {
            return ListTile(
              title: Text(st.replaceAll('_', ' '), style: const TextStyle(color: Colors.white, fontSize: 13)),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await _api.post('/api/v1/operations/bookings/${widget.bookingId}/update_status/', {
                    'operations_status': st,
                  });
                  _loadBookingDetails();
                } catch (e) {
                  debugPrint("Update status err: $e");
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    if (_booking == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(backgroundColor: const Color(0xFF1E293B)),
        body: const Center(child: Text("Booking not found", style: TextStyle(color: Colors.white))),
      );
    }

    final String code = _booking!['booking_code'] ?? 'PB-XXXX';
    final String partner = _booking!['partner_name'] ?? 'Venue';
    final String partnerPhone = _booking!['partner_phone'] ?? '';
    final String customer = _booking!['customer_name'] ?? 'Client';
    final String customerPhone = _booking!['customer_phone'] ?? '';
    final String date = _booking!['event_date'] ?? '';
    final String timeSlot = _booking!['event_time_slot'] ?? '';
    final String pkg = _booking!['package_name'] ?? 'Standard';
    final String amount = "${_booking!['amount'] ?? '0.00'}";
    final String payStatus = _booking!['payment_status'] ?? 'PARTIAL';
    final String opStatus = _booking!['operations_status'] ?? 'COORDINATION';
    final int readiness = _booking!['readiness_percentage'] ?? 0;
    final String instructions = _booking!['special_instructions'] ?? 'No special instructions recorded.';
    final String address = _booking!['venue_address'] ?? 'Venue Address';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          "$code Details",
          style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF10B981)),
            onPressed: _showStatusDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header Card
            Container(
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
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                        ),
                        child: Text(
                          opStatus.replaceAll('_', ' '),
                          style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    partner,
                    style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.location_on_rounded, color: Color(0xFF94A3B8), size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(address, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Readiness Meter Card
            Container(
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
                      const Text(
                        "SERVICE READINESS",
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                      ),
                      Text(
                        "$readiness% Complete",
                        style: TextStyle(
                          color: readiness >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: readiness / 100.0,
                      backgroundColor: const Color(0xFF0F172A),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        readiness >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventReadinessScreen(bookingId: widget.bookingId),
                          ),
                        ).then((_) => _loadBookingDetails());
                      },
                      icon: const Icon(Icons.checklist_rounded, size: 18),
                      label: const Text("Open 8-Point Readiness Checklist"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Event & Customer Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    "EVENT DETAILS",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow("Event Date", "$date ($timeSlot)"),
                  _buildDetailRow("Package", pkg),
                  _buildDetailRow("Amount / Payment", "₹$amount ($payStatus)"),
                  _buildDetailRow("Client Name", customer),
                  _buildDetailRow("Client Phone", customerPhone),
                  _buildDetailRow("Partner Phone", partnerPhone),
                  const Divider(color: Color(0xFF334155), height: 24),
                  const Text(
                    "Special Instructions:",
                    style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(instructions, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Contact Action Buttons
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Calling Partner: $partnerPhone")),
                      );
                    },
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: const Text("CALL PARTNER"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Calling Client: $customerPhone")),
                      );
                    },
                    icon: const Icon(Icons.support_agent_rounded, size: 18),
                    label: const Text("CONTACT CLIENT"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFA78BFA),
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
          Text(value, style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
