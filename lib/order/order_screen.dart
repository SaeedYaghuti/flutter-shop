import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/common/app_drawer.dart';
import 'package:shop/common/show_dialog.dart';
import 'package:shop/order/order_item_widget.dart';
import 'package:shop/order/order_provider.dart';

class OrderScreen extends StatefulWidget {
  static const routeName = '/orders-screen';

  const OrderScreen({Key? key}) : super(key: key);

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  var _isLoading = false;

  @override
  void initState() {
    _loadingStart();

    Provider.of<OrderProvider>(context, listen: false)
        .fetchAndSetOrders()
        .then((value) => _loadingEnd())
        .catchError((e) {
      _loadingEnd();
      print(
          'OS2| Error: OrderScreen > initState : error happend while fetchAndSetOrders');
      print(e.toString());
      showErrorDialog(
        context,
        'OrderScreen',
        'initState > fetchAndSetOrders() > OS3',
        e,
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: true);
    final orders = orderProvider.orders;
    return Scaffold(
      appBar: AppBar(
        title: Text('Order'),
      ),
      drawer: AppDrwer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.length == 0
              ? Center(
                  child: Text(
                  'Nothing to show! please add some order!',
                  style: TextStyle(fontSize: 20),
                ))
              : ListView.builder(
                  itemCount: orderProvider.orders.length,
                  itemBuilder: (ctx, index) =>
                      OrderItemWidget(orderItem: orders[index]),
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
