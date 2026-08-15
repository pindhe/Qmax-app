import 'package:flutter_test/flutter_test.dart';
import 'package:qmax_tools/core/utils/validators.dart';
import 'package:qmax_tools/domain/entities/entities.dart';

void main() {
  test('Formatters.money formats whole dollars without decimals', () {
    expect(Formatters.money(120), r'$120');
    expect(Formatters.money(8.5), r'$8.50');
  });

  test('Product discount and stock helpers work', () {
    const product = Product(
      id: 1,
      categoryId: 1,
      name: 'Drill',
      slug: 'drill',
      sku: 'QMX-1',
      description: 'Test',
      price: 150,
      discountPrice: 120,
      stock: 3,
      brand: 'Bosch',
      images: ['https://example.com/a.jpg'],
    );
    expect(product.hasDiscount, isTrue);
    expect(product.discountPercent, 20);
    expect(product.isLowStock, isTrue);
    expect(product.effectivePrice, 120);
  });

  test('Cart totals apply percent coupons', () {
    const product = Product(
      id: 1,
      categoryId: 1,
      name: 'Drill',
      slug: 'drill',
      sku: 'QMX-1',
      description: 'Test',
      price: 100,
      stock: 10,
      brand: 'Bosch',
      images: ['https://example.com/a.jpg'],
    );
    const cart = Cart(
      items: [CartItem(product: product, quantity: 2)],
      coupon: Coupon(id: 1, code: 'QMAX10', type: CouponType.percent, value: 10),
      deliveryFee: 10,
    );
    expect(cart.subtotal, 200);
    expect(cart.discount, 20);
    expect(cart.total, 190);
  });
}
