import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

import '../../features/users/data/user_repository.dart';
import '../config/app_config.dart';
import '../db/app_database.dart';
import '../network/connectivity_service.dart';

const pendingUserSyncTask = 'pending-user-sync-task';

@pragma('vm:entry-point')
void reelBridgeCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    if (task != pendingUserSyncTask) {
      return true;
    }

    final config = AppConfig.fromEnvironment();
    final database = AppDatabase();
    final userRepository = UserRepository(
      reqresDio: Dio(
        BaseOptions(
          baseUrl: config.reqresBaseUrl,
          headers: {
            'x-api-key': config.reqresApiKey,
            'X-Reqres-Env': config.reqresEnvironment,
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ),
      database: database,
      connectivityService: ConnectivityService(Connectivity()),
      uuid: const Uuid(),
    );

    try {
      await userRepository.syncPendingUsers();
      return true;
    } catch (_) {
      return false;
    } finally {
      await database.close();
    }
  });
}

class WorkmanagerService {
  Future<void> initialize() async {
    if (_initialized || !_supportsWorkmanager) {
      return;
    }

    await Workmanager().initialize(reelBridgeCallbackDispatcher);
    _initialized = true;
  }

  Future<void> schedulePendingSync() async {
    if (!_supportsWorkmanager) {
      return;
    }

    await Workmanager().registerOneOffTask(
      pendingUserSyncTask,
      pendingUserSyncTask,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.connected),
      initialDelay: const Duration(seconds: 3),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 10),
    );
  }

  bool get _supportsWorkmanager {
    if (kIsWeb) {
      return false;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => true,
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  static bool _initialized = false;
}

final workmanagerServiceProvider = Provider<WorkmanagerService>((ref) {
  return WorkmanagerService();
});
