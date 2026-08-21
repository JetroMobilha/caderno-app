import 'dart:io';

/// 🛡️ Configuração de certificados SSL para plataformas nativas (Android/Windows/etc).
/// Esta classe NÃO deve ser importada na Web.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void applyHttpOverrides() {
  HttpOverrides.global = MyHttpOverrides();
}
