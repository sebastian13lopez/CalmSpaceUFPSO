import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primary  = Color(0xFF2B5BFF);
  static const Color _bg       = Color(0xFFF4F6FB);
  static const Color _textMain = Color(0xFF0D1B3E);
  static const Color _textSub  = Color(0xFF8A94A6);

  int    _navIndex  = 0;
  int?   _moodIndex;
  String _nombre    = '';
  String _email     = '';
  String _role      = 'Paciente';
  String _status    = 'activo';
  bool   _loading   = true;

  // IMAGEN MOTIVACIONAL — cambia esta URL por la que prefieras
  static const String _motivationalImageUrl =
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80';

  // Íconos de ánimo (más profesionales que emojis)
  static const List<_MoodOption> _moods = [
    _MoodOption(Icons.sentiment_very_dissatisfied_rounded, Color(0xFFEF4444), 'Muy mal'),
    _MoodOption(Icons.sentiment_dissatisfied_rounded,      Color(0xFFF97316), 'Mal'),
    _MoodOption(Icons.sentiment_neutral_rounded,           Color(0xFFF59E0B), 'Regular'),
    _MoodOption(Icons.sentiment_satisfied_rounded,         Color(0xFF84CC16), 'Bien'),
    _MoodOption(Icons.sentiment_very_satisfied_rounded,    Color(0xFF22C55E), 'Muy bien'),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _nombre = user.displayName ?? '';
      _email  = user.email ?? '';
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final d = doc.data()!;
        setState(() {
          _role   = d['role']   ?? 'Paciente';
          _status = d['status'] ?? 'activo';
          _nombre = d['name']   ?? _nombre;
          _email  = d['email']  ?? _email;
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salir',
                  style: TextStyle(color: Colors.redAccent,
                      fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (ok == true) await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: _bg,
          body: Center(child: CircularProgressIndicator(color: _primary)));
    }
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Llamadas — próximamente'))),
        backgroundColor: _primary,
        child: const Icon(Icons.phone_rounded, color: Colors.white),
      ),
      bottomNavigationBar: _BottomNav(
        current: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
      body: IndexedStack(index: _navIndex, children: [
        _HomeTab(
          nombre: _nombre,
          role: _role,
          moodIndex: _moodIndex,
          moods: _moods,
          imageUrl: _motivationalImageUrl,
          onMoodTap: (i) => setState(() => _moodIndex = i),
          onLogout: _logout,
        ),
        const _ComingSoon(Icons.search_rounded, 'Buscar Psicólogos',
            'HU-06 — próximamente'),
        const _ComingSoon(Icons.calendar_today_rounded, 'Agenda',
            'HU-05 — próximamente'),
        _ProfileTab(
            nombre: _nombre, email: _email, role: _role, onLogout: _logout),
      ]),
    );
  }
}

// ── BOTTOM NAV ────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  static const Color _primary = Color(0xFF2B5BFF);
  static const _items = [
    (Icons.home_rounded, 'Home'),
    (Icons.search_rounded, 'Buscar'),
    (Icons.calendar_today_rounded, 'Agenda'),
    (Icons.person_outline_rounded, 'Perfil'),
  ];
  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(
            color: _primary.withOpacity(0.4),
            blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final active = current == i;
              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? Colors.white.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_items[i].$1,
                        color: active ? Colors.white : Colors.white54, size: 24),
                    const SizedBox(height: 4),
                    Text(_items[i].$2,
                        style: TextStyle(
                          fontSize: 11, color: active ? Colors.white : Colors.white54,
                          fontWeight: active ? FontWeight.w700 : FontWeight.normal)),
                    if (active) ...[
                      const SizedBox(height: 4),
                      Container(width: 4, height: 4,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle)),
                    ],
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── HOME TAB ──────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final String nombre;
  final String role;
  final int? moodIndex;
  final List<_MoodOption> moods;
  final String imageUrl;
  final ValueChanged<int> onMoodTap;
  final VoidCallback onLogout;

  static const Color _primary  = Color(0xFF2B5BFF);
  static const Color _textMain = Color(0xFF0D1B3E);
  static const Color _textSub  = Color(0xFF8A94A6);

  const _HomeTab({
    required this.nombre, required this.role, required this.moodIndex,
    required this.moods, required this.imageUrl,
    required this.onMoodTap, required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final first = nombre.split(' ').first.isNotEmpty ? nombre.split(' ').first : 'Usuario';
    final inicial = first[0].toUpperCase();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // HEADER
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('¡Hola, $first!',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                      color: _textMain, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text(role == 'Psicólogo' ? 'Panel del psicólogo' : 'Que tengas un buen día',
                  style: const TextStyle(fontSize: 13, color: _textSub)),
            ]),
            GestureDetector(
              onTap: onLogout,
              child: Container(
                width: 46, height: 46,
                decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                child: Center(child: Text(inicial,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        color: Colors.white))),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // SELECTOR DE ÁNIMO — íconos profesionales
          const Text('¿Cómo te sientes hoy?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textMain)),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(moods.length, (i) {
              final sel = moodIndex == i;
              final m = moods[i];
              return GestureDetector(
                onTap: () => onMoodTap(i),
                child: Tooltip(message: m.label,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: sel ? m.color.withOpacity(0.15) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: sel ? m.color : Colors.grey.shade200, width: 2),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Icon(m.icon, color: sel ? m.color : Colors.grey.shade400,
                        size: sel ? 30 : 26),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 24),

          // TARJETA MOTIVACIONAL
          // 🖼️ Para cambiar la imagen: modifica _motivationalImageUrl en la clase HomeScreen
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
                  blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Column(children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(imageUrl,
                  height: 160, width: double.infinity, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFB8D4F0), Color(0xFFD4E8C2)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                    child: const Icon(Icons.landscape_rounded, size: 60, color: Colors.white70)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(children: [
                  const Text('Hoy va a ser un gran día',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                          color: _textMain)),
                  const SizedBox(height: 16),
                  SizedBox(width: double.infinity, height: 48,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _primary, elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14))),
                      child: const Text('Siguiente',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // PSICÓLOGOS DISPONIBLES — Firestore en tiempo real
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Psicólogos Disponibles',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textMain)),
            Text('Ver todos',
                style: const TextStyle(fontSize: 13, color: _primary,
                    fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 14),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'Psicólogo')
                .where('status', isEqualTo: 'activo')
                .limit(4)
                .snapshots(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: _primary)));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20)),
                  child: const Column(children: [
                    Icon(Icons.people_outline_rounded,
                        size: 40, color: Color(0xFFCBD5E1)),
                    SizedBox(height: 10),
                    Text('Aún no hay psicólogos disponibles',
                        style: TextStyle(fontSize: 13, color: _textSub)),
                  ]),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12,
                    mainAxisSpacing: 12, childAspectRatio: 0.85),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  return _PsychCard(
                    name:      d['name']      ?? 'Sin nombre',
                    specialty: d['specialty'] ?? 'Psicólogo',
                    rating:    (d['rating']   as num?)?.toDouble(),
                    modality:  d['modality']  ?? '',
                  );
                },
              );
            },
          ),

          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

// ── TARJETA PSICÓLOGO ─────────────────────────────────────────────────────────
class _PsychCard extends StatelessWidget {
  final String name, specialty, modality;
  final double? rating;
  static const Color _primary  = Color(0xFF2B5BFF);
  static const Color _textMain = Color(0xFF0D1B3E);
  static const Color _textSub  = Color(0xFF8A94A6);

  const _PsychCard({required this.name, required this.specialty,
      this.rating, required this.modality});

  @override
  Widget build(BuildContext context) {
    final inicial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          Container(width: 52, height: 52,
            decoration: BoxDecoration(color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(inicial,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                    color: _primary))),
          ),
          Positioned(bottom: 0, right: 0,
            child: Container(width: 12, height: 12,
              decoration: BoxDecoration(color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2))),
          ),
        ]),
        const SizedBox(height: 10),
        Text(name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                color: _textMain),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(specialty, style: const TextStyle(fontSize: 11, color: _textSub)),
        if (rating != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
            const SizedBox(width: 3),
            Text(rating!.toStringAsFixed(1),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: _textMain)),
          ]),
        ],
        const SizedBox(height: 4),
        Row(children: [
          Container(width: 7, height: 7,
              decoration: const BoxDecoration(
                  color: Color(0xFF22C55E), shape: BoxShape.circle)),
          const SizedBox(width: 5),
          const Text('En línea',
              style: TextStyle(fontSize: 11, color: Color(0xFF22C55E),
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}

// ── PERFIL TAB (HU-04 se conectará cuando se haga merge) ─────────────────────
class _ProfileTab extends StatelessWidget {
  final String nombre, email, role;
  final VoidCallback onLogout;
  static const Color _primary  = Color(0xFF2B5BFF);
  static const Color _bg       = Color(0xFFF4F6FB);
  static const Color _textMain = Color(0xFF0D1B3E);
  static const Color _textSub  = Color(0xFF8A94A6);

  const _ProfileTab({required this.nombre, required this.email,
      required this.role, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 16),
          // Avatar
          Container(
            width: 90, height: 90,
            decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
            child: Center(child: Text(inicial,
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                    color: Colors.white))),
          ),
          const SizedBox(height: 16),
          Text(nombre.isNotEmpty ? nombre : 'Usuario',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                  color: _textMain)),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(fontSize: 13, color: _textSub)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20)),
            child: Text(role,
                style: const TextStyle(fontSize: 12, color: _primary,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 32),

          // Acciones
          _ProfileAction(
            icon: Icons.edit_outlined,
            label: 'Editar perfil',
            subtitle: 'HU-04 — completar perfil',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Disponible en HU-04'))),
          ),
          _ProfileAction(
            icon: Icons.lock_outline_rounded,
            label: 'Seguridad',
            onTap: () {},
          ),
          _ProfileAction(
            icon: Icons.notifications_none_rounded,
            label: 'Notificaciones',
            onTap: () {},
          ),

          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Cerrar Sesión',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  static const Color _primary  = Color(0xFF2B5BFF);
  static const Color _textMain = Color(0xFF0D1B3E);
  static const Color _textSub  = Color(0xFF8A94A6);

  const _ProfileAction({required this.icon, required this.label,
      this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8)]),
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: _primary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14,
          fontWeight: FontWeight.w600, color: _textMain)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(fontSize: 11, color: _textSub))
          : null,
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
    ),
  );
}

// ── COMING SOON ───────────────────────────────────────────────────────────────
class _ComingSoon extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  static const Color _primary = Color(0xFF2B5BFF);
  static const Color _textSub = Color(0xFF8A94A6);

  const _ComingSoon(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 64, color: _primary.withOpacity(0.3)),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontSize: 20,
          fontWeight: FontWeight.bold, color: _textSub)),
      const SizedBox(height: 8),
      Text(subtitle, style: const TextStyle(fontSize: 13, color: _textSub)),
    ]),
  );
}

// ── MOOD OPTION ───────────────────────────────────────────────────────────────
class _MoodOption {
  final IconData icon;
  final Color color;
  final String label;
  const _MoodOption(this.icon, this.color, this.label);
}