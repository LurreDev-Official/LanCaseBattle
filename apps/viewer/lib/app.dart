import 'package:flutter/material.dart';
import 'package:lancast_arena/lancast_arena.dart';
import 'package:lancast_viewer/core/router/app_router.dart';

class LancastViewerApp extends StatelessWidget {
  const LancastViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LanCast Arena',
      debugShowCheckedModeBanner: false,
      theme: ArenaTheme.dark(),
      routerConfig: buildViewerRouter(),
    );
  }
}
