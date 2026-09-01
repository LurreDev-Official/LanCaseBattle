import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:lancast_core/lancast_core.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef EnvelopeHandler = void Function(
  SignalingPeer peer,
  Envelope envelope,
);

/// Embedded WebSocket signaling host (runs inside Viewer).
class SignalingServer {
  SignalingServer({
    this.port = LancastConstants.signalingPort,
  });

  final int port;

  HttpServer? _server;
  final _peers = <SignalingPeer>{};
  final _connectionController = StreamController<SignalingPeer>.broadcast();
  final _envelopeController =
      StreamController<(SignalingPeer, Envelope)>.broadcast();
  EnvelopeHandler? onEnvelope;
  void Function(SignalingPeer peer)? onPeerClosed;
  void Function()? onPeersChanged;
  bool _running = false;

  bool get isRunning => _running;
  int get peerCount => _peers.length;
  int? get boundPort => _server?.port;
  Stream<SignalingPeer> get connections$ => _connectionController.stream;
  Stream<(SignalingPeer, Envelope)> get envelopes$ => _envelopeController.stream;

  Future<void> start() async {
    if (_running) return;

    final handler = webSocketHandler((WebSocketChannel channel, String? _) {
      final peer = SignalingPeer(channel);
      _peers.add(peer);
      onPeersChanged?.call();
      if (!_connectionController.isClosed) {
        _connectionController.add(peer);
      }

      peer.messages.listen(
        (raw) {
          try {
            final envelope = Envelope.fromJsonString(raw);
            if (!envelope.isSupportedVersion) return;
            onEnvelope?.call(peer, envelope);
            if (!_envelopeController.isClosed) {
              _envelopeController.add((peer, envelope));
            }
          } catch (_) {
            // Ignore malformed control frames in MVP.
          }
        },
        onDone: () {
          _peers.remove(peer);
          onPeerClosed?.call(peer);
          onPeersChanged?.call();
        },
        onError: (_) {
          _peers.remove(peer);
          onPeerClosed?.call(peer);
          onPeersChanged?.call();
        },
      );
    });

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    _running = true;
  }

  Future<void> stop() async {
    for (final peer in _peers.toList()) {
      await peer.close();
    }
    _peers.clear();
    await _server?.close(force: true);
    _server = null;
    _running = false;
  }

  Future<void> dispose() async {
    await stop();
    await _connectionController.close();
    await _envelopeController.close();
  }

  void broadcast(Envelope envelope) {
    final text = envelope.toJsonString();
    for (final peer in _peers) {
      peer.sendRaw(text);
    }
  }
}

class SignalingPeer {
  SignalingPeer(this._channel);

  final WebSocketChannel _channel;
  String? deviceId;

  Stream<String> get messages => _channel.stream.map((event) {
        if (event is String) return event;
        if (event is List<int>) return utf8.decode(event);
        return event.toString();
      });

  void send(Envelope envelope) => sendRaw(envelope.toJsonString());

  void sendRaw(String raw) {
    _channel.sink.add(raw);
  }

  Future<void> close() async {
    await _channel.sink.close();
  }
}
