import 'package:flutter/material.dart';

class CartNotifier extends ValueNotifier<int> {
  CartNotifier._internal() : super(0);

  static final CartNotifier instance = CartNotifier._internal();

  void updateCount(int count) {
    if (value != count) value = count;
  }
}

