class ApiConfig {
  // Use IP for now as requested for tests (Laravel Reverb issue with domain)
  static const String _ipAddress = '35.205.132.251';
  static const String _domain = 'appcaderno.duckdns.org';

  // API Endpoints
  // Note: Using port 8080 for HTTP/IP as specified by user
  static String get baseUrl => 'http://$_ipAddress:8080/api';
  
  // Storage/Images
  static String get storageUrl => 'http://$_ipAddress:8080/storage/';

  // Reverb (WebSocket)
  static String get reverbHost => _ipAddress;
  static const int reverbPort = 6001;
  static const String reverbKey = '6572db37e0db7615a423';

  // Broadcaster Auth
  static String get authEndpoint => 'http://$_ipAddress:8080/api/broadcasting/auth';

  // Helper to switch to domain later if needed
  static String get baseUrlDomain => 'https://$_domain:9000/api';
  static String get storageUrlDomain => 'https://$_domain:9000/storage/';
}
