import 'package:url_launcher/url_launcher.dart';

class ExternalLinkService {
  ExternalLinkService._();

  static Uri? browserUri(String? value) {
    var raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    if (raw.toLowerCase().startsWith('www.')) raw = 'https://$raw';

    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    return uri;
  }

  static Future<bool> open(String? value) async {
    final uri = browserUri(value);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
