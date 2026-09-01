import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lancast_arena/lancast_arena.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_sender/core/router/app_router.dart';

class LancastSenderApp extends ConsumerStatefulWidget {
  const LancastSenderApp({super.key, this.initialJoinLink});

  final String? initialJoinLink;

  @override
  ConsumerState<LancastSenderApp> createState() => _LancastSenderAppState();
}

class _LancastSenderAppState extends ConsumerState<LancastSenderApp> {
  late final GoRouter _router;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _router = buildSenderRouter(initialJoinLink: widget.initialJoinLink);
    _listenDeepLinks();
  }

  Future<void> _listenDeepLinks() async {
    final appLinks = AppLinks();
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) {
        _openJoinLink(initial.toString());
      }
    } catch (_) {
      // Platform may not support initial link.
    }
    _linkSub = appLinks.uriLinkStream.listen((uri) {
      _openJoinLink(uri.toString());
    });
  }

  void _openJoinLink(String raw) {
    final room = RoomJoinLink.tryDecode(raw);
    if (room == null) return;
    _router.go(SenderRoutes.joinLink, extra: raw);
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LanCast Arena Participant',
      debugShowCheckedModeBanner: false,
      theme: ArenaTheme.dark(),
      routerConfig: _router,
    );
  }
}
