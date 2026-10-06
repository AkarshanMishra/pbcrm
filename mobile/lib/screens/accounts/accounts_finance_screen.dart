import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AccountsFinanceScreen extends StatefulWidget {
  const AccountsFinanceScreen({super.key});

  @override
  State<AccountsFinanceScreen> createState() => _AccountsFinanceScreenState();
}

class _AccountsFinanceScreenState extends State<AccountsFinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _invoiceFilter = 'ALL';
  String _expenseFilter = 'ALL';

  final List<Map<String, dynamic>> _invoices = [
    {
      'id': 'INV-2026-089',
      'client': 'Sharma Wedding Grand Reception',
      'partner': 'Grand Heritage Banquet',
      'amount': 185000,
      'tax': 33300,
      'commission': 22200,
      'status': 'POSTED',
      'date': '04 Oct 2026',
      'due': '15 Oct 2026',
      'paymentMode': 'NEFT / RTGS',
    },
    {
      'id': 'INV-2026-090',
      'client': 'TechCorp Annual Corporate Summit',
      'partner': 'Royal Palms Resort',
      'amount': 340000,
      'tax': 61200,
      'commission': 40800,
      'status': 'SUBMITTED',
      'date': '05 Oct 2026',
      'due': '20 Oct 2026',
      'paymentMode': 'Corporate Cheque',
    },
    {
      'id': 'INV-2026-091',
      'client': 'Verma 25th Silver Jubilee Party',
      'partner': 'Kuhu Espresso Banquet',
      'amount': 75000,
      'tax': 13500,
      'commission': 9000,
      'status': 'DRAFT',
      'date': '05 Oct 2026',
      'due': '10 Oct 2026',
      'paymentMode': 'UPI Instant',
    },
    {
      'id': 'INV-2026-092',
      'client': 'Gupta Engagement Ceremony',
      'partner': 'The Grand Palace',
      'amount': 120000,
      'tax': 21600,
      'commission': 14400,
      'status': 'PAID',
      'date': '01 Oct 2026',
      'due': '05 Oct 2026',
      'paymentMode': 'UPI / NetBanking',
    },
  ];

  final List<Map<String, dynamic>> _payments = [
    {
      'id': 'PAY-8821',
      'bookingId': 'PB-10482',
      'client': 'Sharma Wedding Grand Reception',
      'amount': 185000,
      'mode': 'NEFT / Bank Transfer',
      'txnId': 'TXN9928187219',
      'status': 'VERIFIED',
      'date': '04 Oct 2026, 04:30 PM',
      'verifiedBy': 'Deepak Verma (Accounts Lead)',
    },
    {
      'id': 'PAY-8822',
      'bookingId': 'PB-10479',
      'client': 'Gupta Engagement Ceremony',
      'amount': 120000,
      'mode': 'UPI Instant',
      'txnId': 'UPI202610018821',
      'status': 'VERIFIED',
      'date': '01 Oct 2026, 01:15 PM',
      'verifiedBy': 'Deepak Verma (Accounts Lead)',
    },
    {
      'id': 'PAY-8823',
      'bookingId': 'PB-10495',
      'client': 'TechCorp Annual Corporate Summit',
      'amount': 150000,
      'mode': 'Advance Cheque',
      'txnId': 'CHQ-882103',
      'status': 'UNDER_CLEARING',
      'date': '05 Oct 2026, 11:00 AM',
      'verifiedBy': 'Pending Bank Clearance',
    },
  ];

  final List<Map<String, dynamic>> _expenses = [
    {
      'id': 'EXP-104',
      'employee': 'Kavita Nair',
      'dept': 'Operations',
      'title': 'Venue Inspection Fuel & Toll (Lucknow Highway)',
      'amount': 4250,
      'status': 'PENDING_APPROVAL',
      'date': '02 Oct 2026',
      'receiptAttached': true,
    },
    {
      'id': 'EXP-105',
      'employee': 'Akarshan Mishra',
      'dept': 'IT & Infra',
      'title': 'Cloud Staging CDN & Server Cluster Renewal',
      'amount': 12800,
      'status': 'APPROVED',
      'date': '03 Oct 2026',
      'receiptAttached': true,
    },
    {
      'id': 'EXP-106',
      'employee': 'Rahul Verma',
      'dept': 'Marketing',
      'title': 'Partner Banquet Onboarding Collateral Print',
      'amount': 3100,
      'status': 'REIMBURSED',
      'date': '04 Oct 2026',
      'receiptAttached': true,
    },
    {
      'id': 'EXP-107',
      'employee': 'Pooja Singh',
      'dept': 'HR',
      'title': 'Campus Recruitment Drive Materials & Logistics',
      'amount': 5600,
      'status': 'PENDING_APPROVAL',
      'date': '05 Oct 2026',
      'receiptAttached': true,
    },
  ];

  final List<Map<String, dynamic>> _settlements = [
    {
      'id': 'SET-2026-Q4-01',
      'partner': 'Grand Heritage Banquet',
      'period': 'Cycle 01 (01-05 Oct 2026)',
      'grossGMV': 850000,
      'commissionRate': '12.0%',
      'commissionAmount': 102000,
      'tds': 1020,
      'netPayout': 748980,
      'status': 'READY_FOR_PAYOUT',
      'bank': 'HDFC Bank (A/C ...8842)',
    },
    {
      'id': 'SET-2026-Q4-02',
      'partner': 'Royal Palms Resort',
      'period': 'Cycle 01 (01-05 Oct 2026)',
      'grossGMV': 620000,
      'commissionRate': '12.0%',
      'commissionAmount': 74400,
      'tds': 744,
      'netPayout': 546344,
      'status': 'SETTLED',
      'bank': 'ICICI Bank (A/C ...3190)',
    },
    {
      'id': 'SET-2026-Q4-03',
      'partner': 'Kuhu Espresso Banquet',
      'period': 'Cycle 01 (01-05 Oct 2026)',
      'grossGMV': 180000,
      'commissionRate': '12.0%',
      'commissionAmount': 21600,
      'tds': 216,
      'netPayout': 158616,
      'status': 'PROCESSING',
      'bank': 'Axis Bank (A/C ...9012)',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- CRUD MODALS ---

  void _showCreateInvoiceDialog({Map<String, dynamic>? editInvoice}) {
    final clientCtrl = TextEditingController(text: editInvoice?['client'] ?? '');
    final partnerCtrl = TextEditingController(text: editInvoice?['partner'] ?? 'Grand Heritage Banquet');
    final amountCtrl = TextEditingController(text: editInvoice != null ? editInvoice['amount'].toString() : '');
    final dueCtrl = TextEditingController(text: editInvoice?['due'] ?? '15 Oct 2026');
    String status = editInvoice?['status'] ?? 'SUBMITTED';
    String mode = editInvoice?['paymentMode'] ?? 'UPI Instant';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF7C3AED), size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                editInvoice != null ? 'Edit Enterprise Invoice' : 'Create Enterprise Invoice',
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
                    controller: clientCtrl,
                    decoration: InputDecoration(
                      labelText: 'Client / Booking Name *',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: partnerCtrl,
                    decoration: InputDecoration(
                      labelText: 'Partner Banquet / Venue *',
                      prefixIcon: const Icon(Icons.business_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Base Invoice Amount (₹) *',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dueCtrl,
                    decoration: InputDecoration(
                      labelText: 'Payment Due Date',
                      prefixIcon: const Icon(Icons.event_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: mode,
                    decoration: InputDecoration(
                      labelText: 'Payment Mode',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'UPI Instant', child: Text('UPI Instant')),
                      DropdownMenuItem(value: 'NEFT / RTGS', child: Text('NEFT / RTGS Transfer')),
                      DropdownMenuItem(value: 'Corporate Cheque', child: Text('Corporate Cheque')),
                      DropdownMenuItem(value: 'Debit / Credit Card', child: Text('Debit / Credit Card')),
                    ],
                    onChanged: (val) => setDialogState(() => mode = val ?? 'UPI Instant'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                      labelText: 'Invoice Status',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'DRAFT', child: Text('📝 Draft')),
                      DropdownMenuItem(value: 'SUBMITTED', child: Text('📤 Submitted')),
                      DropdownMenuItem(value: 'POSTED', child: Text('📘 Posted to General Ledger')),
                      DropdownMenuItem(value: 'PAID', child: Text('✅ Fully Paid')),
                    ],
                    onChanged: (val) => setDialogState(() => status = val ?? 'SUBMITTED'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final baseAmt = int.tryParse(amountCtrl.text.trim()) ?? 0;
                if (clientCtrl.text.trim().isEmpty || baseAmt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please provide client name and valid amount')),
                  );
                  return;
                }
                setState(() {
                  if (editInvoice != null) {
                    editInvoice['client'] = clientCtrl.text.trim();
                    editInvoice['partner'] = partnerCtrl.text.trim();
                    editInvoice['amount'] = baseAmt;
                    editInvoice['tax'] = (baseAmt * 0.18).round();
                    editInvoice['commission'] = (baseAmt * 0.12).round();
                    editInvoice['status'] = status;
                    editInvoice['due'] = dueCtrl.text.trim();
                    editInvoice['paymentMode'] = mode;
                  } else {
                    _invoices.insert(0, {
                      'id': 'INV-2026-${_invoices.length + 100}',
                      'client': clientCtrl.text.trim(),
                      'partner': partnerCtrl.text.trim(),
                      'amount': baseAmt,
                      'tax': (baseAmt * 0.18).round(),
                      'commission': (baseAmt * 0.12).round(),
                      'status': status,
                      'date': 'Today',
                      'due': dueCtrl.text.trim(),
                      'paymentMode': mode,
                    });
                  }
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(editInvoice != null ? '✓ Invoice updated successfully!' : '✓ Enterprise Invoice created and posted!'),
                    backgroundColor: AppTheme.success,
                  ),
                );
              },
              child: Text(editInvoice != null ? 'Update Invoice' : 'Generate Invoice'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordPaymentDialog() {
    final bookingCtrl = TextEditingController(text: 'PB-10499');
    final clientCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final txnCtrl = TextEditingController(text: 'UPI${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}');
    String mode = 'UPI Instant';

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
                child: const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 22),
              ),
              const SizedBox(width: 10),
              const Text('Record Client Payment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: bookingCtrl,
                    decoration: InputDecoration(
                      labelText: 'Booking Ref / ID *',
                      prefixIcon: const Icon(Icons.tag_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: clientCtrl,
                    decoration: InputDecoration(
                      labelText: 'Client Name *',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Received Amount (₹) *',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: txnCtrl,
                    decoration: InputDecoration(
                      labelText: 'Bank Reference / UTR No. *',
                      prefixIcon: const Icon(Icons.verified_user_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: mode,
                    decoration: InputDecoration(
                      labelText: 'Payment Channel',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'UPI Instant', child: Text('UPI Instant')),
                      DropdownMenuItem(value: 'NEFT / Bank Transfer', child: Text('NEFT / Bank Transfer')),
                      DropdownMenuItem(value: 'POS Card Machine', child: Text('POS Card Machine')),
                      DropdownMenuItem(value: 'Cash Receipt', child: Text('Cash Receipt')),
                    ],
                    onChanged: (val) => setDialogState(() => mode = val ?? 'UPI Instant'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final amt = int.tryParse(amountCtrl.text.trim()) ?? 0;
                if (clientCtrl.text.trim().isEmpty || amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required payment fields')));
                  return;
                }
                setState(() {
                  _payments.insert(0, {
                    'id': 'PAY-${_payments.length + 8825}',
                    'bookingId': bookingCtrl.text.trim(),
                    'client': clientCtrl.text.trim(),
                    'amount': amt,
                    'mode': mode,
                    'txnId': txnCtrl.text.trim(),
                    'status': 'VERIFIED',
                    'date': 'Today, Just now',
                    'verifiedBy': 'Instant Auto-Reconciled',
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Payment recorded & reconciled to booking!'), backgroundColor: AppTheme.success),
                );
              },
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubmitExpenseDialog() {
    final titleCtrl = TextEditingController();
    final empCtrl = TextEditingController(text: 'Current User');
    final amountCtrl = TextEditingController();
    String dept = 'Operations';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.request_quote_rounded, color: Color(0xFFF59E0B), size: 22),
              ),
              const SizedBox(width: 10),
              const Text('Submit Expense Claim', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Expense Purpose / Title *',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: empCtrl,
                    decoration: InputDecoration(
                      labelText: 'Claimant Employee Name *',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: dept,
                    decoration: InputDecoration(
                      labelText: 'Department',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Operations', child: Text('Operations & Logistics')),
                      DropdownMenuItem(value: 'Marketing', child: Text('Marketing & Growth')),
                      DropdownMenuItem(value: 'IT & Infra', child: Text('IT & Infrastructure')),
                      DropdownMenuItem(value: 'HR', child: Text('Human Resources')),
                      DropdownMenuItem(value: 'Accounts', child: Text('Accounts & Finance')),
                    ],
                    onChanged: (val) => setDialogState(() => dept = val ?? 'Operations'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Claim Amount (₹) *',
                      prefixIcon: const Icon(Icons.currency_rupee_rounded),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final amt = int.tryParse(amountCtrl.text.trim()) ?? 0;
                if (titleCtrl.text.trim().isEmpty || amt <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill title and valid amount')));
                  return;
                }
                setState(() {
                  _expenses.insert(0, {
                    'id': 'EXP-${_expenses.length + 108}',
                    'employee': empCtrl.text.trim(),
                    'dept': dept,
                    'title': titleCtrl.text.trim(),
                    'amount': amt,
                    'status': 'PENDING_APPROVAL',
                    'date': 'Today',
                    'receiptAttached': true,
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Expense claim submitted for manager approval!'), backgroundColor: AppTheme.success),
                );
              },
              child: const Text('Submit Claim'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewSettlementBatchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.handshake_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Generate Settlement Batch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Automated 12% Commission Calculation Model',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A), fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              'This will aggregate all verified events completed in the active settlement window, compute 12% PartyBala revenue share + 0.1% TDS, and generate bank disbursement payout files for all verified banquet partners.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ 3 Partner Settlement payouts calculated and ready for execution!'), backgroundColor: AppTheme.success),
              );
            },
            child: const Text('Compute & Queue Batch'),
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
        title: const Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF7C3AED)),
            SizedBox(width: 8),
            Text(
              'Accounts & Financial Ledger',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF334155)),
            tooltip: 'Refresh Ledger',
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF7C3AED),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          tabs: const [
            Tab(icon: Icon(Icons.receipt_rounded, size: 20), text: "Invoices"),
            Tab(icon: Icon(Icons.payments_rounded, size: 20), text: "Payments"),
            Tab(icon: Icon(Icons.request_quote_rounded, size: 20), text: "Expenses"),
            Tab(icon: Icon(Icons.handshake_rounded, size: 20), text: "Settlements (12%)"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showCreateInvoiceDialog();
          } else if (_tabController.index == 1) {
            _showRecordPaymentDialog();
          } else if (_tabController.index == 2) {
            _showSubmitExpenseDialog();
          } else {
            _showNewSettlementBatchDialog();
          }
        },
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          _tabController.index == 0
              ? '+ New Invoice'
              : _tabController.index == 1
                  ? '+ Record Payment'
                  : _tabController.index == 2
                      ? '+ Submit Expense'
                      : '+ Run Settlement',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInvoicesTab(),
          _buildPaymentsTab(),
          _buildExpensesTab(),
          _buildSettlementsTab(),
        ],
      ),
    );
  }

  // --- INVOICES TAB ---

  Widget _buildInvoicesTab() {
    int totalInvoiced = _invoices.fold(0, (sum, item) => sum + (item['amount'] as int));
    int totalTax = _invoices.fold(0, (sum, item) => sum + (item['tax'] as int));
    int collected = _invoices.where((i) => i['status'] == 'PAID' || i['status'] == 'POSTED').fold(0, (sum, item) => sum + (item['amount'] as int));

    final filtered = _invoices.where((inv) {
      if (_invoiceFilter != 'ALL' && inv['status'] != _invoiceFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return inv['client'].toString().toLowerCase().contains(q) ||
            inv['partner'].toString().toLowerCase().contains(q) ||
            inv['id'].toString().toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary KPI Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCol('Total Invoiced', '₹ ${(totalInvoiced / 100000).toStringAsFixed(1)}L', const Color(0xFF7C3AED)),
              Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
              _buildMetricCol('Collected / Posted', '₹ ${(collected / 100000).toStringAsFixed(1)}L', const Color(0xFF10B981)),
              Container(width: 1, height: 36, color: const Color(0xFFE2E8F0)),
              _buildMetricCol('18% GST Output', '₹ ${(totalTax / 1000).toStringAsFixed(0)}K', const Color(0xFF0284C7)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('ALL', 'All Invoices (${_invoices.length})', _invoiceFilter, (v) => setState(() => _invoiceFilter = v)),
              _buildFilterChip('POSTED', 'Posted', _invoiceFilter, (v) => setState(() => _invoiceFilter = v)),
              _buildFilterChip('SUBMITTED', 'Submitted', _invoiceFilter, (v) => setState(() => _invoiceFilter = v)),
              _buildFilterChip('DRAFT', 'Draft', _invoiceFilter, (v) => setState(() => _invoiceFilter = v)),
              _buildFilterChip('PAID', 'Paid', _invoiceFilter, (v) => setState(() => _invoiceFilter = v)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        ...filtered.map((inv) {
          final status = inv['status'];
          Color statusColor = const Color(0xFF64748B);
          if (status == 'POSTED') statusColor = const Color(0xFF2563EB);
          if (status == 'PAID') statusColor = const Color(0xFF10B981);
          if (status == 'SUBMITTED') statusColor = const Color(0xFFF59E0B);
          if (status == 'DRAFT') statusColor = const Color(0xFF64748B);

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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(inv['id'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF7C3AED))),
                          ),
                          const SizedBox(width: 8),
                          Text(inv['paymentMode'] ?? 'UPI', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(status, style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(inv['client'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text('Partner Venue: ${inv['partner']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Amount: ₹ ${(inv['amount'] as int).toString()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                      Text('GST (18%): ₹ ${(inv['tax'] as int).toString()}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text('Due: ${inv['due']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B))),
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
                            tooltip: 'Edit Invoice',
                            onPressed: () => _showCreateInvoiceDialog(editInvoice: inv),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                            tooltip: 'Delete Invoice',
                            onPressed: () {
                              setState(() => _invoices.remove(inv));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice deleted')));
                            },
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('📄 Generating PDF for ${inv['id']}... Generated!')),
                              );
                            },
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 6),
                          if (status != 'PAID')
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                setState(() => inv['status'] = 'PAID');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('✓ Invoice marked as PAID!'), backgroundColor: AppTheme.success),
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 15),
                              label: const Text('Mark Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

  // --- PAYMENTS TAB ---

  Widget _buildPaymentsTab() {
    int totalCollected = _payments.where((p) => p['status'] == 'VERIFIED').fold(0, (sum, item) => sum + (item['amount'] as int));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Verified Receipts', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('₹ ${(totalCollected / 100000).toStringAsFixed(2)} Lakhs', style: const TextStyle(color: Color(0xFF10B981), fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _showRecordPaymentDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Record Payment'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Reconciled Payment Transactions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),

        ..._payments.map((p) {
          final isVerified = p['status'] == 'VERIFIED';

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
                      Text(p['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7C3AED))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isVerified ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFF59E0B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p['status'],
                          style: TextStyle(color: isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontSize: 10.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(p['client'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                  Text('Booking: ${p['bookingId']} • Mode: ${p['mode']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text('Txn Ref: ${p['txnId']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontFamily: 'monospace')),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹ ${(p['amount'] as int).toString()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF10B981))),
                      Text(p['date'], style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('By: ${p['verifiedBy']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      if (!isVerified)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            setState(() {
                              p['status'] = 'VERIFIED';
                              p['verifiedBy'] = 'Manual Ledger Confirmation';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✓ Payment cleared and verified!'), backgroundColor: AppTheme.success),
                            );
                          },
                          child: const Text('Verify & Clear', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

  // --- EXPENSES TAB ---

  Widget _buildExpensesTab() {
    final filtered = _expenses.where((e) {
      if (_expenseFilter != 'ALL' && e['status'] != _expenseFilter) return false;
      return true;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('ALL', 'All Claims (${_expenses.length})', _expenseFilter, (v) => setState(() => _expenseFilter = v)),
              _buildFilterChip('PENDING_APPROVAL', 'Pending', _expenseFilter, (v) => setState(() => _expenseFilter = v)),
              _buildFilterChip('APPROVED', 'Approved', _expenseFilter, (v) => setState(() => _expenseFilter = v)),
              _buildFilterChip('REIMBURSED', 'Reimbursed', _expenseFilter, (v) => setState(() => _expenseFilter = v)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        ...filtered.map((exp) {
          final status = exp['status'];
          Color color = const Color(0xFFF59E0B);
          if (status == 'APPROVED') color = const Color(0xFF2563EB);
          if (status == 'REIMBURSED') color = const Color(0xFF10B981);
          if (status == 'REJECTED') color = const Color(0xFFEF4444);

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
                      Text(exp['title'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                      Text('₹ ${(exp['amount'] as int).toString()}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: color)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Claimant: ${exp['employee']} (${exp['dept']}) • Date: ${exp['date']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(status.toString().replaceAll('_', ' '), style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800)),
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (status == 'PENDING_APPROVAL') ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFEF4444), side: const BorderSide(color: Color(0xFFEF4444))),
                          onPressed: () {
                            setState(() => exp['status'] = 'REJECTED');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense claim rejected')));
                          },
                          child: const Text('Reject', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                          onPressed: () {
                            setState(() => exp['status'] = 'APPROVED');
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Expense claim approved for disbursement!')));
                          },
                          child: const Text('Approve', style: TextStyle(fontSize: 11)),
                        ),
                      ] else if (status == 'APPROVED') ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                          onPressed: () {
                            setState(() => exp['status'] = 'REIMBURSED');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✓ Payment disbursed directly to employee account!'), backgroundColor: AppTheme.success),
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 14),
                          label: const Text('Disburse Payout', style: TextStyle(fontSize: 11)),
                        ),
                      ],
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

  // --- SETTLEMENTS TAB ---

  Widget _buildSettlementsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PartyBala 12% Revenue Share Settlement Engine', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 6),
              const Text(
                'Automated bi-weekly partner payout cycle with TDS deduction, automated invoicing, and direct NEFT/RTGS batch clearance.',
                style: TextStyle(color: Color(0xFFE9D5FF), fontSize: 12),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF7C3AED)),
                onPressed: _showNewSettlementBatchDialog,
                icon: const Icon(Icons.bolt_rounded, size: 18),
                label: const Text('Run Settlement Cycle Now', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Partner Settlements & Payout Batches', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
        const SizedBox(height: 10),

        ..._settlements.map((set) {
          final isReady = set['status'] == 'READY_FOR_PAYOUT';
          final isSettled = set['status'] == 'SETTLED';

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
                      Text(set['id'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF7C3AED))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSettled ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFFF59E0B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          set['status'],
                          style: TextStyle(color: isSettled ? const Color(0xFF10B981) : const Color(0xFFF59E0B), fontSize: 10.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(set['partner'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                  Text('${set['period']} • ${set['bank']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gross GMV', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          Text('₹ ${(set['grossGMV'] as int).toString()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('12% Commission', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          Text('₹ ${(set['commissionAmount'] as int).toString()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF7C3AED))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Net Payout to Partner', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          Text('₹ ${(set['netPayout'] as int).toString()}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF10B981))),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isReady)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            setState(() => set['status'] = 'SETTLED');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✓ Payout batch transmitted to HDFC Corporate Gateway!'), backgroundColor: AppTheme.success),
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 14),
                          label: const Text('Disburse Partner Payout', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      else if (isSettled)
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                            SizedBox(width: 4),
                            Text('Disbursed & Reconciled', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, String currentVal, Function(String) onSelect) {
    final isSelected = currentVal == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelect(value),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF7C3AED).withOpacity(0.12),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
        ),
        showCheckmark: false,
      ),
    );
  }
}
