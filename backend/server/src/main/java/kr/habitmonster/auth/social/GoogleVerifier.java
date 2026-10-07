package kr.habitmonster.auth.social;

import java.util.Set;

import kr.habitmonster.config.AuthProperties;
import kr.habitmonster.identity.AuthProvider;

import org.springframework.stereotype.Component;

/** 구글: 앱이 {@code google_sign_in}으로 받은 ID 토큰. aud = 우리 OAuth 클라이언트 ID. */
@Component
public class GoogleVerifier extends OidcIdTokenVerifier {

	public GoogleVerifier(AuthProperties props) {
		super("https://www.googleapis.com/oauth2/v3/certs",
				Set.of("accounts.google.com", "https://accounts.google.com"),
				props.google().clientIds());
	}

	@Override
	public AuthProvider provider() {
		return AuthProvider.GOOGLE;
	}
}
