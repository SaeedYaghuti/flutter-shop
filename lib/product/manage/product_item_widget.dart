import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/product/manage/product_form_screen.dart';
import '../product_provider.dart';

class ProductItemWidget extends StatelessWidget {
  final String productId;
  final String title;
  final String imageUrl;

  const ProductItemWidget({
    Key? key,
    required this.productId,
    required this.title,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(imageUrl),
      ),
      title: Text(title),
      trailing: Container(
        width: 120,
        child: Row(
          children: [
            _buildEditButton(context),
            _buildDeleteButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.edit),
      color: Theme.of(context).primaryColor,
      onPressed: () {
        Navigator.of(context).pushNamed(
          ProductFormScreen.routeName,
          arguments: productId,
        );
      },
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    var scaffold = Scaffold.of(context);
    return IconButton(
      icon: Icon(Icons.delete),
      color: Theme.of(context).errorColor,
      onPressed: () async {
        try {
          await Provider.of<ProductProvider>(context, listen: false)
              .deleteProduct(productId);
        } catch (e) {
          scaffold.showSnackBar(SnackBar(
              content: Text(
            'Delete Failed!',
            textAlign: TextAlign.center,
          )));
        }
      },
    );
  }
}
