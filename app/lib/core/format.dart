String two(int n) => n.toString().padLeft(2, '0');

/// 'YYYY-MM-DD' ou ISO -> dd/MM/yyyy
String fmtDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  final l = iso.length > 10 ? d.toLocal() : d;
  return '${two(l.day)}/${two(l.month)}/${l.year}';
}

String fmtDateTime(String? iso) {
  if (iso == null) return '';
  final d = DateTime.tryParse(iso)?.toLocal();
  return d == null ? iso : '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

String ageOf(String? birth) {
  final b = birth == null ? null : DateTime.tryParse(birth);
  if (b == null) return '';
  final now = DateTime.now();
  var months = (now.year - b.year) * 12 + now.month - b.month;
  if (now.day < b.day) months--;
  if (months < 0) return '';
  if (months < 12) return '$months ${months == 1 ? 'mês' : 'meses'}';
  final y = months ~/ 12;
  return '$y ${y == 1 ? 'ano' : 'anos'}';
}

String fmtKg(num? v) => v == null ? '' : '${v % 1 == 0 ? v.toInt() : v} kg';
