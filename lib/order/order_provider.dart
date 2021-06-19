import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shop/cart/cart_item.dart';
import 'package:shop/cart/cart_provider.dart';
import 'package:shop/common/db.dart';
import 'package:http/http.dart' as http;

import 'order.dart';

class OrderProvider with ChangeNotifier {
  final String? _token;
  final String? _userId;
  List<Order> _orders = [];

  OrderProvider(this._token, this._userId, this._orders);

  List<Order> get orders {
    return [..._orders];
  }

  Future<void> addOrder(List<CartItem> cartItems, double total) async {
    var now = DateTime.now();

    final orderItem = Order(
      id: now.toIso8601String(),
      total: total,
      cartItems: cartItems,
      date: now,
    );

    try {
      final postUrl = Uri.parse(dbUrl + 'orders/$_userId.json?auth=$_token');
      final response = await http.post(postUrl, body: orderItem.encodeToJson());
      final productData = json.decode(response.body) as Map<String, dynamic>;
      if (productData['error'] != null) {
        throw HttpException(productData['error']);
      }
      _orders.insert(
        0,
        Order(
          id: productData['name'],
          total: total,
          cartItems: cartItems,
          date: now,
        ),
      );
      notifyListeners();
    } catch (e) {
      print('OP1| Error: addOrder() e: ${e.toString()}');
      throw e;
    }
  }

  Future<void> fetchAndSetOrders() async {
    try {
      final postUrl = Uri.parse(dbUrl + 'orders/$_userId.json?auth=$_token');
      final response = await http.get(postUrl);
      if (response == null) {
        return;
      }
      final fetchedOrders = json.decode(response.body) as Map<String, dynamic>;
      // print('OP2| fetchedOrders: $fetchedOrders');
      if (fetchedOrders['error'] != null) {
        throw HttpException(fetchedOrders['error'] as String);
      }
      if (fetchedOrders == null) {
        return;
      }

      final List<Order> loadedOrders = [];
      fetchedOrders.forEach((orderId, orderData) {
        loadedOrders.add(
          Order.convertToOrderClass(orderId, orderData as Map<String, dynamic>),
        );
      });
      _orders = loadedOrders;
      notifyListeners();
    } catch (e) {
      print('OP5| Error: catch fetchAndSetOrders()');
      print(e.toString());
      throw e;
    }
  }
}
