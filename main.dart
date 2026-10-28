import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'history_page.dart';
import 'home_page.dart';
import 'loans_page.dart';
import 'more_page.dart';
import 'reports_page.dart';
import 'state.dart';
import 'txn_sheet.dart';
import 'util.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlosiApp());
}

class FlosiApp extends StatelessWidget {
  const FlosiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flosi',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  Object? loadError;

  @override
  void initState() {
    super.initState();
    appState.load().catchError((Object e) {
      setState(() => loadError = e);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (loadError != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('ما قدرناش نحلو قاعدة البيانات: $loadError'),
              ),
            ),
          );
        }
        if (!appState.ready) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final pages = <Widget>[
          const HomePage(),
          const HistoryPage(),
          const ReportsPage(),
          const LoansPage(),
          const MorePage(),
        ];
        return Scaffold(
          body: SafeArea(child: pages[tab]),
          floatingActionButton: tab <= 1
              ? FloatingActionButton.extended(
                  onPressed: () => showTxnSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('معاملة جديدة'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            onDestinationSelected: (i) => setState(() => tab = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'الرئيسية'),
              NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: 'السجل'),
              NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'التقارير'),
              NavigationDestination(
                  icon: Icon(Icons.handshake_outlined),
                  selectedIcon: Icon(Icons.handshake),
                  label: 'السلف'),
              NavigationDestination(
                  icon: Icon(Icons.more_horiz),
                  selectedIcon: Icon(Icons.more_horiz),
                  label: 'المزيد'),
            ],
          ),
        );
      },
    );
  }
}
