import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/users/data/user_repository.dart';

class SyncService {
  SyncService({required UserRepository userRepository})
    : _userRepository = userRepository;

  final UserRepository _userRepository;

  Future<void> runPendingSyncs() async {
    await _userRepository.syncPendingUsers();
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(userRepository: ref.watch(userRepositoryProvider));
});
