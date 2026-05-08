// Web implementation: compass/heading not available on web
import 'device_heading.dart';

Stream<DeviceHeading>? headingStreamImpl() {
  // Heading stream is not supported on web
  return null;
}

Future<bool> requestHeadingPermissionImpl() async {
  // No permission needed on web (feature not supported)
  return false;
}
