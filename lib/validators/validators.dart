bool _isBlank(String? v) => v == null || v.trim().isEmpty;

String? requiredText(String? v, {String message = 'Обязательное поле'}) {
  return _isBlank(v) ? message : null;
}

String? minLen(String? v, int min, {String? message}) {
  if (_isBlank(v)) return null;
  return v!.trim().length < min ? (message ?? 'Минимум $min символа') : null;
}

String? maxLen(String? v, int max, {String? message}) {
  if (_isBlank(v)) return null;
  return v!.trim().length > max ? (message ?? 'Максимум $max символов') : null;
}

String? intRequired(String? v, {String message = 'Введите число'}) {
  if (_isBlank(v)) return message;
  return int.tryParse(v!.trim()) == null ? 'Это не целое число' : null;
}

String? intRange(String? v, int min, int max, {String? message}) {
  if (_isBlank(v)) return null;
  final n = int.tryParse(v!.trim());
  if (n == null) return 'Это не целое число';
  if (n < min || n > max) return message ?? 'Диапазон: $min..$max';
  return null;
}

String? email(String? v) {
  if (_isBlank(v)) return 'Введите email';
  final s = v!.trim();
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
  return ok ? null : 'Некорректный email';
}

String? isbn(String? v) {
  if (_isBlank(v)) return 'Введите ISBN';
  final s = v!.trim();
  final ok = RegExp(r'^[0-9\-]{10,20}$').hasMatch(s);
  return ok ? null : 'ISBN: 10–20 символов, цифры и дефисы';
}

/// yyyy-mm-dd
String? dateYmd(String? v) {
  if (_isBlank(v)) return 'Введите дату (yyyy-mm-dd)';
  final s = v!.trim();
  final ok = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s);
  if (!ok) return 'Формат yyyy-mm-dd';
  final dt = DateTime.tryParse(s);
  return dt == null ? 'Некорректная дата' : null;
}

String? combine(List<String? Function()> validators) {
  for (final fn in validators) {
    final r = fn();
    if (r != null) return r;
  }
  return null;
}