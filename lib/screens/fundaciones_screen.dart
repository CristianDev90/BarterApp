import 'package:flutter/material.dart';

class FundacionesScreen extends StatelessWidget {
  const FundacionesScreen({super.key});

  static const _verde      = Color(0xFF2D5A27);
  static const _verdeMedio = Color(0xFF4A7A3F);
  static const _fondo      = Color(0xFFEBE6D6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondo,
      appBar: AppBar(
        backgroundColor: _fondo,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: _verde.withValues(alpha: 0.6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Fundaciones',
          style: TextStyle(
            color: _verde,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // ── Ícono principal ──────────────────────────────────────────
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _verde.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _verde.withValues(alpha: 0.12), width: 2),
              ),
              child: Icon(
                Icons.volunteer_activism_rounded,
                size: 56,
                color: _verde,
              ),
            ),
            const SizedBox(height: 24),

            // ── Badge "Próximamente" ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _verde,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                '🌱 Próximamente',
                style: TextStyle(
                  color: _fondo,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Título ───────────────────────────────────────────────────
            Text(
              'Conexiones con fundaciones\ny organizaciones',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _verde,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 14),

            // ── Descripción ──────────────────────────────────────────────
            Text(
              'Estamos trabajando para conectar a nuestra comunidad '
              'con fundaciones y organizaciones sociales. '
              'Muy pronto podrás donar, colaborar y hacer parte '
              'del cambio desde BarterApp.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _verdeMedio,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 40),

            // ── Tarjetas de funciones futuras ────────────────────────────
            _buildTarjetaFutura(
              icono: Icons.handshake_outlined,
              titulo: 'Conexión con fundaciones',
              descripcion:
                  'Encuentra fundaciones cercanas a ti y conecta con su causa.',
            ),
            const SizedBox(height: 14),
            _buildTarjetaFutura(
              icono: Icons.favorite_border_rounded,
              titulo: 'Donaciones de objetos',
              descripcion:
                  'Dona artículos que ya no usas directamente a organizaciones.',
            ),
            const SizedBox(height: 14),
            _buildTarjetaFutura(
              icono: Icons.groups_outlined,
              titulo: 'Voluntariado',
              descripcion:
                  'Participa en actividades y eventos de impacto social.',
            ),
            const SizedBox(height: 14),
            _buildTarjetaFutura(
              icono: Icons.business_outlined,
              titulo: 'Alianzas con empresas',
              descripcion:
                  'Empresas comprometidas con el medio ambiente y la comunidad.',
            ),
            const SizedBox(height: 40),

            // ── Mensaje final ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _verde.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _verde.withValues(alpha: 0.1)),
              ),
              child: Column(
                children: [
                  Text('🌍',
                      style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 12),
                  Text(
                    'Juntos construimos\nuna comunidad mejor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _verde,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta función estará disponible en una próxima versión de BarterApp.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _verdeMedio,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTarjetaFutura({
    required IconData icono,
    required String titulo,
    required String descripcion,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _fondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _verde.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _verde.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: _verde, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        titulo,
                        style: TextStyle(
                          color: _verde,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _verde.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        'Pronto',
                        style: TextStyle(
                          color: _verde.withValues(alpha: 0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  descripcion,
                  style: TextStyle(
                    color: _verdeMedio,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 