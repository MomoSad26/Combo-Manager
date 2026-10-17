/// Canonización única de nombres, compatible con el buscador inteligente:
/// ignora mayúsculas, acentos, ñ/ n, puntuación y cualquier espacio.
String normalizarNombre(String nombre) => nombre
    .toLowerCase()
    .replaceAll(RegExp(r'[áàäâãå]'), 'a')
    .replaceAll(RegExp(r'[éèëê]'), 'e')
    .replaceAll(RegExp(r'[íìïî]'), 'i')
    .replaceAll(RegExp(r'[óòöôõ]'), 'o')
    .replaceAll(RegExp(r'[úùüû]'), 'u')
    .replaceAll('ñ', 'n')
    .replaceAll('ç', 'c')
    .replaceAll(RegExp(r'[^a-z0-9]'), '');
