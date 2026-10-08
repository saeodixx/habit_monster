/// 빌드할 때 바꿀 수 있는 설정. `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080` 처럼 넣는다.
///
/// 카카오 네이티브 앱 키와 구글 클라이언트 ID는 원래 앱 안에 들어가는 공개 값이라 기본값으로 둔다.
/// (카카오 REST API 키 · 어드민 키, 구글 클라이언트 보안 비밀은 절대 여기에 넣지 않는다.)
class AppConfig {
  AppConfig._();

  /// Spring 서버 주소. 비어 있으면 서버 없이 앱 안에서만 동작하는 가짜 로그인(FakeAuthService)을 쓴다.
  /// Android 에뮬레이터에서 PC의 서버: `http://10.0.2.2:8080`, 실제 폰: `http://<PC의 IP>:8080`
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static bool get useServer => apiBaseUrl.isNotEmpty;

  /// 카카오 개발자 콘솔 [앱] > [플랫폼 키] > [네이티브 앱 키]
  static const String kakaoNativeAppKey =
      String.fromEnvironment('KAKAO_NATIVE_APP_KEY', defaultValue: '8d795d4d9a367e3678e1538467f12fe4');

  /// 구글 OAuth "웹" 클라이언트 ID. Android에서 서버용 ID 토큰을 받을 때 쓴다 (serverClientId).
  /// Android 클라이언트 ID는 코드에 넣지 않는다 — 구글이 패키지명 + SHA-1로 알아서 찾는다.
  static const String googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID',
      defaultValue: '661947484282-v08ku1t429h6dtj70v710pvsm5ps2fhb.apps.googleusercontent.com');
}
