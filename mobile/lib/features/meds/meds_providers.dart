import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/providers.dart';

/// Lista e ilaçeve të përdoruesit, e përbashkët për Ballinën dhe ekranin e Ilaçeve.
final medicationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final api = ref.watch(meApiProvider);
  return api.fetchMedications();
});
