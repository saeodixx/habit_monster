package kr.habitmonster.auth;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;

import kr.habitmonster.common.ApiException;
import kr.habitmonster.common.ErrorCode;
import kr.habitmonster.config.AuthProperties;
import kr.habitmonster.identity.RefreshToken;
import kr.habitmonster.identity.RefreshTokenRepository;
import kr.habitmonster.identity.User;

import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;

/**
 * access 토큰(JWT, sub = users.id) + refresh 토큰(랜덤 문자열, DB엔 SHA-256만) 발급 · 교체 · 폐기.
 * 호출하는 쪽({@link AuthService})의 트랜잭션 안에서 쓴다.
 */
@Service
public class TokenService {

	public record Tokens(String accessToken, String refreshToken) {
	}

	private final SecureRandom random = new SecureRandom();
	private final JwtEncoder encoder;
	private final RefreshTokenRepository refreshTokens;
	private final AuthProperties props;
	private final Clock clock;

	public TokenService(JwtEncoder encoder, RefreshTokenRepository refreshTokens, AuthProperties props, Clock clock) {
		this.encoder = encoder;
		this.refreshTokens = refreshTokens;
		this.props = props;
		this.clock = clock;
	}

	public Tokens issue(User user) {
		Instant now = clock.instant();
		JwtClaimsSet claims = JwtClaimsSet.builder()
			.issuer(props.issuer())
			.subject(String.valueOf(user.getId()))
			.issuedAt(now)
			.expiresAt(now.plus(props.accessTokenTtl()))
			.build();
		String access = encoder
			.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims))
			.getTokenValue();

		byte[] raw = new byte[48];
		random.nextBytes(raw);
		String refresh = Base64.getUrlEncoder().withoutPadding().encodeToString(raw);
		refreshTokens.save(new RefreshToken(user, sha256Hex(refresh), now.plus(props.refreshTokenTtl()), now));
		return new Tokens(access, refresh);
	}

	/**
	 * refresh 토큰을 새것으로 교체(rotation). 이미 폐기된 토큰이 다시 오면 탈취로 보고 그 사용자의 refresh를 전부 폐기한다.
	 * 호출하는 트랜잭션은 {@code noRollbackFor = ApiException.class}여야 이 폐기가 남는다.
	 */
	public User rotate(String refresh) {
		Instant now = clock.instant();
		RefreshToken token = find(refresh);
		if (token.isRevoked()) {
			refreshTokens.revokeAllForUser(token.getUser().getId(), now);
			throw new ApiException(ErrorCode.INVALID_TOKEN);
		}
		if (token.isExpired(now) || token.getUser().isWithdrawn()) {
			throw new ApiException(ErrorCode.INVALID_TOKEN);
		}
		token.revoke(now);
		return token.getUser();
	}

	/** 로그아웃: 없는 토큰이어도 조용히 성공 (같은 요청을 다시 보내도 같은 결과). */
	public void revoke(String refresh) {
		if (refresh == null || refresh.isBlank()) {
			return;
		}
		refreshTokens.findByTokenHash(sha256Hex(refresh)).ifPresent(t -> t.revoke(clock.instant()));
	}

	private RefreshToken find(String refresh) {
		if (refresh == null || refresh.isBlank()) {
			throw new ApiException(ErrorCode.INVALID_TOKEN);
		}
		return refreshTokens.findByTokenHash(sha256Hex(refresh))
			.orElseThrow(() -> new ApiException(ErrorCode.INVALID_TOKEN));
	}

	static String sha256Hex(String value) {
		try {
			byte[] digest = MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8));
			return HexFormat.of().formatHex(digest);
		}
		catch (NoSuchAlgorithmException e) {
			throw new IllegalStateException(e);
		}
	}
}
