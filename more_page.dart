import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'db.dart';
import 'state.dart';
import 'util.dart';
import 'widgets.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});
  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final catCtrl = TextEditingController();
  String? catErr;

  @override
  void dispose() {
    catCtrl.dispose();
    super.dispose();
  }

  Future<void> addCat() async {
    final n = catCtrl.text.trim();
    if (n.isEmpty) {
      setState(() => catErr = 'كتب سمية الفئة');
      return;
    }
    final ok = await appState.addCat(n);
    if (!mounted) return;
    setState(() => catErr = ok ? null : 'هاد الفئة كاينة ديجا');
    if (ok) catCtrl.clear();
  }

  Future<void> exportBackup() async {
    final s = await appState.export();
    await Clipboard.setData(ClipboardData(text: s));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تكوبى النص. لصقو فواتساب ولا نوط وسيفطو ليك.')),
    );
  }

  Future<void> restoreBackup() async {
    final n = await showDialog<int>(
      context: context,
      builder: (_) => const _RestoreDialog(),
    );
    if (n != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تسترجعو $n تسجيل ✓')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const Text('المزيد', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SectionTitle('فئات المصاريف'),
        Panel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: appState.cats
                    .map((c) => InputChip(
                          label: Text(c.name),
                          onDeleted: () async {
                            final ok = await confirmDialog(
                                context, 'مسح فئة "${c.name}"؟ التسجيلات القديمة غادي تبقى.');
                            if (ok) await appState.deleteCat(c.id);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: catCtrl,
                      maxLength: 30,
                      decoration: InputDecoration(
                        hintText: 'فئة جديدة',
                        errorText: catErr,
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: addCat, child: const Text('زيد')),
                ],
              ),
            ],
          ),
        ),
        const SectionTitle('الخدمات (الاسم والثمن)'),
        Panel(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              if (appState.services.isEmpty)
                const EmptyNote('زيد الخدمات اللي كتدير بالثمن ديالها.'),
              ...appState.services.map((s) => Row(
                    children: [
                      Expanded(child: Text(s.name)),
                      Text('${money(s.price)} درهم',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => _ServiceDialog(edit: s),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: C.red),
                        onPressed: () async {
                          final ok = await confirmDialog(context, 'مسح هاد الخدمة؟');
                          if (ok) await appState.deleteService(s.id!);
                        },
                      ),
                    ],
                  )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const _ServiceDialog(),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('خدمة جديدة'),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('النسخة الاحتياطية'),
        Panel(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'كوبي النسخة وسيفطها ليك فواتساب ولا نوط. ملي تبغي ترجعها، لصقها فالاسترجاع.',
                style: TextStyle(color: C.muted),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: exportBackup,
                icon: const Icon(Icons.copy),
                label: const Text('كوبي النسخة الاحتياطية'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: restoreBackup,
                icon: const Icon(Icons.restore),
                label: const Text('استرجاع من نسخة'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Column(
            children: [
              LogoMark(size: 40),
              SizedBox(height: 6),
              Text('Flosi 1.0', style: TextStyle(color: C.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceDialog extends StatefulWidget {
  final Service? edit;
  const _ServiceDialog({this.edit});
  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  final name = TextEditingController();
  final price = TextEditingController();
  String? nameErr;
  String? priceErr;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    if (e != null) {
      name.text = e.name;
      price.text =
          e.price == e.price.roundToDouble() ? e.price.toStringAsFixed(0) : e.price.toString();
    }
  }

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final n = name.text.trim();
    final p = parseAmount(price.text);
    setState(() {
      nameErr = n.isEmpty ? 'كتب سمية الخدمة' : null;
      priceErr = p <= 0 ? 'كتب ثمن صحيح' : null;
    });
    if (nameErr != null || priceErr != null) return;
    final nav = Navigator.of(context);
    await appState.saveService(Service(id: widget.edit?.id, name: n, price: p));
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.edit == null ? 'خدمة جديدة' : 'تعديل الخدمة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: InputDecoration(labelText: 'سمية الخدمة', errorText: nameErr),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'الثمن (درهم)', errorText: priceErr),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: save, child: const Text('سجل')),
      ],
    );
  }
}

class _RestoreDialog extends StatefulWidget {
  const _RestoreDialog();
  @override
  State<_RestoreDialog> createState() => _RestoreDialogState();
}

class _RestoreDialogState extends State<_RestoreDialog> {
  final ctrl = TextEditingController();
  String? err;
  bool armed = false;
  bool busy = false;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  Future<void> paste() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    if (d?.text != null) setState(() => ctrl.text = d!.text!);
  }

  Future<void> restore() async {
    if (ctrl.text.trim().isEmpty) {
      setState(() => err = 'لصق النسخة أول.');
      return;
    }
    if (!armed) {
      setState(() {
        armed = true;
        err = 'غادي يتبدل كلشي فالتطبيق بهاد النسخة. ضغط على "أكد" إيلا متأكد.';
      });
      return;
    }
    setState(() => busy = true);
    final nav = Navigator.of(context);
    try {
      final n = await appState.import(ctrl.text);
      nav.pop(n);
    } on FormatException catch (e) {
      setState(() {
        busy = false;
        armed = false;
        err = e.message;
      });
    } catch (e) {
      setState(() {
        busy = false;
        armed = false;
        err = 'وقع مشكل: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('استرجاع من نسخة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ctrl,
            maxLines: 6,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(hintText: 'لصق النسخة هنا'),
            onChanged: (_) => setState(() {
              armed = false;
              err = null;
            }),
          ),
          TextButton.icon(
            onPressed: paste,
            icon: const Icon(Icons.paste, size: 18),
            label: const Text('لصق من الحافظة'),
          ),
          if (err != null)
            Text(err!, style: TextStyle(color: armed ? C.gold : C.red, fontSize: 13)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(
          onPressed: busy ? null : restore,
          child: Text(armed ? 'أكد' : 'استرجع'),
        ),
      ],
    );
  }
}
