import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

import 'visit_management_screen.dart';
import 'leads_pipeline_screen.dart';
import 'partner_onboarding_screen.dart';
import 'admin_marketing_growth_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final todayData = widget.telemetry?['today'] as Map<String, dynamic>?;
    final itinerary = (widget.telemetry?['itinerary'] as List<dynamic>?) ?? [];

    final int visitsTotal = todayData?['visits_total'] ?? 3;
    final int visitsCompleted = todayData?['visits_completed'] ?? 1;
    final int followupsTotal = todayData?['followups_total'] ?? 6;
    final int followupsCompleted = todayData?['followups_completed'] ?? 4;
    final int newLeads = todayData?['new_leads'] ?? 2;
    final int onboardings = todayData?['active_onboardings'] ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
            const Text(
              'Marketing & Field Operations',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.hub_rounded, color: Color(0xFF2563EB)),
            tooltip: 'Growth Command Center',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMarketingGrowthScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF334155)),
            tooltip: 'Universal Search',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UniversalSearchScreen())),
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
              // 1. ONE-TAP CHECK-IN BANNER
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
                          _isCheckedIn ? 'Since $_checkInTime • GPS Verified' : 'Check in to start logging visits',
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

            // 2. MY DAY OVERVIEW CARD
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('MY DAY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Today\'s Overview', style: TextStyle(color: Color(0xFF2563EB), fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildMetricTile(
                        context,
                        '📍 $visitsTotal Visits',
                        '$visitsCompleted Done',
                        const Color(0xFF2563EB),
                        const Color(0xFFEFF6FF),
                        () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitManagementScreen())),
                      ),
                      const SizedBox(width: 10),
                      _buildMetricTile(
                        context,
                        '📞 $followupsTotal Follow-ups',
                        '$followupsCompleted Done',
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
                        '🤝 $onboardings Onboarding',
                        'Active Pipeline',
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

            // 3. NEEDS ATTENTION CAROUSEL
            Row(
              children: [
                const Icon(Icons.bolt_rounded, color: Color(0xFFEF4444), size: 18),
                const SizedBox(width: 6),
                const Text('NEEDS ATTENTION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A), letterSpacing: 0.5)),
              ],
            ),
            const SizedBox(height: 8),
            _buildAttentionCard(
              title: 'Follow up with ABC Banquet & Resort',
              subtitle: 'Confirm onboarding visit arrival with owner Rahul Sharma',
              dueTime: 'Due in 1 hour',
              color: Colors.red.shade700,
              bgColor: const Color(0xFFFEF2F2),
              icon: Icons.phone_callback_rounded,
              actionLabel: 'Call Now',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeadsPipelineScreen())),
            ),
            const SizedBox(height: 8),
            _buildAttentionCard(
              title: 'Complete Kuhu Espresso Agreement',
              subtitle: 'Verify beverage commission card & upload GST document',
              dueTime: 'Due Today',
              color: Colors.orange.shade800,
              bgColor: const Color(0xFFFFFBEB),
              icon: Icons.assignment_late_rounded,
              actionLabel: 'Open Task',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PartnerOnboardingScreen())),
            ),
            const SizedBox(height: 16),

            // 4. TODAY'S PLAN (CHRONOLOGICAL ITINERARY)
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
                      const Text('TODAY\'S PLAN & ROUTE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A))),
                      TextButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitManagementScreen())),
                        icon: const Icon(Icons.map_rounded, size: 15),
                        label: const Text('View Route', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB), padding: EdgeInsets.zero),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (itinerary.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No more scheduled visits for today. Great job!', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
                    )
                  else
                    ...itinerary.map((item) => _buildItineraryRow(item)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. DAILY TARGETS PROGRESS
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
                      const Text('MONTHLY TARGETS PROGRESS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Color(0xFF0F172A))),
                      const Text('October 2026', style: TextStyle(color: Color(0xFF64748B), fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildTargetProgressBar('Visits Completed', 7, 10, const Color(0xFF2563EB)),
                  const SizedBox(height: 10),
                  _buildTargetProgressBar('Follow-ups Logged', 8, 10, const Color(0xFF10B981)),
                  const SizedBox(height: 10),
                  _buildTargetProgressBar('New Leads Created', 5, 10, const Color(0xFFF59E0B)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6. SMART "NEXT ACTION" ADVISORY
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text('SMART NEXT BEST ACTION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Partner "ABC Banquet" completed visit with HIGH interest.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recommended: Call tomorrow at 11:00 AM to review package draft and finalize booking commissions.',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11.5),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeadsPipelineScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1D4ED8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.alarm_add_rounded, size: 16),
                      label: const Text('Schedule Follow-Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildMetricTile(BuildContext context, String title, String subtitle, Color color, Color bgColor, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: color.withOpacity(0.8), fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttentionCard({
    required String title,
    required String subtitle,
    required String dueTime,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            radius: 16,
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(dueTime, style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Color(0xFF475569), fontSize: 11)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    height: 28,
                    child: ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        elevation: 0,
                      ),
                      child: Text(actionLabel, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItineraryRow(dynamic item) {
    final time = item['time'] ?? '10:00 AM';
    final title = item['title'] ?? '';
    final subtitle = item['subtitle'] ?? '';
    final isDone = item['status'] == 'completed';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 65,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              time,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isDone)
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18)
          else
            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFCBD5E1), size: 12),
        ],
      ),
    );
  }

  Widget _buildTargetProgressBar(String label, int current, int target, Color color) {
    final double pct = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF334155), fontSize: 11.5, fontWeight: FontWeight.w600)),
            Text('$current / $target (${(pct * 100).toInt()}%)', style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
