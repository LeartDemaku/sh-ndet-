import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Butoni i emergjencës në shiritin e sipërm.
///
/// Qëllimisht nuk është FloatingActionButton: në telefon ai mbivendosej me
/// fushën e shkrimit të chat-it dhe bllokonte butonin "Dërgo". Një buton në
/// AppBar është gjithmonë i dukshëm dhe nuk mbulon përmbajtjen.
class EmergencyAction extends StatelessWidget {
  const EmergencyAction({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Semantics(
      button: true,
      label: 'Emergjencë, telefono 194',
      child: TextButton.icon(
        onPressed: () => context.push('/emergency'),
        style: TextButton.styleFrom(
          backgroundColor: ShendetColors.emergency,
          foregroundColor: ShendetColors.onEmergency,
          minimumSize: const Size(78, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        icon: const Icon(Icons.emergency_rounded, size: 18),
        label: const Text('194'),
      ),
    ),
  );
}
