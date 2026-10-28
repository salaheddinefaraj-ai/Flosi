import 'package:flutter/material.dart';
import 'db.dart';
import 'state.dart';
import 'txn_sheet.dart';
import 'util.dart';
import 'widgets.dart';

class _Range {
  final DateTime start;
  final DateTime end;
  final String label;
  const _Range(this.start, this.end, this.label);
}

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String period = 'month';
  DateTime anchor = DateTime.now();

  _Range _range() {
    final a = DateTime(anchor.year, anchor.month, anchor.day);
    switch (period) {
      case 'day':
        return _Range(a, a, niceDate(ymd(a)));
      case 'week':
        final s = DateTime(a.year, a.month, a.day - (a.weekday - 1));
        final e = DateTime(s.year, s.month, s.day + 6);
        return _Range(s, e, '${s.day}/${s.month} - ${e.day}/${e.month}/${e.year}');
      case 'year':
        return _Range(DateTime(a.year, 1, 1), DateTime(a.year, 12, 31), '${a.year}');
      default:
        return _Range(
          DateTime(a.year, a.month, 1),
          DateTime(a.year, a.month + 1, 0),
          '${monthNames[a.month - 1]} ${a.year}',
        );
    }
  }

  void _step(int k) {
    setState(() {
      switch (period) {
        case 'day':
          anchor = DateTime(anchor.year, anchor.month, anchor.day + k);
          break;
        case 'week':
          anchor = DateTime(anchor.year, anchor.month, anchor.day + 7 * k);
          break;
        case 'year':
          anchor = DateTime(anchor.year + k, anchor.month, 1);
          break;
        default:
          anchor = DateTime(anchor.year, anchor.month + k, 1);
      }
    });
  }

  Map<String, double> _group(List<Txn> list, String type) {
    final m = <String, double>{};
    for (final t in list) {
      if (t.type == type) m[t.title] = (m[t.title] ?? 0) + t.amount;
    }
    return m;
  }

  Widget _bars(String title, Map<String, double> m, Color color) {
    final entries = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: entries.isEmpty
              ? const EmptyNote('ما كاين والو.')
              : Column(
                  children: entries
                      .map((e) => BarRow(label: e.key, value: e.value, total: total, color: color))
                      .toList(),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _range();
    final from = ymd(r.start);
    final to = ymd(r.end);
    final list = appState.txns
        .where((t) => t.date.compareTo(from) >= 0 && t.date.compareTo(to) <= 0)
        .toList();
    final i = sum(list, 'in');
    final o = sum(list, 'out');

    final buckets = <String, List<Txn>>{};
    if (period != 'day') {
      for (final t in list) {
        final k = period == 'year' ? t.date.substring(0, 7) : t.date;
        buckets.putIfAbsent(k, () => []).add(t);
      }
    }
    final keys = buckets.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: 'day', label: Text('يومي')),
            ButtonSegment(value: 'week', label: Text('أسبوعي')),
            ButtonSegment(value: 'month', label: Text('شهري')),
            ButtonSegment(value: 'year', label: Text('سنوي')),
          ],
          selected: {period},
          onSelectionChanged: (s) => setState(() {
            period = s.first;
            anchor = DateTime.now();
          }),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(onPressed: () => _step(-1), icon: const Icon(Icons.chevron_right)),
            Expanded(
              child: Text(r.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            IconButton(onPressed: () => _step(1), icon: const Icon(Icons.chevron_left)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: StatBox(label: 'دخل', value: i, color: C.green)),
            const SizedBox(width: 8),
            Expanded(child: StatBox(label: 'مصاريف', value: o, color: C.red)),
            const SizedBox(width: 8),
            Expanded(child: StatBox(label: 'الباقي', value: i - o, color: i - o >= 0 ? C.green : C.red)),
          ],
        ),
        _bars('فين خدمتي', _group(list, 'in'), C.green),
        _bars('فين مشات الفلوس', _group(list, 'out'), C.red),
        if (period == 'day') ...[
          const SectionTitle('تسجيلات النهار'),
          Panel(
            child: list.isEmpty
                ? const EmptyNote('ما كاين والو.')
                : Column(
                    children: list
                        .map((t) => TxnTile(t: t, onTap: () => showTxnSheet(context, edit: t)))
                        .toList(),
                  ),
          ),
        ] else ...[
          SectionTitle(period == 'year' ? 'الشهور' : 'النهارات'),
          Panel(
            child: keys.isEmpty
                ? const EmptyNote('ما كاين والو.')
                : Column(
                    children: keys.map((k) {
                      final day = buckets[k]!;
                      final label = period == 'year'
                          ? monthNames[int.parse(k.substring(5, 7)) - 1]
                          : niceDate(k);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(child: Text(label)),
                            SizedBox(
                              width: 80,
                              child: Text(money(sum(day, 'in')),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(color: C.green)),
                            ),
                            SizedBox(
                              width: 80,
                              child: Text(money(sum(day, 'out')),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(color: C.red)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ],
    );
  }
}
