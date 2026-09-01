import 'dart:io';

/// Picks a usable LAN IPv4 address (prefers non-loopback).
Future<InternetAddress?> resolveLanIpv4() async {
  final interfaces = await NetworkInterface.list(
    includeLinkLocal: false,
    type: InternetAddressType.IPv4,
  );

  for (final iface in interfaces) {
    final name = iface.name.toLowerCase();
    if (name.contains('lo') || name.startsWith('utun') || name.startsWith('awdl')) {
      continue;
    }
    for (final addr in iface.addresses) {
      if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
        return addr;
      }
    }
  }

  for (final iface in interfaces) {
    for (final addr in iface.addresses) {
      if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
        return addr;
      }
    }
  }
  return null;
}

Future<String> resolveOwnerName() async {
  try {
    return Platform.localHostname;
  } catch (_) {
    return 'LanCast-Host';
  }
}
