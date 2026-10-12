import 'package:flutter/material.dart';
import '../temas/colores.dart';

class TarjetaMenu extends StatelessWidget {
  const TarjetaMenu({super.key, required this.icono, required this.titulo, required this.onTap});
  final IconData icono;
  final String titulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark ? ColoresApp.naranjaOscuro : ColoresApp.naranjaClaro;
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: color, width: 2)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icono, size: 42, color: color), const SizedBox(height: 10), Text(titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: .5))],
          ),
        ),
      ),
    );
  }
}
