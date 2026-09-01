import 'package:go_router/go_router.dart';
import 'package:lancast_viewer/features/approval/presentation/approval_queue_screen.dart';
import 'package:lancast_viewer/features/arena/presentation/arena_home_screen.dart';
import 'package:lancast_viewer/features/arena/presentation/arena_lobby_screen.dart';
import 'package:lancast_viewer/features/arena/presentation/battle_arena_screen.dart';
import 'package:lancast_viewer/features/arena/presentation/create_battle_screen.dart';
import 'package:lancast_viewer/features/arena/presentation/judge_dashboard_screen.dart';
import 'package:lancast_viewer/features/devices/presentation/device_manager_screen.dart';
import 'package:lancast_viewer/features/room/presentation/room_dashboard_screen.dart';
import 'package:lancast_viewer/features/settings/presentation/settings_screen.dart';

abstract final class ViewerRoutes {
  static const home = '/';
  static const createBattle = '/arena/create';
  static const lobby = '/arena/lobby';
  static const arena = '/arena/battle';
  static const judge = '/arena/judge';
  static const createRoom = '/room/create';
  static const dashboard = '/room/dashboard';
  static const approval = '/room/approval';
  static const devices = '/room/devices';
  static const settings = '/settings';
}

GoRouter buildViewerRouter() {
  return GoRouter(
    initialLocation: ViewerRoutes.home,
    routes: [
      GoRoute(
        path: ViewerRoutes.home,
        builder: (context, state) => const ArenaHomeScreen(),
      ),
      GoRoute(
        path: ViewerRoutes.createBattle,
        builder: (context, state) => const CreateBattleScreen(),
      ),
      GoRoute(
        path: ViewerRoutes.lobby,
        builder: (context, state) => const ArenaLobbyScreen(),
      ),
      GoRoute(
        path: ViewerRoutes.arena,
        builder: (context, state) => const BattleArenaScreen(),
      ),
      GoRoute(
        path: ViewerRoutes.judge,
        builder: (context, state) => const JudgeDashboardScreen(),
      ),
      GoRoute(
        path: ViewerRoutes.dashboard,
        builder: (context, state) => const RoomDashboardScreen(),
      ),
      GoRoute(
        path: ViewerRoutes.createRoom,
        builder: (context, state) => const CreateBattleScreen(),
      ),
      GoRoute(
        path: ViewerRoutes.approval,
        builder: (context, state) => const ApprovalQueueScreen(),
      ),
      GoRoute(
        path: ViewerRoutes.devices,
        builder: (context, state) => const DeviceManagerScreen(),
      ),
      GoRoute(
        path: ViewerRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}
