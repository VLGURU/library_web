// lib/core/api_debug_params.dart
Map<String, dynamic> apiDebugParamsFromUrl() {
  final q = Uri.base.queryParameters;
  final map = <String, dynamic>{};
  if (q['__delay'] != null) map['__delay'] = q['__delay'];
  if (q['__fail'] != null) map['__fail'] = q['__fail'];
  return map;
}