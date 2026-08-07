class ApiConfig {
  static const String _domain = 'appcaderno.duckdns.org';

  // API Endpoints (Porta 9000 com HTTPS gerida pelo Apache)
  static String get baseUrl => 'https://$_domain:9000/api';
  static String get storageUrl => 'https://$_domain:9000/storage/';

  // Reverb / WebSocket (Porta 6001 com WSS gerida pelo Apache Proxy)
  static String get reverbHost => _domain;
  static const int reverbPort = 6001;
  static const String reverbKey = '6572db37e0db7615a423';

  // Broadcaster Auth
  static String get authEndpoint => 'https://$_domain:9000/api/broadcasting/auth';

  // Helper opcional
  static String get baseUrlDomain => 'https://$_domain:9000/api';
  static String get storageUrlDomain => 'https://$_domain:9000/storage/';
}
