import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class OperationsIssuesScreen extends StatefulWidget {
  const OperationsIssuesScreen({super.key});

  @override
  State<OperationsIssuesScreen> createState() => _OperationsIssuesScreenState();
}

class _OperationsIssuesScreenState extends State<OperationsIssuesScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _issues = [];

  @override
  void initState() {
    super.initState();
    _loadIssues();
  }

  Future<void> _loadIssues() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/v1/operations/issues/');
      if (res.statusCode == 200 && res.data != null) {
        final results = res.data['results'] ?? res.data;
        if (results is List) {
          _issues = results;
        }
      }
    } catch (e) {
      debugPrint("Load ops issues error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNewIssueModal() {
    final problemCtrl = TextEditingController();
    String category = "VENUE_DEFECT";
    String priority = "HIGH";
    int slaHours = 2;

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
                      "REPORT OPERATIONAL ISSUE / SLA",
                      style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: category,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: "Issue Category",
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: "PARTNER_DELAY", child: Text("Partner Delay")),
                        DropdownMenuItem(value: "VENUE_DEFECT", child: Text("Venue Defect / Missing Amenity")),
                        DropdownMenuItem(value: "PAYMENT_DISPUTE", child: Text("Payment Dispute")),
                        DropdownMenuItem(value: "CUSTOMER_COMPLAINT", child: Text("Customer Complaint")),
                        DropdownMenuItem(value: "CATERING_QUALITY", child: Text("Catering / Food Quality")),
                        DropdownMenuItem(value: "DECORATION_MISMATCH", child: Text("Decoration Mismatch")),
                        DropdownMenuItem(value: "STAFF_SHORTAGE", child: Text("Staff Shortage")),
                        DropdownMenuItem(value: "LOGISTICS_DELAY", child: Text("Logistics Delay")),
                        DropdownMenuItem(value: "EQUIPMENT_FAILURE", child: Text("Equipment Failure")),
                        DropdownMenuItem(value: "OTHER", child: Text("Other Operational Issue")),
                      ],
                      onChanged: (val) => setModalState(() => category = val!),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: priority,
                            dropdownColor: const Color(0xFF0F172A),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: "Priority",
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: "LOW", child: Text("Low")),
                              DropdownMenuItem(value: "MEDIUM", child: Text("Medium")),
                              DropdownMenuItem(value: "HIGH", child: Text("High")),
                              DropdownMenuItem(value: "CRITICAL", child: Text("Critical")),
                            ],
                            onChanged: (val) => setModalState(() => priority = val!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: slaHours,
                            dropdownColor: const Color(0xFF0F172A),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: "SLA (Hours)",
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text("1 Hour")),
                              DropdownMenuItem(value: 2, child: Text("2 Hours")),
                              DropdownMenuItem(value: 4, child: Text("4 Hours")),
                              DropdownMenuItem(value: 8, child: Text("8 Hours")),
                            ],
                            onChanged: (val) => setModalState(() => slaHours = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: problemCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Problem Statement & Location Details",
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
                          backgroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (problemCtrl.text.trim().isEmpty) return;
                          Navigator.pop(ctx);
                          try {
                            await _api.post('/api/v1/operations/issues/', {
                              'category': category,
                              'priority': priority,
                              'sla_hours': slaHours,
                              'problem_statement': problemCtrl.text.trim(),
                            });
                            _loadIssues();
                          } catch (e) {
                            debugPrint("Create issue err: $e");
                          }
                        },
                        child: const Text("RAISE ISSUE WITH SLA", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
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

  void _escalateIssue(String id) async {
    try {
      await _api.post('/api/v1/operations/issues/$id/escalate/', {});
      _loadIssues();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Issue Escalated to Operations Management"), backgroundColor: Color(0xFFEF4444)),
      );
    } catch (e) {
      debugPrint("Escalate err: $e");
    }
  }

  void _resolveIssue(String id) async {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Mark Issue as Resolved", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: noteCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Resolution notes...",
            hintStyle: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.post('/api/v1/operations/issues/$id/resolve/', {
                  'resolution_notes': noteCtrl.text.trim().isEmpty ? 'Resolved on site.' : noteCtrl.text.trim(),
                });
                _loadIssues();
              } catch (e) {
                debugPrint("Resolve err: $e");
              }
            },
            child: const Text("RESOLVE"),
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
        title: const Text(
          "Operations Issues & SLA",
          style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_alert_rounded, color: Color(0xFFEF4444)),
            onPressed: _showNewIssueModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFEF4444)))
          : RefreshIndicator(
              onRefresh: _loadIssues,
              color: const Color(0xFFEF4444),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _issues.length,
                itemBuilder: (context, index) {
                  final item = _issues[index];
                  final String code = item['issue_code'] ?? 'OP-XXXX';
                  final String cat = item['category'] ?? 'OTHER';
                  final String prio = item['priority'] ?? 'HIGH';
                  final String st = item['status'] ?? 'OPEN';
                  final String esc = item['escalation_level'] ?? 'EXECUTIVE';
                  final String problem = item['problem_statement'] ?? '';
                  final String deadline = item['sla_deadline'] ?? '';

                  Color prioColor = const Color(0xFFEF4444);
                  if (prio == 'MEDIUM') prioColor = const Color(0xFFF59E0B);
                  if (prio == 'LOW') prioColor = const Color(0xFF38BDF8);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: prioColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              "$code • ${cat.replaceAll('_', ' ')}",
                              style: TextStyle(color: prioColor, fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: prioColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                prio,
                                style: TextStyle(color: prioColor, fontSize: 10, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          problem,
                          style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            const Icon(Icons.timer_outlined, color: Color(0xFF94A3B8), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              "SLA Target: ${deadline.split('T').first}",
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
                            const Spacer(),
                            Text(
                              "Level: $esc",
                              style: const TextStyle(color: Color(0xFFA78BFA), fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        if (st != 'RESOLVED' && st != 'CLOSED') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _escalateIssue(item['id']),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFEF4444)),
                                    foregroundColor: const Color(0xFFEF4444),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  child: const Text("ESCALATE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _resolveIssue(item['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    elevation: 0,
                                  ),
                                  child: const Text("RESOLVE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          const Text("✓ Resolved", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 12)),
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
