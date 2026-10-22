import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Profili i përdoruesit aktual. Përdoret nga Ballina dhe Profili, që të
/// mos bëhet e njëjta kërkesë disa herë.
final meProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.watch(meApiProvider);
  return api.fetchMe();
});
