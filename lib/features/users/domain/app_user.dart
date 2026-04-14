import '../../../core/db/app_database.dart';

enum UserOrigin { remote, local }

class AppUser {
  const AppUser({
    required this.localId,
    required this.name,
    required this.origin,
    this.remoteId,
    this.job,
    this.email,
    this.avatarUrl,
    this.isPendingSync = false,
  });

  factory AppUser.fromLocalRow(LocalUser row) {
    return AppUser(
      localId: row.localId,
      remoteId: row.remoteId,
      name: row.name,
      job: row.job,
      email: row.email,
      avatarUrl: row.avatarUrl,
      isPendingSync: row.isPendingSync,
      origin: UserOrigin.local,
    );
  }

  final String localId;
  final String? remoteId;
  final String name;
  final String? job;
  final String? email;
  final String? avatarUrl;
  final bool isPendingSync;
  final UserOrigin origin;

  String get subtitle {
    if (job?.isNotEmpty == true) {
      return job!;
    }
    if (email?.isNotEmpty == true) {
      return email!;
    }
    if (isPendingSync) {
      return 'Pending sync';
    }
    return origin == UserOrigin.remote
        ? 'Remote directory user'
        : 'Local app user';
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class PaginatedUsersPage {
  const PaginatedUsersPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<AppUser> items;
  final int page;
  final int totalPages;
}
