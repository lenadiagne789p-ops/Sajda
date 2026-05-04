import 'heading_source_mobile.dart'
  if (dart.library.html) 'heading_source_web.dart';

import 'device_heading.dart';

/// Returns a stream of DeviceHeading where available. May be null if unsupported.
Stream<DeviceHeading>? headingStream() => headingStreamImpl();

/// Requests orientation sensor permission when required (Web/Safari).
/// Returns true if permission is granted or not needed.
Future<bool> requestHeadingPermission() => requestHeadingPermissionImpl();
