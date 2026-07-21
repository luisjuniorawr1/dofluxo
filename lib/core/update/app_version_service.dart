/// Serviço de checagem de versão publicada.
///
/// Implementação real na web; no-op nas demais plataformas.
export 'app_version_service_stub.dart'
    if (dart.library.html) 'app_version_service_web.dart';
