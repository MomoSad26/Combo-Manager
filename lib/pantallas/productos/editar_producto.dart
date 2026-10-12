import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logica/formato_numeros.dart';
import '../../modelos/configuracion.dart';
import '../../modelos/producto.dart';
import '../../providers/configuracion_provider.dart';
import '../../providers/producto_provider.dart';
import '../../temas/colores.dart';
import '../../widgets/boton_volver.dart';
import '../../widgets/dialogo_confirmacion.dart';

class EditarProducto extends StatefulWidget {
  const EditarProducto({super.key, required this.producto});
  final Producto producto;
  @override
  State<EditarProducto> createState() => _EditarProductoState();
}

class _EditarProductoState extends State<EditarProducto> {
  final _formKey = GlobalKey<FormState>();
  late Producto _actual;
  late final TextEditingController _nombre;
  late final TextEditingController _compra;
  late final TextEditingController _venta;
  bool _compraEditada = false;
  bool _ventaEditada = false;

  @override
  void initState() {
    super.initState();
    _actual = widget.producto;
    _nombre = TextEditingController(text: _actual.nombre);
    _compra = TextEditingController(text: FormatoNumeros.moneda(_actual.precioCompra));
    _venta = TextEditingController(text: FormatoNumeros.moneda(_actual.precioVenta));
  }

  @override
  void dispose() { _nombre.dispose(); _compra.dispose(); _venta.dispose(); super.dispose(); }

  void _alCambiarCompra(String texto, Configuracion config) {
    _compraEditada = true;
    _ventaEditada = false;
    final compra = FormatoNumeros.leerNumero(texto);
    if (compra == null || compra < 0) { _venta.clear(); }
    else { final valor = context.read<ProductoProvider>().precioVentaCalculado(compra, config); final salida = FormatoNumeros.moneda(valor); _venta.value = TextEditingValue(text: salida, selection: TextSelection.collapsed(offset: salida.length)); }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final compra = _compraEditada
        ? (FormatoNumeros.leerNumero(_compra.text) ?? 0)
        : _actual.precioCompra;
    final config = context.read<ConfiguracionProvider>().configuracion;
    final venta = !_ventaEditada
        ? (_compraEditada
            ? context.read<ProductoProvider>().precioVentaCalculado(compra, config)
            : _actual.precioVenta)
        : (FormatoNumeros.leerNumero(_venta.text) ?? context.read<ProductoProvider>().precioVentaCalculado(compra, config));
    final manual = _ventaEditada ? true : (_compraEditada ? false : _actual.precioVentaManual);
    final guardado = await context.read<ProductoProvider>().guardarEdicion(original: _actual, nombre: _nombre.text.trim(), precioCompra: compra, precioVenta: venta, precioVentaManual: manual);
    if (!mounted) return;
    if (!guardado) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya existe un producto con ese nombre')));
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _eliminar() async {
    final confirmado = await DialogoConfirmacion.mostrar(context, titulo: 'Eliminar producto', mensaje: '¿Eliminar el producto ${_actual.nombre}?');
    if (!confirmado || !mounted) return;
    await context.read<ProductoProvider>().eliminar(_actual);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _cambiarEstado() async {
    final eraActivo = _actual.activo;
    await context.read<ProductoProvider>().cambiarEstado(_actual);
    if (mounted) setState(() => _actual = _actual.copiar(activo: !eraActivo));
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfiguracionProvider>().configuracion;
    final colorTexto = _actual.activo ? Theme.of(context).colorScheme.onSurface : (Theme.of(context).brightness == Brightness.dark ? ColoresApp.inactivoOscuro : ColoresApp.inactivoClaro);
    return Scaffold(
      appBar: AppBar(leadingWidth: 112, leading: const BotonVolver(), title: const Text('EDITAR PRODUCTO')),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
        Text('NOMBRE', style: Theme.of(context).textTheme.labelLarge), const SizedBox(height: 8),
        TextFormField(controller: _nombre, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(), validator: (v) => (v == null || v.trim().isEmpty) ? 'Debes escribir un nombre' : null),
        const SizedBox(height: 22),
        Text('PRECIO DE COMPRA', style: Theme.of(context).textTheme.labelLarge), const SizedBox(height: 8),
        TextFormField(controller: _compra, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(), onChanged: (v) => setState(() => _alCambiarCompra(v, config)), validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Debes escribir el precio de compra';
          final n = FormatoNumeros.leerNumero(v); if (n == null || !n.isFinite || n < 0) return 'Escribe un precio válido'; return null;
        }),
        const SizedBox(height: 22),
        Text('PRECIO DE VENTA', style: Theme.of(context).textTheme.labelLarge), const SizedBox(height: 8),
        TextFormField(controller: _venta, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: const InputDecoration(), onChanged: (_) { _ventaEditada = true; }, validator: (v) {
          if (v == null || v.trim().isEmpty) return null;
          final n = FormatoNumeros.leerNumero(v); if (n == null || !n.isFinite || n < 0) return 'Escribe un precio válido'; return null;
        }),
        const SizedBox(height: 24),
        OutlinedButton.icon(onPressed: _cambiarEstado, icon: Icon(_actual.activo ? Icons.visibility_off_outlined : Icons.visibility_outlined), label: Text(_actual.activo ? 'DESACTIVAR' : 'ACTIVAR'), style: OutlinedButton.styleFrom(foregroundColor: colorTexto, minimumSize: const Size(48, 50))),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _eliminar, icon: const Icon(Icons.delete_outline), label: const Text('ELIMINAR'), style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error, minimumSize: const Size(48, 50))),
      ])),
      bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 14), child: FilledButton(onPressed: _guardar, child: const Text('GUARDAR CAMBIOS')))),
    );
  }
}
