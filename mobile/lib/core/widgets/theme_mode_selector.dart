import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../theme/theme_mode.dart';

/// Zgjedhësi i pamjes: E ndritshme · E errët.
///
/// Përdoret te Profili. Të dyja opsionet janë karta të prekshme, me gjendje
/// të zgjedhur të dukshme, etiketë për lexuesin e ekranit dhe kontrast AA.
/// Parazgjedhja është e ndritshme; e errëta aktivizohet vetëm me zgjedhje.
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Row(
      children: [
        Expanded(
          child: _ThemeChoice(
            icon: Icons.light_mode_rounded,
            label: 'E ndritshme',
            selected: mode != ThemeMode.dark,
            onTap: () =>
                ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
          ),
        ),
        const SizedBox(width: Gap.s),
        Expanded(
          child: _ThemeChoice(
            icon: Icons.dark_mode_rounded,
            label: 'E errët',
            selected: mode == ThemeMode.dark,
            onTap: () =>
                ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
          ),
        ),
      ],
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? p.mint : p.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? p.primary : p.line,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, size: 22, color: selected ? p.primaryDark : p.muted),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: selected ? p.primaryDark : p.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
