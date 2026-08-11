/// Formateador de hora.
/// Funcion pura — sin estado, sin side effects.
String formatTime(DateTime dt) {
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

/// Formatea una fecha para mostrar "Hoy", "Ayer" o la fecha.
String formatRelativeDate(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(dt.year, dt.month, dt.day);

  final diff = today.difference(date).inDays;
  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Ayer';
  if (diff < 7) return 'Hace $diff dias';
  return '${dt.day}/${dt.month}/${dt.year}';
}

/// Formatea una fecha como dd/MM/yyyy.
String formatDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
