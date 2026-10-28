import 'package:flutter/material.dart';
import 'db.dart';
import 'state.dart';
import 'util.dart';
import 'widgets.dart';

Future<void> showLoanSheet(BuildContext context, {Loan? edit}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => LoanForm(edit: edit),
  );
}

class LoanForm extends StatefulWidget {
  final Loan? edit;
  const LoanForm({super.key, this.edit});
  @override
  State<LoanForm> createState() => _LoanFormState();
}

class _LoanFormState extends State<LoanForm> {
  late String kind;
  late DateTime date;
  final who = TextEditingController();
  final amount = TextEditingController();
  final note = TextEditingController();
  String? whoErr;
  String? amountErr;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    kind = e?.kind ?? 'l';
    date = e != null ? dateOf(e.date) : DateTime.now();
    if (e != null) {
      who.text = e.who;
      amount.text = e.amount == e.amount.roundToDouble()
          ? e.amount.toStringAsFixed(0)
          : e.amount.toString();
      note.text = e.note;
    }
  }

  @override
  void dispose() {
    who.dispose();
    amount.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => date = d);
  }

  Future<void> save() async {
    final w = who.text.trim();
    final a = parseAmount(amount.text);
    setState(() {
      whoErr = w.isEmpty ? 'كتب سمية الشخص' : null;
      amountErr = a <= 0 ? 'كتب مبلغ صحيح' : null;
    });
    if (whoErr != null || amountErr != null) return;
    final nav = Navigator.of(context);
    final msg = ScaffoldMessenger.of(context);
    try {
      await appState.saveLoan(Loan(
        id: widget.edit?.id,
        who: w,
        kind: kind,
        amount: a,
        date: ymd(date),
        paidDate: widget.edit?.paidDate,
        note: note.text.trim(),
      ));
      nav.pop();
      msg.showSnackBar(const SnackBar(content: Text('تسجل ✓')));
    } catch (e) {
      msg.showSnackBar(SnackBar(content: Text('وقع مشكل فالحفظ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.edit == null ? 'سلف جديد' : 'تعديل السلف',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            gap,
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'l', label: Text('أنا سلفتو')),
                ButtonSegment(value: 'b', label: Text('هو سلفني')),
              ],
              selected: {kind},
              onSelectionChanged: (s) => setState(() => kind = s.first),
            ),
            gap,
            TextField(
              controller: who,
              maxLength: 40,
              decoration: InputDecoration(labelText: 'سمية الشخص', errorText: whoErr, counterText: ''),
            ),
            gap,
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'المبلغ (درهم)', errorText: amountErr),
            ),
            gap,
            OutlinedButton.icon(
              onPressed: pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(niceDate(ymd(date))),
            ),
            gap,
            TextField(
              controller: note,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)', counterText: ''),
            ),
            gap,
            FilledButton(onPressed: save, child: const Text('سجل')),
          ],
        ),
      ),
    );
  }
}

class LoansPage extends StatelessWidget {
  const LoansPage({super.key});

  Widget _tile(BuildContext context, Loan l) {
    final color = l.iLent ? C.green : C.red;
    final sub = StringBuffer(l.iLent ? 'سلفتو' : 'سلفني');
    sub.write(' فـ ${niceDate(l.date)}');
    if (l.paid) sub.write('، تخلص فـ ${niceDate(l.paidDate!)}');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.who, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(sub.toString(), style: const TextStyle(color: C.muted, fontSize: 12)),
                  if (l.note.isNotEmpty)
                    Text(l.note, style: const TextStyle(color: C.muted, fontSize: 12)),
                ],
              ),
            ),
            Text(money(l.amount), style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'paid') {
                  await appState.saveLoan(Loan(
                    id: l.id,
                    who: l.who,
                    kind: l.kind,
                    amount: l.amount,
                    date: l.date,
                    paidDate: l.paid ? null : ymd(DateTime.now()),
                    note: l.note,
                  ));
                } else if (v == 'edit') {
                  await showLoanSheet(context, edit: l);
                } else if (v == 'del') {
                  final ok = await confirmDialog(context, 'مسح هاد السلف؟');
                  if (ok) await appState.deleteLoan(l.id!);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'paid', child: Text(l.paid ? 'ما تخلصش' : 'تخلص')),
                const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                const PopupMenuItem(value: 'del', child: Text('مسح')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final open = appState.loans.where((l) => !l.paid).toList();
    final done = appState.loans.where((l) => l.paid).toList();
    double lent = 0;
    double borrowed = 0;
    for (final l in open) {
      if (l.iLent) {
        lent += l.amount;
      } else {
        borrowed += l.amount;
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('السلف', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            FilledButton.icon(
              onPressed: () => showLoanSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('سلف جديد'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: StatBox(label: 'عندهم ليا', value: lent, color: C.green)),
            const SizedBox(width: 8),
            Expanded(child: StatBox(label: 'عندي ليهم', value: borrowed, color: C.red)),
            const SizedBox(width: 8),
            Expanded(
              child: StatBox(
                label: 'الصافي',
                value: lent - borrowed,
                color: lent - borrowed >= 0 ? C.green : C.red,
              ),
            ),
          ],
        ),
        const SectionTitle('باقي ما تخلصش'),
        if (open.isEmpty) const EmptyNote('ما كاين حتى سلف مفتوح.'),
        ...open.map((l) => _tile(context, l)),
        const SectionTitle('تخلص'),
        if (done.isEmpty) const EmptyNote('ما كاين والو.'),
        ...done.map((l) => _tile(context, l)),
      ],
    );
  }
}
