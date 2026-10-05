import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class OperationsRequestsScreen extends StatefulWidget {
  const OperationsRequestsScreen({super.key});

  @override
  State<OperationsRequestsScreen> createState() => _OperationsRequestsScreenState();
}

class _OperationsRequestsScreenState extends State<OperationsRequestsScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/v1/operations/requests/');
      if (res.statusCode == 200 && res.data != null) {
        final results = res.data['results'] ?? res.data;
        if (results is List) {
          _requests = results;
        }
      }
    } catch (e) {
      debugPrint("Load ops requests error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNewRequestModal() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String reqType = "ADDITIONAL_STAFF";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      "SUBMIT OPERATIONAL SUPPORT REQUEST",
                      style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: reqType,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Request Type",
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: "ADDITIONAL_STAFF", child: Text("Additional Operations Staff")),
                        DropdownMenuItem(value: "EQUIPMENT_REQUISITION", child: Text("Equipment / Requisition")),
                        DropdownMenuItem(value: "BUDGET_APPROVAL", child: Text("Emergency Budget Approval")),
                        DropdownMenuItem(value: "TIMELINE_EXTENSION", child: Text("Timeline Extension")),
                        DropdownMenuItem(value: "PARTNER_REPLACEMENT", child: Text("Emergency Partner Replacement")),
                        DropdownMenuItem(value: "REFUND_OVERRIDE", child: Text("Customer Refund / Discount")),
                        DropdownMenuItem(value: "TRANSPORT_SUPPORT", child: Text("Transport / Logistics Support")),
                      ],
                      onChanged: (val) => setModalState(() => reqType = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Subject / Requirement Title",
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amtCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Estimated Amount (₹) if applicable",
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Justification & Details",
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (titleCtrl.text.trim().isEmpty) return;
                          Navigator.pop(ctx);
                          try {
                            await _api.post('/api/v1/operations/requests/', {
                              'request_type': reqType,
                              'title': titleCtrl.text.trim(),
                              'amount': double.tryParse(amtCtrl.text.trim()) ?? 0.0,
                              'description': descCtrl.text.trim(),
                            });
                            _loadRequests();
                          } catch (e) {
                            debugPrint("Create req err: $e");
                          }
                        },
                        child: const Text("SUBMIT REQUEST", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _approveRequest(String id) async {
    try {
      await _api.post('/api/v1/operations/requests/$id/approve/', {'approval_notes': 'Approved by operations manager.'});
      _loadRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request Approved"), backgroundColor: Color(0xFF10B981)),
      );
    } catch (e) {
      debugPrint("Approve err: $e");
    }
  }

  void _rejectRequest(String id) async {
    try {
      await _api.post('/api/v1/operations/requests/$id/reject/', {'approval_notes': 'Rejected by operations manager.'});
      _loadRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request Rejected"), backgroundColor: Color(0xFFEF4444)),
      );
    } catch (e) {
      debugPrint("Reject err: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          "Operations Requests & Approvals",
          style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.post_add_rounded, color: Color(0xFF10B981)),
            onPressed: _showNewRequestModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : RefreshIndicator(
              onRefresh: _loadRequests,
              color: const Color(0xFF10B981),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _requests.length,
                itemBuilder: (context, index) {
                  final req = _requests[index];
                  final String code = req['request_code'] ?? 'REQ-XXXX';
                  final String type = req['request_type'] ?? 'SUPPORT';
                  final String title = req['title'] ?? 'Request';
                  final String status = req['status'] ?? 'NEW';
                  final String amount = "${req['amount'] ?? '0.00'}";
                  final String desc = req['description'] ?? '';

                  Color stColor = const Color(0xFF38BDF8);
                  if (status == 'APPROVED') stColor = const Color(0xFF10B981);
                  if (status == 'REJECTED') stColor = const Color(0xFFEF4444);

                  return Container(
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
                              "$code • ${type.replaceAll('_', ' ')}",
                              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: stColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: stColor.withOpacity(0.4)),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(color: stColor, fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        if (double.tryParse(amount) != null && double.parse(amount) > 0) ...[
                          const SizedBox(height: 4),
                          Text("Estimated Cost: ₹$amount", style: const TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.w700)),
                        ],
                        const SizedBox(height: 6),
                        Text(desc, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                        if (status == 'NEW' || status == 'REVIEW') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _rejectRequest(req['id']),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFEF4444)),
                                    foregroundColor: const Color(0xFFEF4444),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text("REJECT"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _approveRequest(req['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text("APPROVE"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
