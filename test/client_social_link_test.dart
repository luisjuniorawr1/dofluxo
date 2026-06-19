import 'package:dofluxo/presentation/clients/models/client_social_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SocialLinkDetector', () {
    test('detects Instagram from URL', () {
      final result = SocialLinkDetector.detect('https://instagram.com/pequi.agencia');
      expect(result.platform, SocialPlatform.instagram);
      expect(result.handle, '@pequi.agencia');
    });

    test('detects Instagram from @handle', () {
      final result = SocialLinkDetector.detect('@pequi.agencia');
      expect(result.platform, SocialPlatform.instagram);
      expect(result.handle, '@pequi.agencia');
    });

    test('detects WhatsApp from phone number', () {
      final result = SocialLinkDetector.detect('11987654321');
      expect(result.platform, SocialPlatform.whatsapp);
      expect(result.normalizedValue, contains('wa.me'));
    });

    test('detects LinkedIn from URL', () {
      final result = SocialLinkDetector.detect('linkedin.com/company/pequi');
      expect(result.platform, SocialPlatform.linkedin);
    });

    test('parses ClientSocialLink for storage', () {
      final link = ClientSocialLink.parse('https://tiktok.com/@pequi');
      expect(link.platform, SocialPlatform.tiktok);
      expect(link.toMap()['platform'], 'tiktok');
    });
  });
}
