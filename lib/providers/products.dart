import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'product.dart';

import '../models/http_exception.dart';

class Products with ChangeNotifier {
  List<Product> _items = [];

  List<Product> get favoriteItems {
    return _items.where((product) => product.isFavorite).toList();
  }

  List<Product> get items {
    return [..._items];
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts() async {
    const url = 'https://flutter-course-1178a.firebaseio.com/products.json';
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) return;
      final List<Product> loadedProduts = [];
      extractedData.forEach((id, product) {
        loadedProduts.add(Product(
            id: id,
            title: product['title'],
            description: product['description'],
            price: product['price'],
            imageUrl: product['imageURL'],
            isFavorite: product['isFavorite']));
      });
      _items = loadedProduts;
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> addProduct(Product product) async {
    const url = 'https://flutter-course-1178a.firebaseio.com/products.json';
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'imageURL': product.imageUrl,
          'price': product.price,
          'isFavorite': product.isFavorite
        }),
      );
      final newProduct = Product(
          id: json.decode(response.body)['name'],
          title: product.title,
          price: product.price,
          description: product.description,
          imageUrl: product.imageUrl);
      _items.add(newProduct);
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> updateProduct(String id, Product product) async {
    final productIndex = _items.indexWhere((p) => p.id == id);
    if (productIndex >= 0) {
      final url =
          'https://flutter-course-1178a.firebaseio.com/products/$id.json';
      await http.patch(url,
          body: json.encode({
            'title': product.title,
            'description': product.description,
            'price': product.price,
            'imageURL': product.imageUrl,
          }));
      _items[productIndex] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    final url = 'https://flutter-course-1178a.firebaseio.com/products/$id.json';
    final productIndex = _items.indexWhere((product) => product.id == id);
    var deleteProduct = _items[productIndex];
    _items.removeAt(productIndex);
    notifyListeners();
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      _items.insert(productIndex, deleteProduct);
      notifyListeners();
      throw HttpException('Could not delete product!');
    }
    deleteProduct = null;
  }
}
