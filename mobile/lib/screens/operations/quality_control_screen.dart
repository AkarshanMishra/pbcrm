import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class QualityControlScreen extends StatefulWidget {
  const QualityControlScreen({super.key});

  @override
  State<QualityControlScreen> createState() => _QualityControlScreenState();
}

class _QualityControlScreenState extends State<QualityControlScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _inspections = [];

  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  Future<void> _loadInspections() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/v1/operations/inspections/');
      if (res.statusCode == 200 && res.data != null) {
        final results = res.data['results'] ?? res.data;
        if (results is List) {
          _inspections = results;
        }
      }
    } catch (e) {
      debugPrint("Load inspections error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNewInspectionModal() {
    final partnerCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String result = "PASS";
    int score = 90;

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
                      "RECORD QC AUDIT & INSPECTION",
                      style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: partnerCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Partner / Venue Name",
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: result,
                            dropdownColor: const Color(0xFF0F172A),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: "Audit Result",
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: "PASS", child: Text("Pass / Approved")),
                              DropdownMenuItem(value: "PASS_WITH_ISSUES", child: Text("Pass with Minor Flags")),
                              DropdownMenuItem(value: "FAIL", child: Text("Failed / Non-Compliant")),
                            ],
                            onChanged: (val) => setModalState(() => result = val!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: score,
                            dropdownColor: const Color(0xFF0F172A),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: "Score (0-100)",
                              labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            items: const [
                              DropdownMenuItem(value: 100, child: Text("100%")),
                              DropdownMenuItem(value: 90, child: Text("90%")),
                              DropdownMenuItem(value: 75, child: Text("75%")),
                              DropdownMenuItem(value: 50, child: Text("50% (Fail)")),
                              DropdownMenuItem(value: 30, child: Text("30% (Fail)")),
                            ],
                            onChanged: (val) => setModalState(() => score = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "QC Notes & Kitchen/Hall Observations",
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
                          if (partnerCtrl.text.trim().isEmpty) return;
                          Navigator.pop(ctx);
                          try {
                            await _api.post('/api/v1/operations/inspections/', {
                              'partner_name': partnerCtrl.text.trim(),
                              'result': result,
                              'score': score,
                              'notes': noteCtrl.text.trim(),
                            });
                            _loadInspections();
                          } catch (e) {
                            debugPrint("Create QC err: $e");
                          }
                        },
                        child: const Text("SUBMIT AUDIT REPORT", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          "Quality Control & Audits",
          style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18, fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add_task_rounded, color: Color(0xFF10B981)),
            onPressed: _showNewInspectionModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : RefreshIndicator(
              onRefresh: _loadInspections,
              color: const Color(0xFF10B981),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _inspections.length,
                itemBuilder: (context, index) {
                  final item = _inspections[index];
                  final String code = item['inspection_code'] ?? 'QC-XXXX';
                  final String partner = item['partner_name'] ?? 'Partner Venue';
                  final String result = item['result'] ?? 'PASS';
                  final int score = item['score'] ?? 100;
                  final String date = item['inspection_date'] ?? '';
                  final String notes = item['notes'] ?? '';

                  Color resColor = const Color(0xFF10B981);
                  if (result == 'FAIL') resColor = const Color(0xFFEF4444);
                  if (result == 'PASS_WITH_ISSUES') resColor = const Color(0xFFF59E0B);

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
                              code,
                              style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: resColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: resColor.withOpacity(0.4)),
                              ),
                              child: Text(
                                "$result ($score%)",
                                style: TextStyle(color: resColor, fontSize: 10, fontWeight: FontWeight.w800),
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
                          "Date: $date",
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            notes,
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                          ),
                        ],
                        if (item['auto_generated_issue'] != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: const <Widget>[
                                Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 16),
                                SizedBox(width: 6),
                                Text(
                                  "Auto-escalated blocker issue generated",
                                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
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
