
class BuscadorInteligente {
  static String normalizar(String texto) {
    return texto
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâãå]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöôõ]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static bool coincide(String nombre, String textoBusqueda) {
    final busqueda = normalizar(textoBusqueda);

    if (busqueda.isEmpty) {
      return true;
    }

    return normalizar(nombre).contains(busqueda);
  }
}
