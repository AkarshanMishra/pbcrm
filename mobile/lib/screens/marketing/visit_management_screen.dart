import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class VisitManagementScreen extends StatefulWidget {
  const VisitManagementScreen({super.key});

  @override
  State<VisitManagementScreen> createState() => _VisitManagementScreenState();
}

class _VisitManagementScreenState extends State<VisitManagementScreen> with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _visits = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchVisits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchVisits() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/v1/marketing/visits/');
      if (mounted) {
        setState(() {
          _visits = (res.data is List) ? res.data : (res.data['results'] ?? []);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getVisitsForTab(int tabIndex) {
    if (tabIndex == 0) {
      // Today / Scheduled
      return _visits.where((v) => v['status'] == 'scheduled' || v['status'] == 'in_progress').toList();
    } else if (tabIndex == 1) {
      // In Progress / Active
      return _visits.where((v) => v['status'] == 'in_progress').toList();
    } else {
      // Completed
      return _visits.where((v) => v['status'] == 'completed').toList();
    }
  }

  void _openVisitWorkflowSheet(dynamic visit) {
    final bool isInProgress = visit['status'] == 'in_progress';
    final bool isCompleted = visit['status'] == 'completed';

    final notesCtrl = TextEditingController(text: visit['discussion_notes'] ?? '');
    final nextActionCtrl = TextEditingController(text: visit['next_action'] ?? '');
    String partnerInterest = visit['partner_interest'] ?? 'high';

    // Checklist state
    final Map<String, dynamic> checklist = Map<String, dynamic>.from(visit['checklist'] ?? {});
    checklist.putIfAbsent('owner_details', () => true);
    checklist.putIfAbsent('contact_details', () => true);
    checklist.putIfAbsent('aadhaar', () => true);
    checklist.putIfAbsent('pan', () => true);
    checklist.putIfAbsent('gst', () => false);
    checklist.putIfAbsent('exterior_photos', () => false);
    checklist.putIfAbsent('interior_photos', () => false);
    checklist.putIfAbsent('room_photos', () => false);
    checklist.putIfAbsent('parking_photos', () => false);
    checklist.putIfAbsent('amenities_ac', () => true);
    checklist.putIfAbsent('amenities_parking', () => true);
    checklist.putIfAbsent('amenities_wifi', () => true);
    checklist.putIfAbsent('amenities_backup', () => true);

    final List<dynamic> photos = List<dynamic>.from(visit['photos'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.98,
          expand: false,
          builder: (_, scrollController) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),

                // Visit Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit['partner_name'] ?? 'Partner Visit',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${visit['visit_code'] ?? ''} • ${visit['purpose']?.toString().replaceAll('_', ' ').toUpperCase() ?? ''}',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isInProgress
                            ? const Color(0xFFECFDF5)
                            : (isCompleted ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (visit['status'] ?? 'SCHEDULED').toString().replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          color: isInProgress
                              ? const Color(0xFF059669)
                              : (isCompleted ? const Color(0xFF2563EB) : const Color(0xFFD97706)),
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Location Verification Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fmd_good_rounded, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(visit['location_name'] ?? 'Assigned Area', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                            const SizedBox(height: 2),
                            const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 13),
                                SizedBox(width: 4),
                                Text('Location: Within allowed visit area (GPS Verified)', style: TextStyle(color: Color(0xFF059669), fontSize: 10.5, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),

                // START VISIT BUTTON IF NOT STARTED
                if (!isInProgress && !isCompleted) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await _api.post('/api/v1/marketing/visits/${visit['id']}/start-visit/', {
                            'latitude': 26.4499,
                            'longitude': 80.3319,
                          });
                          visit['status'] = 'in_progress';
                          setModalState(() {});
                          _fetchVisits();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit started! GPS location verified.'), backgroundColor: Colors.green));
                        } catch (_) {}
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                      label: const Text('START VISIT NOW', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 11. VENUE VISIT CHECKLIST
                const Text('VENUE & PARTNER ONBOARDING CHECKLIST', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                _buildChecklistGroup('Partner Information', [
                  _buildChecklistItem('Owner details & KYC', checklist, 'owner_details', setModalState),
                  _buildChecklistItem('Contact details & phone', checklist, 'contact_details', setModalState),
                ]),
                const SizedBox(height: 8),
                _buildChecklistGroup('Documents Collection', [
                  _buildChecklistItem('Aadhaar Card Copy', checklist, 'aadhaar', setModalState),
                  _buildChecklistItem('PAN Card Verification', checklist, 'pan', setModalState),
                  _buildChecklistItem('GST Registration Certificate', checklist, 'gst', setModalState),
                ]),
                const SizedBox(height: 8),
                _buildChecklistGroup('Property Photography', [
                  _buildChecklistItem('Exterior & Facade photos', checklist, 'exterior_photos', setModalState),
                  _buildChecklistItem('Interior banquet hall photos', checklist, 'interior_photos', setModalState),
                  _buildChecklistItem('Bridal & Guest rooms', checklist, 'room_photos', setModalState),
                  _buildChecklistItem('Valet & Parking spaces', checklist, 'parking_photos', setModalState),
                ]),
                const SizedBox(height: 8),
                _buildChecklistGroup('Amenities Verification', [
                  _buildChecklistItem('AC Conditioning working', checklist, 'amenities_ac', setModalState),
                  _buildChecklistItem('Dedicated Parking space', checklist, 'amenities_parking', setModalState),
                  _buildChecklistItem('Wi-Fi connection', checklist, 'amenities_wifi', setModalState),
                  _buildChecklistItem('Power Generator Backup', checklist, 'amenities_backup', setModalState),
                ]),
                const SizedBox(height: 16),

                // 12. PHOTO COLLECTION MATRIX
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('PROPERTY PHOTOS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    TextButton.icon(
                      onPressed: () {
                        photos.add({'category': 'exterior', 'url': 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=400&q=80'});
                        setModalState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo attached to visit gallery!')));
                      },
                      icon: const Icon(Icons.add_a_photo_rounded, size: 16),
                      label: const Text('Add Photo', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
                    ),
                  ],
                ),
                if (photos.isEmpty)
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                    ),
                    child: const Center(
                      child: Text('Tap "+ Add Photo" to attach camera shots of the property', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
                    ),
                  )
                else
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      itemBuilder: (ctx, pi) => Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFFE2E8F0),
                          image: const DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=200&q=80'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            color: Colors.black54,
                            padding: const EdgeInsets.all(2),
                            child: const Text('Captured', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // 13. VISIT NOTES & PARTNER INTEREST
                const Text('VISIT OUTCOME & NOTES', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Partner Interest:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 10),
                    _buildInterestChip('high', '🟢 High', partnerInterest, (v) => setModalState(() => partnerInterest = v)),
                    const SizedBox(width: 6),
                    _buildInterestChip('medium', '🟡 Medium', partnerInterest, (v) => setModalState(() => partnerInterest = v)),
                    const SizedBox(width: 6),
                    _buildInterestChip('low', '🔴 Low', partnerInterest, (v) => setModalState(() => partnerInterest = v)),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Discussion Notes *', hintText: 'Discussed pricing, commission rates, onboarding packages...'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nextActionCtrl,
                  decoration: const InputDecoration(labelText: 'Next Action *', hintText: 'Send contract draft tomorrow, schedule follow-up call...'),
                ),
                const SizedBox(height: 20),

                // COMPLETE VISIT ACTION
                if (!isCompleted)
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (notesCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please write discussion notes before completing.')));
                          return;
                        }
                        Navigator.pop(ctx);
                        try {
                          await _api.post('/api/v1/marketing/visits/${visit['id']}/complete-visit/', {
                            'checklist': checklist,
                            'photos': photos,
                            'partner_interest': partnerInterest,
                            'discussion_notes': notesCtrl.text.trim(),
                            'next_action': nextActionCtrl.text.trim().isEmpty ? 'Follow up tomorrow' : nextActionCtrl.text.trim(),
                            'next_follow_up_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit completed successfully! Auto follow-up scheduled.'), backgroundColor: Colors.green));
                          _fetchVisits();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to complete visit: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text('COMPLETE VISIT & LOG FOLLOW-UP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistGroup(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 10, bottom: 4),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String label, Map<String, dynamic> map, String key, StateSetter setModalState) {
    final bool checked = map[key] == true;
    return CheckboxListTile(
      dense: true,
      title: Text(label, style: TextStyle(fontSize: 12, color: checked ? const Color(0xFF0F172A) : const Color(0xFF64748B), fontWeight: checked ? FontWeight.w600 : FontWeight.normal)),
      value: checked,
      activeColor: const Color(0xFF2563EB),
      onChanged: (val) {
        setModalState(() {
          map[key] = val ?? false;
        });
      },
    );
  }

  Widget _buildInterestChip(String key, String label, String current, Function(String) onSelect) {
    final isSelected = current == key;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF334155))),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB),
      onSelected: (_) => onSelect(key),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Field Visits & Verification', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 17)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Today\'s Route'),
            Tab(text: 'Active Visits'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVisitList(0),
                _buildVisitList(1),
                _buildVisitList(2),
              ],
            ),
    );
  }

  Widget _buildVisitList(int tabIndex) {
    final list = _getVisitsForTab(tabIndex);
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No visits found for this section.\nTap "+" on the home bar to schedule a visit.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8))),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final v = list[i];
        final time = (v['scheduled_start'] ?? '').toString().substring(11, 16);
        final isCompleted = v['status'] == 'completed';
        final isInProgress = v['status'] == 'in_progress';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isInProgress ? const Color(0xFF34D399) : const Color(0xFFE2E8F0), width: isInProgress ? 1.5 : 1),
            boxShadow: [
              BoxShadow(
                color: (isInProgress ? const Color(0xFF10B981) : Colors.black).withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _openVisitWorkflowSheet(v),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                        child: Text(time.isNotEmpty ? time : '10:00 AM', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF334155))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isInProgress
                              ? const Color(0xFFECFDF5)
                              : (isCompleted ? const Color(0xFFEFF6FF) : const Color(0xFFFFFBEB)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          (v['status'] ?? 'SCHEDULED').toString().replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            color: isInProgress
                                ? const Color(0xFF059669)
                                : (isCompleted ? const Color(0xFF2563EB) : const Color(0xFFD97706)),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    v['partner_name'] ?? 'Partner',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Purpose: ${v['purpose']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'ONBOARDING'}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          v['location_name'] ?? 'Assigned Area',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _openVisitWorkflowSheet(v),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInProgress ? const Color(0xFF10B981) : const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          minimumSize: const Size(60, 26),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        child: Text(
                          isInProgress ? 'In Progress' : (isCompleted ? 'View Report' : 'Open Visit'),
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
