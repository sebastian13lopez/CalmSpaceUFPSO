import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _primary   = Color(0xFF2B5BFF);
  static const Color _bg        = Color(0xFFF4F6FB);
  static const Color _textMain  = Color(0xFF0D1B3E);
  static const Color _textSub   = Color(0xFF8A94A6);

  int    _navIndex    = 0;
  int?   _moodIndex;
  String _nombre      = 'Usuario';
  String _role        = 'Paciente';
  bool   _loading     = true;

  final List<String> _moods = ['😢', '😕', '😐', '🙂', '😄'];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _nombre = user.displayName ?? user.email ?? 'Usuario';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _role   = data['role'] ?? 'Paciente';
          _nombre = data['name'] ?? _nombre;
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
            child: const Text('Cancelar', style: TextStyle(color: _textSub))),
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
      return const Scaffold(
        backgroundColor: _bg,
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
      bottomNavigationBar: _buildBottomNav(),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildHomeTab(),
          _buildPlaceholder(Icons.search_rounded, 'Buscar'),
          _buildPlaceholder(Icons.calendar_today_rounded, 'Agenda'),
          _buildPlaceholder(Icons.person_outline_rounded, 'Perfil'),
        ],
      ),
    );
  }

  // ── BOTTOM NAV ──────────────────────────────────────────────────────────────
  Widget _buildBottomNav() {
    final items = [
      (Icons.home_rounded,           'Home'),
      (Icons.search_rounded,         'Buscar'),
      (Icons.calendar_today_rounded, 'Agenda'),
      (Icons.person_outline_rounded, 'Perfil'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(
          color: _primary.withOpacity(0.4),
          blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = _navIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _navIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.white.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].$1,
                        color: isActive
                            ? Colors.white
                            : Colors.white54,
                        size: 24),
                      const SizedBox(height: 4),
                      Text(items[i].$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isActive
                              ? Colors.white
                              : Colors.white54)),
                      if (isActive) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 4, height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle)),
                      ]
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── HOME TAB ────────────────────────────────────────────────────────────────
  Widget _buildHomeTab() {
    final firstName = _nombre.split(' ').first;
    final isPsi = _role == 'Psicólogo';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── HEADER ──────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('¡Hola, $firstName!',
                      style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w900,
                        color: _textMain, letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text(isPsi
                        ? 'Panel del psicólogo'
                        : 'Que tengas un buen día',
                      style: const TextStyle(
                        fontSize: 13, color: _textSub)),
                  ],
                ),
                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    width: 46, height: 46,
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── SELECTOR DE ÁNIMO ────────────────────────────────────────────
            const Text('¿Cómo te sientes hoy?',
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: _textMain)),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(_moods.length, (i) {
                final isSelected = _moodIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _moodIndex = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primary.withOpacity(0.12)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? _primary : Colors.transparent,
                        width: 2),
                      boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: Center(
                      child: Text(_moods[i],
                        style: TextStyle(
                          fontSize: isSelected ? 28 : 24))),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // ── TARJETA MOTIVACIONAL ─────────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(
                children: [
                  // Imagen de naturaleza
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24)),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFB8D4F0), Color(0xFFD4E8C2)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter)),
                        child: const Center(
                          child: Icon(Icons.landscape_rounded,
                            size: 60, color: Colors.white70)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      children: [
                        const Text('Hoy va a ser un gran día',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold,
                            color: _textMain)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14))),
                            child: const Text('Siguiente',
                              style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold,
                                color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── PRÓXIMA CITA ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  // Avatar psicólogo
                  Stack(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EEFF),
                          borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.person_rounded,
                          color: _primary, size: 30),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white, width: 2)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dra. Martínez',
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold,
                            color: _textMain)),
                        SizedBox(height: 2),
                        Text('Jueves 4:00 PM',
                          style: TextStyle(
                            fontSize: 12, color: _textSub)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Chat — próximamente'))),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: const BorderSide(color: _primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8)),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                    label: const Text('Chat',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── PSICÓLOGOS DISPONIBLES ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Psicólogos Disponibles',
                  style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold,
                    color: _textMain)),
                GestureDetector(
                  onTap: () {},
                  child: const Text('Ver todos',
                    style: TextStyle(
                      fontSize: 13, color: _primary,
                      fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _PsychCard(
                  name: 'Dr. Alejandro Ruiz',
                  specialty: 'Psicólogo Clínico',
                  rating: 4.9)),
                const SizedBox(width: 12),
                Expanded(child: _PsychCard(
                  name: 'Dra. Carolina López',
                  specialty: 'Psicóloga',
                  rating: 4.8)),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── PLACEHOLDER TABS ────────────────────────────────────────────────────────
  Widget _buildPlaceholder(IconData icon, String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: _primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(label,
            style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: _textSub)),
          const SizedBox(height: 8),
          const Text('Próximamente',
            style: TextStyle(fontSize: 13, color: _textSub)),
        ],
      ),
    );
  }
}

// ── TARJETA PSICÓLOGO ────────────────────────────────────────────────────────
class _PsychCard extends StatelessWidget {
  final String name;
  final String specialty;
  final double rating;

  static const Color _primary  = Color(0xFF2B5BFF);
  static const Color _textMain = Color(0xFF0D1B3E);
  static const Color _textSub  = Color(0xFF8A94A6);

  const _PsychCard({
    required this.name,
    required this.specialty,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + En línea
          Stack(
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.person_rounded,
                  color: _primary, size: 30),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(name,
            style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, color: _textMain),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(specialty,
            style: const TextStyle(fontSize: 11, color: _textSub)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 14),
              const SizedBox(width: 3),
              Text(rating.toString(),
                style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: _textMain)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 7, height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('En línea',
                style: TextStyle(
                  fontSize: 11, color: Color(0xFF22C55E),
                  fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}