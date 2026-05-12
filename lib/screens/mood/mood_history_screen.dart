import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Paleta compartida de estados de ánimo
// ─────────────────────────────────────────────────────────────────────────────
class MoodData {
  static const moods = [
    _Mood(0, Icons.sentiment_very_dissatisfied_rounded,
        Color(0xFFEF4444), Color(0xFFFF8A80), 'Mal'),
    _Mood(1, Icons.sentiment_dissatisfied_rounded,
        Color(0xFFF97316), Color(0xFFFFAB40), 'No muy bien'),
    _Mood(2, Icons.sentiment_neutral_rounded,
        Color(0xFFF59E0B), Color(0xFFFFD740), 'Más o menos'),
    _Mood(3, Icons.sentiment_satisfied_rounded,
        Color(0xFF84CC16), Color(0xFFCCFF90), 'Bien'),
    _Mood(4, Icons.sentiment_very_satisfied_rounded,
        Color(0xFF22C55E), Color(0xFF69F0AE), 'Genial'),
  ];

  static String todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2,'0')}-${n.day.toString().padLeft(2,'0')}';
  }

  static String keyFor(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  static Future<void> save(int value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('moods').doc(todayKey())
        .set({
      'value': value,
      'label': moods[value].label,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, int>> loadRange(int days) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return {};
    final result = <String, int>{};
    for (int i = 0; i < days; i++) {
      final d = DateTime.now().subtract(Duration(days: i));
      final key = keyFor(d);
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('moods').doc(key).get();
      if (doc.exists) result[key] = (doc.data()!['value'] as int);
    }
    return result;
  }
}

class _Mood {
  final int value;
  final IconData icon;
  final Color color;
  final Color light;
  final String label;
  const _Mood(this.value, this.icon, this.color, this.light, this.label);
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantalla principal de historial de ánimo
// ─────────────────────────────────────────────────────────────────────────────
class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key});
  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary  = Color(0xFF2B5BFF);
  static const Color _bg       = Color(0xFFF4F6FB);
  static const Color _textMain = Color(0xFF0D1B3E);
  static const Color _textSub  = Color(0xFF8A94A6);

  late TabController _tabs;
  Map<String, int> _moodMap = {};
  bool _loading = true;
  DateTime _calMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final data = await MoodData.loadRange(90);
    if (mounted) setState(() { _moodMap = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mi Bienestar',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Gráfica'),
            Tab(icon: Icon(Icons.calendar_month_rounded), text: 'Calendario'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : TabBarView(controller: _tabs, children: [
              _ChartTab(moodMap: _moodMap),
              _CalendarTab(
                moodMap: _moodMap,
                month: _calMonth,
                onMonthChanged: (m) => setState(() => _calMonth = m),
              ),
            ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Gráfica de barras (últimos 14 días)
// ─────────────────────────────────────────────────────────────────────────────
class _ChartTab extends StatelessWidget {
  final Map<String, int> moodMap;
  static const Color _primary  = Color(0xFF2B5BFF);
  static const Color _textMain = Color(0xFF0D1B3E);
  static const Color _textSub  = Color(0xFF8A94A6);

  const _ChartTab({required this.moodMap});

  @override
  Widget build(BuildContext context) {
    final days = List.generate(14, (i) =>
        DateTime.now().subtract(Duration(days: 13 - i)));
    final values = days.map((d) => moodMap[MoodData.keyFor(d)]).toList();

    // Promedio
    final filled = values.whereType<int>().toList();
    final avg = filled.isEmpty ? null
        : filled.fold(0, (a, b) => a + b) / filled.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Resumen
        if (avg != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, const Color(0xFF6B8FFF)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              Icon(MoodData.moods[avg.round()].icon,
                  color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Estado promedio',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(MoodData.moods[avg.round()].label,
                    style: const TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Basado en ${filled.length} registros',
                    style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
        ],

        const Text('Últimos 14 días',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: _textMain)),
        const SizedBox(height: 16),

        // Gráfica de barras
        Container(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                blurRadius: 12)]),
          child: Column(children: [
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(14, (i) {
                  final v = values[i];
                  final d = days[i];
                  final color = v != null
                      ? MoodData.moods[v].color
                      : Colors.grey.shade200;
                  final h = v != null ? (v + 1) / 5.0 : 0.05;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (v != null)
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle)),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            height: 120 * h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: v != null
                                    ? [MoodData.moods[v].light, color]
                                    : [Colors.grey.shade100, Colors.grey.shade200],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter),
                              borderRadius: BorderRadius.circular(8)),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            ['L','M','X','J','V','S','D'][d.weekday - 1],
                            style: TextStyle(fontSize: 9, color: _textSub)),
                          Text('${d.day}',
                              style: TextStyle(fontSize: 8,
                                  color: _textSub.withOpacity(0.6))),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            // Leyenda
            Wrap(spacing: 12, runSpacing: 8,
              children: MoodData.moods.map((m) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10,
                      decoration: BoxDecoration(
                          color: m.color, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text(m.label, style: const TextStyle(fontSize: 10,
                      color: _textSub)),
                ],
              )).toList()),
          ]),
        ),

        const SizedBox(height: 24),

        // Lista de registros recientes
        const Text('Registros recientes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: _textMain)),
        const SizedBox(height: 12),
        ...days.reversed.take(7).where((d) =>
            moodMap.containsKey(MoodData.keyFor(d))).map((d) {
          final v = moodMap[MoodData.keyFor(d)]!;
          final m = MoodData.moods[v];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
                  blurRadius: 8)]),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: m.light.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(m.icon, color: m.color, size: 26)),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.label, style: const TextStyle(
                      fontWeight: FontWeight.w600, color: _textMain)),
                  Text('${d.day}/${d.month}/${d.year}',
                      style: const TextStyle(fontSize: 11, color: _textSub)),
                ],
              )),
              Icon(m.icon, color: m.color.withOpacity(0.3), size: 30),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Calendario mensual de estados
// ─────────────────────────────────────────────────────────────────────────────
class _CalendarTab extends StatelessWidget {
  final Map<String, int> moodMap;
  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;
  static const Color _primary  = Color(0xFF2B5BFF);
  static const Color _textMain = Color(0xFF0D1B3E);
  static const Color _textSub  = Color(0xFF8A94A6);

  const _CalendarTab({required this.moodMap, required this.month,
      required this.onMonthChanged});

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Offset para que empiece en lunes
    final startOffset = (firstDay.weekday - 1) % 7;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final monthNames = ['Enero','Febrero','Marzo','Abril','Mayo','Junio',
      'Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [

        // Navegación de mes
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                  blurRadius: 12)]),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              IconButton(
                onPressed: () => onMonthChanged(
                    DateTime(month.year, month.month - 1)),
                icon: const Icon(Icons.chevron_left_rounded, color: _primary)),
              Text('${monthNames[month.month - 1]} ${month.year}',
                  style: const TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold, color: _textMain)),
              IconButton(
                onPressed: () => onMonthChanged(
                    DateTime(month.year, month.month + 1)),
                icon: const Icon(Icons.chevron_right_rounded, color: _primary)),
            ]),

            // Días de semana
            const Row(
              children: [
                Expanded(child: Center(child: Text('L', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSub)))),
                Expanded(child: Center(child: Text('M', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSub)))),
                Expanded(child: Center(child: Text('X', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSub)))),
                Expanded(child: Center(child: Text('J', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSub)))),
                Expanded(child: Center(child: Text('V', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSub)))),
                Expanded(child: Center(child: Text('S', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSub)))),
                Expanded(child: Center(child: Text('D', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _textSub)))),
              ],
            ),
            const SizedBox(height: 8),

            // Grid de días
            ...List.generate(rows, (row) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  final dayNum = cellIndex - startOffset + 1;

                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 40));
                  }

                  final date = DateTime(month.year, month.month, dayNum);
                  final key = MoodData.keyFor(date);
                  final v = moodMap[key];
                  final m = v != null ? MoodData.moods[v] : null;
                  final isToday = date.year == DateTime.now().year &&
                      date.month == DateTime.now().month &&
                      date.day == DateTime.now().day;

                  return Expanded(
                    child: Container(
                      height: 42,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: m != null
                            ? m.light.withOpacity(0.45)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isToday
                            ? Border.all(color: _primary, width: 2)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (m != null)
                            Icon(m.icon, color: m.color, size: 16)
                          else
                            Text('$dayNum',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isToday ? _primary : _textSub)),
                          if (m != null)
                            Text('$dayNum',
                                style: TextStyle(fontSize: 9,
                                    color: m.color.withOpacity(0.8))),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            )),
          ]),
        ),

        const SizedBox(height: 20),

        // Leyenda
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Referencia de estados',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                      color: _textMain)),
              const SizedBox(height: 12),
              ...MoodData.moods.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: m.light.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(m.icon, color: m.color, size: 18)),
                  const SizedBox(width: 12),
                  Text(m.label, style: const TextStyle(fontSize: 13,
                      color: _textMain, fontWeight: FontWeight.w500)),
                ]),
              )),
            ],
          ),
        ),
      ]),
    );
  }
}
