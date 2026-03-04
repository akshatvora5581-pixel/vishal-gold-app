import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsProvider extends ChangeNotifier {
  bool _newOrderAlerts = true;
  bool _inventoryAlerts = true;
  bool _customerFeedbackAlerts = true;
  bool _isLoaded = false;

  bool get newOrderAlerts => _newOrderAlerts;
  bool get inventoryAlerts => _inventoryAlerts;
  bool get customerFeedbackAlerts => _customerFeedbackAlerts;
  bool get isLoaded => _isLoaded;

  NotificationSettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _newOrderAlerts = prefs.getBool('notify_new_order') ?? true;
    _inventoryAlerts = prefs.getBool('notify_inventory') ?? true;
    _customerFeedbackAlerts = prefs.getBool('notify_feedback') ?? true;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> toggleNewOrder(bool value) async {
    _newOrderAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_new_order', value);
    notifyListeners();
  }

  Future<void> toggleInventory(bool value) async {
    _inventoryAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_inventory', value);
    notifyListeners();
  }

  Future<void> toggleFeedback(bool value) async {
    _customerFeedbackAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notify_feedback', value);
    notifyListeners();
  }
}
