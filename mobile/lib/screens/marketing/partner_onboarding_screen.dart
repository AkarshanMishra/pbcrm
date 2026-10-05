import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class PartnerOnboardingScreen extends StatefulWidget {
  const PartnerOnboardingScreen({super.key});

  @override
  State<PartnerOnboardingScreen> createState() => _PartnerOnboardingScreenState();
}

class _PartnerOnboardingScreenState extends State<PartnerOnboardingScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _onboardings = [];

  @override
  void initState() {
    super.initState();
    _fetchOnboardings();
  }

  Future<void> _fetchOnboardings() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/v1/marketing/onboardings/');
      if (mounted) {
        setState(() {
          _onboardings = (res.data is List) ? res.data : (res.data['results'] ?? []);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openOnboardingWizard(dynamic onboarding) {
    int currentStep = _getStepNumber(onboarding['workflow_step']);
    final user = context.read<AuthProvider>().currentUser;
    final bool isManagerOrAdmin = user?.email?.contains('admin') == true || user?.email?.contains('manager') == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            onboarding['partner_name'] ?? 'Partner Onboarding',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text('${onboarding['onboarding_code'] ?? ''} • ${onboarding['partner_type']?.toString().toUpperCase() ?? 'VENUE'}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${onboarding['progress_percentage'] ?? 25}% COMPLETE',
                        style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ((onboarding['progress_percentage'] ?? 25) as num) / 100.0,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 20),

                // Step Progression List
                const Text('ONBOARDING PIPELINE STEPS', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                _buildWorkflowStepRow(1, 'Partner Basic Information', currentStep >= 1, currentStep == 1, 'Owner name, contact phone, indoor/outdoor capacity'),
                _buildWorkflowStepRow(2, 'Documents & Legal Collection', currentStep >= 2, currentStep == 2, 'Aadhaar, PAN Card, GST Registration, FSSAI'),
                _buildWorkflowStepRow(3, 'KYC & Identity Verification', currentStep >= 3, currentStep == 3, 'Govt ID verification & background check'),
                _buildWorkflowStepRow(4, 'Property Photography & Gallery', currentStep >= 4, currentStep == 4, 'Exterior, interior halls, rooms & parking areas'),
                _buildWorkflowStepRow(5, 'Amenities & Services Setup', currentStep >= 5, currentStep == 5, 'AC, Wi-Fi, Generator power backup, Valet parking'),
                _buildWorkflowStepRow(6, 'Packages & Commission Pricing', currentStep >= 6, currentStep == 6, 'Silver/Gold packages, per plate rate, platform terms'),
                _buildWorkflowStepRow(7, 'Marketing Manager Review', currentStep >= 7, currentStep == 7, 'Internal quality compliance check'),
                _buildWorkflowStepRow(8, 'Admin Approval & Live Launch', currentStep >= 8, currentStep == 8, 'Published live on PartyBala customer app'),
                const SizedBox(height: 24),

                // ACTION BUTTONS
                if (currentStep < 7)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await _api.post('/api/v1/marketing/onboardings/${onboarding['id']}/submit-step/', {
                            'step': _getStepKey(currentStep + 1),
                            'data': {'completed': true},
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Step submitted and progressed!'), backgroundColor: Colors.green));
                          Navigator.pop(ctx);
                          _fetchOnboardings();
                        } catch (_) {}
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('COMPLETE & PROCEED TO NEXT STEP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    ),
                  )
                else if (isManagerOrAdmin) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _api.post('/api/v1/marketing/onboardings/${onboarding['id']}/approve/', {
                                'notes': 'Approved by manager. Listing ready for live publication.',
                              });
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Partner Approved & Published Live!'), backgroundColor: Colors.green));
                              Navigator.pop(ctx);
                              _fetchOnboardings();
                            } catch (_) {}
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          icon: const Icon(Icons.verified_rounded, size: 18),
                          label: const Text('APPROVE PARTNER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes requested sent to marketing executive.')));
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                        child: const Text('Request Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getStepNumber(String? step) {
    switch (step) {
      case 'info':
        return 1;
      case 'documents':
        return 2;
      case 'kyc':
        return 3;
      case 'photos':
        return 4;
      case 'amenities':
        return 5;
      case 'packages':
        return 6;
      case 'manager_review':
        return 7;
      case 'admin_approval':
      case 'active':
        return 8;
      default:
        return 1;
    }
  }

  String _getStepKey(int num) {
    switch (num) {
      case 1:
        return 'info';
      case 2:
        return 'documents';
      case 3:
        return 'kyc';
      case 4:
        return 'photos';
      case 5:
        return 'amenities';
      case 6:
        return 'packages';
      default:
        return 'packages';
    }
  }

  Widget _buildWorkflowStepRow(int number, String title, bool isCompleted, bool isCurrent, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: isCompleted
                ? const Color(0xFF10B981)
                : (isCurrent ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text(
                    '$number',
                    style: TextStyle(
                      color: isCurrent ? Colors.white : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isCompleted || isCurrent ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(color: isCompleted || isCurrent ? const Color(0xFF64748B) : const Color(0xFFCBD5E1), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Partner Onboarding Pipeline', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)), onPressed: _fetchOnboardings),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _onboardings.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No active partner onboardings.\nConvert a lead to onboarding or tap "+" to create one.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: _onboardings.length,
                  itemBuilder: (ctx, i) {
                    final o = _onboardings[i];
                    final pct = (o['progress_percentage'] ?? 25) as num;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openOnboardingWizard(o),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    o['partner_name'] ?? 'Partner',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                    child: Text('$pct% COMPLETE', style: const TextStyle(color: Color(0xFF2563EB), fontSize: 10.5, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Stage: ${o['workflow_step']?.toString().toUpperCase() ?? 'INFO'}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: pct / 100.0,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                                  minHeight: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
