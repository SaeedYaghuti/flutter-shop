import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/common/app_drawer.dart';
import 'package:shop/common/show_dialog.dart';
import 'package:shop/product/manage/product_form_screen.dart';
import 'package:shop/product/manage/product_item_widget.dart';
import '../product_provider.dart';

class ManageProductScreen extends StatefulWidget {
  static const routeName = '/user-product';
  const ManageProductScreen({Key? key}) : super(key: key);

  @override
  _ManageProductScreenState createState() => _ManageProductScreenState();
}

class _ManageProductScreenState extends State<ManageProductScreen> {
  var _isLoading = false;
  Future<void> _refreshProducts(BuildContext context) async {
    try {
      await Provider.of<ProductProvider>(context, listen: false)
          .fetchAndSetProducts(true);
    } on Exception catch (e) {
      showErrorDialog(
        context,
        '_refreshProducts',
        'Error happend while refreshing product at ManageProductScreen',
        e,
      );
    }
  }

  @override
  void initState() {
    _loadingStart();
    Provider.of<ProductProvider>(context, listen: false)
        .fetchAndSetProducts(true)
        .then(
      (value) {
        _loadingEnd();
      },
    ).catchError(
      (e) {
        _loadingEnd();
        showErrorDialog(
          context,
          '_refreshProducts',
          'Error happend while refreshing product at ManageProductScreen',
          e,
        );
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context, listen: true);
    final products = productProvider.items;
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Products'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed(ProductFormScreen.routeName);
            },
          )
        ],
      ),
      drawer: AppDrwer(),
      body: RefreshIndicator(
        onRefresh: () => _refreshProducts(context),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Padding(
                padding: EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: productProvider.items.length,
                  itemBuilder: (ctx, index) => ProductItemWidget(
                      productId: products[index].id,
                      title: products[index].title,
                      imageUrl: products[index].imageUrl),
                ),
              ),
      ),
    );
  }

  void _loadingStart() {
    setState(() {
      _isLoading = true;
    });
  }

  void _loadingEnd() {
    setState(() {
      _isLoading = false;
    });
  }
}
