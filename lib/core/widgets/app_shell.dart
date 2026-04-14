import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/connectivity_service.dart';
import '../network/network_retry_monitor.dart';
import '../sync/sync_service.dart';
import '../sync/workmanager_service.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  ProviderSubscription<AsyncValue<bool>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeServices());
    _connectivitySubscription = ref.listenManual<AsyncValue<bool>>(
      connectivityStatusProvider,
      (previous, next) {
        final wasOnline = previous?.value ?? false;
        final isOnline = next.value ?? false;

        if (!wasOnline && isOnline) {
          unawaited(_runPendingSyncs());
        }
      },
    );
  }

  @override
  void dispose() {
    _connectivitySubscription?.close();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await ref.read(workmanagerServiceProvider).initialize();
    await _runPendingSyncs();
  }

  Future<void> _runPendingSyncs() async {
    await ref.read(syncServiceProvider).runPendingSyncs();
    await ref.read(workmanagerServiceProvider).schedulePendingSync();
  }

  @override
  Widget build(BuildContext context) {
    final isRetrying = ref.watch(isRetryingNetworkProvider);

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: IgnorePointer(
            child: AnimatedSlide(
              offset: isRetrying ? Offset.zero : const Offset(0, -1.4),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: isRetrying ? 1 : 0,
                duration: const Duration(milliseconds: 160),
                child: const _RetryBanner(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RetryBanner extends StatelessWidget {
  const _RetryBanner();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 18,
                  color: Color(0x33000000),
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'Reconnecting...',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
