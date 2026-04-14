import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class LocalUsers extends Table {
  TextColumn get localId => text()();

  TextColumn get remoteId => text().nullable()();

  TextColumn get name => text()();

  TextColumn get job => text().nullable()();

  TextColumn get email => text().nullable()();

  TextColumn get avatarUrl => text().nullable()();

  BoolColumn get isPendingSync =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {localId};
}

class Bookmarks extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get userLocalId => text()();

  TextColumn get userRemoteId => text().nullable()();

  TextColumn get movieId => text()();

  TextColumn get movieTitle => text()();

  TextColumn get posterUrl => text().nullable()();

  TextColumn get releaseDate => text().nullable()();

  TextColumn get plot => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {userLocalId, movieId},
  ];
}

class SyncQueueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get entityType => text()();

  TextColumn get entityLocalId => text()();

  TextColumn get action => text()();

  TextColumn get payload => text()();

  TextColumn get status => text().withDefault(const Constant('pending'))();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  TextColumn get lastError => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
}

@DriftDatabase(tables: [LocalUsers, Bookmarks, SyncQueueEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Stream<List<LocalUser>> watchLocalUsers() {
    return (select(localUsers)..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<void> upsertLocalUser(LocalUsersCompanion entry) {
    return into(localUsers).insertOnConflictUpdate(entry);
  }

  Future<LocalUser?> findLocalUser(String localId) {
    return (select(
      localUsers,
    )..where((t) => t.localId.equals(localId))).getSingleOrNull();
  }

  Future<List<LocalUser>> getPendingUsers() {
    return (select(
      localUsers,
    )..where((t) => t.isPendingSync.equals(true))).get();
  }

  Future<void> markUserSynced({
    required String localId,
    required String remoteId,
  }) async {
    await transaction(() async {
      await (update(localUsers)..where((t) => t.localId.equals(localId))).write(
        LocalUsersCompanion(
          remoteId: Value(remoteId),
          isPendingSync: const Value(false),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await (update(
        bookmarks,
      )..where((t) => t.userLocalId.equals(localId))).write(
        BookmarksCompanion(
          userRemoteId: Value(remoteId),
          updatedAt: Value(DateTime.now()),
        ),
      );

      await (update(syncQueueEntries)..where(
            (t) =>
                t.entityLocalId.equals(localId) &
                t.entityType.equals('user') &
                t.action.equals('create'),
          ))
          .write(
            SyncQueueEntriesCompanion(
              status: const Value('completed'),
              updatedAt: Value(DateTime.now()),
              lastError: const Value.absent(),
            ),
          );
    });
  }

  Future<void> enqueuePendingUser({
    required String localId,
    required String payload,
  }) {
    return into(syncQueueEntries).insert(
      SyncQueueEntriesCompanion.insert(
        entityType: 'user',
        entityLocalId: localId,
        action: 'create',
        payload: payload,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> markSyncFailure({
    required String localId,
    required Object error,
  }) {
    return (update(syncQueueEntries)..where(
          (t) =>
              t.entityLocalId.equals(localId) &
              t.entityType.equals('user') &
              t.action.equals('create'),
        ))
        .write(
          SyncQueueEntriesCompanion(
            status: const Value('failed'),
            lastError: Value(error.toString()),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> upsertBookmark(BookmarksCompanion entry) {
    return into(bookmarks).insert(entry, mode: InsertMode.insertOrReplace);
  }

  Future<void> removeBookmark({
    required String userLocalIdValue,
    required String movieIdValue,
  }) {
    return (delete(bookmarks)..where(
          (t) =>
              t.userLocalId.equals(userLocalIdValue) &
              t.movieId.equals(movieIdValue),
        ))
        .go();
  }

  Stream<List<Bookmark>> watchBookmarksForUser(String userLocalIdValue) {
    return (select(bookmarks)
          ..where((t) => t.userLocalId.equals(userLocalIdValue))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'reel_bridge.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
