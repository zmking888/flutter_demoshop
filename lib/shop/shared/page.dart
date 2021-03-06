// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'theme.dart';
import 'types.dart';
import '../cart.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import '../redux/app_state.dart';
import '../redux/actions.dart';
import 'routes.dart';

enum ShrineAction { sortByPrice, sortByProduct, emptyCart }

class ShrinePage extends StatefulWidget {
  const ShrinePage(
      {Key key,
      @required this.scaffoldKey,
      @required this.body,
      this.floatingActionButton})
      : assert(body != null),
        assert(scaffoldKey != null),
        super(key: key);

  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget body;
  final Widget floatingActionButton;

  @override
  ShrinePageState createState() => new ShrinePageState();
}

/// Defines the Scaffold, AppBar, etc that the demo pages have in common.
class ShrinePageState extends State<ShrinePage> {
  double _appBarElevation = 0.0;

  bool _handleScrollNotification(ScrollNotification notification) {
    final double elevation =
        notification.metrics.extentBefore <= 0.0 ? 0.0 : 1.0;
    if (elevation != _appBarElevation) {
      setState(() {
        _appBarElevation = elevation;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final ShrineTheme theme = ShrineTheme.of(context);
    return new StoreConnector<AppState, _ViewModel>(
      converter: _ViewModel.fromStore,
      builder: (context, vm) {
        return new Scaffold(
            key: widget.scaffoldKey,
            appBar: new AppBar(
                elevation: _appBarElevation,
                iconTheme: Theme.of(context).iconTheme,
                brightness: Brightness.light,
                flexibleSpace: new Container(
                    decoration: new BoxDecoration(
                        border: new Border(
                            bottom: new BorderSide(
                                color: theme.appBarBorderColor)))),
                title: new Text('ДЕМО',
                    style: ShrineTheme.of(context).appBarTitleStyle),
                centerTitle: true,
                actions: <Widget>[
                  new IconButton(
                      icon: new Icon(Icons.shopping_cart,
                          color: vm.shoppingCart.isEmpty
                              ? Colors.white70
                              : theme.appBarFullCartIconColor),
                      tooltip: 'Корзина',
                      onPressed: vm.onEditCart(context)),
                  new PopupMenuButton<ShrineAction>(
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuItem<ShrineAction>>[
                            const PopupMenuItem<ShrineAction>(
                                value: ShrineAction.sortByPrice,
                                child: const Text('Сортировать по цене')),
                            const PopupMenuItem<ShrineAction>(
                                value: ShrineAction.sortByProduct,
                                child: const Text('Сортировать по названию')),
                            const PopupMenuItem<ShrineAction>(
                                value: ShrineAction.emptyCart,
                                child: const Text('Очистить корзину'))
                          ],
                      onSelected: (ShrineAction action) {
                        switch (action) {
                          case ShrineAction.sortByPrice:
                            vm.onSortByPrice();
                            break;
                          case ShrineAction.sortByProduct:
                            vm.onSortByName();
                            break;
                          case ShrineAction.emptyCart:
                            vm.onClearCart();
                            break;
                        }
                      })
                ]),
            floatingActionButton: widget.floatingActionButton,
            body: new NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification, child: widget.body));
      },
    );
  }
}

class _ViewModel {
  final List<Product> products;
  final Function() onSortByName;
  final Function() onSortByPrice;

  final Map<Product, Order> shoppingCart;
  final Function() onClearCart;
  final Function(BuildContext context) onEditCart;

  _ViewModel({
    @required this.products,
    @required this.onSortByName,
    @required this.onSortByPrice,
    @required this.shoppingCart,
    @required this.onClearCart,
    @required this.onEditCart,
  });

  static _ViewModel fromStore(Store<AppState> store) {
    return new _ViewModel(
      products: store.state.products,
      shoppingCart: store.state.shoppingCart,
      onSortByName: () => store.dispatch(new ProductsSortByNameAction()),
      onSortByPrice: () => store.dispatch(new ProductsSortByPriceAction()),
      onClearCart: () => store.dispatch(new ClearCartAction()),
      onEditCart: (BuildContext context) {
        final BuildContext _context = context;
        return () async {
          if (store.state.shoppingCart.isEmpty) {
            showModalBottomSheet<Null>(
                context: _context,
                builder: (BuildContext context) {
                  if (store.state.shoppingCart.isEmpty) {
                    return const Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: const Text('Корзина пуста'));
                  }
                });
          } else {
            await Navigator.push(
              _context,
              new ShrineCartRoute(builder: (BuildContext context) {
                return new CartPage();
              }),
            );
          }
        };
      },
    );
  }
}
