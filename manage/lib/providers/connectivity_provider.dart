import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);

  final controller = StreamController<bool>();

  controller.add(service.isConnected);

  final subscription = service.connectionStream.listen(
    (connected) => controller.add(connected),
    onError: (error) {
      controller.add(true);
    },
  );

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

final isConnectedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(connectivityServiceProvider);
  try {
    return await service.checkConnection();
  } catch (e) {
    return true;
  }
});
