package kr.habitmonster.config;

import java.time.Duration;
import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

/**
 * 인증 설정 ({@code app.auth.*}). 비밀값은 환경변수로 넣는다 — application.properties 참고.
 *
 * @param jwtSecret access 토큰 서명 키 (HS256, 32바이트 이상)
 * @param kakao 카카오 앱 ID — 다른 앱에서 발급된 카카오 토큰을 거르기 위해 꼭 필요
 * @param google 허용할 구글 OAuth 클라이언트 ID들 (Android · iOS · 웹)
 * @param apple 허용할 애플 audience (iOS 번들 ID, 웹이면 Service ID)
 */
@ConfigurationProperties("app.auth")
public record AuthProperties(
		String jwtSecret,
		@DefaultValue("habit-monster") String issuer,
		@DefaultValue("30m") Duration accessTokenTtl,
		@DefaultValue("30d") Duration refreshTokenTtl,
		@DefaultValue Kakao kakao,
		@DefaultValue Google google,
		@DefaultValue Apple apple) {

	public record Kakao(@DefaultValue("") String appId) {
	}

	public record Google(@DefaultValue List<String> clientIds) {
	}

	public record Apple(@DefaultValue List<String> audiences) {
	}
}
