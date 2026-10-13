class ResultadoImportacion {
  const ResultadoImportacion({
    required this.productosAgregados,
    required this.combosAgregados,
    required this.productosExistentes,
    required this.combosExistentes,
    this.configuracionCambiada = false,
  });

  final int productosAgregados;
  final int combosAgregados;
  final int productosExistentes;
  final int combosExistentes;

  /// El respaldo traía un margen o una tasa distintos y se aplicaron.
  final bool configuracionCambiada;
}
