import 'package:flutter/material.dart';
import '../configuracion/configuracion_pantalla.dart';
import '../productos/lista_productos.dart';
import '../combos/lista_combos.dart';
import '../../widgets/tarjeta_menu.dart';

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 32, 22, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text('GESTOR DE COMBOS', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: .7)),
                    const SizedBox(height: 28),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TarjetaMenu(icono: Icons.card_giftcard_rounded, titulo: 'COMBOS', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListaCombos()))),
                          const SizedBox(height: 16),
                          TarjetaMenu(icono: Icons.lunch_dining_rounded, titulo: 'PRODUCTOS', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListaProductos()))),
                          const SizedBox(height: 16),
                          TarjetaMenu(icono: Icons.settings_rounded, titulo: 'CONFIGURACIÓN', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfiguracionPantalla()))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
