import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'base_datos/base_datos.dart';
import 'logica/respaldo.dart';
import 'providers/combo_provider.dart';
import 'providers/configuracion_provider.dart';
import 'providers/producto_provider.dart';
import 'pantallas/menu_principal/menu_principal.dart';
import 'repositorios/combo_repositorio.dart';
import 'repositorios/configuracion_repositorio.dart';
import 'repositorios/producto_repositorio.dart';
import 'temas/tema_claro.dart';
import 'temas/tema_oscuro.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);

  final baseDatos = BaseDatos.instancia;
  await baseDatos.inicializar();
  final productoRepositorio = ProductoRepositorio(baseDatos);
  final comboRepositorio = ComboRepositorio(baseDatos);
  final configuracionRepositorio = ConfiguracionRepositorio(baseDatos);

  late final ComboProvider comboProvider;
  late final ProductoProvider productoProvider;
  late final ConfiguracionProvider configuracionProvider;

  comboProvider = ComboProvider(comboRepositorio, configuracionRepositorio);
  productoProvider = ProductoProvider(
    productoRepositorio,
    comboRepositorio,
    configuracionRepositorio,
    alCambiarCombos: comboProvider.recargar,
  );
  configuracionProvider = ConfiguracionProvider(
    configuracionRepositorio,
    productoRepositorio,
    comboRepositorio,
    alCambiarProductos: productoProvider.recargar,
    alCambiarCombos: comboProvider.recargar,
  );
  await Future.wait<void>([
    configuracionProvider.recargar(),
    productoProvider.recargar(),
    comboProvider.recargar(),
  ]);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<ConfiguracionProvider>.value(value: configuracionProvider),
      ChangeNotifierProvider<ProductoProvider>.value(value: productoProvider),
      ChangeNotifierProvider<ComboProvider>.value(value: comboProvider),
      Provider<RespaldoService>.value(value: RespaldoService(baseDatos, configuracionRepositorio)),
    ],
    child: const ComboManagerApp(),
  ));
}

class ComboManagerApp extends StatelessWidget {
  const ComboManagerApp({super.key});

  @override
  Widget build(BuildContext context) => Consumer<ConfiguracionProvider>(
        builder: (context, configuracion, _) => MaterialApp(
          title: 'Combo Manager',
          debugShowCheckedModeBanner: false,
          theme: crearTemaClaro(),
          darkTheme: crearTemaOscuro(),
          themeMode: configuracion.modoOscuro ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: configuracion.modoOscuro ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const MenuPrincipal(),
        ),
      );
}
