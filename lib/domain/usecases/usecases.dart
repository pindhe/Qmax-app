import '../../core/network/api_result.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

class SearchProducts {
  SearchProducts(this._catalog);
  final CatalogRepository _catalog;

  Future<ApiResult<PaginatedData<Product>>> call({
    required String query,
    int page = 1,
    ProductFilter? filter,
  }) {
    return _catalog.getProducts(
      page: page,
      filter: (filter ?? const ProductFilter()).copyWith(query: query),
    );
  }
}

class PlaceOrder {
  PlaceOrder(this._orders);
  final OrderRepository _orders;

  Future<ApiResult<Order>> call({
    required Cart cart,
    required Address address,
    required DeliveryMethod delivery,
    required PaymentMethod payment,
  }) {
    return _orders.placeOrder(
      cart: cart,
      address: address,
      delivery: delivery,
      payment: payment,
    );
  }
}
