import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  stdout.writeln('=== LIVE PROBE ===');

  try {
    final ws = await WebSocket.connect('ws://127.0.0.1:17890')
        .timeout(const Duration(seconds: 3));
    stdout.writeln('WS: CONNECTED ws://127.0.0.1:17890');
    await ws.close();
  } catch (e) {
    stdout.writeln('WS: FAIL $e');
  }

  try {
    final probe = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      17891,
      reuseAddress: true,
    );
    probe.broadcastEnabled = true;
    stdout.writeln('UDP: listening on 17891 for 5s...');
    final completer = Completer<String>();
    probe.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = probe.receive();
      if (dg == null) return;
      final text = utf8.decode(dg.data);
      if (!completer.isCompleted) {
        completer.complete(
          'from ${dg.address.address}:${dg.port} => $text',
        );
      }
    });

    try {
      final packet = await completer.future.timeout(const Duration(seconds: 5));
      stdout.writeln('UDP: GOT ANNOUNCE');
      stdout.writeln(packet);
    } on TimeoutException {
      stdout.writeln(
        'UDP: NO ANNOUNCE in 5s (viewer not announcing or broadcast blocked)',
      );
    }
    probe.close();
  } catch (e) {
    stdout.writeln('UDP: FAIL $e');
  }

  stdout.writeln('=== DONE ===');
}
