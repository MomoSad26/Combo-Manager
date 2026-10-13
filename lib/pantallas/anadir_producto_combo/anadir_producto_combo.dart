import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logica/formato_numeros.dart';
import '../../logica/buscador_inteligente.dart';
import '../../providers/combo_provider.dart';
import '../../providers/producto_provider.dart';
import '../../widgets/boton_volver.dart';

class AnadirProductoCombo extends StatefulWidget {
  const AnadirProductoCombo({super.key, required this.comboId});
  final int comboId;
  @override
  State<AnadirProductoCombo> createState() => _AnadirProductoComboState();
}

class _AnadirProductoComboState extends State<AnadirProductoCombo> {
  final _busqueda = TextEditingController();

  @override
  void dispose() { _busqueda.dispose(); super.dispose(); }

  Future<void> _mostrarCantidad(int productoId, String nombre) async {
    final contiene = await context.read<ComboProvider>().yaContieneProducto(widget.comboId, productoId);
    if (!mounted) return;
    if (contiene) {
      await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
        content: const Text('Este producto ya está en el combo'),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ACEPTAR'))],
      ));
      return;
    }
    final resultado = await _dialogoCantidad(nombre);
    if (resultado == null || !mounted) return;
    if (!resultado.valido) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes escribir una cantidad')));
      return;
    }
    final agregado = await context.read<ComboProvider>().anadirProducto(widget.comboId, productoId, resultado.cantidad);
    if (!mounted) return;
    if (!agregado) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este producto ya está en el combo')));
      return;
    }
    if (resultado.salir) Navigator.pop(context);
  }

  Future<_ResultadoCantidad?> _dialogoCantidad(String nombre) async {
    final controller = TextEditingController(text: '1');
    String? error;
    final result = await showDialog<_ResultadoCantidad>(context: context, barrierDismissible: false, builder: (dialogContext) => StatefulBuilder(
      builder: (contexto, setDialogState) => AlertDialog(
        title: Text(nombre),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          decoration: InputDecoration(labelText: 'Cantidad', errorText: error),
        ),
        actions: [
          TextButton(onPressed: () {
            final n = FormatoNumeros.leerNumero(controller.text);
            if (n == null || n < 1 || n % 1 != 0) { setDialogState(() => error = 'Debes escribir una cantidad'); return; }
            Navigator.pop(dialogContext, _ResultadoCantidad(n.toInt(), false, true));
          }, child: const Text('GUARDAR Y CONTINUAR')),
          TextButton(onPressed: () {
            final n = FormatoNumeros.leerNumero(controller.text);
            if (n == null || n < 1 || n % 1 != 0) { setDialogState(() => error = 'Debes escribir una cantidad'); return; }
            Navigator.pop(dialogContext, _ResultadoCantidad(n.toInt(), true, true));
          }, child: const Text('GUARDAR Y SALIR')),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCELAR')),
        ],
      ),
    ));
    controller.dispose();
    return result;
  }

  
  @override
  Widget build(BuildContext context) {
    final productosActivos = context
        .watch<ProductoProvider>()
        .productos
        .where((p) => p.activo)
        .toList();

    final productos = productosActivos
        .where(
          (p) => BuscadorInteligente.coincide(
            p.nombre,
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
        title: const Text('AÑADIR PRODUCTO'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
            child: TextField(
              controller: _busqueda,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar producto...',
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
            child: productosActivos.isEmpty
                ? const Center(
                    child: Text(
                      'No hay productos activos para añadir.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : productos.isEmpty
                    ? const Center(
                        child: Text('No se encontraron productos.'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          0,
                          20,
                          16,
                        ),
                        itemCount: productos.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor,
                        ),
                        itemBuilder: (context, index) {
                          final p = productos[index];

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 2,
                            ),
                            title: Text(
                              p.nombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'V: ${FormatoNumeros.moneda(p.precioVenta)}',
                            ),
                            onTap: () => _mostrarCantidad(
                              p.id,
                              p.nombre,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }


class _ResultadoCantidad {
  const _ResultadoCantidad(this.cantidad, this.salir, this.valido);
  final int cantidad;
  final bool salir;
  final bool valido;
}
