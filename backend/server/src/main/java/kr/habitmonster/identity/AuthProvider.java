package kr.habitmonster.identity;

import java.util.Locale;
import java.util.Optional;

/**
 * DB {@code identity.auth_provider.code}. 새 제공자(네이버 등)는 DB INSERT + 여기 + SocialVerifier 구현.
 * (애플은 유료 개발자 계정이 필요해 지금은 쓰지 않는다. DB의 APPLE 코드는 그대로 둠.)
 */
public enum AuthProvider {
	EMAIL, KAKAO, GOOGLE;

	/** URL 경로의 소문자 이름 ({@code /auth/social/kakao}) → 소셜 제공자. EMAIL은 소셜이 아니므로 제외. */
	public static Optional<AuthProvider> social(String path) {
		for (AuthProvider p : values()) {
			if (p != EMAIL && p.name().equals(path.toUpperCase(Locale.ROOT))) {
				return Optional.of(p);
			}
		}
		return Optional.empty();
	}
}
