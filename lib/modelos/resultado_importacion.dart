class ResultadoImportacion {
  const ResultadoImportacion({
    required this.productosAgregados,
    required this.combosAgregados,
    required this.productosExistentes,
    required this.combosExistentes,
  });

  final int productosAgregados;
  final int combosAgregados;
  final int productosExistentes;
  final int combosExistentes;
}
