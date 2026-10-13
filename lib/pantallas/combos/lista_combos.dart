import 'dart:ui' show Offset;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logica/compartir_combo.dart';
import '../../logica/buscador_inteligente.dart';
import '../../logica/formato_numeros.dart';
import '../../modelos/combo.dart';
import '../../providers/combo_provider.dart';
import '../../temas/colores.dart';
import '../../widgets/boton_volver.dart';
import '../../widgets/dialogo_confirmacion.dart';
import 'detalle_combo.dart';

class ListaCombos extends StatefulWidget {
  const ListaCombos({super.key});

  @override
  State<ListaCombos> createState() => _ListaCombosState();
}

class _ListaCombosState extends State<ListaCombos> {
  final TextEditingController _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _crearCombo(BuildContext context) async {
    final controller = TextEditingController();

    String? error;
    bool comprobando = false;

    final nombre = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('CREAR COMBO'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setDialogState(() => error = null),
            decoration: InputDecoration(
              labelText: 'Nombre',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: controller.text.trim().isEmpty || comprobando
                  ? null
                  : () async {
                      final nombreEscrito = controller.text.trim();

                      setDialogState(() {
                        comprobando = true;
                        error = null;
                      });

                      final existe = await context
                          .read<ComboProvider>()
                          .existeNombre(nombreEscrito);

                      if (!dialogContext.mounted) return;

                      setDialogState(() => comprobando = false);

                      if (existe) {
                        setDialogState(
                          () => error = 'Ya existe un combo con ese nombre',
                        );
                      } else {
                        Navigator.pop(dialogContext, nombreEscrito);
                      }
                    },
              child: const Text('ACEPTAR'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();

    if (nombre == null || !context.mounted) return;

    final id = await context.read<ComboProvider>().crear(nombre);

    if (!context.mounted) return;

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe un combo con ese nombre'),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleCombo(comboId: id),
      ),
    );
  }

  Future<void> _mostrarMenuCombo(
    BuildContext context,
    Combo combo,
    Offset posicion,
  ) async {
    final puedeCompartir = CompartirCombo.tieneProductosCompartibles(combo);

    final opcion = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar menú de combo',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 120),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final media = MediaQuery.of(dialogContext);
        final pantalla = media.size;

        const anchoMenu = 230.0;
        final altoMenu = puedeCompartir ? 113.0 : 56.0;

        final izquierdaMinima = media.padding.left + 8.0;
        final izquierdaMaxima =
            pantalla.width - media.padding.right - anchoMenu - 8.0;

        final izquierda = posicion.dx
            .clamp(
              izquierdaMinima,
              izquierdaMaxima < izquierdaMinima
                  ? izquierdaMinima
                  : izquierdaMaxima,
            )
            .toDouble();

        final arribaMinimo = media.padding.top + 8.0;
        final arribaMaximo =
            pantalla.height - media.padding.bottom - altoMenu - 8.0;

        var arriba = posicion.dy;

        if (arriba + altoMenu >
            pantalla.height - media.padding.bottom - 8.0) {
          arriba -= altoMenu;
        }

        arriba = arriba
            .clamp(
              arribaMinimo,
              arribaMaximo < arribaMinimo
                  ? arribaMinimo
                  : arribaMaximo,
            )
            .toDouble();

        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                left: izquierda,
                top: arriba,
                width: anchoMenu,
                child: Material(
                  elevation: 8,
                  color: Theme.of(dialogContext).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _opcionMenu(
                        dialogContext,
                        icono: Icons.delete_outline,
                        texto: 'Eliminar combo',
                        valor: 'eliminar',
                      ),
                      if (puedeCompartir)
                        Divider(
                          height: 1,
                          color: Theme.of(dialogContext).dividerColor,
                        ),
                      if (puedeCompartir)
                        _opcionMenu(
                          dialogContext,
                          icono: Icons.share_outlined,
                          texto: 'Compartir combo',
                          valor: 'compartir',
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || opcion == null) return;

    if (opcion == 'compartir') {
      await CompartirCombo.compartir(context, combo);
      return;
    }

    if (opcion == 'eliminar') {
      final confirmado = await DialogoConfirmacion.mostrar(
        context,
        titulo: 'Eliminar combo',
        mensaje: '¿Eliminar el combo ${combo.nombre}?',
      );

      if (!confirmado || !context.mounted) return;

      await context.read<ComboProvider>().eliminar(combo.id);
    }
  }

  Widget _opcionMenu(
    BuildContext context, {
    required IconData icono,
    required String texto,
    required String valor,
  }) {
    return SizedBox(
      height: 56,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(valor),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icono),
              const SizedBox(width: 12),
              Text(texto),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ComboProvider>();
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final combosFiltrados = provider.combos
    .where(
      (combo) => BuscadorInteligente.coincide(
        combo.nombre,
        _busqueda.text,
      ),
    )
    .toList()
  ..sort(
    (a, b) => BuscadorInteligente.normalizar(a.nombre).compareTo(
      BuscadorInteligente.normalizar(b.nombre),
    ),
  );

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 112,
        leading: const BotonVolver(),
        title: const Text('COMBOS'),
      ),
      
body: provider.cargando
    ? const Center(child: CircularProgressIndicator())
    : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
            child: TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar combo...',
                border: const OutlineInputBorder(),
                suffixIcon: _busqueda.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _busqueda.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: provider.combos.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No hay combos todavía. '
                        'Presiona + CREAR COMBO para comenzar.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : combosFiltrados.isEmpty
                    ? const Center(
                        child: Text('No se encontraron combos.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          8,
                          20,
                          20,
                        ),
                        itemCount: combosFiltrados.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        itemBuilder: (context, index) {
                          final combo = combosFiltrados[index];

                          return _FilaComboInteractiva(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DetalleCombo(
                                    comboId: combo.id,
                                  ),
                                ),
                              );
                            },
                            onLongPress: (posicion) {
                              _mostrarMenuCombo(
                                context,
                                combo,
                                posicion,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 4,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    combo.nombre,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (combo.items.isEmpty)
                                    Text(
                                      'Sin productos',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .hintColor,
                                          ),
                                    ),
                                  ...combo.items.map(
                                    (item) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        '• ${item.cantidad ?? '—'} '
                                        '${item.nombreProducto}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: item.activo
                                                  ? null
                                                  : (oscuro
                                                      ? ColoresApp.rojoOscuro
                                                      : ColoresApp.alerta),
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Venta: ${FormatoNumeros.moneda(combo.precioCombo)}'
                                    '    Costo: ${FormatoNumeros.moneda(combo.costoProductos)}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Ganancia: ${FormatoNumeros.moneda(combo.ganancia)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: oscuro
                                              ? ColoresApp.gananciaOscura
                                              : ColoresApp.gananciaClaro,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: FilledButton.icon(
            onPressed: () => _crearCombo(context),
            icon: const Icon(Icons.add),
            label: const Text('CREAR COMBO'),
          ),
        ),
      ),
    );
  }
}

class _FilaComboInteractiva extends StatelessWidget {
  const _FilaComboInteractiva({
    required this.onTap,
    required this.onLongPress,
    required this.child,
  });

  final VoidCallback onTap;
  final ValueChanged<Offset> onLongPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        LongPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(
            duration: const Duration(milliseconds: 800),
          ),
          (instance) {
            instance.onLongPressStart = (details) {
              onLongPress(details.globalPosition);
            };
          },
        ),
      },
      child: InkWell(
        onTap: onTap,
        child: child,
      ),
    );
  }
}
