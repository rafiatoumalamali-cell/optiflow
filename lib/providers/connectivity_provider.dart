import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync/sync_manager.dart';
import '../services/shared_preferences_service.dart';
import '../utils/logger.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  final SyncManager _syncManager = SyncManager();

  ConnectivityProvider() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) async {
      final bool wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      if (wasOffline && _isOnline) {
        Logger.info('Connectivity: Online restored. Triggering full sync...', name: 'ConnectivityProvider');
        final businessId = SharedPreferencesService.businessId;
        if (businessId != null && businessId.isNotEmpty) {
          await _syncManager.performFullSync(businessId);
        }
      }
      
      notifyListeners();
    });
  }
}
