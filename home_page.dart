import 'package:flutter/material.dart';
import 'state.dart';
import 'txn_sheet.dart';
import 'util.dart';
import 'widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayKey = ymd(now);
    final monthKey = todayKey.substring(0, 7);
    final month = appState.txns.where((t) => t.date.startsWith(monthKey)).toList();
    final today = appState.txns.where((t) => t.date == todayKey).toList();
    final mi = sum(month, 'in');
    final mo = sum(month, 'out');
    final net = mi - mo;
    final total = sum(appState.txns, 'in') - sum(appState.txns, 'out');
    final recent = appState.txns.take(8).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        const Row(
          children: [
            LogoMark(),
            SizedBox(width: 12),
            Text('Flosi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 16),
        Panel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الباقي فـ ${monthNames[now.month - 1]}',
                  style: const TextStyle(color: C.muted)),
              const SizedBox(height: 4),
              Text(
                '${money(net)} درهم',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: net >= 0 ? C.green : C.red,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: StatBox(label: 'دخل', value: mi, color: C.green)),
                  const SizedBox(width: 10),
                  Expanded(child: StatBox(label: 'مصاريف', value: mo, color: C.red)),
                ],
              ),
              const SizedBox(height: 12),
              Text('الرصيد الإجمالي: ${money(total)} درهم',
                  style: const TextStyle(color: C.muted)),
            ],
          ),
        ),
        const SectionTitle('اليوم'),
        Panel(
          child: today.isEmpty
              ? const EmptyNote('ما كاين حتى تسجيل اليوم.')
              : Column(
                  children: today
                      .map((t) => TxnTile(t: t, onTap: () => showTxnSheet(context, edit: t)))
                      .toList(),
                ),
        ),
        const SectionTitle('آخر التسجيلات'),
        Panel(
          child: recent.isEmpty
              ? const EmptyNote('ضغط على "معاملة جديدة" باش تبدا.')
              : Column(
                  children: recent
                      .map((t) => TxnTile(
                            t: t,
                            showDate: true,
                            onTap: () => showTxnSheet(context, edit: t),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}
