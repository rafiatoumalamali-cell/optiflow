import 'package:flutter/material.dart';

class CurrencyProvider with ChangeNotifier {
  String _currencyCode = 'XOF';
  String get currencyCode => _currencyCode;

  String get currencySymbol {
    switch (_currencyCode) {
      case 'GHS': return '₵';
      case 'NGN': return '₦';
      default: return 'CFA';
    }
  }

  String get symbol => currencySymbol;

  void setCurrency(String code) {
    _currencyCode = code;
    notifyListeners();
  }
}
