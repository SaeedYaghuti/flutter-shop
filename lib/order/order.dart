import 'dart:convert';

import 'package:shop/cart/cart_item.dart';
import 'package:shop/cart/cart_provider.dart';

class Order {
  final String id;
  final double total;
  final DateTime date;
  final List<CartItem> cartItems;

  Order({
    required this.id,
    required this.total,
    required this.cartItems,
    required this.date,
  });

  String encodeToJson() {
    return json.encode({
      // 'id': id, //we don't need to send our fake id to server
      'total': total,
      'date': date.toIso8601String(),
      'cartItems': CartItem.encodeListToJson(cartItems),
    });
  }

  Order replaceId(String newId) {
    return Order(
      id: newId,
      total: total,
      date: date,
      cartItems: cartItems,
    );
  }

  static Order convertToOrderClass(
    String orderId,
    Map<String, dynamic> jsonOrder,
  ) {
    return Order(
      id: orderId,
      total: jsonOrder['total'] as double,
      date: DateTime.parse(jsonOrder['date'] as String),
      cartItems: CartItem.convertToListOfCartItems(
        jsonOrder['cartItems'] as String,
      ),
    );
  }
}
