import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

enum ConnectivityStatus { online, offline, syncing }

class ConnectivityService extends Notifier<ConnectivityStatus> {
  late Connectivity _connectivity;
  late InternetConnectionChecker _internetConnectionChecker;

  @override
  ConnectivityStatus build() {
    _connectivity = Connectivity();
    _internetConnectionChecker = InternetConnectionChecker.instance;
    _init();
    return ConnectivityStatus.offline;
  }

  void _init() {
    _connectivity.onConnectivityChanged.listen((results) {
      _checkStatus(results);
    });

    _connectivity.checkConnectivity().then(_checkStatus);
  }

  Future<void> _checkStatus(List<ConnectivityResult> results) async {
    bool isConnected = results.any(
      (result) => result != ConnectivityResult.none,
    );

    print('ConnectivityService: results=$results, isConnected=$isConnected');

    if (isConnected) {
      try {
        bool hasInternet = await _internetConnectionChecker.hasConnection;
        print('ConnectivityService: hasInternet=$hasInternet');
        state = hasInternet
            ? ConnectivityStatus.online
            : ConnectivityStatus.offline;
      } catch (e) {
        print('ConnectivityService: Error checking internet: $e');
        state = ConnectivityStatus.online; // Fallback
      }
    } else {
      state = ConnectivityStatus.offline;
    }
  }

  void updateManualStatus(ConnectivityStatus status) {
    state = status;
  }
}

final connectivityServiceProvider =
    NotifierProvider<ConnectivityService, ConnectivityStatus>(() {
      return ConnectivityService();
    });
