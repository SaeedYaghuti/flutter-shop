import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:shop/auth/auth_provider.dart';
import 'package:shop/cart/cart_provider.dart';

import '../product_details_screen/product_detail_screen.dart';
import './product.dart';

class ProductItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final product = Provider.of<Product>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GridTile(
        child: _buildProducImage(context, product),
        footer: GridTileBar(
          leading: _buildFavoriteButton(
            context,
            product,
            authProvider.token!,
            authProvider.userId!,
          ),
          title: Text(product.title, textAlign: TextAlign.center),
          trailing: _buildCartButton(context, product, cart),
          backgroundColor: Colors.black87,
        ),
      ),
    );
  }

  void navigateToProductDetailsScreen(BuildContext context, String productId) {
    Navigator.of(context).pushNamed(
      ProductDetailScreen.routeName,
      arguments: productId,
    );
  }

  Widget _buildFavoriteButton(
    BuildContext context,
    Product product,
    String token,
    String userId,
  ) {
    return Consumer<Product>(
      builder: (ctx, produtc, child) => IconButton(
        icon: Icon(product.isFavorite ? Icons.favorite : Icons.favorite_border),
        color: Theme.of(context).accentColor,
        onPressed: () async {
          try {
            await product.toggleFavoriteStatus(
              token,
              userId,
            );
          } catch (e) {
            print('Warn: handled error at _buildFavoriteButton catch-block');
            Scaffold.of(context).hideCurrentSnackBar();
            Scaffold.of(context).showSnackBar(SnackBar(
              content: Text('Failed to change favorite status'),
              duration: Duration(seconds: 2),
            ));
          }
        },
      ),
    );
  }

  Widget _buildCartButton(
    BuildContext context,
    Product product,
    CartProvider cart,
  ) {
    return IconButton(
      icon: Icon(Icons.shopping_cart),
      color: Theme.of(context).accentColor,
      onPressed: () {
        cart.addItem(
          id: product.id,
          title: product.title,
          price: product.price,
          imageUrl: product.imageUrl,
        );
        Scaffold.of(context).hideCurrentSnackBar();
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text('Add item to crt'),
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              cart.removeSingleItem(product.id);
            },
          ),
        ));
      },
    );
  }

  Widget _buildProducImage(BuildContext context, Product product) {
    return GestureDetector(
      onTap: () => navigateToProductDetailsScreen(context, product.id),
      child: Image.network(
        product.imageUrl,
        fit: BoxFit.cover,
      ),
    );
  }

  /*
Widget build(BuildContext context) {

    final product = Provider.of<Product>(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GridTile(
        child: GestureDetector(
          onTap: () => navigateToProductDetailsScreen(context, product.id),
          child: Image.network(
            product.imageUrl,
            fit: BoxFit.cover,
          ),
        ),
        footer: GridTileBar(
          backgroundColor: Colors.black87,
          leading: IconButton(
            icon: Icon(
                product.isFavorite ? Icons.favorite : Icons.favorite_border),
            color: Theme.of(context).accentColor,
            onPressed: () => product.toggleFavoriteStatus(),
          ),
          title: Text(
            product.title,
            textAlign: TextAlign.center,
          ),
          // subtitle: Text(product.description),
          trailing: Icon(
            Icons.shopping_cart,
            color: Theme.of(context).accentColor,
          ),
        ),
      ),
    );
  }

  */

}
