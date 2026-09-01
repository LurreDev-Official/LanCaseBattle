import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lancast_core/lancast_core.dart';
import 'package:lancast_sender/app.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  String? initialLink;
  for (final arg in args) {
    if (RoomJoinLink.tryDecode(arg) != null) {
      initialLink = arg;
      break;
    }
  }
  runApp(
    ProviderScope(
      child: LancastSenderApp(initialJoinLink: initialLink),
    ),
  );
}
