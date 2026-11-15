import 'package:url_launcher/url_launcher.dart';

class MapLauncherService {
  /// Opens the destination in Google Maps, leveraging user's downloaded offline areas.
  static Future<bool> openGoogleMaps({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    final encodedLabel = Uri.encodeComponent(label ?? 'Destination');

    // 1. Try Android native google.navigation intent first (works with offline downloaded areas)
    final Uri navUri = Uri.parse('google.navigation:q=$latitude,$longitude');
    try {
      if (await canLaunchUrl(navUri)) {
        return await launchUrl(navUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // 2. Try geo URI scheme
    final Uri geoUri =
        Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude($encodedLabel)');
    try {
      if (await canLaunchUrl(geoUri)) {
        return await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // 3. Fallback to web/app navigation URL
    final Uri webUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude');
    try {
      return await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
