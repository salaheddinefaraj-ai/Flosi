import 'package:flutter/material.dart';
import 'db.dart';
import 'util.dart';

class LogoMark extends StatelessWidget {
  final double size;
  const LogoMark({super.key, this.size = 44});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: C.deep,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Center(
        child: Container(
          width: size * 0.68,
          height: size * 0.68,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: C.gold, shape: BoxShape.circle),
          child: Text(
            'F',
            style: TextStyle(
              color: C.deep,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.line),
      ),
      child: child,
    );
  }
}

class StatBox extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const StatBox({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: C.muted, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              money(value),
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
    );
  }
}

class EmptyNote extends StatelessWidget {
  final String text;
  const EmptyNote(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(child: Text(text, style: const TextStyle(color: C.muted))),
    );
  }
}

class BarRow extends StatelessWidget {
  final String label;
  final double value;
  final double total;
  final Color color;
  const BarRow({
    super.key,
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text(label)),
              Text('${money(value)} درهم', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: total > 0 ? value / total : 0,
            minHeight: 6,
            backgroundColor: C.line,
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}

class TxnTile extends StatelessWidget {
  final Txn t;
  final VoidCallback onTap;
  final bool showDate;
  const TxnTile({super.key, required this.t, required this.onTap, this.showDate = false});
  @override
  Widget build(BuildContext context) {
    final color = t.isIn ? C.green : C.red;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withAlpha(40),
              child: Icon(t.isIn ? Icons.south_west : Icons.north_east, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (showDate)
                    Text(niceDate(t.date), style: const TextStyle(color: C.muted, fontSize: 12)),
                  if (t.note.isNotEmpty)
                    Text(t.note, style: const TextStyle(color: C.muted, fontSize: 12)),
                ],
              ),
            ),
            Text(
              '${t.isIn ? '+' : '−'}${money(t.amount)}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String text, {String yes = 'مسح'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(yes, style: const TextStyle(color: C.red)),
        ),
      ],
    ),
  );
  return r ?? false;
}
