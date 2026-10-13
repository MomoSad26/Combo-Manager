
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logica/buscador_inteligente.dart';
import '../../logica/formato_numeros.dart';
import '../../providers/producto_provider.dart';
import '../../temas/colores.dart';
import '../../widgets/boton_volver.dart';
import 'crear_producto.dart';
import 'editar_producto.dart';

class ListaProductos extends StatefulWidget {
  const ListaProductos({super.key});

  @override
  State<ListaProductos> createState() => _ListaProductosState();
}

class _ListaProductosState extends State<ListaProductos> {
  final TextEditingController _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductoProvider>();
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    final productos = provider.productos
        .where(
          (producto) => BuscadorInteligente.coincide(
            producto.nombre,
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
        title: const Text('PRODUCTOS'),
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
                  child: provider.productos.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No hay productos todavía. '
                              'Presiona + AÑADIR PRODUCTO para comenzar.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : productos.isEmpty
                          ? const Center(
                              child: Text('No se encontraron productos.'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                8,
                                20,
                                20,
                              ),
                              itemCount: productos.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Theme.of(context).dividerColor,
                              ),
                              itemBuilder: (context, index) {
                                final producto = productos[index];

                                final color = producto.activo
                                    ? Theme.of(context).colorScheme.onSurface
                                    : oscuro
                                        ? ColoresApp.inactivoOscuro
                                        : ColoresApp.inactivoClaro;

                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => EditarProducto(
                                          producto: producto,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                producto.nombre,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: color,
                                                    ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                'C: ${FormatoNumeros.moneda(producto.precioCompra)}'
                                                '    V: ${FormatoNumeros.moneda(producto.precioVenta)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(color: color),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (!producto.activo)
                                          Text(
                                            'INACTIVO',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: color,
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CrearProducto(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('AÑADIR PRODUCTO'),
          ),
        ),
      ),
    );
  }
}
