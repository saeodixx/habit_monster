import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app.dart';
import 'core/auth/auth_service.dart';
import 'core/auth/http_auth_service.dart';
import 'core/auth/social_login.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) KakaoSdk.init(nativeAppKey: AppConfig.kakaoNativeAppKey);

  // 서버 주소를 주고 빌드하면 진짜 로그인, 아니면 앱 안에서만 동작하는 가짜 로그인.
  final AuthService auth = AppConfig.useServer
      ? HttpAuthService(baseUrl: AppConfig.apiBaseUrl, social: SdkSocialLogin())
      : FakeAuthService();
  runApp(HabitMonsterApp(authService: auth));
}
