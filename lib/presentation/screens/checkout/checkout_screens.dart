import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/state_providers.dart';
import '../../widgets/common/qmax_common.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _step = 0;
  Address? _address;
  DeliveryMethod _delivery = DeliveryMethod.standard;
  PaymentMethod _payment = PaymentMethod.zaad;
  bool _placing = false;

  double get _deliveryFee => switch (_delivery) {
        DeliveryMethod.standard => 10,
        DeliveryMethod.express => 18,
        DeliveryMethod.pickup => 0,
      };

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final addresses = ref.read(addressProvider);
      setState(() => _address = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull);
    });
  }

  Future<void> _place() async {
    if (_address == null) return;
    setState(() => _placing = true);
    await ref.read(cartProvider.notifier).setDeliveryFee(_deliveryFee);
    final order = await ref.read(ordersProvider.notifier).place(
          cart: ref.read(cartProvider),
          address: _address!,
          delivery: _delivery,
          payment: _payment,
        );
    if (!mounted) return;
    setState(() => _placing = false);
    if (order != null) {
      await ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      context.go('/order-confirmation?id=${order.id}');
    } else if (mounted) {
      context.showSnack(context.l10n.somethingWentWrong, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final addresses = ref.watch(addressProvider);
    final cart = ref.watch(cartProvider);
    _address ??= addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.checkout)),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step == 0 && _address == null) {
            context.showSnack(l10n.addAddress, error: true);
            return;
          }
          if (_step < 2) {
            setState(() => _step++);
            ref.read(cartProvider.notifier).setDeliveryFee(_deliveryFee);
          } else {
            _place();
          }
        },
        onStepCancel: _step == 0 ? null : () => setState(() => _step--),
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: QmaxButton(
                    label: _step == 2 ? l10n.placeOrder : l10n.continueLabel,
                    loading: _placing,
                    onPressed: details.onStepContinue,
                  ),
                ),
                if (_step > 0) ...[
                  const SizedBox(width: 8),
                  TextButton(onPressed: details.onStepCancel, child: Text(l10n.cancel)),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: Text(l10n.stepAddress),
            isActive: _step >= 0,
            content: Column(
              children: [
                ...addresses.map(
                  (a) => RadioListTile<int>(
                    value: a.id,
                    groupValue: _address?.id,
                    onChanged: (_) => setState(() => _address = a),
                    title: Text(a.name),
                    subtitle: Text(a.fullLine),
                    secondary: a.isDefault ? Chip(label: Text(l10n.defaultAddress)) : null,
                  ),
                ),
                QmaxButton(
                  label: l10n.addAddress,
                  outlined: true,
                  onPressed: () => context.push('/addresses/form'),
                ),
              ],
            ),
          ),
          Step(
            title: Text(l10n.stepDelivery),
            isActive: _step >= 1,
            content: Column(
              children: [
                RadioListTile(
                  value: DeliveryMethod.standard,
                  groupValue: _delivery,
                  onChanged: (v) => setState(() => _delivery = v!),
                  title: Text(l10n.standardDelivery),
                  subtitle: Text(l10n.standardDeliveryEta),
                  secondary: Text(Formatters.money(10)),
                ),
                RadioListTile(
                  value: DeliveryMethod.express,
                  groupValue: _delivery,
                  onChanged: (v) => setState(() => _delivery = v!),
                  title: Text(l10n.expressDelivery),
                  subtitle: Text(l10n.expressDeliveryEta),
                  secondary: Text(Formatters.money(18)),
                ),
                RadioListTile(
                  value: DeliveryMethod.pickup,
                  groupValue: _delivery,
                  onChanged: (v) => setState(() => _delivery = v!),
                  title: Text(l10n.storePickup),
                  subtitle: Text(l10n.storePickupEta),
                  secondary: Text(l10n.free),
                ),
              ],
            ),
          ),
          Step(
            title: Text(l10n.stepPayment),
            isActive: _step >= 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.choosePayment, style: context.texts.titleMedium),
                RadioListTile(value: PaymentMethod.zaad, groupValue: _payment, onChanged: (v) => setState(() => _payment = v!), title: Text(l10n.zaad)),
                RadioListTile(value: PaymentMethod.edahab, groupValue: _payment, onChanged: (v) => setState(() => _payment = v!), title: Text(l10n.edahab)),
                RadioListTile(value: PaymentMethod.card, groupValue: _payment, onChanged: (v) => setState(() => _payment = v!), title: Text(l10n.card)),
                RadioListTile(value: PaymentMethod.cashOnDelivery, groupValue: _payment, onChanged: (v) => setState(() => _payment = v!), title: Text(l10n.cashOnDelivery)),
                const SizedBox(height: 8),
                Text('${l10n.total}: ${Formatters.money(cart.subtotal + _deliveryFee - cart.discount)}', style: context.texts.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(ordersProvider).where((o) => o.id == orderId).firstOrNull;
    final l10n = context.l10n;
    if (order == null) {
      return Scaffold(body: QmaxEmptyState(icon: Icons.receipt_long, title: l10n.somethingWentWrong, onAction: () => context.go('/home'), actionLabel: l10n.continueShopping));
    }
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.pagePadding),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.check_circle, size: 96, color: Color(0xFF2D6A4F))
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 16),
              Text(l10n.orderPlaced, textAlign: TextAlign.center, style: context.texts.headlineSmall),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _kv(l10n.orderNumber, order.orderNumber),
                      _kv(l10n.total, Formatters.money(order.total)),
                      _kv(l10n.paymentMethod, order.paymentMethod.name),
                      _kv(l10n.deliveryAddress, order.address.fullLine),
                      _kv(l10n.estimatedDelivery, order.estimatedDelivery?.toLocal().toString().split(' ').first ?? '—'),
                      _kv(l10n.orderDate, order.createdAt.toLocal().toString().split(' ').first),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              QmaxButton(label: l10n.trackOrder, onPressed: () => context.go('/orders/${order.id}/track')),
              const SizedBox(height: 8),
              QmaxButton(label: l10n.continueShopping, outlined: true, onPressed: () => context.go('/home')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 130, child: Text(k)),
            Expanded(child: Text(v, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
