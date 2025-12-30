import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/connectivity_service.dart';
import '../../services/sync_service.dart';

class ConnectivityController extends Notifier<ConnectivityStatus> {
  @override
  ConnectivityStatus build() {
    final connectivityStatus = ref.watch(connectivityServiceProvider);
    final isSyncing = ref.watch(syncStatusNotifierProvider);

    if (connectivityStatus == ConnectivityStatus.online) {
      return isSyncing ? ConnectivityStatus.syncing : ConnectivityStatus.online;
    }

    return connectivityStatus;
  }

  void updateStatus(ConnectivityStatus status) {
    state = status;
  }
}

final connectivityControllerProvider =
    NotifierProvider<ConnectivityController, ConnectivityStatus>(() {
      return ConnectivityController();
    });
