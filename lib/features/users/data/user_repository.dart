import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/database_provider.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/app_user.dart';

class CreateUserResult {
  const CreateUserResult({required this.user, required this.createdOffline});

  final AppUser user;
  final bool createdOffline;
}

class UserRepository {
  UserRepository({
    required Dio reqresDio,
    required AppDatabase database,
    required ConnectivityService connectivityService,
    required Uuid uuid,
  }) : _reqresDio = reqresDio,
       _database = database,
       _connectivityService = connectivityService,
       _uuid = uuid;

  final Dio _reqresDio;
  final AppDatabase _database;
  final ConnectivityService _connectivityService;
  final Uuid _uuid;

  Stream<List<AppUser>> watchLocalUsers() {
    return _database.watchLocalUsers().map(
      (rows) => rows.map(AppUser.fromLocalRow).toList(),
    );
  }

  Future<PaginatedUsersPage> fetchUsers({required int page}) async {
    final response = await _reqresDio.get<Map<String, dynamic>>(
      '/api/users',
      queryParameters: {'page': page},
    );

    final data = response.data ?? const <String, dynamic>{};
    final items = (data['data'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => AppUser(
            localId: 'remote-${json['id']}',
            remoteId: '${json['id']}',
            name: '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'
                .trim(),
            email: json['email'] as String?,
            avatarUrl: json['avatar'] as String?,
            origin: UserOrigin.remote,
          ),
        )
        .toList();

    return PaginatedUsersPage(
      items: items,
      page: (data['page'] as num?)?.toInt() ?? page,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? page,
    );
  }

  Future<CreateUserResult> createUser({
    required String name,
    required String job,
  }) async {
    final now = DateTime.now();
    final localId = _uuid.v4();
    final isOnline = await _connectivityService.isOnline();

    if (isOnline) {
      final response = await _reqresDio.post<Map<String, dynamic>>(
        '/api/users',
        data: {'name': name, 'job': job},
      );

      final remoteId = _extractCreatedUserId(response.data);
      final user = AppUser(
        localId: localId,
        remoteId: remoteId,
        name: name,
        job: job,
        origin: UserOrigin.local,
      );

      await _database.upsertLocalUser(
        LocalUsersCompanion.insert(
          localId: localId,
          remoteId: Value(remoteId),
          name: name,
          job: Value(job),
          createdAt: now,
          updatedAt: now,
        ),
      );

      return CreateUserResult(user: user, createdOffline: false);
    }

    final user = AppUser(
      localId: localId,
      name: name,
      job: job,
      origin: UserOrigin.local,
      isPendingSync: true,
    );

    await _database.upsertLocalUser(
      LocalUsersCompanion.insert(
        localId: localId,
        name: name,
        job: Value(job),
        isPendingSync: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _database.enqueuePendingUser(
      localId: localId,
      payload: jsonEncode({'name': name, 'job': job}),
    );

    return CreateUserResult(user: user, createdOffline: true);
  }

  Future<void> syncPendingUsers() async {
    if (!await _connectivityService.isOnline()) {
      return;
    }

    final pendingUsers = await _database.getPendingUsers();
    for (final user in pendingUsers) {
      try {
        final response = await _reqresDio.post<Map<String, dynamic>>(
          '/api/users',
          data: {'name': user.name, 'job': user.job ?? 'Unspecified'},
        );

        final remoteId = _extractCreatedUserId(response.data);
        await _database.markUserSynced(
          localId: user.localId,
          remoteId: remoteId,
        );
      } catch (error) {
        await _database.markSyncFailure(localId: user.localId, error: error);
      }
    }
  }

  String _extractCreatedUserId(Map<String, dynamic>? data) {
    final raw = data?['id'];
    if (raw == null || '$raw'.trim().isEmpty) {
      return _uuid.v4();
    }
    return '$raw';
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(
    reqresDio: ref.watch(reqresDioProvider),
    database: ref.watch(appDatabaseProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
    uuid: const Uuid(),
  );
});
