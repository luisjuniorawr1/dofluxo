/// Serviço de checagem de versão publicada.
///
/// Implementação real na web (`app_version_service_web.dart`) e no-op nas
/// demais plataformas (`app_version_service_stub.dart`), selecionada em
/// tempo de compilação.
export 'app_version_service_stub.dart'
    if (dart.library.html) 'app_version_service_web.dart';
