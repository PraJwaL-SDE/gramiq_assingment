import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isDialogShowing = false;

  void initialize() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _checkStatus(results);
    });
    
    // Initial check
    _connectivity.checkConnectivity().then((results) => _checkStatus(results));
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _checkStatus(List<ConnectivityResult> results) {
    bool hasConnection = results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi || 
      result == ConnectivityResult.ethernet
    );

    if (!hasConnection) {
      _showNoInternetDialog();
    } else if (_isDialogShowing) {
      _hideNoInternetDialog();
    }
  }

  void _showNoInternetDialog() async {
    if (_isDialogShowing) return;
    
    // If context is not ready yet (e.g. during splash initialization), 
    // wait a bit and try again.
    if (navigatorKey.currentContext == null) {
      await Future.delayed(const Duration(milliseconds: 500));
      _showNoInternetDialog();
      return;
    }

    final context = navigatorKey.currentContext;
    if (context == null) return;

    _isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.redAccent),
              SizedBox(width: 10),
              Text('No Connection'),
            ],
          ),
          content: const Text(
            'It seems you are offline. Please check your internet connection to continue using Plant Doctor AI.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final results = await _connectivity.checkConnectivity();
                bool stillOffline = !results.any((result) => 
                  result == ConnectivityResult.mobile || 
                  result == ConnectivityResult.wifi || 
                  result == ConnectivityResult.ethernet
                );
                
                if (!stillOffline) {
                  _hideNoInternetDialog();
                } else {
                  // Show a little shake or toast? For now just stay.
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  void _hideNoInternetDialog() {
    if (!_isDialogShowing) return;
    
    final context = navigatorKey.currentContext;
    if (context != null && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    _isDialogShowing = false;
  }
}
