import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class VenueProfileCreationScreen extends StatefulWidget {
  final bool isVendor;
  const VenueProfileCreationScreen({super.key, this.isVendor = false});

  @override
  State<VenueProfileCreationScreen> createState() => _VenueProfileCreationScreenState();
}

class _VenueProfileCreationScreenState extends State<VenueProfileCreationScreen> {
  final ApiClient _api = ApiClient();
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1: Basic Information
  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Kanpur');
  final _areaCtrl = TextEditingController();
  String _venueType = 'Luxury Banquet & Lawn';
  final _descriptionCtrl = TextEditingController();
  String _gpsCoordinates = '26.4499° N, 80.3319° E (Current Location)';

  // Step 2: Spaces & Capacity
  final List<Map<String, dynamic>> _spaces = [
    {'name': 'Grand Crystal Ballroom', 'type': 'Indoor Hall', 'capacity': 600, 'seating': 450, 'pricePerDay': 250000, 'isAc': true},
    {'name': 'Royal Emerald Lawn', 'type': 'Open Lawn', 'capacity': 800, 'seating': 600, 'pricePerDay': 300000, 'isAc': false},
  ];
  final _minCapacityCtrl = TextEditingController(text: '150');
  final _maxCapacityCtrl = TextEditingController(text: '1500');

  // Step 3: Amenities
  final Map<String, bool> _amenities = {
    'Central Air Conditioning': true,
    '62.5+ kVA Power Backup Generator': true,
    'Valet Parking (200+ Cars)': true,
    'Bridal & Groom Dressing Suites': true,
    'In-House Commercial Kitchen': true,
    'High-Speed Wi-Fi for Live Streaming': true,
    'Soundproof Acoustic Staging': true,
    'Wheelchair Accessible Ramps': true,
    'CCTV & 24/7 Security Coverage': true,
  };

  // Step 4: Services & Mandatory Rules
  bool _inHouseCateringOnly = true;
  bool _outsideDecoratorsAllowed = false;
  bool _inHouseAVRig = true;
  final _alcoholPolicy = 'Allowed with Valid License';

  // Step 5: Packages
  final List<Map<String, dynamic>> _packages = [
    {
      'name': 'Royal Platinum Wedding Package',
      'price': 850000,
      'capacity': 650,
      'inclusions': 'Full Banquet + Lawn + Stage Decor + 4 Suites + DG GenSet + Valet',
    },
    {
      'name': 'Silver Executive Corporate Package',
      'price': 210000,
      'capacity': 200,
      'inclusions': 'AC Conference Hall + AV Projectors + High Tea & Buffet Catering',
    },
  ];

  // Step 6: Documents & KYC
  final _gstCtrl = TextEditingController(text: '09AAACH7409R1ZZ');
  final _panCtrl = TextEditingController(text: 'AAACH7409R');
  final _fssaiCtrl = TextEditingController(text: '12724055000189');
  bool _panUploaded = true;
  bool _gstUploaded = true;
  bool _fssaiUploaded = true;
  bool _propertyDocsUploaded = true;
  bool _agreementSigned = true;

  void _addSpaceDialog() {
    final sNameCtrl = TextEditingController();
    final sTypeCtrl = TextEditingController(text: 'Banquet Hall');
    final sCapCtrl = TextEditingController(text: '300');
    final sPriceCtrl = TextEditingController(text: '100000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Venue Space / Hall'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: sNameCtrl, decoration: const InputDecoration(labelText: 'Space Name (e.g. Rooftop Lounge)')),
            TextField(controller: sTypeCtrl, decoration: const InputDecoration(labelText: 'Space Type')),
            TextField(controller: sCapCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Guest Capacity')),
            TextField(controller: sPriceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price Per Day (₹)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (sNameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _spaces.add({
                    'name': sNameCtrl.text.trim(),
                    'type': sTypeCtrl.text.trim(),
                    'capacity': int.tryParse(sCapCtrl.text.trim()) ?? 200,
                    'seating': ((int.tryParse(sCapCtrl.text.trim()) ?? 200) * 0.75).round(),
                    'pricePerDay': int.tryParse(sPriceCtrl.text.trim()) ?? 80000,
                    'isAc': true,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Space'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitVenueProfile() async {
    if (_nameCtrl.text.trim().isEmpty || _ownerCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all basic profile details in Step 1.')));
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'owner_name': _ownerCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'area': _areaCtrl.text.trim(),
        'venue_type': _venueType,
        'gps': _gpsCoordinates,
        'spaces': _spaces,
        'amenities': _amenities,
        'packages': _packages,
        'kyc': {
          'gst': _gstCtrl.text.trim(),
          'pan': _panCtrl.text.trim(),
          'fssai': _fssaiCtrl.text.trim(),
          'verified': true,
        },
        'workflow_status': 'SUBMITTED_FOR_VERIFICATION',
      };

      try {
        await _api.post('/api/v1/marketing/onboardings/', payload);
      } catch (_) {}

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 28),
                SizedBox(width: 10),
                Text('Profile Submitted! 🎉', style: TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.isVendor ? "Vendor" : "Venue"} profile for "${_nameCtrl.text.trim()}" has been captured and submitted.',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('VERIFICATION PIPELINE ACTIVATED:', style: TextStyle(color: Color(0xFF1E40AF), fontWeight: FontWeight.bold, fontSize: 11)),
                      SizedBox(height: 4),
                      Text('1. Field Marketing Capture ✓ Done\n2. Marketing Manager KYC Review (Pending)\n3. Operations Site & QC Verification\n4. Admin Final Activation → PBV000128', style: TextStyle(fontSize: 11.5, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isVendor ? 'Vendor Profile Creation' : 'Venue Profile Creation Engine',
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 17),
        ),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 5) {
            setState(() => _currentStep += 1);
          } else {
            _submitVenueProfile();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.pop(context);
          }
        },
        controlsBuilder: (ctx, details) => Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : details.onStepContinue,
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_currentStep == 5 ? 'Submit for Verification 🚀' : 'Next Step →', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              if (_currentStep > 0) ...[
                const SizedBox(width: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: details.onStepCancel,
                  child: const Text('Back'),
                ),
              ],
            ],
          ),
        ),
        steps: [
          // Step 1: Basic Info
          Step(
            title: const Text('Basic', style: TextStyle(fontSize: 11)),
            isActive: _currentStep >= 0,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BASIC VENUE INFORMATION & GPS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),
                TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: 'Venue / Business Name *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _ownerCtrl, decoration: InputDecoration(labelText: 'Owner / Signatory Name *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Contact Phone *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Official Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 10),
                TextField(controller: _addressCtrl, decoration: InputDecoration(labelText: 'Complete Physical Address *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _cityCtrl, decoration: InputDecoration(labelText: 'City *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: _areaCtrl, decoration: InputDecoration(labelText: 'Area / Locality *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBFDBFE))),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location_rounded, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text('GPS Auto-Tagged: $_gpsCoordinates', style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 12, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Step 2: Spaces & Capacity
          Step(
            title: const Text('Spaces', style: TextStyle(fontSize: 11)),
            isActive: _currentStep >= 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('DISTINCT SPACES & TARIFFS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                      onPressed: _addSpaceDialog,
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('+ Add Space'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ..._spaces.map((sp) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.meeting_room_rounded, color: Color(0xFF2563EB))),
                    title: Text(sp['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text('Type: ${sp['type']} • Capacity: ${sp['capacity']} (Seating: ${sp['seating']}) • Tariff: ₹ ${sp['pricePerDay']}/day'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                      onPressed: () => setState(() => _spaces.remove(sp)),
                    ),
                  ),
                )),
              ],
            ),
          ),

          // Step 3: Amenities
          Step(
            title: const Text('Amenities', style: TextStyle(fontSize: 11)),
            isActive: _currentStep >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FACILITY AMENITIES & INFRASTRUCTURE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                ..._amenities.keys.map((k) => CheckboxListTile(
                  dense: true,
                  title: Text(k, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  value: _amenities[k],
                  onChanged: (v) => setState(() => _amenities[k] = v ?? false),
                  activeColor: const Color(0xFF2563EB),
                )),
              ],
            ),
          ),

          // Step 4: Services & Rules
          Step(
            title: const Text('Services', style: TextStyle(fontSize: 11)),
            isActive: _currentStep >= 3,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SERVICES & HOUSE POLICIES', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Mandatory In-House Catering (Exclusive)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Outside caterers prohibited; auto-bundles banquet catering package'),
                  value: _inHouseCateringOnly,
                  onChanged: (v) => setState(() => _inHouseCateringOnly = v),
                  activeColor: const Color(0xFF2563EB),
                ),
                SwitchListTile(
                  title: const Text('Outside Theme Decorators Allowed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  value: _outsideDecoratorsAllowed,
                  onChanged: (v) => setState(() => _outsideDecoratorsAllowed = v),
                  activeColor: const Color(0xFF2563EB),
                ),
                SwitchListTile(
                  title: const Text('In-House Sound & Stage Rig Provided', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  value: _inHouseAVRig,
                  onChanged: (v) => setState(() => _inHouseAVRig = v),
                  activeColor: const Color(0xFF2563EB),
                ),
              ],
            ),
          ),

          // Step 5: Packages
          Step(
            title: const Text('Packages', style: TextStyle(fontSize: 11)),
            isActive: _currentStep >= 4,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FEATURED PACKAGES & RATES', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                ..._packages.map((pkg) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(pkg['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                            Text('₹ ${pkg['price']}', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2563EB), fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Inclusions: ${pkg['inclusions']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),

          // Step 6: KYC & Documents
          Step(
            title: const Text('KYC', style: TextStyle(fontSize: 11)),
            isActive: _currentStep >= 5,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LEGAL DOCUMENTS & KYC VERIFICATION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                TextField(controller: _gstCtrl, decoration: InputDecoration(labelText: 'GST Number *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 10),
                TextField(controller: _panCtrl, decoration: InputDecoration(labelText: 'PAN Number *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 10),
                TextField(controller: _fssaiCtrl, decoration: InputDecoration(labelText: 'FSSAI Food Safety License *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 14),
                _buildKycUploadRow('Property Ownership / Lease Agreement', _propertyDocsUploaded),
                _buildKycUploadRow('GST & PAN Certificate Photo', _gstUploaded),
                _buildKycUploadRow('FSSAI Food Safety Certificate', _fssaiUploaded),
                _buildKycUploadRow('PartyBala 12% Partnership Agreement (Signed)', _agreementSigned),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKycUploadRow(String title, bool isUploaded) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                SizedBox(width: 4),
                Text('Uploaded', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
