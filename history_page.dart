import 'package:flutter/material.dart';
import 'db.dart';
import 'state.dart';
import 'txn_sheet.dart';
import 'util.dart';
import 'widgets.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String query = '';
  String type = 'all';
  DateTimeRange? range;

  List<Txn> get filtered {
    final q = query.trim().toLowerCase();
    return appState.txns.where((t) {
      if (type != 'all' && t.type != type) return false;
      if (range != null) {
        if (t.date.compareTo(ymd(range!.start)) < 0) return false;
        if (t.date.compareTo(ymd(range!.end)) > 0) return false;
      }
      if (q.isNotEmpty) {
        final hit = t.title.toLowerCase().contains(q) ||
            t.note.toLowerCase().contains(q) ||
            t.amount.toString().contains(q);
        if (!hit) return false;
      }
      return true;
    }).toList();
  }

  Future<void> pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: range,
    );
    if (r != null) setState(() => range = r);
  }

  @override
  Widget build(BuildContext context) {
    final list = filtered;
    final children = <Widget>[
      TextField(
        onChanged: (v) => setState(() => query = v),
        decoration: const InputDecoration(
          hintText: 'قلب (المكان، النوع، ملاحظة، مبلغ)',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
              label: const Text('الكل'),
              selected: type == 'all',
              onSelected: (_) => setState(() => type = 'all')),
          ChoiceChip(
              label: const Text('دخل'),
              selected: type == 'in',
              onSelected: (_) => setState(() => type = 'in')),
          ChoiceChip(
              label: const Text('مصاريف'),
              selected: type == 'out',
              onSelected: (_) => setState(() => type = 'out')),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: pickRange,
              icon: const Icon(Icons.date_range, size: 18),
              label: Text(
                range == null
                    ? 'كل التواريخ'
                    : '${niceDate(ymd(range!.start))} إلى ${niceDate(ymd(range!.end))}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (range != null)
            IconButton(
              onPressed: () => setState(() => range = null),
              icon: const Icon(Icons.close),
              tooltip: 'مسح الفلتر',
            ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: StatBox(label: 'دخل', value: sum(list, 'in'), color: C.green)),
          const SizedBox(width: 10),
          Expanded(child: StatBox(label: 'مصاريف', value: sum(list, 'out'), color: C.red)),
        ],
      ),
    ];

    if (list.isEmpty) {
      children.add(const EmptyNote('ما كاين حتى تسجيل بهاد الفلاتر.'));
    }
    String? last;
    for (final t in list) {
      if (t.date != last) {
        last = t.date;
        final day = list.where((x) => x.date == t.date);
        final net = sum(day, 'in') - sum(day, 'out');
        children.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(niceDate(t.date), style: const TextStyle(color: C.muted)),
              Text(money(net),
                  style: TextStyle(color: net >= 0 ? C.green : C.red, fontWeight: FontWeight.w700)),
            ],
          ),
        ));
      }
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Panel(child: TxnTile(t: t, onTap: () => showTxnSheet(context, edit: t))),
      ));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: children,
    );
  }
}
