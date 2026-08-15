import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/state_providers.dart';
import '../../widgets/brand/qmax_logo.dart';
import '../../widgets/common/qmax_common.dart';
import '../../widgets/navigation/main_shell.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final l10n = context.l10n;
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: EdgeInsets.all(context.pagePadding),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: context.colors.primaryContainer,
              child: Text(user?.name.initials ?? 'G', style: context.texts.headlineSmall),
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(user?.name ?? l10n.guest, style: context.texts.titleLarge)),
          if (user != null) Center(child: Text(user.phone)),
          const SizedBox(height: 8),
          if (!auth.isAuthenticated)
            QmaxButton(label: l10n.login, onPressed: () => context.push('/login')),
          const SizedBox(height: 16),
          _tile(Icons.receipt_long, l10n.myOrders, () {
            if (!RequireAuth.ensure(context, ref)) return;
            context.push('/orders');
          }),
          _tile(Icons.favorite_outline, l10n.wishlist, () => context.go('/wishlist')),
          _tile(Icons.location_on_outlined, l10n.addresses, () {
            if (!RequireAuth.ensure(context, ref)) return;
            context.push('/addresses');
          }),
          _tile(Icons.payments_outlined, l10n.paymentMethods, () {
            if (!RequireAuth.ensure(context, ref)) return;
            context.push('/payment-methods');
          }),
          _tile(Icons.notifications_outlined, l10n.notifications, () => context.push('/notifications')),
          _tile(Icons.settings_outlined, l10n.settings, () => context.push('/settings')),
          _tile(Icons.help_outline, l10n.helpCenter, () => context.push('/help')),
          _tile(Icons.storefront_outlined, l10n.aboutQmax, () => context.push('/about')),
          _tile(Icons.description_outlined, l10n.terms, () => context.push('/terms')),
          _tile(Icons.privacy_tip_outlined, l10n.privacy, () => context.push('/privacy')),
          if (auth.isAuthenticated)
            _tile(Icons.logout, l10n.logout, () async {
              final ok = await QmaxDialog.confirm(context, title: l10n.logout, message: l10n.logoutConfirm, confirmLabel: l10n.yes, cancelLabel: l10n.no);
              if (ok) await ref.read(authProvider.notifier).logout();
            }),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap);
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(l10n.language),
            subtitle: Text(switch (settings.locale.languageCode) {
              'so' => l10n.somali,
              'ar' => l10n.arabic,
              _ => l10n.english,
            }),
            onTap: () async {
              final locale = await showModalBottomSheet<Locale>(
                context: context,
                builder: (_) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(title: Text(l10n.english), onTap: () => Navigator.pop(context, const Locale('en'))),
                    ListTile(title: Text(l10n.somali), onTap: () => Navigator.pop(context, const Locale('so'))),
                    ListTile(title: Text(l10n.arabic), onTap: () => Navigator.pop(context, const Locale('ar'))),
                  ],
                ),
              );
              if (locale != null) ref.read(settingsProvider.notifier).setLocale(locale);
            },
          ),
          ListTile(
            title: Text(l10n.darkMode),
            subtitle: Text(switch (settings.themeMode) {
              ThemeMode.light => l10n.themeLight,
              ThemeMode.dark => l10n.themeDark,
              _ => l10n.themeSystem,
            }),
            onTap: () async {
              final mode = await showModalBottomSheet<ThemeMode>(
                context: context,
                builder: (_) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(title: Text(l10n.themeSystem), onTap: () => Navigator.pop(context, ThemeMode.system)),
                    ListTile(title: Text(l10n.themeLight), onTap: () => Navigator.pop(context, ThemeMode.light)),
                    ListTile(title: Text(l10n.themeDark), onTap: () => Navigator.pop(context, ThemeMode.dark)),
                  ],
                ),
              );
              if (mode != null) ref.read(settingsProvider.notifier).setTheme(mode);
            },
          ),
          SwitchListTile(
            title: Text(l10n.notifications),
            value: settings.notificationsEnabled,
            onChanged: (v) => ref.read(settingsProvider.notifier).setNotifications(v),
          ),
          ListTile(title: Text(l10n.privacy), onTap: () => context.push('/privacy')),
          ListTile(title: Text(l10n.security), subtitle: Text(l10n.changePassword), onTap: () {
            if (!RequireAuth.ensure(context, ref)) return;
            context.push('/change-password');
          }),
          ListTile(
            title: Text(l10n.clearCache),
            onTap: () async {
              await ref.read(settingsProvider.notifier).clearCache();
              if (context.mounted) context.showSnack(l10n.cacheCleared);
            },
          ),
          ListTile(title: Text(l10n.aboutApplication), subtitle: Text(l10n.version(AppConstants.version))),
        ],
      ),
    );
  }
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationsListProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [TextButton(onPressed: () => ref.read(notificationsListProvider.notifier).markAll(), child: Text(l10n.markAllRead))],
      ),
      body: items.isEmpty
          ? QmaxEmptyState(icon: Icons.notifications_none, title: l10n.noNotifications)
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final n = items[i];
                return ListTile(
                  leading: Icon(_icon(n.type), color: n.isRead ? null : Theme.of(context).colorScheme.primary),
                  title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700)),
                  subtitle: Text(n.message),
                );
              },
            ),
    );
  }

  IconData _icon(String type) => switch (type) {
        'order_confirmed' => Icons.check_circle_outline,
        'order_shipped' => Icons.local_shipping_outlined,
        'order_delivered' => Icons.home_outlined,
        'flash_sale' => Icons.bolt,
        'new_products' => Icons.new_releases_outlined,
        _ => Icons.notifications_outlined,
      };
}

class HelpCenterScreen extends ConsumerWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpCenter)),
      body: ListView(
        children: [
          ListTile(leading: const Icon(Icons.call), title: Text(l10n.callQmax), onTap: () => launchUrl(Uri.parse('tel:${AppConfig.storePhone}'))),
          ListTile(leading: const Icon(Icons.chat), title: Text(l10n.whatsapp), onTap: () => launchUrl(Uri.parse('https://wa.me/${AppConfig.storeWhatsapp}'), mode: LaunchMode.externalApplication)),
          ExpansionTile(
            title: Text(l10n.contactForm),
            children: const [_ContactForm()],
          ),
          ExpansionTile(title: Text(l10n.faqOrder), children: [ListTile(subtitle: Text(l10n.faqOrderAnswer))]),
          ExpansionTile(title: Text(l10n.faqPay), children: [ListTile(subtitle: Text(l10n.faqPayAnswer))]),
          ExpansionTile(title: Text(l10n.faqDelivery), children: [ListTile(subtitle: Text(l10n.faqDeliveryAnswer))]),
          ExpansionTile(title: Text(l10n.faqCancel), children: [ListTile(subtitle: Text(l10n.faqCancelAnswer))]),
          ExpansionTile(title: Text(l10n.faqReturn), children: [ListTile(subtitle: Text(l10n.faqReturnAnswer))]),
        ],
      ),
    );
  }
}

class _ContactForm extends ConsumerStatefulWidget {
  const _ContactForm();
  @override
  ConsumerState<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends ConsumerState<_ContactForm> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          QmaxTextField(label: l10n.subject, controller: _subject),
          const SizedBox(height: 8),
          QmaxTextField(label: l10n.message, controller: _message, maxLines: 4),
          const SizedBox(height: 8),
          QmaxButton(
            label: l10n.sendMessage,
            onPressed: () {
              context.showSnack(l10n.messageSent);
              _subject.clear();
              _message.clear();
            },
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutQmax)),
      body: ListView(
        padding: EdgeInsets.all(context.pagePadding),
        children: [
          const Center(child: QmaxLogo(size: 88)),
          const SizedBox(height: 16),
          Text(l10n.appName, textAlign: TextAlign.center, style: context.texts.headlineSmall),
          Text(l10n.hardwareStore, textAlign: TextAlign.center),
          Text(l10n.location, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(AppConstants.storePhone, textAlign: TextAlign.center, style: context.texts.titleMedium),
          const SizedBox(height: 16),
          Text(l10n.aboutBody),
          const SizedBox(height: 20),
          QmaxButton(label: l10n.callQmax, icon: Icons.call, onPressed: () => launchUrl(Uri.parse('tel:${AppConfig.storePhone}'))),
          const SizedBox(height: 8),
          QmaxButton(
            label: l10n.whatsapp,
            outlined: true,
            icon: Icons.chat,
            onPressed: () => launchUrl(Uri.parse('https://wa.me/${AppConfig.storeWhatsapp}'), mode: LaunchMode.externalApplication),
          ),
          const SizedBox(height: 8),
          QmaxButton(
            label: l10n.getDirections,
            outlined: true,
            icon: Icons.map_outlined,
            onPressed: () => launchUrl(
              Uri.parse('https://maps.google.com/?q=${AppConfig.storeLat},${AppConfig.storeLng}'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 8),
          QmaxButton(
            label: l10n.shareStore,
            outlined: true,
            icon: Icons.share,
            onPressed: () => Share.share('QMAX Tools — Hardware & Construction Materials, Hargeisa. ${AppConstants.storePhone}'),
          ),
        ],
      ),
    );
  }
}

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.pagePadding),
        child: Text(body, style: context.texts.bodyLarge),
      ),
    );
  }
}

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(addressProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addresses)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/addresses/form'),
        icon: const Icon(Icons.add),
        label: Text(l10n.addAddress),
      ),
      body: addresses.isEmpty
          ? QmaxEmptyState(icon: Icons.location_off, title: l10n.addAddress)
          : ListView.builder(
              padding: EdgeInsets.all(context.pagePadding),
              itemCount: addresses.length,
              itemBuilder: (_, i) {
                final a = addresses[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(a.name),
                    subtitle: Text(a.fullLine),
                    leading: Icon(a.isDefault ? Icons.home : Icons.location_on_outlined),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(onPressed: () => context.push('/addresses/form?id=${a.id}'), icon: const Icon(Icons.edit_outlined)),
                        IconButton(onPressed: () => ref.read(addressProvider.notifier).remove(a.id), icon: const Icon(Icons.delete_outline)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.addressId});
  final int? addressId;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _city;
  late final TextEditingController _area;
  late final TextEditingController _street;
  late final TextEditingController _directions;
  bool _default = false;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(addressProvider).where((a) => a.id == widget.addressId).firstOrNull;
    _name = TextEditingController(text: existing?.name ?? ref.read(authProvider).user?.name ?? '');
    _phone = TextEditingController(text: existing?.phone ?? ref.read(authProvider).user?.phone ?? '');
    _city = TextEditingController(text: existing?.city ?? 'Hargeisa');
    _area = TextEditingController(text: existing?.area ?? '');
    _street = TextEditingController(text: existing?.street ?? '');
    _directions = TextEditingController(text: existing?.directions ?? '');
    _default = existing?.isDefault ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _area.dispose();
    _street.dispose();
    _directions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(widget.addressId == null ? l10n.addAddress : l10n.editAddress)),
      body: Form(
        key: _form,
        child: ListView(
          padding: EdgeInsets.all(context.pagePadding),
          children: [
            QmaxTextField(label: l10n.fullName, controller: _name, validator: (v) => Validators.requiredField(v, l10n)),
            const SizedBox(height: 12),
            QmaxTextField(label: l10n.phone, controller: _phone, validator: (v) => Validators.phone(v, l10n)),
            const SizedBox(height: 12),
            QmaxTextField(label: l10n.city, controller: _city, validator: (v) => Validators.requiredField(v, l10n)),
            const SizedBox(height: 12),
            QmaxTextField(label: l10n.area, controller: _area, validator: (v) => Validators.requiredField(v, l10n)),
            const SizedBox(height: 12),
            QmaxTextField(label: l10n.street, controller: _street, validator: (v) => Validators.requiredField(v, l10n)),
            const SizedBox(height: 12),
            QmaxTextField(label: l10n.directions, controller: _directions, maxLines: 3),
            SwitchListTile(title: Text(l10n.setAsDefault), value: _default, onChanged: (v) => setState(() => _default = v)),
            QmaxButton(
              label: l10n.save,
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                await ref.read(addressProvider.notifier).save(
                      Address(
                        id: widget.addressId ?? 0,
                        name: _name.text,
                        phone: _phone.text,
                        city: _city.text,
                        area: _area.text,
                        street: _street.text,
                        directions: _directions.text,
                        isDefault: _default,
                      ),
                    );
                if (context.mounted) context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.changePassword)),
      body: Form(
        key: _form,
        child: ListView(
          padding: EdgeInsets.all(context.pagePadding),
          children: [
            QmaxTextField(label: l10n.currentPassword, controller: _current, obscure: true, validator: (v) => Validators.password(v, l10n)),
            const SizedBox(height: 12),
            QmaxTextField(label: l10n.newPassword, controller: _next, obscure: true, validator: (v) => Validators.password(v, l10n)),
            const SizedBox(height: 12),
            QmaxTextField(label: l10n.confirmPassword, controller: _confirm, obscure: true, validator: (v) => Validators.confirmPassword(v, _next.text, l10n)),
            const SizedBox(height: 20),
            QmaxButton(
              label: l10n.save,
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                final ok = await ref.read(authProvider.notifier).changePassword(_current.text, _next.text);
                if (!context.mounted) return;
                if (ok) {
                  context.showSnack(l10n.passwordChanged);
                  context.pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentMethods)),
      body: ListView(
        children: [
          ListTile(leading: const Icon(Icons.phone_android), title: Text(l10n.zaad), subtitle: const Text('API-ready')),
          ListTile(leading: const Icon(Icons.account_balance_wallet_outlined), title: Text(l10n.edahab), subtitle: const Text('API-ready')),
          ListTile(leading: const Icon(Icons.credit_card), title: Text(l10n.card), subtitle: Text(l10n.privacyBody.split('.').first)),
          ListTile(leading: const Icon(Icons.payments_outlined), title: Text(l10n.cashOnDelivery)),
        ],
      ),
    );
  }
}
