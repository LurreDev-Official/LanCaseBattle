import 'dart:async';
import 'dart:convert';

import 'package:lancast_core/lancast_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket signaling client used by Sender.
class SignalingClient {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final _envelopeController = StreamController<Envelope>.broadcast();
  bool _connected = false;

  bool get isConnected => _connected;
  Stream<Envelope> get envelopes$ => _envelopeController.stream;

  Future<void> connect(Uri wsUrl) async {
    await disconnect();
    _channel = WebSocketChannel.connect(wsUrl);
    await _channel!.ready;
    _connected = true;
    _sub = _channel!.stream.listen(
      (event) {
        try {
          final raw = event is String
              ? event
              : event is List<int>
                  ? utf8.decode(event)
                  : event.toString();
          final envelope = Envelope.fromJsonString(raw);
          if (!_envelopeController.isClosed) {
            _envelopeController.add(envelope);
          }
        } catch (_) {}
      },
      onDone: () {
        _connected = false;
      },
      onError: (_) {
        _connected = false;
      },
    );
  }

  void send(Envelope envelope) {
    final channel = _channel;
    if (channel == null || !_connected) {
      throw StateError('SignalingClient is not connected');
    }
    channel.sink.add(envelope.toJsonString());
  }

  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
    _connected = false;
  }

  Future<void> dispose() async {
    await disconnect();
    await _envelopeController.close();
  }
}
