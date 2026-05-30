/// Legal document bodies (EN / TR). Titles come from [AppLocalizations].
enum LegalDocumentType { privacy, terms, cookies }

class LegalSection {
  final String title;
  final List<String> paragraphs;

  const LegalSection({required this.title, required this.paragraphs});
}

List<LegalSection> legalSections(LegalDocumentType type, String languageCode) {
  final tr = languageCode.startsWith('tr');
  switch (type) {
    case LegalDocumentType.privacy:
      return tr ? _privacyTr : _privacyEn;
    case LegalDocumentType.terms:
      return tr ? _termsTr : _termsEn;
    case LegalDocumentType.cookies:
      return tr ? _cookiesTr : _cookiesEn;
  }
}

const _privacyEn = [
  LegalSection(
    title: '1. Who we are',
    paragraphs: [
      'Phobes is operated by Techluna Software ("we", "us"). This Privacy Policy explains how we collect, use, and protect information when you use the Phobes mobile and web applications.',
      'Contact: support@phobes.app',
    ],
  ),
  LegalSection(
    title: '2. Data we process',
    paragraphs: [
      'Account data: email, display name, authentication identifiers, and profile settings you provide.',
      'Productivity data you create: tasks, notes, calendars, budgets, medications, habits, appointments, team content, and AI chat history with Nova.',
      'Technical data: device type, app version, crash reports (Crashlytics on mobile), and security signals (Firebase App Check).',
      'We do not sell your personal data.',
    ],
  ),
  LegalSection(
    title: '3. How we use data',
    paragraphs: [
      'To provide and sync your workspace across devices.',
      'To send notifications you enable (reminders, team activity, etc.).',
      'To secure the service (authentication, abuse prevention, Firestore security rules).',
      'Nova AI: prompts and context snippets are sent to our Cloud Functions proxy; API keys stay on the server, not in the client app.',
    ],
  ),
  LegalSection(
    title: '4. Service providers',
    paragraphs: [
      'We use Google Firebase (Authentication, Firestore, Cloud Functions, Hosting, FCM, App Check) and, for Nova, Groq via our backend. These providers process data under their terms and our configuration.',
      'Optional integrations (e.g. calendar sync) only run when you enable them.',
    ],
  ),
  LegalSection(
    title: '5. Storage and retention',
    paragraphs: [
      'Your content is stored in Firebase Firestore in your project region as configured in the Firebase console.',
      'You may export a JSON backup from Account settings and request account deletion, which removes your profile via our deleteUserAccount Cloud Function subject to legal retention limits.',
    ],
  ),
  LegalSection(
    title: '6. Your rights',
    paragraphs: [
      'Depending on your region (including GDPR / KVKK), you may request access, correction, deletion, or restriction of processing. Contact support@phobes.app.',
      'You can sign out at any time and disable modules you do not use.',
    ],
  ),
  LegalSection(
    title: '7. Children',
    paragraphs: [
      'Phobes is not directed at children under 13 (or the minimum age in your country). We do not knowingly collect data from children.',
    ],
  ),
  LegalSection(
    title: '8. Changes',
    paragraphs: [
      'We may update this policy. Material changes will be reflected in the app or on the landing page. Continued use after the effective date constitutes acceptance.',
    ],
  ),
];

const _privacyTr = [
  LegalSection(
    title: '1. Veri sorumlusu',
    paragraphs: [
      'Phobes, Techluna Software ("biz") tarafından işletilir. Bu Gizlilik Politikası, Phobes mobil ve web uygulamalarını kullandığınızda bilgilerinizi nasıl topladığımızı, kullandığımızı ve koruduğumuzu açıklar.',
      'İletişim: support@phobes.app',
    ],
  ),
  LegalSection(
    title: '2. İşlenen veriler',
    paragraphs: [
      'Hesap verileri: e-posta, görünen ad, kimlik doğrulama bilgileri ve profil ayarları.',
      'Oluşturduğunuz veriler: görevler, notlar, takvim, bütçe, ilaçlar, alışkanlıklar, randevular, ekip içerikleri ve Nova sohbet geçmişi.',
      'Teknik veriler: cihaz türü, uygulama sürümü, çökme raporları (mobilde Crashlytics) ve güvenlik sinyalleri (Firebase App Check).',
      'Kişisel verilerinizi satmıyoruz.',
    ],
  ),
  LegalSection(
    title: '3. Kullanım amaçları',
    paragraphs: [
      'Hizmeti sunmak ve cihazlar arasında senkronize etmek.',
      'Etkinleştirdiğiniz bildirimleri göndermek.',
      'Hizmeti güvence altına almak (kimlik doğrulama, kötüye kullanım önleme, Firestore kuralları).',
      'Nova AI: istemler ve bağlam parçaları Cloud Functions üzerinden iletilir; API anahtarları istemcide tutulmaz.',
    ],
  ),
  LegalSection(
    title: '4. Hizmet sağlayıcılar',
    paragraphs: [
      'Google Firebase (Kimlik Doğrulama, Firestore, Cloud Functions, Hosting, FCM, App Check) ve Nova için Groq (sunucu tarafı proxy) kullanıyoruz.',
      'İsteğe bağlı entegrasyonlar (ör. takvim) yalnızca siz etkinleştirdiğinizde çalışır.',
    ],
  ),
  LegalSection(
    title: '5. Saklama',
    paragraphs: [
      'İçerikleriniz Firebase Firestore\'da saklanır.',
      'Hesap ayarlarından JSON yedek alabilir; hesap silme talebi deleteUserAccount Cloud Function ile işlenir.',
    ],
  ),
  LegalSection(
    title: '6. Haklarınız',
    paragraphs: [
      'KVKK / GDPR kapsamında erişim, düzeltme, silme veya işlemeyi kısıtlama talep edebilirsiniz: support@phobes.app',
    ],
  ),
  LegalSection(
    title: '7. Çocuklar',
    paragraphs: [
      'Phobes, 13 yaş altına yönelik değildir; bilerek çocuk verisi toplamıyoruz.',
    ],
  ),
  LegalSection(
    title: '8. Değişiklikler',
    paragraphs: [
      'Bu politikayı güncelleyebiliriz. Önemli değişiklikler uygulama veya landing sayfasında yansıtılır.',
    ],
  ),
];

const _termsEn = [
  LegalSection(
    title: '1. Acceptance',
    paragraphs: [
      'By creating an account or using Phobes, you agree to these Terms of Service. If you disagree, do not use the service.',
    ],
  ),
  LegalSection(
    title: '2. The service',
    paragraphs: [
      'Phobes is a personal productivity platform (tasks, notes, calendar, budget, teams, AI assistant, and related modules). Features may change; some modules can be disabled in settings.',
      'We strive for high availability but do not guarantee uninterrupted access.',
    ],
  ),
  LegalSection(
    title: '3. Your account',
    paragraphs: [
      'You are responsible for safeguarding your credentials and for activity under your account.',
      'You must provide accurate information and comply with applicable laws.',
    ],
  ),
  LegalSection(
    title: '4. Acceptable use',
    paragraphs: [
      'Do not upload illegal content, malware, or material that infringes others\' rights.',
      'Do not attempt to bypass security, scrape other users\' data, or abuse Nova or API rate limits.',
      'We may suspend accounts that violate these terms or harm the service.',
    ],
  ),
  LegalSection(
    title: '5. Teams and sharing',
    paragraphs: [
      'When you join a team, other members may see content you share in that team according to Firestore rules and in-app permissions.',
      'Team owners and admins manage membership; share sensitive data only with trusted collaborators.',
    ],
  ),
  LegalSection(
    title: '6. AI (Nova)',
    paragraphs: [
      'Nova outputs are generated automatically and may be inaccurate. Do not rely on Nova for medical, legal, or financial decisions.',
      'You retain ownership of your prompts and content; you grant us a license to process them solely to provide the feature.',
    ],
  ),
  LegalSection(
    title: '7. Limitation of liability',
    paragraphs: [
      'To the extent permitted by law, Phobes and Techluna Software are not liable for indirect damages, data loss not caused by our negligence, or third-party service outages.',
      'Our total liability is limited to the amount you paid us in the twelve months before the claim (or zero for free use).',
    ],
  ),
  LegalSection(
    title: '8. Termination',
    paragraphs: [
      'You may delete your account at any time. We may terminate access for breach of these terms.',
    ],
  ),
];

const _termsTr = [
  LegalSection(
    title: '1. Kabul',
    paragraphs: [
      'Hesap oluşturarak veya Phobes\'i kullanarak bu Kullanım Şartları\'nı kabul etmiş olursunuz.',
    ],
  ),
  LegalSection(
    title: '2. Hizmet',
    paragraphs: [
      'Phobes kişisel verimlilik platformudur. Özellikler değişebilir; modüller ayarlardan kapatılabilir.',
      'Kesintisiz erişim garanti edilmez.',
    ],
  ),
  LegalSection(
    title: '3. Hesap',
    paragraphs: [
      'Kimlik bilgilerinizin güvenliğinden ve hesabınızdaki işlemlerden siz sorumlusunuz.',
    ],
  ),
  LegalSection(
    title: '4. Kabul edilebilir kullanım',
    paragraphs: [
      'Yasadışı içerik, kötü amaçlı yazılım veya başkalarının haklarını ihlal eden materyal yüklemeyin.',
      'Güvenliği aşmaya, veri kazımaya veya Nova/API limitlerini kötüye kullanmaya çalışmayın.',
    ],
  ),
  LegalSection(
    title: '5. Ekipler',
    paragraphs: [
      'Bir ekibe katıldığınızda, paylaştığınız içerik kurallar ve izinlere göre diğer üyelere görünebilir.',
    ],
  ),
  LegalSection(
    title: '6. Nova AI',
    paragraphs: [
      'Nova çıktıları otomatiktir ve hatalı olabilir. Tıbbi, hukuki veya finansal kararlar için güvenmeyin.',
    ],
  ),
  LegalSection(
    title: '7. Sorumluluk sınırı',
    paragraphs: [
      'Yasaların izin verdiği ölçüde dolaylı zararlardan sorumlu değiliz.',
    ],
  ),
  LegalSection(
    title: '8. Fesih',
    paragraphs: [
      'Hesabınızı istediğiniz zaman silebilirsiniz. Şart ihlalinde erişim sonlandırılabilir.',
    ],
  ),
];

const _cookiesEn = [
  LegalSection(
    title: '1. What are cookies?',
    paragraphs: [
      'Cookies and similar technologies (local storage, session storage) help websites remember preferences and keep you signed in.',
    ],
  ),
  LegalSection(
    title: '2. Web app (phobes.app)',
    paragraphs: [
      'Firebase Authentication uses secure tokens stored in the browser to maintain your session.',
      'Firebase App Check and reCAPTCHA may set cookies or use browser storage to reduce abuse.',
      'We do not use third-party advertising cookies on the Phobes web app.',
    ],
  ),
  LegalSection(
    title: '3. Mobile apps',
    paragraphs: [
      'Android and iOS apps use platform secure storage and Firebase SDKs instead of browser cookies.',
    ],
  ),
  LegalSection(
    title: '4. Managing cookies',
    paragraphs: [
      'You can clear site data in your browser settings. Signing out removes the active session token.',
      'Disabling cookies may prevent the web app from working correctly.',
    ],
  ),
];

const _cookiesTr = [
  LegalSection(
    title: '1. Çerez nedir?',
    paragraphs: [
      'Çerezler ve benzeri teknolojiler (yerel depolama), web sitesinin tercihlerinizi hatırlamasına ve oturumunuzu sürdürmesine yardımcı olur.',
    ],
  ),
  LegalSection(
    title: '2. Web uygulaması',
    paragraphs: [
      'Firebase Authentication oturumunuzu sürdürmek için güvenli belirteçler kullanır.',
      'Firebase App Check ve reCAPTCHA kötüye kullanımı azaltmak için depolama kullanabilir.',
      'Phobes web uygulamasında üçüncü taraf reklam çerezi kullanmıyoruz.',
    ],
  ),
  LegalSection(
    title: '3. Mobil uygulamalar',
    paragraphs: [
      'Android ve iOS uygulamaları tarayıcı çerezleri yerine platform güvenli depolama ve Firebase SDK kullanır.',
    ],
  ),
  LegalSection(
    title: '4. Yönetim',
    paragraphs: [
      'Tarayıcı ayarlarından site verilerini temizleyebilirsiniz. Çıkış yapmak oturum belirtecini kaldırır.',
      'Çerezleri devre dışı bırakmak web uygulamasının çalışmasını engelleyebilir.',
    ],
  ),
];
