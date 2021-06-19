import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:shop/auth/auth_provider.dart';
import 'package:shop/auth/auth_screen.dart';
import 'package:shop/common/loading_screen.dart';
import 'package:shop/order/order_provider.dart';
import 'package:shop/order/order_screen.dart';
import 'package:shop/product/manage/manage_product_screen.dart';
import 'package:shop/product/manage/product_form_screen.dart';
import './cart/cart_screen.dart';

import 'product/product_provider.dart';
import './products_overview_screen/products_overview_screen.dart';
import 'product_details_screen/product_detail_screen.dart';
import 'cart/cart_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(
          create: (ctx) => ProductProvider(null, null, []),
          update: (ctx, authProvder, previousProductProvider) =>
              ProductProvider(
            authProvder.userId,
            authProvder.token,
            previousProductProvider == null
                ? []
                : previousProductProvider.items,
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (ctx) => OrderProvider(null, null, []),
          update: (ctx, authProvder, previousOrderProvider) => OrderProvider(
            authProvder.token,
            authProvder.userId,
            previousOrderProvider == null ? [] : previousOrderProvider.orders,
          ),
        ),
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
      ],
      child: MaterialApp(
        title: 'My Shop',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          accentColor: Colors.deepOrange,
          fontFamily: 'Lato',
        ),
        home: Consumer<AuthProvider>(
          builder: (ctx, authProvider, child) {
            return authProvider.isAuth
                ? ProductsOverviewScreen()
                : FutureBuilder(
                    future: authProvider.tryAutoLogin(),
                    builder: (ctx, snapshot) =>
                        snapshot.connectionState == ConnectionState.waiting
                            ? LoadingScreen()
                            : AuthScreen(),
                  );
          },
        ),
        routes: {
          ProductDetailScreen.routeName: (ctx) => ProductDetailScreen(),
          CartScreen.routeName: (ctx) => CartScreen(),
          OrderScreen.routeName: (ctx) => OrderScreen(),
          ManageProductScreen.routeName: (ctx) => ManageProductScreen(),
          ProductFormScreen.routeName: (ctx) => ProductFormScreen(),
        },
      ),
    );
  }
}
