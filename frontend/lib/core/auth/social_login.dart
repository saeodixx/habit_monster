import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../config/app_config.dart';
import 'auth_service.dart';

/// 카카오 · 구글 SDK로 로그인 창을 띄워 "서버에 보낼 토큰"을 받는다.
/// 받은 토큰은 서버가 직접 검증한다 (backend/README.md "인증 API").
abstract class SocialLogin {
  /// 카카오: access token / 구글: ID 토큰. 사용자가 취소하면 `AuthException('CANCELED')`.
  Future<String> token(AuthProvider provider);

  /// 다음 로그인 때 계정을 다시 고를 수 있게 SDK 쪽 로그인도 끊는다.
  Future<void> signOut(AuthProvider provider);
}

class SdkSocialLogin implements SocialLogin {
  Future<void>? _googleInit;

  static const _canceled = AuthException('CANCELED', '로그인을 취소했어요');

  @override
  Future<String> token(AuthProvider provider) async {
    if (kIsWeb) {
      // 웹은 카카오 JavaScript 키 · 구글 웹 버튼이 따로 필요해서 아직 지원하지 않는다.
      throw const AuthException('UNSUPPORTED', '웹에서는 아직 지원하지 않아요. 앱에서 이용해 주세요');
    }
    return switch (provider) {
      AuthProvider.kakao => _kakao(),
      AuthProvider.google => _google(),
      AuthProvider.email => throw ArgumentError('이메일은 소셜 로그인이 아님'),
    };
  }

  /// 카카오톡이 있으면 카카오톡으로, 없거나 연결된 계정이 없으면 카카오계정(브라우저)으로 (카카오 권장 순서).
  Future<String> _kakao() async {
    try {
      if (await isKakaoTalkInstalled()) {
        try {
          return (await UserApi.instance.loginWithKakaoTalk()).accessToken;
        } on PlatformException catch (e) {
          if (e.code == 'CANCELED') throw _canceled;
          // 카카오톡에 연결된 카카오계정이 없으면 아래 카카오계정 로그인으로
        }
      }
      return (await UserApi.instance.loginWithKakaoAccount()).accessToken;
    } on AuthException {
      rethrow;
    } on KakaoAuthException catch (e) {
      if (e.error == AuthErrorCause.accessDenied) throw _canceled;
      throw const AuthException('SOCIAL_FAILED', '카카오 로그인에 실패했어요');
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') throw _canceled;
      throw const AuthException('SOCIAL_FAILED', '카카오 로그인에 실패했어요');
    } catch (_) {
      throw const AuthException('SOCIAL_FAILED', '카카오 로그인에 실패했어요');
    }
  }

  Future<String> _google() async {
    final g = GoogleSignIn.instance;
    try {
      await (_googleInit ??= g.initialize(serverClientId: AppConfig.googleServerClientId));
      final account = await g.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthException('SOCIAL_FAILED', '구글 로그인에 실패했어요');
      return idToken;
    } on AuthException {
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw _canceled;
      throw const AuthException('SOCIAL_FAILED', '구글 로그인에 실패했어요');
    } catch (_) {
      throw const AuthException('SOCIAL_FAILED', '구글 로그인에 실패했어요');
    }
  }

  @override
  Future<void> signOut(AuthProvider provider) async {
    if (kIsWeb) return;
    try {
      switch (provider) {
        case AuthProvider.kakao:
          await UserApi.instance.logout();
        case AuthProvider.google:
          await (_googleInit ??= GoogleSignIn.instance.initialize(serverClientId: AppConfig.googleServerClientId));
          await GoogleSignIn.instance.signOut();
        case AuthProvider.email:
          break;
      }
    } catch (_) {
      // SDK 로그아웃 실패는 무시 (우리 서버 로그아웃은 이미 끝남)
    }
  }
}
