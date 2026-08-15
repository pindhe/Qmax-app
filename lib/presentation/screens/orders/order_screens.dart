import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/entities.dart';
import '../../providers/state_providers.dart';
import '../../widgets/common/qmax_common.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    Future.microtask(() => ref.read(ordersProvider.notifier).refresh());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (!ref.watch(authProvider).isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.myOrders)),
        body: QmaxEmptyState(icon: Icons.receipt_long, title: l10n.loginRequired, actionLabel: l10n.login, onAction: () => context.push('/login')),
      );
    }
    final orders = ref.watch(ordersProvider);
    List<Order> filter(int i) => switch (i) {
          1 => orders.where((o) => o.status == OrderStatus.pending).toList(),
          2 => orders.where((o) => o.status == OrderStatus.preparing || o.status == OrderStatus.confirmed || o.status == OrderStatus.outForDelivery).toList(),
          3 => orders.where((o) => o.status == OrderStatus.delivered).toList(),
          4 => orders.where((o) => o.status == OrderStatus.cancelled).toList(),
          _ => orders,
        };
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myOrders),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.all),
            Tab(text: l10n.pending),
            Tab(text: l10n.processing),
            Tab(text: l10n.delivered),
            Tab(text: l10n.cancelled),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: List.generate(5, (i) {
          final list = filter(i);
          if (list.isEmpty) {
            return QmaxEmptyState(icon: Icons.receipt_long, title: l10n.emptyOrders, subtitle: l10n.emptyOrdersHint);
          }
          return ListView.builder(
            padding: EdgeInsets.all(context.pagePadding),
            itemCount: list.length,
            itemBuilder: (_, index) => _OrderCard(order: list[index]),
          );
        }),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(order.orderNumber, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l10n.productsCount(order.productCount)),
            Text(Formatters.money(order.total), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Chip(label: Text(_statusText(l10n, order.status))),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: () => context.push('/orders/${order.id}'), child: Text(l10n.viewDetails)),
            ),
          ],
        ),
      ),
    );
  }
}

String _statusText(dynamic l10n, OrderStatus status) => switch (status) {
      OrderStatus.pending => l10n.pending as String,
      OrderStatus.confirmed => l10n.orderConfirmed as String,
      OrderStatus.preparing => l10n.processing as String,
      OrderStatus.outForDelivery => l10n.outForDelivery as String,
      OrderStatus.delivered => l10n.delivered as String,
      OrderStatus.cancelled => l10n.cancelled as String,
    };

class OrderDetailsScreen extends ConsumerWidget {
  const OrderDetailsScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(ordersProvider).where((o) => o.id == orderId).firstOrNull;
    final l10n = context.l10n;
    if (order == null) {
      return Scaffold(appBar: AppBar(), body: const QmaxLoading());
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderDetails)),
      body: ListView(
        padding: EdgeInsets.all(context.pagePadding),
        children: [
          Text(order.orderNumber, style: context.texts.headlineSmall),
          Text(order.createdAt.toLocal().toString().split(' ').first),
          Chip(label: Text(_statusText(l10n, order.status))),
          const SizedBox(height: 12),
          ...order.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: item.image == null
                  ? const Icon(Icons.handyman)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(imageUrl: item.image!, width: 48, height: 48, fit: BoxFit.cover),
                    ),
              title: Text(item.productName),
              subtitle: Text('${item.quantity} × ${Formatters.money(item.price)}'),
              trailing: Text(Formatters.money(item.subtotal)),
            ),
          ),
          const Divider(),
          _row(l10n.subtotal, Formatters.money(order.subtotal)),
          _row(l10n.delivery, Formatters.money(order.deliveryFee)),
          _row(l10n.discount, '-${Formatters.money(order.discount)}'),
          _row(l10n.total, Formatters.money(order.total)),
          _row(l10n.paymentMethod, order.paymentMethod.name),
          _row(l10n.address, order.address.fullLine),
          const SizedBox(height: 16),
          QmaxButton(label: l10n.trackOrder, onPressed: () => context.push('/orders/${order.id}/track')),
          const SizedBox(height: 8),
          if (order.status == OrderStatus.pending || order.status == OrderStatus.confirmed || order.status == OrderStatus.preparing)
            QmaxButton(
              label: l10n.cancelOrder,
              outlined: true,
              onPressed: () async {
                final ok = await QmaxDialog.confirm(context, title: l10n.cancelOrder, message: l10n.cancelOrder, confirmLabel: l10n.yes, cancelLabel: l10n.no);
                if (ok) await ref.read(ordersProvider.notifier).cancel(order.id);
              },
            ),
          const SizedBox(height: 8),
          QmaxButton(
            label: l10n.reorder,
            outlined: true,
            onPressed: () async {
              for (final item in order.items) {
                final product = await ref.read(productProvider(item.productId).future);
                if (product != null) {
                  await ref.read(cartProvider.notifier).add(product, quantity: item.quantity);
                }
              }
              if (context.mounted) context.go('/cart');
            },
          ),
          const SizedBox(height: 8),
          QmaxButton(label: l10n.contactQmax, outlined: true, onPressed: () => context.push('/help')),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [Text(k), const Spacer(), Flexible(child: Text(v, textAlign: TextAlign.end))]),
      );
}

class OrderTrackingScreen extends ConsumerWidget {
  const OrderTrackingScreen({super.key, required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(ordersProvider).where((o) => o.id == orderId).firstOrNull;
    final l10n = context.l10n;
    if (order == null) return const Scaffold(body: QmaxLoading());
    final steps = [
      (l10n.orderPlacedStatus, OrderStatus.pending),
      (l10n.orderConfirmed, OrderStatus.confirmed),
      (l10n.preparingOrder, OrderStatus.preparing),
      (l10n.outForDelivery, OrderStatus.outForDelivery),
      (l10n.delivered, OrderStatus.delivered),
    ];
    final currentIndex = switch (order.status) {
      OrderStatus.pending => 0,
      OrderStatus.confirmed => 1,
      OrderStatus.preparing => 2,
      OrderStatus.outForDelivery => 3,
      OrderStatus.delivered => 4,
      OrderStatus.cancelled => -1,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.trackOrder)),
      body: ListView(
        padding: EdgeInsets.all(context.pagePadding),
        children: [
          Text(order.orderNumber, style: context.texts.titleLarge),
          if (order.status == OrderStatus.cancelled)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(l10n.cancelled, style: TextStyle(color: context.colors.error, fontWeight: FontWeight.w700)),
            ),
          ...List.generate(steps.length, (i) {
            final done = currentIndex >= i;
            return ListTile(
              leading: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? const Color(0xFF2D6A4F) : context.colors.outline),
              title: Text(steps[i].$1),
            );
          }),
          const Divider(),
          Text(l10n.items, style: context.texts.titleMedium),
          ...order.items.map((e) => ListTile(title: Text(e.productName), trailing: Text('x${e.quantity}'))),
          _kv(l10n.total, Formatters.money(order.total)),
          _kv(l10n.deliveryAddress, order.address.fullLine),
          if (order.driver != null) ...[
            const SizedBox(height: 8),
            Text(l10n.driverInfo, style: context.texts.titleMedium),
            ListTile(title: Text(order.driver!.name), subtitle: Text(order.driver!.phone), leading: const Icon(Icons.local_shipping_outlined)),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => ListTile(title: Text(k), subtitle: Text(v));
}
