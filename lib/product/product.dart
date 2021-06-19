import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shop/common/db.dart';
import 'package:http/http.dart' as http;

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isFavorite = false,
  });

  void _setFavorite(bool newState) {
    isFavorite = newState;
    notifyListeners();
  }

  Future<void> toggleFavoriteStatus(String token, String userId) async {
    var oldFavorite = isFavorite;
    _setFavorite(!isFavorite);
    try {
      // final patchUrl = Uri.parse(dbUrl + 'products/$id.json?auth=$token');
      final patchUrl =
          Uri.parse(dbUrl + 'userFavorites/$userId/$id.json?auth=$token');
      final response = await http.put(
        patchUrl,
        body: json.encode(isFavorite),
      );
      if (response.statusCode >= 400) {
        print(
            'Warn: handled statusCode >= 400 at toggleFavoriteStatus try-block');
        _setFavorite(oldFavorite);
        throw HttpException('Unable to change favorite status at server');
      }
    } catch (e) {
      print('Warn: handled error at toggleFavoriteStatus catch-block');
      print(e.toString());
      _setFavorite(oldFavorite);
      throw e;
    }
  }

  String encodeToJson(String userId) {
    return json.encode({
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'creatorId': userId,
      // 'isFavorite': isFavorite, // structure changed
    });
  }

  Map<String, Object> toMap(String userId) {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'creatorId': userId,
      // 'isFavorite': isFavorite, // structure changed
    };
  }

  Product replaceId(String newId) {
    return Product(
      id: newId,
      title: title,
      description: description,
      price: price,
      imageUrl: imageUrl,
    );
  }
}
