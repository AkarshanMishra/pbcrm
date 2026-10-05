import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AccountsFinanceScreen extends StatefulWidget {
  const AccountsFinanceScreen({super.key});

  @override
  State<AccountsFinanceScreen> createState() => _AccountsFinanceScreenState();
}

class _AccountsFinanceScreenState extends State<AccountsFinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _invoices = [
    {
      'id': 'INV-2026-089',
      'client': 'Sharma Wedding Reception',
      'partner': 'Grand Heritage Banquet',
      'amount': '₹ 1,85,000',
      'status': 'POSTED',
      'date': '04 Oct 2026',
      'due': '15 Oct 2026'
    },
    {
      'id': 'INV-2026-090',
      'client': 'TechCorp Annual Meet',
      'partner': 'Royal Palms Resort',
      'amount': '₹ 3,40,000',
      'status': 'SUBMITTED',
      'date': '05 Oct 2026',
      'due': '20 Oct 2026'
    },
    {
      'id': 'INV-2026-091',
      'client': 'Verma Birthday Celebration',
      'partner': 'Kuhu Espresso Banquet',
      'amount': '₹ 45,000',
      'status': 'DRAFT',
      'date': '05 Oct 2026',
      'due': '10 Oct 2026'
    },
  ];

  final List<Map<String, dynamic>> _expenses = [
    {
      'id': 'EXP-104',
      'employee': 'Kavita Nair (Operations)',
      'title': 'Venue Inspection Fuel & Toll',
      'amount': '₹ 4,250',
      'status': 'PENDING_APPROVAL',
      'date': '02 Oct 2026'
    },
    {
      'id': 'EXP-105',
      'employee': 'Akarshan Mishra (IT)',
      'title': 'Cloud Staging CDN & Replica Server Renewal',
      'amount': '₹ 12,800',
      'status': 'APPROVED',
      'date': '03 Oct 2026'
    },
    {
      'id': 'EXP-106',
      'employee': 'Rahul Verma (Marketing)',
      'title': 'Client Banquet Onboarding Lunch & Collateral',
      'amount': '₹ 3,100',
      'status': 'REIMBURSED',
      'date': '04 Oct 2026'
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

  void _showCreateInvoiceDialog() {
    final clientCtrl = TextEditingController();
    final partnerCtrl = TextEditingController(text: 'Grand Heritage Banquet');
    final amountCtrl = TextEditingController();
    String status = 'SUBMITTED';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.purple),
            SizedBox(width: 8),
            Text('Create Enterprise Invoice', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: clientCtrl,
                decoration: const InputDecoration(labelText: 'Client / Booking Name *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: partnerCtrl,
                decoration: const InputDecoration(labelText: 'Partner Banquet / Venue *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Invoice Amount (₹) *', border: OutlineInputBorder(), prefixText: '₹ '),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Initial Ledger Status', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'DRAFT', child: Text('Draft (Editable)')),
                  DropdownMenuItem(value: 'SUBMITTED', child: Text('Submitted (Pending Verification)')),
                  DropdownMenuItem(value: 'POSTED', child: Text('Posted (Official Ledger)')),
                ],
                onChanged: (val) => status = val ?? 'SUBMITTED',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            onPressed: () {
              if (clientCtrl.text.trim().isEmpty || amountCtrl.text.trim().isEmpty) return;
              setState(() {
                _invoices.insert(0, {
                  'id': 'INV-2026-${_invoices.length + 100}',
                  'client': clientCtrl.text.trim(),
                  'partner': partnerCtrl.text.trim(),
                  'amount': '₹ ${amountCtrl.text.trim()}',
                  'status': status,
                  'date': DateTime.now().toIso8601String().substring(0, 10),
                  'due': '15 Days Net',
                });
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Invoice registered into accounts ledger!'), backgroundColor: AppTheme.success),
              );
            },
            child: const Text('Save & Generate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Financial Ledger'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.purple.shade700,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.purple.shade700,
          tabs: const [
            Tab(icon: Icon(Icons.receipt), text: "Invoices"),
            Tab(icon: Icon(Icons.payments), text: "Payments"),
            Tab(icon: Icon(Icons.request_quote), text: "Expenses"),
            Tab(icon: Icon(Icons.account_balance), text: "Settlements"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateInvoiceDialog,
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('+ Invoice'),
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

  Widget _buildInvoicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Top KPI Cards
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFinanceCol('Total Invoiced', '₹ 24.8 L', Colors.purple),
                _buildFinanceCol('Collected', '₹ 18.2 L', Colors.green),
                _buildFinanceCol('Pending Net', '₹ 6.6 L', Colors.orange),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Enterprise Invoices & Tax Billings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        ..._invoices.map((inv) {
          final status = inv['status'];
          Color statusColor = Colors.grey;
          if (status == 'POSTED') statusColor = Colors.green;
          if (status == 'SUBMITTED') statusColor = Colors.blue;
          if (status == 'DRAFT') statusColor = Colors.orange;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(inv['id'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.purple)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(inv['client'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Partner Venue: ${inv['partner']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  const SizedBox(height: 6),
                  Text('Amount: ${inv['amount']} • Date: ${inv['date']} • Due: ${inv['due']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('✓ Generating PDF Invoice ${inv['id']}...')),
                          );
                        },
                        icon: const Icon(Icons.download, size: 14),
                        label: const Text('Download PDF', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade700, foregroundColor: Colors.white),
                        onPressed: () {
                          setState(() => inv['status'] = 'POSTED');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✓ Invoice posted to general ledger!'), backgroundColor: AppTheme.success),
                          );
                        },
                        icon: const Icon(Icons.check, size: 14),
                        label: const Text('Post Ledger', style: TextStyle(fontSize: 11)),
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

  Widget _buildPaymentsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Collections & Payment Receipts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFECFDF5), child: Icon(Icons.payment, color: Colors.green)),
            title: const Text('₹ 1,00,000 received for PB-10482', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Mode: UPI / Bank Transfer • Txn #TXN992818 • Verified by Accounts'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
              child: const Text('VERIFIED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Employee Reimbursements & Operational Claims', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        ..._expenses.map((exp) {
          final status = exp['status'];
          Color color = Colors.orange;
          if (status == 'APPROVED') color = Colors.blue;
          if (status == 'REIMBURSED') color = Colors.green;

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(exp['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(exp['amount'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Claimant: ${exp['employee']} • Date: ${exp['date']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() => exp['status'] = 'REJECTED');
                        },
                        child: const Text('Reject', style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () {
                          setState(() => exp['status'] = 'REIMBURSED');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('✓ Expense approved & reimbursement scheduled!'), backgroundColor: AppTheme.success),
                          );
                        },
                        child: const Text('Approve & Pay'),
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

  Widget _buildSettlementsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Partner Commissions & Banquet Settlements (12% Model)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.handshake)),
            title: const Text('Grand Heritage Banquet (Settlement Cycle Q4-01)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Gross GMV: ₹ 8,50,000 • PartyBala Commission (12%): ₹ 1,02,000\nNet Payout: ₹ 7,48,000'),
            isThreeLine: true,
            trailing: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Payout batch generated for Bank Transfer!')),
                );
              },
              child: const Text('Settle Payout'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceCol(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }
}
