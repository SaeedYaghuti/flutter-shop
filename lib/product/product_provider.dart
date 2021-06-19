import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop/common/db.dart';
import 'package:shop/db/db_helper.dart';
import 'product.dart';

class ProductProvider with ChangeNotifier {
  final String? _userId;
  final String? _token;
  List<Product> _items = [];

  ProductProvider(
    this._userId,
    this._token,
    this._items,
  );

  List<Product> get items {
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((product) => product.isFavorite == true).toList();
  }

  Future<void> addProduct(Product product) async {
    try {
      final postUrl = Uri.parse(dbUrl + 'products.json?auth=$_token');
      final response =
          await http.post(postUrl, body: product.encodeToJson(_userId!));
      final productData = json.decode(response.body);
      _items.add(product.replaceId(productData['name']));
      notifyListeners();

      var rowNumber = await DBHelper.insert(
        'product',
        product.toMap(_userId!),
      );
      print('PP10| DBHelper.insert rowNumber: $rowNumber');
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<void> fetchAndSetProducts([bool currentUserProduct = false]) async {
    try {
      final filter =
          currentUserProduct ? 'orderBy="creatorId"&equalTo="$_userId"' : '';
      final postUrl = Uri.parse(dbUrl + 'products.json?auth=$_token&$filter');
      final response = await http.get(postUrl);
      final fetchedProducts =
          json.decode(response.body) as Map<String, dynamic>;

      if (fetchedProducts == null) {
        // we don't have any product yer!
        return;
      }
      if (fetchedProducts['error'] != null) {
        throw HttpException(fetchedProducts['error']);
      }

      final favoriteUrl = Uri.parse(
        dbUrl + 'userFavorites/$_userId.json?auth=$_token',
      );
      final favResponse = await http.get(favoriteUrl);
      final favoriteData = json.decode(favResponse.body);
      if (favoriteData != null && favoriteData['error'] != null) {
        throw HttpException(favoriteData['error']);
      }

      final List<Product> loadedProducts = [];
      fetchedProducts.forEach((prodId, prodData) {
        loadedProducts.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          imageUrl: prodData['imageUrl'],
          isFavorite:
              favoriteData == null ? false : favoriteData['prodId'] ?? false,
        ));
      });
      _items = loadedProducts;
      notifyListeners();

      // fetch data from DB
      final productList = await DBHelper.getData('product');
      print('PP30| fetched data from db productList: $productList');
    } catch (e) {
      print('Error: catch fetchAndSetProducts()');
      print(e.toString());
      throw e;
    }
  }

  Future<void> deleteProduct(String id) async {
    var existingIndex = _items.indexWhere((p) => p.id == id);
    var existingProduct = _items[existingIndex];

    _items.removeWhere((p) => p.id == id);
    notifyListeners();

    final deleteUrl = Uri.parse(dbUrl + 'products/$id.json?auth=$_token');
    final response = await http.delete(deleteUrl);
    if (response.statusCode >= 400) {
      print('WARN: deleteResponse.statusCode >= 400');
      _items.insert(existingIndex, existingProduct);
      notifyListeners();
      throw HttpException('Prblem at deleting product from server!');
    }
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    try {
      final patchUrl = Uri.parse(dbUrl + 'products/$id.json?auth=$_token');
      final response = await http.patch(
        patchUrl,
        body: newProduct.encodeToJson(_userId!),
      );
      var index = _items.indexWhere((p) => p.id == id);
      if (index >= 0) {
        _items[index] = newProduct;
      } else {
        print('WARN: updateProduct() can not find product with id: $id');
      }
      final productData = json.decode(response.body);
      print(productData);
      notifyListeners();
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Product getById(String id) {
    return items.firstWhere((product) => product.id == id);
  }
}
