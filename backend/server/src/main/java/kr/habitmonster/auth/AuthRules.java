package kr.habitmonster.auth;

import java.nio.charset.StandardCharsets;
import java.util.Locale;
import java.util.regex.Pattern;

import kr.habitmonster.common.ApiException;
import kr.habitmonster.common.ErrorCode;

/** 입력 규칙 — 앱의 {@code AuthRules}와 같다 (앱이 먼저 검사해도 서버가 다시 검사). */
final class AuthRules {

	static final int MIN_PASSWORD_LENGTH = 8;
	/** BCrypt는 72바이트까지만 본다. */
	static final int MAX_PASSWORD_BYTES = 72;
	private static final Pattern EMAIL = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

	private AuthRules() {
	}

	static String normalizeEmail(String email) {
		return email == null ? "" : email.trim().toLowerCase(Locale.ROOT);
	}

	static String requireValidEmail(String email) {
		String e = normalizeEmail(email);
		if (e.length() > 255 || !EMAIL.matcher(e).matches()) {
			throw new ApiException(ErrorCode.INVALID_EMAIL);
		}
		return e;
	}

	static void requireValidPassword(String password) {
		if (password == null || password.length() < MIN_PASSWORD_LENGTH) {
			throw new ApiException(ErrorCode.WEAK_PASSWORD);
		}
		if (password.getBytes(StandardCharsets.UTF_8).length > MAX_PASSWORD_BYTES) {
			throw new ApiException(ErrorCode.WEAK_PASSWORD, "비밀번호가 너무 길어요");
		}
	}
}
