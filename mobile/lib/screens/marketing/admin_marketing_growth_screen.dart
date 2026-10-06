import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'partner_onboarding_screen.dart';
import 'visit_management_screen.dart';
import 'leads_pipeline_screen.dart';

class AdminMarketingGrowthScreen extends StatefulWidget {
  final int initialSectionIndex;
  const AdminMarketingGrowthScreen({super.key, this.initialSectionIndex = 0});

  @override
  State<AdminMarketingGrowthScreen> createState() => _AdminMarketingGrowthScreenState();
}

class _AdminMarketingGrowthScreenState extends State<AdminMarketingGrowthScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _api = ApiClient();
  late TabController _tabController;
  int _currentSection = 0;
  String _searchQuery = '';
  String _leadStageFilter = 'ALL';
  String _selectedDateHorizon = 'Today';

  // ===========================================================================
  // 1. DATA STORES (COMPLETE ENTERPRISE MARKETING & GROWTH ENTITIES)
  // ===========================================================================

  // 1.1 CRM — Leads
  final List<Map<String, dynamic>> _leads = [
    {
      'id': 'LD-1024',
      'type': 'Venue',
      'business': 'Grand Heritage Banquet & Lawn',
      'contact': 'Rajesh Sharma',
      'phone': '+91 98390 12345',
      'email': 'rajesh@grandheritage.com',
      'city': 'Kanpur',
      'area': 'Civil Lines',
      'source': 'Google Search Campaign',
      'campaign': 'Diwali Partner Drive',
      'owner': 'Rohan Gupta',
      'dept': 'Marketing & Field Sales',
      'priority': 'High',
      'score': 87,
      'expectedValue': 850000,
      'stage': 'Visit Scheduled',
      'nextAction': 'Site Visit & Photo Audit',
      'nextFollowup': 'Tomorrow, 11:30 AM',
      'createdDate': '04 Oct 2026',
      'activitiesCount': 12,
    },
    {
      'id': 'LD-1025',
      'type': 'Direct Client',
      'business': 'Sunil Mittal Wedding',
      'contact': 'Sunil Mittal',
      'phone': '+91 94150 98765',
      'email': 'sunil.mittal@gmail.com',
      'city': 'Lucknow',
      'area': 'Gomti Nagar',
      'source': 'Instagram Reel Ad',
      'campaign': 'Royal Weddings 2026',
      'owner': 'Kavita Nair',
      'dept': 'Operations & Sales',
      'priority': 'Urgent',
      'score': 94,
      'expectedValue': 340000,
      'stage': 'Negotiation',
      'nextAction': 'Send Final Discounted Proposal',
      'nextFollowup': 'Today, 04:00 PM',
      'createdDate': '05 Oct 2026',
      'activitiesCount': 8,
    },
    {
      'id': 'LD-1026',
      'type': 'Vendor / Caterer',
      'business': 'Royal Flavors Catering Services',
      'contact': 'Anoop Verma',
      'phone': '+91 98890 55432',
      'email': 'anoop@royalflavors.in',
      'city': 'Kanpur',
      'area': 'Swaroop Nagar',
      'source': 'Direct Field Sourcing',
      'campaign': 'Vendor Ecosystem Q4',
      'owner': 'Rahul Verma',
      'dept': 'Marketing',
      'priority': 'Medium',
      'score': 68,
      'expectedValue': 450000,
      'stage': 'Contacted',
      'nextAction': 'Schedule Tasting & Menu Verification',
      'nextFollowup': '08 Oct 2026',
      'createdDate': '05 Oct 2026',
      'activitiesCount': 3,
    },
    {
      'id': 'LD-1027',
      'type': 'Corporate Partner',
      'business': 'TechNova Solutions Annual Meet',
      'contact': 'Pooja Tandon',
      'phone': '+91 97920 11223',
      'email': 'pooja.t@technova.com',
      'city': 'Kanpur',
      'area': 'Kidwai Nagar',
      'source': 'Website Referral',
      'campaign': 'B2B Enterprise Connect',
      'owner': 'Rohan Gupta',
      'dept': 'Marketing',
      'priority': 'High',
      'score': 79,
      'expectedValue': 280000,
      'stage': 'Qualified',
      'nextAction': 'Send Corporate Package Deck',
      'nextFollowup': '07 Oct 2026',
      'createdDate': '06 Oct 2026',
      'activitiesCount': 5,
    },
  ];

  // 1.2 CRM — Contacts & Accounts
  final List<Map<String, dynamic>> _contacts = [
    {
      'id': 'CNT-501',
      'name': 'Rohit Sharma',
      'phone': '+91 98390 12345',
      'email': 'rohit@grandheritage.com',
      'role': 'Owner / Managing Director',
      'business': 'Grand Heritage Banquet',
      'partnerCode': 'PBV000124',
      'leadsCount': 2,
      'bookingsCount': 4,
      'totalRevenue': '₹ 12,40,000',
      'status': 'ACTIVE',
    },
    {
      'id': 'CNT-502',
      'name': 'Sunil Mittal',
      'phone': '+91 94150 98765',
      'email': 'sunil.mittal@gmail.com',
      'role': 'Client / Host',
      'business': 'Mittal Enterprises',
      'partnerCode': 'N/A',
      'leadsCount': 1,
      'bookingsCount': 1,
      'totalRevenue': '₹ 3,40,000',
      'status': 'ACTIVE',
    },
    {
      'id': 'CNT-503',
      'name': 'Anoop Verma',
      'phone': '+91 98890 55432',
      'email': 'anoop@royalflavors.in',
      'role': 'Head Chef & Proprietor',
      'business': 'Royal Flavors Catering',
      'partnerCode': 'PBV000188',
      'leadsCount': 1,
      'bookingsCount': 6,
      'totalRevenue': '₹ 8,90,000',
      'status': 'ACTIVE',
    },
  ];

  // 1.3 Acquisition — Campaigns & Channels
  final List<Map<String, dynamic>> _campaigns = [
    {
      'id': 'CMP-2026-01',
      'name': 'Diwali Partner Acquisition Drive',
      'objective': 'Partner Acquisition (Banquets)',
      'channel': 'Google Ads & Meta',
      'budget': 80000,
      'spend': 64200,
      'leads': 420,
      'partners': 28,
      'bookings': 96,
      'revenue': 780000,
      'roas': '9.75x',
      'status': 'LIVE',
      'owner': 'Rohan Gupta',
      'period': '15 Sep - 31 Oct 2026',
    },
    {
      'id': 'CMP-2026-02',
      'name': 'Royal Weddings 2026 Video Campaign',
      'objective': 'Customer Acquisition (Weddings)',
      'channel': 'Instagram Reels & YouTube',
      'budget': 150000,
      'spend': 142000,
      'leads': 820,
      'partners': 0,
      'bookings': 140,
      'revenue': 1420000,
      'roas': '10.0x',
      'status': 'LIVE',
      'owner': 'Rahul Verma',
      'period': '01 Oct - 30 Nov 2026',
    },
    {
      'id': 'CMP-2026-03',
      'name': 'Corporate Year-End Summit Drive',
      'objective': 'B2B Corporate Events',
      'channel': 'LinkedIn & Direct Email',
      'budget': 50000,
      'spend': 22000,
      'leads': 110,
      'partners': 4,
      'bookings': 18,
      'revenue': 280000,
      'roas': '5.6x',
      'status': 'SCHEDULED',
      'owner': 'Rohan Gupta',
      'period': '10 Oct - 15 Dec 2026',
    },
  ];

  // 1.4 Sales & Conversion — Opportunities & Quotations
  final List<Map<String, dynamic>> _opportunities = [
    {
      'id': 'OPP-301',
      'title': 'Grand Heritage Annual Partnership Contract',
      'business': 'Grand Heritage Banquet',
      'contact': 'Rajesh Sharma',
      'stage': 'Negotiation',
      'value': 850000,
      'probability': 0.75,
      'expectedClose': '20 Oct 2026',
      'owner': 'Rohan Gupta',
      'pipeline': 'Partner Pipeline',
    },
    {
      'id': 'OPP-302',
      'title': 'TechCorp Annual 3-Day Gala & Summit',
      'business': 'TechCorp Global',
      'contact': 'Pooja Tandon',
      'stage': 'Proposal Sent',
      'value': 340000,
      'probability': 0.60,
      'expectedClose': '15 Oct 2026',
      'owner': 'Kavita Nair',
      'pipeline': 'Customer Pipeline',
    },
    {
      'id': 'OPP-303',
      'title': 'Royal Palms Resort Exclusive Catering Tie-up',
      'business': 'Royal Palms Resort',
      'contact': 'Vikram Singh',
      'stage': 'Qualification',
      'value': 620000,
      'probability': 0.45,
      'expectedClose': '30 Oct 2026',
      'owner': 'Rohan Gupta',
      'pipeline': 'Partner Pipeline',
    },
  ];

  final List<Map<String, dynamic>> _quotations = [
    {
      'id': 'QT-901',
      'client': 'Sunil Mittal (Anniversary)',
      'venue': 'Royal Palms Resort (Poolside)',
      'services': ['Gourmet BBQ Buffet', 'Fusion Acoustic Band', 'LED Screen'],
      'amount': 420000,
      'discount': 25000,
      'netAmount': 395000,
      'status': 'SENT',
      'validUntil': '15 Oct 2026',
    },
    {
      'id': 'QT-902',
      'client': 'TechNova Solutions',
      'venue': 'Kuhu Espresso Conference Hall',
      'services': ['Full Day AV & High Tea', 'Executive Lunch', 'Delegate Kits'],
      'amount': 210000,
      'discount': 10000,
      'netAmount': 200000,
      'status': 'APPROVED',
      'validUntil': '20 Oct 2026',
    },
  ];

  // 1.5 Partner Growth & Activation Lifecycle
  final List<Map<String, dynamic>> _partners = [
    {
      'code': 'PBV-00124',
      'name': 'Grand Heritage Banquet',
      'category': 'Banquet & Lawn',
      'city': 'Kanpur',
      'healthScore': 88,
      'status': 'HEALTHY',
      'bookingsMonthly': 18,
      'revenueMonthly': '₹ 14.8 L',
      'reviewsScore': '4.9 ★',
      'responseRate': '98%',
      'expansionOpportunity': 'Add In-House Floral Decor (Est. +₹2.4L/yr)',
      'activationStage': 'ACTIVE & VERIFIED',
    },
    {
      'code': 'PBV-00125',
      'name': 'Royal Palms Resort',
      'category': 'Resort & Lawn',
      'city': 'Lucknow',
      'healthScore': 82,
      'status': 'HEALTHY',
      'bookingsMonthly': 12,
      'revenueMonthly': '₹ 9.5 L',
      'reviewsScore': '4.8 ★',
      'responseRate': '92%',
      'expansionOpportunity': 'Add Live Barista & Dessert Bar',
      'activationStage': 'ACTIVE & VERIFIED',
    },
    {
      'code': 'PBV-00126',
      'name': 'Kuhu Espresso Banquet',
      'category': 'Boutique Banquet',
      'city': 'Kanpur',
      'healthScore': 64,
      'status': 'AT_RISK',
      'bookingsMonthly': 4,
      'revenueMonthly': '₹ 2.1 L',
      'reviewsScore': '4.2 ★',
      'responseRate': '76%',
      'expansionOpportunity': 'Retrain Front Desk & Revamp Lighting Package',
      'activationStage': 'KYC VERIFIED (PENDING PRICING)',
    },
  ];

  // 1.6 Customer Growth & Reviews
  final List<Map<String, dynamic>> _customerSegments = [
    {'name': '💎 High Net Worth Wedding Planners', 'rule': 'Bookings > ₹2.5L in last 90 days', 'count': 142, 'targetAction': 'VIP Concierge Invite'},
    {'name': '🎉 Repeat Birthday & Anniversary Hosts', 'rule': '2+ events organized with PartyBala', 'count': 380, 'targetAction': '₹1,000 Loyalty Voucher'},
    {'name': '⏰ Inactive (>180 Days) Dormant Accounts', 'rule': 'No bookings in 6 months', 'count': 820, 'targetAction': 'Diwali Festive Reactivation'},
    {'name': '🏢 Corporate Procurement Leads', 'rule': 'B2B summit bookings & recurring GST', 'count': 95, 'targetAction': 'Annual Contract Deck'},
  ];

  final List<Map<String, dynamic>> _reviews = [
    {
      'id': 'REV-701',
      'customer': 'Amit Sharma',
      'event': 'Sharma Grand Wedding Reception',
      'venue': 'Grand Heritage Banquet',
      'rating': 5,
      'comment': 'Flawless execution! The royal floral decor and catering were praised by all 650 guests.',
      'responseStatus': 'RESPONDED',
      'date': 'Yesterday',
    },
    {
      'id': 'REV-702',
      'customer': 'Dr. Alok Srivastava',
      'event': 'MedCare National Surgeons Conference',
      'venue': 'Kuhu Espresso Banquet',
      'rating': 5,
      'comment': 'High-speed internet and AV setup worked smoothly for the live surgery streaming session.',
      'responseStatus': 'PENDING_RESPONSE',
      'date': 'Today, 09:00 AM',
    },
  ];

  // 1.7 Content & Omnichannel Communication
  final List<Map<String, dynamic>> _templates = [
    {
      'id': 'TMP-01',
      'name': 'WhatsApp Instant Lead Outreach',
      'channel': 'WhatsApp (Meta Approved)',
      'content': 'Hi {{client_name}}, thank you for inquiring with PartyBala for {{venue_name}}. Your dedicated manager is {{manager_name}}...',
      'status': 'APPROVED',
    },
    {
      'id': 'TMP-02',
      'name': 'Partner Welcome & KYC Kit',
      'channel': 'Email & WhatsApp',
      'content': 'Welcome {{partner_name}} to the PartyBala Verified Network! Complete your bank & GST verification here: {{link}}',
      'status': 'APPROVED',
    },
    {
      'id': 'TMP-03',
      'name': 'Post-Event Review & Feedback Invitation',
      'channel': 'WhatsApp & SMS',
      'content': 'Hi {{client_name}}, how was your event at {{venue_name}}? Share your feedback and get ₹500 cashback: {{review_url}}',
      'status': 'APPROVED',
    },
  ];

  // 1.8 Automation Studio
  final List<Map<String, dynamic>> _workflows = [
    {
      'id': 'WF-01',
      'name': 'High-Value Lead Instant Routing',
      'trigger': 'New Lead Created with Score >= 70',
      'actions': 'Assign Senior Executive → Send SMS & WhatsApp → Create Call Task (SLA 30m)',
      'status': 'ACTIVE',
      'runsThisMonth': 342,
    },
    {
      'id': 'WF-02',
      'name': 'Post-Visit Automated Follow-Up Matrix',
      'trigger': 'Field Visit Marked Completed',
      'actions': 'Day 1: WhatsApp Brochure → Day 3: Call Task → Day 7: Manager Escalation',
      'status': 'ACTIVE',
      'runsThisMonth': 188,
    },
    {
      'id': 'WF-03',
      'name': 'Partner Inactivity Alert & Reactivation',
      'trigger': 'No Bookings in 30 Days for Active Banquet',
      'actions': 'Notify Marketing Lead → Auto-schedule Account Review Visit',
      'status': 'ACTIVE',
      'runsThisMonth': 14,
    },
  ];

  // 1.9 Growth Strategy & Goals
  final List<Map<String, dynamic>> _goals = [
    {'title': 'Monthly Partner Acquisition (Banquets)', 'target': 100, 'current': 78, 'unit': 'Partners', 'deadline': '31 Oct 2026', 'status': 'ON_TRACK'},
    {'title': 'Monthly Attributed Gross Revenue', 'target': 3500000, 'current': 2480000, 'unit': '₹ INR', 'deadline': '31 Oct 2026', 'status': 'ON_TRACK'},
    {'title': 'Direct Customer Lead Conversion', 'target': 30, 'current': 24.6, 'unit': '% Rate', 'deadline': '31 Oct 2026', 'status': 'NEEDS_ATTENTION'},
  ];

  final List<Map<String, dynamic>> _experiments = [
    {
      'id': 'EXP-024',
      'hypothesis': 'Premium Partner Landing Page with 360° Virtual Tour increases partner inquiries by >25%.',
      'variantA': 'Classic Form Landing Page',
      'variantB': '360° Interactive Virtual Tour + Instant Estimator',
      'primaryMetric': 'Lead Conversion Rate',
      'currentLift': '+31.4%',
      'trafficSplit': '50 / 50',
      'sampleSize': '4,280 Visitors',
      'status': 'RUNNING',
      'duration': 'Day 18 of 30',
      'decision': 'Variant B Outperforming (P-value < 0.01)',
    },
    {
      'id': 'EXP-025',
      'hypothesis': 'Automated WhatsApp Video Confirmation within 15 mins increases lead-to-visit rate.',
      'variantA': 'Standard SMS Confirmation',
      'variantB': 'Personalized WhatsApp Video Note from City Lead',
      'primaryMetric': 'Visit Completion Rate',
      'currentLift': '+42.8%',
      'trafficSplit': '50 / 50',
      'sampleSize': '680 Leads',
      'status': 'WINNER_DECLARED',
      'duration': 'Completed (30 Days)',
      'decision': 'Rollout Variant B across all North India regions',
    },
  ];

  final List<Map<String, dynamic>> _competitors = [
    {
      'name': 'WedMeGood Local Kanpur',
      'marketShare': '22%',
      'pricing': 'Listing Fee Model (₹25K/yr) vs PartyBala 12% Success Fee',
      'strengths': 'Strong national brand recall & direct organic search',
      'weaknesses': 'No ground execution crew, zero on-site banquet QC',
      'partyBalaAdvantage': 'Full turnkey decor + operations + zero upfront listing fees',
      'threatLevel': 'MEDIUM',
    },
    {
      'name': 'WeddingWire Lucknow',
      'marketShare': '18%',
      'pricing': 'Pay-per-lead model (₹400/lead)',
      'strengths': 'Heavy Google search ad budgets',
      'weaknesses': 'Unverified junk leads, low conversion rates',
      'partyBalaAdvantage': 'Pre-qualified verified client bookings with dedicated managers',
      'threatLevel': 'LOW',
    },
  ];

  // 1.10 Approvals & Settings
  final List<Map<String, dynamic>> _approvals = [
    {
      'id': 'APP-MKT-101',
      'type': 'Campaign Budget Approval',
      'title': 'Diwali Partner Drive Budget Top-Up (+₹30,000)',
      'requestedBy': 'Rohan Gupta (Marketing Head)',
      'amount': '₹ 30,000',
      'status': 'PENDING',
      'date': 'Today, 02:15 PM',
      'priority': 'High',
    },
    {
      'id': 'APP-MKT-102',
      'type': 'Partner Onboarding Approval',
      'title': 'Grand Hyatt Regency Banquet Approval & 12% Model',
      'requestedBy': 'Rahul Verma (Field Sales)',
      'amount': 'N/A',
      'status': 'PENDING',
      'date': 'Today, 11:30 AM',
      'priority': 'Urgent',
    },
    {
      'id': 'APP-MKT-103',
      'type': 'Promo Code Creation',
      'title': 'FLASH5000 Festive Booking Discount Voucher',
      'requestedBy': 'Kavita Nair (Campaign Ops)',
      'amount': 'Max ₹5,000 / Booking',
      'status': 'APPROVED',
      'date': 'Yesterday',
      'priority': 'Medium',
    },
  ];

  final List<Map<String, dynamic>> _scoringRules = [
    {'criterion': 'Phone Contact Number Verified via OTP / Call', 'points': 20, 'category': 'Verification', 'enabled': true},
    {'criterion': 'Expressed Direct Interest in Booking Date', 'points': 15, 'category': 'Intent', 'enabled': true},
    {'criterion': 'On-Site Field Visit & Venue Audit Completed', 'points': 20, 'category': 'Engagement', 'enabled': true},
    {'criterion': 'Budget Confirmed > ₹ 2.5 Lakhs', 'points': 15, 'category': 'Budget', 'enabled': true},
    {'criterion': 'Direct Decision Maker Engaged (Owner/Host)', 'points': 20, 'category': 'Authority', 'enabled': true},
    {'criterion': 'Follow-up Response within 2 Hours', 'points': 10, 'category': 'Responsiveness', 'enabled': true},
  ];

  final List<Map<String, dynamic>> _promoCodes = [
    {
      'code': 'WELCOME500',
      'discount': '₹ 500 Flat OFF',
      'minBooking': 5000,
      'maxDiscount': 500,
      'usageLimit': '1 per user',
      'usedCount': 412,
      'expiry': '31 Dec 2026',
      'status': 'ACTIVE',
      'category': 'All Bookings',
    },
    {
      'code': 'ROYALWEDDING',
      'discount': '10% OFF',
      'minBooking': 100000,
      'maxDiscount': 15000,
      'usageLimit': 'Unlimited',
      'usedCount': 84,
      'expiry': '15 Nov 2026',
      'status': 'ACTIVE',
      'category': 'Wedding Banquets',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentSection = widget.initialSectionIndex;
    _tabController = TabController(length: 11, vsync: this, initialIndex: _currentSection);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentSection = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // 2. COMPLETE CRUD MODALS & ACTION DIALOGS
  // ===========================================================================

  // 2.1 Quick Actions Bottom Sheet
  void _showMarketingQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bolt_rounded, color: Color(0xFF2563EB), size: 24),
                SizedBox(width: 8),
                Text('Growth & CRM Quick Action Hub', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildQuickActionBtn('Add Lead', Icons.person_add_alt_1_rounded, const Color(0xFF2563EB), () {
                  Navigator.pop(ctx);
                  _showCreateLeadDialog();
                }),
                _buildQuickActionBtn('Launch Campaign', Icons.campaign_rounded, const Color(0xFF10B981), () {
                  Navigator.pop(ctx);
                  _showCreateCampaignDialog();
                }),
                _buildQuickActionBtn('New Deal', Icons.insights_rounded, const Color(0xFF8B5CF6), () {
                  Navigator.pop(ctx);
                  _showCreateOpportunityDialog();
                }),
                _buildQuickActionBtn('Create Quote', Icons.request_quote_rounded, const Color(0xFFD97706), () {
                  Navigator.pop(ctx);
                  _showCreateQuotationDialog();
                }),
                _buildQuickActionBtn('Onboard Partner', Icons.handshake_rounded, const Color(0xFF0891B2), () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerOnboardingScreen()));
                }),
                _buildQuickActionBtn('New Promo Code', Icons.local_offer_rounded, const Color(0xFFE11D48), () {
                  Navigator.pop(ctx);
                  _showCreatePromoDialog();
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }

  // 2.2 Create / Edit Lead Dialog
  void _showCreateLeadDialog({Map<String, dynamic>? editLead}) {
    final businessCtrl = TextEditingController(text: editLead?['business'] ?? '');
    final contactCtrl = TextEditingController(text: editLead?['contact'] ?? '');
    final phoneCtrl = TextEditingController(text: editLead?['phone'] ?? '');
    final emailCtrl = TextEditingController(text: editLead?['email'] ?? '');
    final cityCtrl = TextEditingController(text: editLead?['city'] ?? 'Kanpur');
    final areaCtrl = TextEditingController(text: editLead?['area'] ?? '');
    final valueCtrl = TextEditingController(text: editLead != null ? editLead['expectedValue'].toString() : '500000');
    String type = editLead?['type'] ?? 'Venue';
    String priority = editLead?['priority'] ?? 'High';
    String stage = editLead?['stage'] ?? 'New';
    String source = editLead?['source'] ?? 'Google Search Campaign';
    String owner = editLead?['owner'] ?? 'Rohan Gupta';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                editLead != null ? 'Edit Lead & Account' : 'Create Enterprise CRM Lead',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: type,
                          decoration: InputDecoration(labelText: 'Lead Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: const [
                            DropdownMenuItem(value: 'Venue', child: Text('🏢 Venue / Banquet')),
                            DropdownMenuItem(value: 'Direct Client', child: Text('👤 Direct Client')),
                            DropdownMenuItem(value: 'Vendor / Caterer', child: Text('🍽️ Vendor / Supplier')),
                            DropdownMenuItem(value: 'Corporate Partner', child: Text('🤝 Corporate Partner')),
                          ],
                          onChanged: (v) => setDialogState(() => type = v ?? 'Venue'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: priority,
                          decoration: InputDecoration(labelText: 'Priority Level', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: const [
                            DropdownMenuItem(value: 'Urgent', child: Text('🔴 Urgent')),
                            DropdownMenuItem(value: 'High', child: Text('🟠 High')),
                            DropdownMenuItem(value: 'Medium', child: Text('🟡 Medium')),
                            DropdownMenuItem(value: 'Low', child: Text('🟢 Low')),
                          ],
                          onChanged: (v) => setDialogState(() => priority = v ?? 'High'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: businessCtrl,
                    decoration: InputDecoration(
                      labelText: 'Business / Event Title *',
                      prefixIcon: const Icon(Icons.storefront_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: contactCtrl,
                          decoration: InputDecoration(
                            labelText: 'Contact Person *',
                            prefixIcon: const Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number *',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: valueCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Expected Value (₹)',
                            prefixIcon: const Icon(Icons.currency_rupee_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cityCtrl,
                          decoration: InputDecoration(
                            labelText: 'City',
                            prefixIcon: const Icon(Icons.location_city_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: areaCtrl,
                          decoration: InputDecoration(
                            labelText: 'Area / Locality',
                            prefixIcon: const Icon(Icons.place_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: stage,
                          decoration: InputDecoration(labelText: 'Pipeline Stage', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: const [
                            DropdownMenuItem(value: 'New', child: Text('New')),
                            DropdownMenuItem(value: 'Contacted', child: Text('Contacted')),
                            DropdownMenuItem(value: 'Qualified', child: Text('Qualified')),
                            DropdownMenuItem(value: 'Visit Scheduled', child: Text('Visit Scheduled')),
                            DropdownMenuItem(value: 'Negotiation', child: Text('Negotiation')),
                            DropdownMenuItem(value: 'Onboarding', child: Text('Onboarding')),
                            DropdownMenuItem(value: 'Active', child: Text('Active Won')),
                            DropdownMenuItem(value: 'Lost', child: Text('Lost')),
                          ],
                          onChanged: (v) => setDialogState(() => stage = v ?? 'New'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: owner,
                          decoration: InputDecoration(labelText: 'Assigned Lead', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: const [
                            DropdownMenuItem(value: 'Rohan Gupta', child: Text('Rohan Gupta (Growth)')),
                            DropdownMenuItem(value: 'Kavita Nair', child: Text('Kavita Nair (Ops)')),
                            DropdownMenuItem(value: 'Rahul Verma', child: Text('Rahul Verma (Sales)')),
                          ],
                          onChanged: (v) => setDialogState(() => owner = v ?? 'Rohan Gupta'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              onPressed: () {
                if (businessCtrl.text.trim().isEmpty || contactCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required lead fields.')));
                  return;
                }
                setState(() {
                  if (editLead != null) {
                    editLead['business'] = businessCtrl.text.trim();
                    editLead['contact'] = contactCtrl.text.trim();
                    editLead['phone'] = phoneCtrl.text.trim();
                    editLead['email'] = emailCtrl.text.trim();
                    editLead['type'] = type;
                    editLead['priority'] = priority;
                    editLead['stage'] = stage;
                    editLead['city'] = cityCtrl.text.trim();
                    editLead['area'] = areaCtrl.text.trim();
                    editLead['owner'] = owner;
                    editLead['expectedValue'] = int.tryParse(valueCtrl.text.trim()) ?? 500000;
                  } else {
                    _leads.insert(0, {
                      'id': 'LD-${_leads.length + 1028}',
                      'type': type,
                      'business': businessCtrl.text.trim(),
                      'contact': contactCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'city': cityCtrl.text.trim(),
                      'area': areaCtrl.text.trim(),
                      'source': source,
                      'campaign': 'Direct CRM Lead',
                      'owner': owner,
                      'dept': 'Marketing',
                      'priority': priority,
                      'score': 85,
                      'expectedValue': int.tryParse(valueCtrl.text.trim()) ?? 500000,
                      'stage': stage,
                      'nextAction': 'Direct Outreach & Schedule Visit',
                      'nextFollowup': 'Tomorrow, 10:00 AM',
                      'createdDate': 'Today',
                      'activitiesCount': 1,
                    });
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(editLead != null ? '✓ Lead updated successfully!' : '✓ Enterprise Lead created with automated scoring!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              },
              child: Text(editLead != null ? 'Update Lead' : 'Create Lead & Score'),
            ),
          ],
        ),
      ),
    );
  }

  // 2.3 Create / Edit Campaign Dialog
  void _showCreateCampaignDialog({Map<String, dynamic>? editCampaign}) {
    final nameCtrl = TextEditingController(text: editCampaign?['name'] ?? '');
    final budgetCtrl = TextEditingController(text: editCampaign != null ? editCampaign['budget'].toString() : '100000');
    final channelCtrl = TextEditingController(text: editCampaign?['channel'] ?? 'Google Ads & Meta');
    final periodCtrl = TextEditingController(text: editCampaign?['period'] ?? '01 Nov - 31 Dec 2026');
    String obj = editCampaign?['objective'] ?? 'Lead Generation';
    String status = editCampaign?['status'] ?? 'DRAFT';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.campaign_rounded, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                editCampaign != null ? 'Edit Growth Campaign' : 'Create Growth Campaign',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Campaign Name *',
                      prefixIcon: const Icon(Icons.flag_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: obj,
                    decoration: InputDecoration(labelText: 'Primary Objective', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: const [
                      DropdownMenuItem(value: 'Lead Generation', child: Text('🎯 Lead Generation')),
                      DropdownMenuItem(value: 'Partner Acquisition (Banquets)', child: Text('🤝 Partner Acquisition (Banquets)')),
                      DropdownMenuItem(value: 'Customer Acquisition (Weddings)', child: Text('💍 Customer Acquisition (Weddings)')),
                      DropdownMenuItem(value: 'Brand Awareness & Retargeting', child: Text('📢 Brand Awareness & Retargeting')),
                    ],
                    onChanged: (v) => setDialogState(() => obj = v ?? 'Lead Generation'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: budgetCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Campaign Budget (₹) *',
                            prefixIcon: const Icon(Icons.currency_rupee_rounded),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: status,
                          decoration: InputDecoration(labelText: 'Campaign Status', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          items: const [
                            DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                            DropdownMenuItem(value: 'SCHEDULED', child: Text('Scheduled')),
                            DropdownMenuItem(value: 'LIVE', child: Text('Live')),
                            DropdownMenuItem(value: 'PAUSED', child: Text('Paused')),
                            DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                          ],
                          onChanged: (v) => setDialogState(() => status = v ?? 'DRAFT'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: channelCtrl,
                    decoration: InputDecoration(
                      labelText: 'Marketing Channels',
                      prefixIcon: const Icon(Icons.device_hub_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: periodCtrl,
                    decoration: InputDecoration(
                      labelText: 'Campaign Flight / Schedule',
                      prefixIcon: const Icon(Icons.date_range_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
              onPressed: () {
                final b = int.tryParse(budgetCtrl.text.trim()) ?? 0;
                if (nameCtrl.text.trim().isEmpty || b <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill campaign name and budget.')));
                  return;
                }
                setState(() {
                  if (editCampaign != null) {
                    editCampaign['name'] = nameCtrl.text.trim();
                    editCampaign['objective'] = obj;
                    editCampaign['budget'] = b;
                    editCampaign['channel'] = channelCtrl.text.trim();
                    editCampaign['period'] = periodCtrl.text.trim();
                    editCampaign['status'] = status;
                  } else {
                    _campaigns.insert(0, {
                      'id': 'CMP-2026-${_campaigns.length + 4}',
                      'name': nameCtrl.text.trim(),
                      'objective': obj,
                      'channel': channelCtrl.text.trim(),
                      'budget': b,
                      'spend': 0,
                      'leads': 0,
                      'partners': 0,
                      'bookings': 0,
                      'revenue': 0,
                      'roas': '0.0x',
                      'status': status,
                      'owner': 'Rohan Gupta',
                      'period': periodCtrl.text.trim(),
                    });
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Campaign registered with UTM tracking and attribution!'), backgroundColor: AppTheme.success),
                );
              },
              child: Text(editCampaign != null ? 'Save Campaign' : 'Launch Campaign'),
            ),
          ],
        ),
      ),
    );
  }

  // 2.4 Create Opportunity / Deal Dialog
  void _showCreateOpportunityDialog() {
    final titleCtrl = TextEditingController();
    final businessCtrl = TextEditingController(text: 'Grand Heritage Banquet');
    final contactCtrl = TextEditingController(text: 'Rajesh Sharma');
    final valueCtrl = TextEditingController(text: '500000');
    final closeDateCtrl = TextEditingController(text: '25 Oct 2026');
    String stage = 'Qualification';
    double prob = 0.50;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.insights_rounded, color: Color(0xFF8B5CF6)),
              SizedBox(width: 8),
              Text('Create Sales Deal / Opportunity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(labelText: 'Deal Title *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: businessCtrl, decoration: InputDecoration(labelText: 'Business Account *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: contactCtrl, decoration: InputDecoration(labelText: 'Contact Person *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: valueCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Deal Value (₹) *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: closeDateCtrl, decoration: InputDecoration(labelText: 'Target Close Date', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: stage,
                  decoration: InputDecoration(labelText: 'Pipeline Stage', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: const [
                    DropdownMenuItem(value: 'Qualification', child: Text('Qualification (20%)')),
                    DropdownMenuItem(value: 'Proposal Sent', child: Text('Proposal Sent (60%)')),
                    DropdownMenuItem(value: 'Negotiation', child: Text('Negotiation (80%)')),
                    DropdownMenuItem(value: 'Closed Won', child: Text('Closed Won (100%)')),
                    DropdownMenuItem(value: 'Closed Lost', child: Text('Closed Lost (0%)')),
                  ],
                  onChanged: (v) => setDialogState(() => stage = v ?? 'Qualification'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() {
                  _opportunities.insert(0, {
                    'id': 'OPP-${_opportunities.length + 304}',
                    'title': titleCtrl.text.trim(),
                    'business': businessCtrl.text.trim(),
                    'contact': contactCtrl.text.trim(),
                    'stage': stage,
                    'value': int.tryParse(valueCtrl.text.trim()) ?? 300000,
                    'probability': stage == 'Closed Won' ? 1.0 : stage == 'Negotiation' ? 0.8 : 0.5,
                    'expectedClose': closeDateCtrl.text.trim(),
                    'owner': 'Rohan Gupta',
                    'pipeline': 'Enterprise Growth Pipeline',
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Deal created in Sales Pipeline!'), backgroundColor: AppTheme.success));
              },
              child: const Text('Create Opportunity'),
            ),
          ],
        ),
      ),
    );
  }

  // 2.5 Create Quotation Dialog
  void _showCreateQuotationDialog() {
    final clientCtrl = TextEditingController();
    final venueCtrl = TextEditingController(text: 'Grand Heritage Banquet');
    final amountCtrl = TextEditingController(text: '350000');
    final discountCtrl = TextEditingController(text: '15000');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.request_quote_rounded, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('Generate Formal Quotation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: clientCtrl, decoration: InputDecoration(labelText: 'Client / Event Name *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 10),
              TextField(controller: venueCtrl, decoration: InputDecoration(labelText: 'Proposed Venue & Packages *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Gross Amount (₹) *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: discountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Approved Discount (₹)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))))),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
            onPressed: () {
              if (clientCtrl.text.trim().isEmpty) return;
              final gross = int.tryParse(amountCtrl.text.trim()) ?? 300000;
              final disc = int.tryParse(discountCtrl.text.trim()) ?? 0;
              setState(() {
                _quotations.insert(0, {
                  'id': 'QT-${_quotations.length + 903}',
                  'client': clientCtrl.text.trim(),
                  'venue': venueCtrl.text.trim(),
                  'services': ['Banquet Space', 'Custom Decor', 'Turnkey Catering'],
                  'amount': gross,
                  'discount': disc,
                  'netAmount': gross - disc,
                  'status': 'SENT',
                  'validUntil': '30 Oct 2026',
                });
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Formal quotation generated and dispatched via WhatsApp!'), backgroundColor: AppTheme.success));
            },
            child: const Text('Generate Quote'),
          ),
        ],
      ),
    );
  }

  // 2.6 Create Promo Code Dialog
  void _showCreatePromoDialog() {
    final codeCtrl = TextEditingController();
    final discountCtrl = TextEditingController(text: '₹ 1,000 Flat OFF');
    final minCtrl = TextEditingController(text: '10000');
    final expCtrl = TextEditingController(text: '31 Dec 2026');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.local_offer_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Create Enterprise Promo Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Promo Code String *',
                  hintText: 'e.g. DIWALI1000',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountCtrl,
                decoration: InputDecoration(
                  labelText: 'Discount Description *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Minimum Booking Value (₹) *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: expCtrl,
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white),
            onPressed: () {
              if (codeCtrl.text.trim().isEmpty) return;
              setState(() {
                _promoCodes.insert(0, {
                  'code': codeCtrl.text.trim().toUpperCase(),
                  'discount': discountCtrl.text.trim(),
                  'minBooking': int.tryParse(minCtrl.text.trim()) ?? 5000,
                  'maxDiscount': 5000,
                  'usageLimit': '1 per user',
                  'usedCount': 0,
                  'expiry': expCtrl.text.trim(),
                  'status': 'ACTIVE',
                  'category': 'All Bookings',
                });
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Promo code created and active in booking engine!'), backgroundColor: AppTheme.success),
              );
            },
            child: const Text('Create Promo Code'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. MAIN BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text(
              'Marketing & Growth Command Center',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Quick Actions Hub',
            onPressed: _showMarketingQuickActions,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)),
            tooltip: 'Refresh Growth Engine',
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_customize_rounded, size: 18), text: '📊 Dashboard'),
            Tab(icon: Icon(Icons.person_search_rounded, size: 18), text: '👥 CRM & Leads'),
            Tab(icon: Icon(Icons.campaign_rounded, size: 18), text: '🚀 Campaigns'),
            Tab(icon: Icon(Icons.insights_rounded, size: 18), text: '💼 Sales & Deals'),
            Tab(icon: Icon(Icons.handshake_rounded, size: 18), text: '🤝 Partner Growth'),
            Tab(icon: Icon(Icons.groups_rounded, size: 18), text: '📈 Customer Growth'),
            Tab(icon: Icon(Icons.mark_email_read_rounded, size: 18), text: '✍️ Content & Comms'),
            Tab(icon: Icon(Icons.account_tree_rounded, size: 18), text: '⚡ Automation Studio'),
            Tab(icon: Icon(Icons.science_rounded, size: 18), text: '🎯 Strategy & Goals'),
            Tab(icon: Icon(Icons.monetization_on_rounded, size: 18), text: '💰 Attribution'),
            Tab(icon: Icon(Icons.verified_user_rounded, size: 18), text: '🛡️ Approvals & Rules'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showMarketingQuickActions,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('+ Growth Action', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGrowthDashboardTab(),
          _buildCrmHubTab(),
          _buildAcquisitionTab(),
          _buildSalesPipelinesTab(),
          _buildPartnerGrowthTab(),
          _buildCustomerGrowthTab(),
          _buildContentCommsTab(),
          _buildAutomationStudioTab(),
          _buildStrategyExperimentsTab(),
          _buildRevenueAttributionTab(),
          _buildApprovalsRulesTab(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. TAB IMPLEMENTATIONS
  // ===========================================================================

  // 4.1 📊 GROWTH DASHBOARD
  Widget _buildGrowthDashboardTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Real-time Growth Alerts Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 8),
                  Text('REAL-TIME GROWTH & PIPELINE ALERTS', style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
                ],
              ),
              const SizedBox(height: 10),
              _buildAlertItem('🟠 24 high-value leads awaiting immediate follow-up (>48h)', 'Kanpur North & Gomti Nagar clusters'),
              _buildAlertItem('🟠 8 partner banquets onboarded but pending initial activation booking', 'Grand Hyatt & Kuhu Banquets'),
              _buildAlertItem('🟡 Customer Acquisition Cost (CAC) down 14% to ₹1,479 via Instagram Reels Ads', 'Optimal ROAS efficiency'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4 Growth Pillar Cards
        const Text('GROWTH PILLARS (30-DAY VELOCITY)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildMetricCard('New Leads', '1,248', '684 Qualified (54.8%)', Icons.person_search_rounded, const Color(0xFF2563EB))),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('New Partners', '126', '78.2% Active Rate', Icons.handshake_rounded, const Color(0xFF10B981))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildMetricCard('Attributed Revenue', '₹ 24.8 L', 'Spend ₹4.2L • ROAS 5.9x', Icons.monetization_on_rounded, const Color(0xFF7C3AED))),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Partner Retention', '91.0%', 'Repeat Bookings: 38%', Icons.replay_circle_filled_rounded, const Color(0xFFF59E0B))),
          ],
        ),
        const SizedBox(height: 20),

        // End-to-End Funnel Visualizer
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('END-TO-END CONVERSION FUNNEL', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                  Text('Acquire → Onboard → Revenue', style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              _buildFunnelRow('Leads Generated', '10,000', '100%', 1.0, const Color(0xFF2563EB)),
              _buildFunnelRow('Qualified Leads', '6,800', '68.0%', 0.68, const Color(0xFF38BDF8)),
              _buildFunnelRow('Field Visits Completed', '3,672', '54.0%', 0.54, const Color(0xFF10B981)),
              _buildFunnelRow('Onboarded Partners', '1,175', '32.0%', 0.32, const Color(0xFFF59E0B)),
              _buildFunnelRow('Active Bookings Generated', '2,420', '78.0%', 0.24, const Color(0xFF7C3AED)),
              _buildFunnelRow('Net Attributed Revenue', '₹ 2.8 Cr', 'Direct Bookings', 0.20, const Color(0xFF059669)),
            ],
          ),
        ),
      ],
    );
  }

  // 4.2 👥 CRM & LEADS
  Widget _buildCrmHubTab() {
    final filtered = _leads.where((l) {
      if (_leadStageFilter != 'ALL' && l['stage'] != _leadStageFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return l['business'].toString().toLowerCase().contains(q) ||
            l['contact'].toString().toLowerCase().contains(q) ||
            l['city'].toString().toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Top Action Bar
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Search leads by business, contact, or area...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showCreateLeadDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('+ Add Lead'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Stage Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ALL', 'New', 'Contacted', 'Qualified', 'Visit Scheduled', 'Negotiation', 'Active'].map((st) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(st, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _leadStageFilter == st ? Colors.white : const Color(0xFF334155))),
                selected: _leadStageFilter == st,
                selectedColor: const Color(0xFF2563EB),
                backgroundColor: Colors.white,
                onSelected: (v) => setState(() => _leadStageFilter = st),
              ),
            )).toList(),
          ),
        ),
        const SizedBox(height: 16),

        const Text('ENTERPRISE LEADS PIPELINE & SCORING', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),

        ...filtered.map((lead) {
          final score = (lead['score'] as int);
          final scoreColor = score >= 80 ? const Color(0xFF10B981) : score >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(lead['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF2563EB))),
                          ),
                          const SizedBox(width: 8),
                          Text('${lead['type']} • ${lead['city']} (${lead['area']})', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: scoreColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          '🔥 Score: $score/100',
                          style: TextStyle(color: scoreColor, fontWeight: FontWeight.w900, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(lead['business'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text('Contact: ${lead['contact']} (${lead['phone']}) • Owner: ${lead['owner']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Stage: ${lead['stage']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF2563EB))),
                      Text('Expected: ₹ ${(lead['expectedValue'] as int).toString()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                      Text('Follow-up: ${lead['nextFollowup']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                            onPressed: () => _showCreateLeadDialog(editLead: lead),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                            onPressed: () {
                              setState(() => _leads.remove(lead));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lead archived')));
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              side: const BorderSide(color: Color(0xFF2563EB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitManagementScreen()));
                            },
                            icon: const Icon(Icons.place_rounded, size: 14),
                            label: const Text('Schedule Visit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerOnboardingScreen()));
                            },
                            icon: const Icon(Icons.handshake_rounded, size: 14),
                            label: const Text('Convert to Partner', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // 4.3 🚀 CAMPAIGNS & ACQUISITION
  Widget _buildAcquisitionTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Promo Codes Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PROMO CODES & REFERRAL VOUCHERS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
                  TextButton.icon(
                    onPressed: _showCreatePromoDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Promo Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: _promoCodes.map((p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.confirmation_number_outlined, color: Color(0xFFD97706), size: 16),
                      const SizedBox(width: 6),
                      Text(p['code'], style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF92400E), fontSize: 12.5)),
                      const SizedBox(width: 6),
                      Text('(${p['discount']})', style: const TextStyle(color: Color(0xFF78350F), fontSize: 11)),
                    ],
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ACTIVE MULTI-CHANNEL CAMPAIGNS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
              onPressed: _showCreateCampaignDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ New Campaign'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ..._campaigns.map((cmp) {
          final isLive = cmp['status'] == 'LIVE';

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(cmp['id'], style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isLive ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFF59E0B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cmp['status'],
                          style: TextStyle(color: isLive ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontSize: 10.5, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(cmp['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                  Text('Channels: ${cmp['channel']} • Flight: ${cmp['period']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniCol('Budget', '₹ ${(cmp['budget'] as int).toString()}'),
                      _buildMiniCol('Spend', '₹ ${(cmp['spend'] as int).toString()}'),
                      _buildMiniCol('Leads', '${cmp['leads']}'),
                      _buildMiniCol('Revenue', '₹ ${(cmp['revenue'] as int).toString()}'),
                      _buildMiniCol('ROAS', cmp['roas'], isHighlight: true),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _showCreateCampaignDialog(editCampaign: cmp)),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attribution report for "${cmp['name']}" generated.')));
                        },
                        child: const Text('View ROAS Analytics', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // 4.4 💼 SALES & PIPELINES
  Widget _buildSalesPipelinesTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ACTIVE SALES PIPELINES & DEALS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
              onPressed: _showCreateOpportunityDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ New Deal'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ..._opportunities.map((opp) {
          final prob = (opp['probability'] as double);

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(opp['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(opp['stage'], style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(opp['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                  Text('Business: ${opp['business']} • Lead Owner: ${opp['owner']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Deal Value: ₹ ${(opp['value'] as int).toString()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                      Text('Close Probability: ${(prob * 100).toInt()}%', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Est Close: ${opp['expectedClose']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() => opp['stage'] = 'Closed Lost');
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deal marked Closed Lost')));
                        },
                        child: const Text('Mark Lost', style: TextStyle(color: Colors.red, fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                        onPressed: () {
                          setState(() => opp['stage'] = 'Closed Won');
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Deal Closed Won! Generating contract...'), backgroundColor: AppTheme.success));
                        },
                        child: const Text('Close Won 🎉', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('GENERATED PROPOSALS & QUOTATIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
            TextButton.icon(
              onPressed: _showCreateQuotationDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('+ New Quote'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._quotations.map((qt) => Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
          color: Colors.white,
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFFEF3C7), child: Icon(Icons.request_quote_rounded, color: Color(0xFFD97706))),
            title: Text('${qt['id']} - ${qt['client']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            subtitle: Text('Venue: ${qt['venue']} • Net: ₹ ${qt['netAmount']} (Discount: ₹ ${qt['discount']})'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
              child: Text(qt['status'], style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ),
        )),
      ],
    );
  }

  // 4.5 🤝 PARTNER GROWTH
  Widget _buildPartnerGrowthTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('PARTNER 360° & EXPANSION OPPORTUNITIES', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),

        ..._partners.map((p) {
          final isHealthy = p['status'] == 'HEALTHY';
          final Color healthColor = isHealthy ? const Color(0xFF10B981) : const Color(0xFFEF4444);

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p['code'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: healthColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '${p['healthScore']}/100 • ${p['status']}',
                          style: TextStyle(color: healthColor, fontWeight: FontWeight.w900, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                  Text('${p['category']} • ${p['city']} • Monthly Revenue: ${p['revenueMonthly']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI Growth Opportunity: ${p['expansionOpportunity']}',
                            style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Growth meeting scheduled with ${p['name']}')));
                        },
                        child: const Text('Schedule Expansion Meeting', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // 4.6 📈 CUSTOMER GROWTH
  Widget _buildCustomerGrowthTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DYNAMIC CUSTOMER SEGMENTS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              ..._customerSegments.map((seg) => _buildSegmentItem(seg['name'], seg['rule'], '${seg['count']} Users')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('CUSTOMER REVIEWS & POST-EVENT FEEDBACK', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        ..._reviews.map((rev) => Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${rev['customer']} • ${rev['date']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                    const Text('⭐⭐⭐⭐⭐', style: TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Event: ${rev['event']} (${rev['venue']})', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                Text('"${rev['comment']}"', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        )),
      ],
    );
  }

  // 4.7 ✍️ CONTENT & COMMS
  Widget _buildContentCommsTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('OMNICHANNEL TEMPLATES & ASSETS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        ..._templates.map((tmp) => _buildTemplateCard(tmp['name'], tmp['content'], tmp['channel'])),
      ],
    );
  }

  // 4.8 ⚡ AUTOMATION STUDIO
  Widget _buildAutomationStudioTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('ACTIVE MARKETING & CRM AUTOMATIONS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),

        ..._workflows.map((wf) => Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(wf['name'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(wf['status'], style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Trigger: ${wf['trigger']}', style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                Text('Actions: ${wf['actions']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 8),
                Text('Executed ${wf['runsThisMonth']} times this month', style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
        )),
      ],
    );
  }

  // 4.9 🎯 STRATEGY & GOALS
  Widget _buildStrategyExperimentsTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('GROWTH GOALS & TARGETS (KPI RADAR)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        ..._goals.map((g) {
          final double pct = (g['current'] as num) / (g['target'] as num);

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(g['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                      Text('${g['current']} / ${g['target']} ${g['unit']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF2563EB))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
        const Text('A/B TESTS & GROWTH EXPERIMENTS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),

        ..._experiments.map((exp) => Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(exp['id'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(exp['currentLift'], style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(exp['hypothesis'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Text('Variant A: ${exp['variantA']}\nVariant B: ${exp['variantB']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const Divider(height: 18),
                Text('Result: ${exp['decision']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF059669))),
              ],
            ),
          ),
        )),

        const SizedBox(height: 16),
        const Text('COMPETITOR INTELLIGENCE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),
        ..._competitors.map((comp) => Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(comp['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A))),
                    Text('Market Share: ${comp['marketShare']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB))),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Pricing: ${comp['pricing']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                Text('PartyBala Advantage: ${comp['partyBalaAdvantage']}', style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        )),
      ],
    );
  }

  // 4.10 💰 REVENUE ATTRIBUTION
  Widget _buildRevenueAttributionTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MULTI-TOUCH REVENUE ATTRIBUTION GRAPH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 6),
              const Text(
                'Campaign → Channel → Lead → Opportunity → Partner → Booking → Revenue',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, letterSpacing: 0.5),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildAttributionStat('Total Spend', '₹ 4.2 L', const Color(0xFF38BDF8)),
                  _buildAttributionStat('Attributed GMV', '₹ 24.8 L', const Color(0xFF34D399)),
                  _buildAttributionStat('Blended ROAS', '5.9x', const Color(0xFFFBBF24)),
                  _buildAttributionStat('Blended CAC', '₹ 1,479', const Color(0xFFA78BFA)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4.11 🛡️ APPROVALS & RULES
  Widget _buildApprovalsRulesTab() {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('PENDING MARKETING APPROVALS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),

        ..._approvals.map((app) {
          final isPending = app['status'] == 'PENDING';

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(app['type'], style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPending ? const Color(0xFFF59E0B).withOpacity(0.12) : const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          app['status'],
                          style: TextStyle(color: isPending ? const Color(0xFFF59E0B) : const Color(0xFF10B981), fontWeight: FontWeight.w800, fontSize: 10.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(app['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                  Text('Requested by: ${app['requestedBy']} • Date: ${app['date']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isPending) ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () {
                            setState(() => app['status'] = 'REJECTED');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected')));
                          },
                          child: const Text('Reject', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                          onPressed: () {
                            setState(() => app['status'] = 'APPROVED');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Approved and enacted!'), backgroundColor: AppTheme.success));
                          },
                          child: const Text('Approve & Enact', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ] else ...[
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                            SizedBox(width: 4),
                            Text('Approved & Enacted', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 18),
        const Text('LEAD SCORING ENGINE RULES', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),

        ..._scoringRules.map((rule) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rule['criterion'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
                    Text('Category: ${rule['category']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: Text('+${rule['points']} pts', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ],
          ),
        )),
      ],
    );
  }

  // ===========================================================================
  // 5. HELPER WIDGETS
  // ===========================================================================

  Widget _buildAlertItem(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF78350F))),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF92400E))),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String val, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(val, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFunnelRow(String label, String count, String pct, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A))),
              Text('$count ($pct)', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCol(String label, String val, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: isHighlight ? const Color(0xFF10B981) : const Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildSegmentItem(String name, String criteria, String count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                Text(criteria, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Text(count, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2563EB), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(String title, String body, String channel) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
      color: Colors.white,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('Channel: $channel\n$body', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        isThreeLine: true,
        trailing: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF2563EB)),
      ),
    );
  }

  Widget _buildAttributionStat(String label, String val, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
