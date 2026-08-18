import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../providers/state_providers.dart';

class QmaxDarkModeButton extends ConsumerWidget {
  const QmaxDarkModeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final dark = switch (settings.themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
    };
    return IconButton(
      tooltip: context.l10n.darkMode,
      onPressed: () => ref.read(settingsProvider.notifier).toggleDark(context),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Icon(
          dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          key: ValueKey(dark),
        ),
      ),
    );
  }
}

class QmaxDarkModeSwitch extends ConsumerWidget {
  const QmaxDarkModeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;
    final dark = ref.read(settingsProvider.notifier).isDark(context);
    return SwitchListTile(
      secondary: Icon(dark ? Icons.dark_mode : Icons.light_mode_outlined),
      title: Text(l10n.darkMode),
      subtitle: Text(switch (settings.themeMode) {
        ThemeMode.light => l10n.themeLight,
        ThemeMode.dark => l10n.themeDark,
        ThemeMode.system => l10n.themeSystem,
      }),
      value: dark,
      onChanged: (_) => ref.read(settingsProvider.notifier).toggleDark(context),
    );
  }
}
