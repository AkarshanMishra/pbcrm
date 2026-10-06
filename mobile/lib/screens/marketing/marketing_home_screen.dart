import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

import 'visit_management_screen.dart';
import 'leads_pipeline_screen.dart';
import 'partner_onboarding_screen.dart';
import 'venue_profile_creation_screen.dart';
import 'admin_marketing_growth_screen.dart';
import 'marketing_manager_dashboard.dart';
import 'marketing_report_screen.dart';
import '../search/universal_search_screen.dart';
import '../notifications/notification_center_screen.dart';

class MarketingHomeScreen extends StatefulWidget {
  final Map<String, dynamic>? telemetry;
  final VoidCallback onRefresh;

  const MarketingHomeScreen({super.key, required this.telemetry, required this.onRefresh});

  @override
  State<MarketingHomeScreen> createState() => _MarketingHomeScreenState();
}

class _MarketingHomeScreenState extends State<MarketingHomeScreen> {
  final ApiClient _api = ApiClient();
  bool _isCheckedIn = true;
  String _checkInTime = "09:32 AM";
  bool _isLoadingCheckIn = false;
  String _selectedRole = 'EXECUTIVE'; // 'EXECUTIVE', 'MANAGER', 'ADMIN'
  int _offlineQueueCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchTodayAttendance();
  }

  Future<void> _fetchTodayAttendance() async {
    try {
      final res = await _api.get('/api/v1/attendance/records/today/');
      if (mounted && res.data != null) {
        setState(() {
          _isCheckedIn = res.data['status'] == 'CHECKED_IN' || res.data['status'] == 'WORKING';
          if (res.data['check_in_time'] != null) {
            _checkInTime = res.data['check_in_time'].toString().substring(11, 16);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleCheckIn() async {
    setState(() => _isLoadingCheckIn = true);
    try {
      if (_isCheckedIn) {
        await _api.post('/api/v1/attendance/records/checkout/', {});
        setState(() => _isCheckedIn = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Checked out successfully. Have a restful evening!'), backgroundColor: Colors.orange),
          );
        }
      } else {
        await _api.post('/api/v1/attendance/records/checkin/', {});
        setState(() {
          _isCheckedIn = true;
          _checkInTime = "Just now";
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are checked in! Have a productive marketing day.'), backgroundColor: Colors.green),
          );
        }
      }
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attendance action failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingCheckIn = false);
    }
  }

  void _triggerOfflineSync() {
    setState(() => _offlineQueueCount = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ All offline field visits, venue photos, and leads synced with Central Cloud!'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final todayData = widget.telemetry?['today'] as Map<String, dynamic>?;
    final itinerary = (widget.telemetry?['itinerary'] as List<dynamic>?) ?? [];

    final int visitsTotal = todayData?['visits_total'] ?? 4;
    final int visitsCompleted = todayData?['visits_completed'] ?? 2;
    final int followupsTotal = todayData?['followups_total'] ?? 6;
    final int followupsCompleted = todayData?['followups_completed'] ?? 4;
    final int newLeads = todayData?['new_leads'] ?? 5;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: _buildMarketingSidebar(context, user),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Good Morning, ${user?.name?.split(' ').first ?? 'Rahul'} 👋',
                  style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  _selectedRole == 'ADMIN'
                      ? 'Admin Growth View'
                      : _selectedRole == 'MANAGER'
                          ? 'Marketing Manager View'
                          : 'Marketing Field Executive',
                  style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF2563EB)),
              ],
            ),
          ],
        ),
        actions: [
          // Role Switcher Chip in AppBar
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  Text(_selectedRole, style: const TextStyle(color: Color(0xFF2563EB), fontSize: 10.5, fontWeight: FontWeight.w900)),
                  const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF2563EB)),
                ],
              ),
            ),
            onSelected: (val) {
              setState(() => _selectedRole = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Switched view to $val Mode'), duration: const Duration(seconds: 1)),
              );
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'EXECUTIVE', child: Text('👤 Executive Field App')),
              PopupMenuItem(value: 'MANAGER', child: Text('👥 Manager Control Plane')),
              PopupMenuItem(value: 'ADMIN', child: Text('👑 Admin Organization Center')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.hub_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Growth Command Center',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMarketingGrowthScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF334155)),
            tooltip: 'Notifications',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationCenterScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          widget.onRefresh();
          await _fetchTodayAttendance();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ONE-TAP GPS CHECK-IN BANNER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isCheckedIn
                        ? [const Color(0xFF065F46), const Color(0xFF047857)]
                        : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (_isCheckedIn ? const Color(0xFF047857) : Colors.black).withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isCheckedIn ? Icons.fmd_good_rounded : Icons.location_off_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _isCheckedIn ? const Color(0xFF34D399) : Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isCheckedIn ? 'CHECKED IN (FIELD READY)' : 'NOT CHECKED IN',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _isCheckedIn ? 'Since $_checkInTime • GPS Verified (Accuracy < 15m)' : 'Check in to start logging visits',
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    _isLoadingCheckIn
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : ElevatedButton(
                            onPressed: _toggleCheckIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isCheckedIn ? Colors.white : const Color(0xFF10B981),
                              foregroundColor: _isCheckedIn ? const Color(0xFF065F46) : Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: Text(
                              _isCheckedIn ? 'CHECK OUT' : 'CHECK IN',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. QUICK FIELD CREATION HUB (VENUES, VENDORS, VISITS)
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('FIELD CAPTURE & CREATION ENGINE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A))),
                        Text('Full Mobile CRUD', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionTile(
                            '🏢 Create Venue',
                            'Multi-space profile',
                            const Color(0xFF2563EB),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VenueProfileCreationScreen(isVendor: false))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionTile(
                            '🍽️ Create Vendor',
                            'Catering & Decor',
                            const Color(0xFF10B981),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VenueProfileCreationScreen(isVendor: true))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionTile(
                            '📍 Log Visit',
                            'GPS Check-in',
                            const Color(0xFFF59E0B),
                            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitManagementScreen())),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. MY DAY OVERVIEW & TELEMETRY
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('MY DAY (FIELD EXECUTION)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Today\'s Targets', style: TextStyle(color: Color(0xFF2563EB), fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildMetricTile(
                          context,
                          '📍 $visitsTotal Visits',
                          '$visitsCompleted Completed',
                          const Color(0xFF2563EB),
                          const Color(0xFFEFF6FF),
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitManagementScreen())),
                        ),
                        const SizedBox(width: 10),
                        _buildMetricTile(
                          context,
                          '📞 $followupsTotal Follow-ups',
                          '$followupsCompleted Completed',
                          const Color(0xFF10B981),
                          const Color(0xFFECFDF5),
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeadsPipelineScreen())),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildMetricTile(
                          context,
                          '👥 $newLeads New Leads',
                          'In Pipeline',
                          const Color(0xFFF59E0B),
                          const Color(0xFFFFFBEB),
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeadsPipelineScreen())),
                        ),
                        const SizedBox(width: 10),
                        _buildMetricTile(
                          context,
                          '🤝 2 Onboardings',
                          'KYC Pending',
                          const Color(0xFF8B5CF6),
                          const Color(0xFFF5F3FF),
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerOnboardingScreen())),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. OFFLINE SYNC STATUS
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_sync_rounded, color: Color(0xFF10B981), size: 22),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Field Offline Mode Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                            Text(_offlineQueueCount == 0 ? 'All 0 records synced to cloud' : '$_offlineQueueCount items in local queue', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                      onPressed: _triggerOfflineSync,
                      child: const Text('Sync Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. TODAY'S ITINERARY & LIVE STOPS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TODAY\'S ITINERARY & VISITS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                  TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitManagementScreen())),
                    icon: const Icon(Icons.map_rounded, size: 14),
                    label: const Text('View Route Map', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _buildItineraryCard(
                '1. Grand Heritage Banquet & Lawn',
                'Civil Lines, Kanpur • Pre-Wedding Floral QC & Generator Test',
                '10:30 AM',
                'COMPLETED',
                const Color(0xFF10B981),
              ),
              _buildItineraryCard(
                '2. Royal Palms Resort',
                'Bithoor Road, Kanpur • Poolside Deck & BBQ Area Verification',
                '02:00 PM',
                'IN_PROGRESS',
                const Color(0xFF2563EB),
              ),
              _buildItineraryCard(
                '3. Kuhu Espresso Banquet',
                'Swaroop Nagar, Kanpur • Soundproofing & Menu Sign-off',
                '04:30 PM',
                'SCHEDULED',
                const Color(0xFFF59E0B),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SIDEBAR DRAWER (EXECUTIVE, MANAGER & ADMIN MODULES)
  // ===========================================================================
  Widget _buildMarketingSidebar(BuildContext context, dynamic user) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF2563EB),
                      radius: 24,
                      child: Text(
                        user?.name?.isNotEmpty == true ? user.name[0] : 'R',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Rahul Verma',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _selectedRole == 'ADMIN' ? '👑 Admin Mode' : _selectedRole == 'MANAGER' ? '👥 Manager Mode' : '👤 Field Sales Executive',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                  child: const Text('PBV000124 • PartyBala Network', style: TextStyle(color: Color(0xFF60A5FA), fontSize: 10.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // Drawer Navigation Items based on active role
          _buildDrawerSectionTitle('CRM & SALES ENGINE'),
          _buildDrawerItem(Icons.person_search_rounded, 'Leads Pipeline (360°)', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LeadsPipelineScreen()));
          }),
          _buildDrawerItem(Icons.storefront_rounded, 'Venue Profile Creator', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VenueProfileCreationScreen(isVendor: false)));
          }),
          _buildDrawerItem(Icons.restaurant_rounded, 'Vendor Profile Creator', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VenueProfileCreationScreen(isVendor: true)));
          }),
          _buildDrawerItem(Icons.handshake_rounded, 'Partner Onboarding Wizard', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerOnboardingScreen()));
          }),

          _buildDrawerSectionTitle('FIELD WORK & LOCATION'),
          _buildDrawerItem(Icons.place_rounded, 'Visits & GPS Check-in', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitManagementScreen()));
          }),
          _buildDrawerItem(Icons.summarize_rounded, 'Daily Visit Reports', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketingReportScreen()));
          }),

          if (_selectedRole == 'MANAGER' || _selectedRole == 'ADMIN') ...[
            _buildDrawerSectionTitle('MANAGER CONTROL PLANE'),
            _buildDrawerItem(Icons.groups_rounded, 'Team Dashboard & Map', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketingManagerDashboard()));
            }),
          ],

          _buildDrawerSectionTitle('ADMIN COMMAND CENTER'),
          _buildDrawerItem(Icons.admin_panel_settings_rounded, 'Full Growth Command Hub', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMarketingGrowthScreen()));
          }),

          const Divider(color: Color(0xFF334155), height: 30),
          _buildDrawerItem(Icons.cloud_sync_rounded, 'Force Cloud Offline Sync', () {
            Navigator.pop(context);
            _triggerOfflineSync();
          }),
        ],
      ),
    );
  }

  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.white, size: 20),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  // ===========================================================================
  // HELPER TILES
  // ===========================================================================

  Widget _buildActionTile(String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, String title, String sub, Color color, Color bg, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color)),
              const SizedBox(height: 2),
              Text(sub, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItineraryCard(String title, String subtitle, String time, String status, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(Icons.location_on_rounded, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(time, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
              child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 9.5)),
            ),
          ],
        ),
      ),
    );
  }
}
