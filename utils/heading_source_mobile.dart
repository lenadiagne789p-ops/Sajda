import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'device_heading.dart';

// Mobile/desktop (non-web) implementation: proxies flutter_qiblah events
Stream<DeviceHeading>? headingStreamImpl() {
  try {
    return FlutterQiblah.qiblahStream.map((e) => DeviceHeading(e.direction));
  } catch (_) {
    return null;
  }
}

Future<bool> requestHeadingPermissionImpl() async {
  // Mobile sensors for compass do not require explicit permission
  // (location permission is handled elsewhere for bearing calculation).
  return true;
}
