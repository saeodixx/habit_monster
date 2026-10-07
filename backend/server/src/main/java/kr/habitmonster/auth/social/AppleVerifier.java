package kr.habitmonster.auth.social;

import java.util.Set;

import kr.habitmonster.config.AuthProperties;
import kr.habitmonster.identity.AuthProvider;

import org.springframework.stereotype.Component;

/** 애플: 앱이 {@code sign_in_with_apple}로 받은 identity token. aud = iOS 번들 ID (웹은 Service ID). */
@Component
public class AppleVerifier extends OidcIdTokenVerifier {

	public AppleVerifier(AuthProperties props) {
		super("https://appleid.apple.com/auth/keys", Set.of("https://appleid.apple.com"), props.apple().audiences());
	}

	@Override
	public AuthProvider provider() {
		return AuthProvider.APPLE;
	}
}
