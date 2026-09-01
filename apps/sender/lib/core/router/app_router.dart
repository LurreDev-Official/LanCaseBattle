import 'package:go_router/go_router.dart';
import 'package:lancast_sender/features/audio/presentation/audio_settings_screen.dart';
import 'package:lancast_sender/features/discovery/presentation/home_screen.dart';
import 'package:lancast_sender/features/discovery/presentation/room_list_screen.dart';
import 'package:lancast_sender/features/room/presentation/join_via_link_screen.dart';
import 'package:lancast_sender/features/room/presentation/rejected_screen.dart';
import 'package:lancast_sender/features/room/presentation/request_join_screen.dart';
import 'package:lancast_sender/features/room/presentation/waiting_approval_screen.dart';
import 'package:lancast_sender/features/streaming/presentation/sharing_console_screen.dart';

abstract final class SenderRoutes {
  static const home = '/';
  static const roomList = '/rooms';
  static const joinLink = '/join/link';
  static const requestJoin = '/join/request';
  static const waiting = '/join/waiting';
  static const rejected = '/join/rejected';
  static const sharing = '/sharing';
  static const audioSettings = '/settings/audio';
}

GoRouter buildSenderRouter({String? initialJoinLink}) {
  return GoRouter(
    initialLocation: initialJoinLink != null && initialJoinLink.isNotEmpty
        ? SenderRoutes.joinLink
        : SenderRoutes.home,
    routes: [
      GoRoute(
        path: SenderRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: SenderRoutes.roomList,
        builder: (context, state) => const RoomListScreen(),
      ),
      GoRoute(
        path: SenderRoutes.joinLink,
        builder: (context, state) {
          final fromExtra = state.extra as String?;
          final fromQuery = state.uri.queryParameters['url'];
          return JoinViaLinkScreen(
            initialLink: fromExtra ?? fromQuery ?? initialJoinLink,
          );
        },
      ),
      GoRoute(
        path: SenderRoutes.requestJoin,
        builder: (context, state) => const RequestJoinScreen(),
      ),
      GoRoute(
        path: SenderRoutes.waiting,
        builder: (context, state) => const WaitingApprovalScreen(),
      ),
      GoRoute(
        path: SenderRoutes.rejected,
        builder: (context, state) => const RejectedScreen(),
      ),
      GoRoute(
        path: SenderRoutes.sharing,
        builder: (context, state) => const SharingConsoleScreen(),
      ),
      GoRoute(
        path: SenderRoutes.audioSettings,
        builder: (context, state) => const AudioSettingsScreen(),
      ),
    ],
  );
}
