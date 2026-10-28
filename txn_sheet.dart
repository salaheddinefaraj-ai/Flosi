import 'package:flutter/material.dart';
import 'db.dart';
import 'state.dart';
import 'util.dart';
import 'widgets.dart';

Future<void> showTxnSheet(BuildContext context, {Txn? edit, String? type}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => TxnForm(edit: edit, initialType: type),
  );
}

class TxnForm extends StatefulWidget {
  final Txn? edit;
  final String? initialType;
  const TxnForm({super.key, this.edit, this.initialType});
  @override
  State<TxnForm> createState() => _TxnFormState();
}

class _TxnFormState extends State<TxnForm> {
  late String type;
  late DateTime date;
  final title = TextEditingController();
  final amount = TextEditingController();
  final note = TextEditingController();
  String? titleErr;
  String? amountErr;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    type = e?.type ?? widget.initialType ?? 'in';
    date = e != null ? dateOf(e.date) : DateTime.now();
    if (e != null) {
      title.text = e.title;
      amount.text = e.amount == e.amount.roundToDouble()
          ? e.amount.toStringAsFixed(0)
          : e.amount.toString();
      note.text = e.note;
    }
  }

  @override
  void dispose() {
    title.dispose();
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
    final t = title.text.trim();
    final a = parseAmount(amount.text);
    setState(() {
      titleErr = t.isEmpty
          ? (type == 'in' ? 'كتب فين خدمتي' : 'اختار نوع المصروف')
          : null;
      amountErr = a <= 0 ? 'كتب مبلغ صحيح' : null;
    });
    if (titleErr != null || amountErr != null) return;
    final nav = Navigator.of(context);
    final msg = ScaffoldMessenger.of(context);
    try {
      await appState.saveTxn(Txn(
        id: widget.edit?.id,
        type: type,
        title: t,
        amount: a,
        date: ymd(date),
        note: note.text.trim(),
      ));
      nav.pop();
      msg.showSnackBar(const SnackBar(content: Text('تسجل ✓')));
    } catch (e) {
      msg.showSnackBar(SnackBar(content: Text('وقع مشكل فالحفظ: $e')));
    }
  }

  Future<void> remove() async {
    final ok = await confirmDialog(context, 'مسح هاد التسجيل؟');
    if (!ok || !mounted) return;
    final nav = Navigator.of(context);
    await appState.deleteTxn(widget.edit!.id!);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isIn = type == 'in';
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
              widget.edit == null ? 'معاملة جديدة' : 'تعديل التسجيل',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            gap,
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'in', label: Text('دخل')),
                ButtonSegment(value: 'out', label: Text('مصروف')),
              ],
              selected: {type},
              onSelectionChanged: (s) => setState(() {
                type = s.first;
                title.clear();
                titleErr = null;
              }),
            ),
            gap,
            if (isIn) ...[
              if (appState.services.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: appState.services
                      .map((s) => ActionChip(
                            label: Text('${s.name} (${money(s.price)})'),
                            onPressed: () => setState(() {
                              title.text = s.name;
                              amount.text = s.price == s.price.roundToDouble()
                                  ? s.price.toStringAsFixed(0)
                                  : s.price.toString();
                              titleErr = null;
                              amountErr = null;
                            }),
                          ))
                      .toList(),
                ),
              if (appState.services.isNotEmpty) gap,
              TextField(
                controller: title,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: 'فين خدمتي؟ (مثلا: لاصال)',
                  errorText: titleErr,
                  counterText: '',
                ),
              ),
            ] else ...[
              if (appState.cats.isEmpty)
                const Text('زيد فئة المصاريف من صفحة "المزيد".',
                    style: TextStyle(color: C.muted)),
              Wrap(
                spacing: 8,
                children: appState.cats
                    .map((c) => ChoiceChip(
                          label: Text(c.name),
                          selected: title.text == c.name,
                          onSelected: (_) => setState(() {
                            title.text = c.name;
                            titleErr = null;
                          }),
                        ))
                    .toList(),
              ),
              if (titleErr != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(titleErr!, style: const TextStyle(color: C.red, fontSize: 12)),
                ),
            ],
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
            FilledButton(
              onPressed: save,
              child: Text(isIn ? 'سجل الدخل' : 'سجل المصروف'),
            ),
            if (widget.edit != null)
              TextButton(
                onPressed: remove,
                child: const Text('مسح هاد التسجيل', style: TextStyle(color: C.red)),
              ),
          ],
        ),
      ),
    );
  }
}
