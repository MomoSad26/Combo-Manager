import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logica/formato_numeros.dart';
import '../../providers/configuracion_provider.dart';
import '../configuracion/configuracion_pantalla.dart';
import '../productos/lista_productos.dart';
import '../combos/lista_combos.dart';
import '../../widgets/tarjeta_menu.dart';

class MenuPrincipal extends StatelessWidget {
  const MenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    final configuracion =
        context.watch<ConfiguracionProvider>().configuracion;
    final esModoOscuro = Theme.of(context).brightness == Brightness.dark;

    void abrirConfiguracion() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ConfiguracionPantalla(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 32, 22, 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'GESTOR DE COMBOS',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: .7,
                        ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TarjetaMenu(
                          icono: Icons.card_giftcard_rounded,
                          titulo: 'COMBOS',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ListaCombos(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TarjetaMenu(
                          icono: Icons.lunch_dining_rounded,
                          titulo: 'PRODUCTOS',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ListaProductos(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TarjetaMenu(
                          icono: Icons.settings_rounded,
                          titulo: 'CONFIGURACIÓN',
                          onTap: abrirConfiguracion,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: abrirConfiguracion,
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Margen: ${FormatoNumeros.moneda(configuracion.margen)}'
                                ' | Tasa: ${FormatoNumeros.moneda(configuracion.tasaReferencia)}',
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 14,
                                      color: esModoOscuro
                                          ? const Color(0xFFB0B0B0)
                                          : const Color(0xFF6B6B6B),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
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
}
