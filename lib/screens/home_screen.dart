import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/loan.dart';
import '../storage/ledger_store.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

enum Role { admin, collector }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.mode, required this.onMode});
  final AppThemeMode mode;
  final ValueChanged<AppThemeMode> onMode;
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  final db = LedgerStore.instance;
  int tab = 0;
  Role role = Role.admin;
  String filter = 'All';
  String search = '';
  String kes(num n) => 'KES ${NumberFormat('#,##0.00').format(n)}';

  bool overdue(Loan loan) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final paid = db.paid(loan.id);
    for (var i = 0; i < loan.terms; i++) {
      if (loan.due(i).isBefore(today) && paid < (i + 1) * loan.installment - .01) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: db.revision,
      builder: (context, revision, child) {
        final loans = db.loans;
        final payments = db.payments;
        final overdueCount = loans.where(overdue).length;
        final total = loans.fold<double>(0, (sum, loan) => sum + loan.total);
        final outstanding = loans.fold<double>(0, (sum, loan) => sum + db.balance(loan));
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-.8, -.9), radius: 1.5,
                colors: [Color(0xFF174B43), Color(0xFF101820), Color(0xFF0D141B)],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: AppTheme.mint, size: 30),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('SokoMikopo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            Text('BORROWER LEDGER • OFFLINE FIRST', style: TextStyle(fontSize: 9, color: Colors.white60, letterSpacing: 1.1)),
                          ]),
                        ),
                        PopupMenuButton<Role>(
                          initialValue: role,
                          onSelected: (value) => setState(() => role = value),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: Role.admin, child: Text('Loan Admin / Treasurer')),
                            PopupMenuItem(value: Role.collector, child: Text('Field Collector / Clerk')),
                          ],
                          child: Chip(label: Text(role == Role.admin ? 'Admin' : 'Collector'), avatar: const Icon(Icons.verified_user, size: 15)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(children: [
                      _metric('Loan book', kes(total)),
                      const SizedBox(width: 7),
                      _metric('Outstanding', kes(outstanding)),
                      const SizedBox(width: 7),
                      _metric('Overdue', '$overdueCount'),
                    ]),
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: tab,
                      children: [
                        _loans(loans),
                        _repayments(loans, payments),
                        _arrears(loans),
                        _settings(loans, payments),
                      ],
                    ),
                  ),
                  NavigationBar(
                    selectedIndex: tab,
                    onDestinationSelected: (value) => setState(() => tab = value),
                    destinations: const [
                      NavigationDestination(icon: Icon(Icons.wallet_outlined), selectedIcon: Icon(Icons.wallet), label: 'Loans'),
                      NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Repayments'),
                      NavigationDestination(icon: Icon(Icons.warning_amber_outlined), label: 'Arrears'),
                      NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
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

  Widget _metric(String label, String value) => Expanded(
    child: GlassCard(
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white60)),
      ]),
    ),
  );

  Widget _loans(List<Loan> loans) {
    final list = loans.where((loan) {
      final query = search.toLowerCase();
      final status = db.balance(loan) < .01 ? 'Cleared' : overdue(loan) ? 'Overdue' : 'Active';
      return (loan.name.toLowerCase().contains(query) || loan.phone.contains(query)) && (filter == 'All' || filter == status);
    }).toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          const Expanded(child: Text('Loan book', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800))),
          FilledButton.icon(onPressed: _newLoan, icon: const Icon(Icons.add), label: const Text('New loan')),
        ]),
        const SizedBox(height: 10),
        TextField(onChanged: (value) => setState(() => search = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search borrower / phone')),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: ['All', 'Active', 'Overdue', 'Cleared'].map((value) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(label: Text(value), selected: filter == value, onSelected: (_) => setState(() => filter = value)),
          )).toList()),
        ),
        Expanded(
          child: list.isEmpty
            ? Center(child: Text(loans.isEmpty ? 'No loans yet. Add your first borrower.' : 'No matching loans.', style: const TextStyle(color: Colors.white60)))
            : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final loan = list[index];
                final balance = db.balance(loan);
                final paid = db.paid(loan.id);
                final status = balance < .01 ? 'Cleared' : overdue(loan) ? 'Overdue' : 'Active';
                return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text(loan.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))), _pill(status)]),
                  if (loan.phone.isNotEmpty) Text(loan.phone, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Balance  ${kes(balance)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('Total  ${kes(loan.total)}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  ]),
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (paid / loan.total).clamp(0, 1).toDouble(), minHeight: 7)),
                  const SizedBox(height: 7),
                  Text('${(paid / loan.total * 100).toStringAsFixed(0)}% paid • ${loan.terms} monthly installments • ${kes(loan.installment)} each', style: const TextStyle(fontSize: 10, color: Colors.white60)),
                  Row(children: [
                    Text('Started ${DateFormat.yMMMd().format(loan.start)}', style: const TextStyle(fontSize: 10, color: Colors.white54)),
                    const Spacer(),
                    if (role == Role.admin) IconButton(onPressed: () => _delete(loan), icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
                  ]),
                ]));
              },
            ),
        ),
      ]),
    );
  }

  Widget _pill(String status) {
    final color = status == 'Overdue' ? Colors.red : status == 'Cleared' ? Colors.green : Colors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: .16), borderRadius: BorderRadius.circular(18)),
      child: Text(status, style: TextStyle(fontSize: 10, color: status == 'Overdue' ? Colors.redAccent : status == 'Cleared' ? Colors.greenAccent : Colors.amberAccent)),
    );
  }

  Widget _repayments(List<Loan> loans, List<dynamic> payments) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      Row(children: [
        const Expanded(child: Text('Repayment log', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800))),
        FilledButton.icon(onPressed: () => _newPayment(loans), icon: const Icon(Icons.add), label: const Text('Record')),
      ]),
      GlassCard(child: Row(children: [
        const Icon(Icons.receipt_long, color: AppTheme.mint),
        const SizedBox(width: 8),
        Expanded(child: Text('${payments.length} transactions')),
        Text(kes(payments.fold<double>(0, (sum, payment) => sum + payment.amount)), style: const TextStyle(fontWeight: FontWeight.w800)),
      ])),
      Expanded(
        child: payments.isEmpty
          ? const Center(child: Text('No repayments recorded yet.', style: TextStyle(color: Colors.white60)))
          : ListView.separated(
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 7),
            itemBuilder: (context, index) {
              final payment = payments[index];
              final matching = loans.where((loan) => loan.id == payment.loanId);
              final name = matching.isEmpty ? 'Archived borrower' : matching.first.name;
              return GlassCard(child: Row(children: [
                const Icon(Icons.south_west, color: AppTheme.mint),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${payment.mode} • ${DateFormat.yMMMd().add_jm().format(payment.date)}', style: const TextStyle(fontSize: 10, color: Colors.white60)),
                  if (payment.note.isNotEmpty) Text(payment.note, style: const TextStyle(fontSize: 11, color: Colors.white60)),
                ])),
                Text('+ ${kes(payment.amount)}', style: const TextStyle(color: AppTheme.mint, fontWeight: FontWeight.w800)),
              ]));
            },
          ),
      ),
    ]),
  );

  Widget _arrears(List<Loan> loans) {
    final list = loans.where(overdue).toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Arrears watchlist', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
        Text('${list.length} borrowers need follow-up', style: const TextStyle(color: Colors.white60)),
        Expanded(
          child: list.isEmpty
            ? const Center(child: Text('No overdue installments', style: TextStyle(color: AppTheme.mint, fontWeight: FontWeight.w700)))
            : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final loan = list[index];
                final now = DateTime.now();
                var late = 0;
                for (var i = 0; i < loan.terms; i++) {
                  if (loan.due(i).isBefore(DateTime(now.year, now.month, now.day)) && (i + 1) * loan.installment > db.paid(loan.id) + .01) late++;
                }
                final estimate = (late * loan.installment - db.paid(loan.id)).clamp(0, loan.total);
                return GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [const Icon(Icons.warning_amber, color: Colors.orangeAccent), const SizedBox(width: 8), Expanded(child: Text(loan.name, style: const TextStyle(fontWeight: FontWeight.w800))), Text('$late late', style: const TextStyle(color: Colors.orangeAccent))]),
                  const SizedBox(height: 8),
                  Text('Estimated overdue: ${kes(estimate)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  Text('Outstanding: ${kes(db.balance(loan))} • ${loan.phone}', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                ]));
              },
            ),
        ),
      ]),
    );
  }

  Widget _settings(List<Loan> loans, List<dynamic> payments) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text('Settings & APK center', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Active role', style: TextStyle(fontWeight: FontWeight.w800)),
        DropdownButtonFormField<Role>(
          initialValue: role,
          items: const [
            DropdownMenuItem(value: Role.admin, child: Text('Loan Admin / Treasurer')),
            DropdownMenuItem(value: Role.collector, child: Text('Field Collector / Clerk')),
          ],
          onChanged: (value) { if (value != null) setState(() => role = value); },
        ),
        Text(role == Role.admin ? 'Local ledger and export controls.' : 'Collector view. Backup export and record deletion are disabled.', style: const TextStyle(fontSize: 11, color: Colors.white60)),
      ])),
      const SizedBox(height: 9),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Theme', style: TextStyle(fontWeight: FontWeight.w800)),
        ...AppThemeMode.values.map((mode) => RadioListTile<AppThemeMode>(
          contentPadding: EdgeInsets.zero,
          value: mode,
          groupValue: widget.mode,
          title: Text(switch (mode) {
            AppThemeMode.obsidian => 'Vault Obsidian',
            AppThemeMode.daylight => 'Daylight Ledger',
            AppThemeMode.field => 'High-Contrast Field',
          }),
          onChanged: (value) { if (value != null) widget.onMode(value); },
        )),
      ])),
      const SizedBox(height: 9),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Offline storage', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('${loans.length} loans • ${payments.length} repayments • ${db.recordCount} records'),
        const Text('Data is stored locally on this device and does not sync between collectors. Export backups regularly; clearing app or browser data may erase this ledger.', style: TextStyle(fontSize: 11, color: Colors.white60)),
      ])),
      if (role == Role.admin) ...[
        const SizedBox(height: 9),
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Treasurer tools', style: TextStyle(fontWeight: FontWeight.w800)),
          FilledButton.icon(
            onPressed: () async {
              final data = db.exportJson();
              await Share.shareXFiles([
                XFile.fromData(Uint8List.fromList(utf8.encode(data)), mimeType: 'application/json', name: 'sokomikopo-backup.json'),
              ], text: 'SokoMikopo ledger backup');
            },
            icon: const Icon(Icons.ios_share),
            label: const Text('Export ledger backup (JSON)'),
          ),
        ])),
      ],
      const SizedBox(height: 9),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Android app', style: TextStyle(fontWeight: FontWeight.w800)),
        const Text('Download the latest APK produced by the repository release workflow.', style: TextStyle(fontSize: 11, color: Colors.white60)),
        FilledButton.icon(
          onPressed: () => launchUrl(Uri.parse('https://github.com/kennedy-blip/soko-mikopa/releases/latest/download/SokoMikopo.apk'), mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.android),
          label: const Text('Download Android APK'),
        ),
      ])),
      const Center(child: Text('SokoMikopo • v1.0.0', style: TextStyle(fontSize: 10, color: Colors.white54))),
    ],
  );

  Future<void> _newLoan() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final phone = TextEditingController();
    final principal = TextEditingController();
    final rate = TextEditingController(text: '10');
    final terms = TextEditingController(text: '4');
    final note = TextEditingController();
    var start = DateTime.now();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refresh) => AlertDialog(
          title: const Text('Create borrower loan'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Borrower name'), validator: (value) => value == null || value.trim().isEmpty ? 'Name is required' : null),
                TextFormField(controller: phone, decoration: const InputDecoration(labelText: 'Phone number')),
                TextFormField(controller: principal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Principal (KES)'), validator: (value) { final amount = double.tryParse(value ?? ''); return amount == null || amount <= 0 ? 'Enter a positive amount' : null; }),
                if (role == Role.admin) TextFormField(controller: rate, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Flat fee / interest (%)'), validator: (value) { final amount = double.tryParse(value ?? ''); return amount == null || amount < 0 ? 'Enter a valid fee' : null; }),
                TextFormField(controller: terms, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly installments (1–60)'), validator: (value) { final count = int.tryParse(value ?? ''); return count == null || count < 1 || count > 60 ? 'Use 1–60' : null; }),
                TextFormField(controller: note, decoration: const InputDecoration(labelText: 'Agreement reference / notes')),
                TextButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(context: dialogContext, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: start);
                    if (date != null) refresh(() => start = date);
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text('Start: ${DateFormat.yMMMd().format(start)}'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await db.addLoan(
                  name: name.text, phone: phone.text, note: note.text,
                  principal: double.parse(principal.text),
                  rate: role == Role.admin ? double.parse(rate.text) : 10,
                  terms: int.parse(terms.text), start: start,
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save loan'),
            ),
          ],
        ),
      ),
    );
    name.dispose(); phone.dispose(); principal.dispose(); rate.dispose(); terms.dispose(); note.dispose();
  }

  Future<void> _newPayment(List<Loan> loans) async {
    final active = loans.where((loan) => db.balance(loan) > .001).toList();
    if (active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No outstanding loans to receive payment.')));
      return;
    }
    final formKey = GlobalKey<FormState>();
    var loanId = active.first.id;
    var mode = 'Cash';
    final amount = TextEditingController();
    final note = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, refresh) => AlertDialog(
          title: const Text('Record repayment'),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                initialValue: loanId,
                items: active.map((loan) => DropdownMenuItem(value: loan.id, child: Text('${loan.name} • ${kes(db.balance(loan))}', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (value) => refresh(() => loanId = value ?? loanId),
                decoration: const InputDecoration(labelText: 'Borrower'),
              ),
              TextFormField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount received (KES)'),
                validator: (value) {
                  final received = double.tryParse(value ?? '');
                  if (received == null || received <= 0) return 'Enter a positive amount';
                  if (received > db.balance(active.firstWhere((loan) => loan.id == loanId)) + .001) return 'Exceeds outstanding balance';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: mode,
                decoration: const InputDecoration(labelText: 'Payment mode'),
                items: ['Cash', 'M-Pesa', 'Bank', 'Other'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                onChanged: (value) => refresh(() => mode = value ?? 'Cash'),
              ),
              TextFormField(controller: note, decoration: const InputDecoration(labelText: 'Transaction code / notes')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await db.addPayment(loanId: loanId, amount: double.parse(amount.text), mode: mode, note: note.text);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save repayment'),
            ),
          ],
        ),
      ),
    );
    amount.dispose(); note.dispose();
  }

  Future<void> _delete(Loan loan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete loan?'),
        content: Text('This removes ${loan.name} and all linked repayment history. Export a backup first.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) await db.deleteLoan(loan.id);
  }
}
