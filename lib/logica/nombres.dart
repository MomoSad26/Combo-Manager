/// Forma canónica de un nombre para detectar duplicados: "Combo 1", " combo 1 "
/// y "COMBO 1" se consideran el mismo nombre.
String normalizarNombre(String nombre) => nombre.trim().toLowerCase();
