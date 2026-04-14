import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/workmanager_service.dart';
import '../data/user_repository.dart';
import '../domain/app_user.dart';

final localUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(userRepositoryProvider).watchLocalUsers();
});

class RemoteUsersState {
  const RemoteUsersState({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    this.isLoadingMore = false,
  });

  final List<AppUser> items;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  bool get hasMore => currentPage < totalPages;

  RemoteUsersState copyWith({
    List<AppUser>? items,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return RemoteUsersState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class RemoteUsersController extends AsyncNotifier<RemoteUsersState> {
  UserRepository get _repository => ref.read(userRepositoryProvider);

  @override
  Future<RemoteUsersState> build() async {
    final page = await _repository.fetchUsers(page: 1);
    return RemoteUsersState(
      items: page.items,
      currentPage: page.page,
      totalPages: page.totalPages,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = await _repository.fetchUsers(page: 1);
      return RemoteUsersState(
        items: page.items,
        currentPage: page.page,
        totalPages: page.totalPages,
      );
    });
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final page = await _repository.fetchUsers(page: current.currentPage + 1);
      final combined = <String, AppUser>{
        for (final item in current.items) item.localId: item,
        for (final item in page.items) item.localId: item,
      }.values.toList();

      state = AsyncData(
        current.copyWith(
          items: combined,
          currentPage: page.page,
          totalPages: page.totalPages,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }
}

final remoteUsersControllerProvider =
    AsyncNotifierProvider<RemoteUsersController, RemoteUsersState>(
      RemoteUsersController.new,
    );

class AddUserController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<CreateUserResult> submit({
    required String name,
    required String job,
  }) async {
    state = const AsyncLoading();

    try {
      final result = await ref
          .read(userRepositoryProvider)
          .createUser(name: name, job: job);
      ref.invalidate(localUsersProvider);
      ref.invalidate(remoteUsersControllerProvider);

      if (result.createdOffline) {
        unawaited(ref.read(workmanagerServiceProvider).schedulePendingSync());
      }

      state = const AsyncData(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final addUserControllerProvider =
    AsyncNotifierProvider<AddUserController, void>(AddUserController.new);
