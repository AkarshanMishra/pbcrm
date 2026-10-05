import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';

class EventReadinessScreen extends StatefulWidget {
  final String bookingId;
  const EventReadinessScreen({super.key, required this.bookingId});

  @override
  State<EventReadinessScreen> createState() => _EventReadinessScreenState();
}

class _EventReadinessScreenState extends State<EventReadinessScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  bool _isSaving = false;

  bool _hall = false;
  bool _seating = false;
  bool _decoration = false;
  bool _catering = false;
  bool _parking = false;
  bool _setup = false;
  bool _staff = false;
  bool _power = false;
  final TextEditingController _notesController = TextEditingController();

  int get _score {
    int count = 0;
    if (_hall) count++;
    if (_seating) count++;
    if (_decoration) count++;
    if (_catering) count++;
    if (_parking) count++;
    if (_setup) count++;
    if (_staff) count++;
    if (_power) count++;
    return ((count / 8.0) * 100).round();
  }

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/v1/operations/bookings/${widget.bookingId}/');
      if (res.statusCode == 200 && res.data != null) {
        final checklist = res.data['readiness_checklist'];
        if (checklist != null) {
          _hall = checklist['hall_confirmed'] ?? false;
          _seating = checklist['seating_confirmed'] ?? false;
          _decoration = checklist['decoration_confirmed'] ?? false;
          _catering = checklist['catering_confirmed'] ?? false;
          _parking = checklist['parking_confirmed'] ?? false;
          _setup = checklist['setup_confirmed'] ?? false;
          _staff = checklist['staff_confirmed'] ?? false;
          _power = checklist['power_backup_confirmed'] ?? false;
          _notesController.text = checklist['notes'] ?? '';
        }
      }
    } catch (e) {
      debugPrint("Load checklist err: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChecklist() async {
    setState(() => _isSaving = true);
    try {
      final res = await _api.post('/api/v1/operations/bookings/${widget.bookingId}/update_readiness/', {
        'hall_confirmed': _hall,
        'seating_confirmed': _seating,
        'decoration_confirmed': _decoration,
        'catering_confirmed': _catering,
        'parking_confirmed': _parking,
        'setup_confirmed': _setup,
        'staff_confirmed': _staff,
        'power_backup_confirmed': _power,
        'notes': _notesController.text.trim(),
      });
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Readiness Updated: $_score% Confirmed"),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint("Save checklist err: $e");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
          "8-Point Readiness Checklist",
          style: TextStyle(color: Color(0xFFF8FAFC), fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Score Indicator Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _score >= 80 ? const Color(0xFF10B981).withOpacity(0.5) : const Color(0xFFF59E0B).withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text(
                              "READINESS SCORE",
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                            ),
                            Text(
                              "$_score%",
                              style: TextStyle(
                                color: _score >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _score / 100.0,
                            backgroundColor: const Color(0xFF0F172A),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _score >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                            minHeight: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "8 OPERATIONAL VERIFICATION CHECKPOINTS",
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 10),

                  _buildCheckTile("1. Hall & Venue Confirmation", "Space clean, air conditioning verified", _hall, (val) => setState(() => _hall = val!)),
                  _buildCheckTile("2. Seating & Layout Verification", "Guest seating plan & VIP tables positioned", _seating, (val) => setState(() => _seating = val!)),
                  _buildCheckTile("3. Decoration & Lighting Setup", "Floral & theme elements completed as per package", _decoration, (val) => setState(() => _decoration = val!)),
                  _buildCheckTile("4. Catering & Food Readiness", "Menu cooked, warmers ready, FSSAI standards verified", _catering, (val) => setState(() => _catering = val!)),
                  _buildCheckTile("5. Parking & Valet Arrangement", "Signage placed and security staff posted", _parking, (val) => setState(() => _parking = val!)),
                  _buildCheckTile("6. AV & Projector / Sound Setup", "Microphones tested, mixer levels balanced", _setup, (val) => setState(() => _setup = val!)),
                  _buildCheckTile("7. Operations Staff Attendance", "Ushers, managers, and service team on ground", _staff, (val) => setState(() => _staff = val!)),
                  _buildCheckTile("8. Power Backup / Generator Ready", "Generator fueled and auto-switch tested", _power, (val) => setState(() => _power = val!)),

                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Verification Notes & Audit Remarks",
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF334155))),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChecklist,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "SUBMIT & SYNC READINESS",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildCheckTile(String title, String subtitle, bool value, ValueChanged<bool?> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: value ? const Color(0xFF10B981).withOpacity(0.5) : const Color(0xFF334155)),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF10B981),
        checkColor: const Color(0xFF0F172A),
        title: Text(
          title,
          style: TextStyle(
            color: const Color(0xFFF8FAFC),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            decoration: value ? TextDecoration.none : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
      ),
    );
  }
}
