package kr.habitmonster.common;

import org.springframework.http.HttpStatus;

/**
 * 앱과 같은 오류 코드. 응답은 {@code {"code": ..., "message": ...}}이고, message는 앱이 화면에 그대로 보여준다.
 * (frontend/lib/core/auth/auth_service.dart 의 AuthException 문구와 맞춤)
 */
public enum ErrorCode {
	INVALID_EMAIL(HttpStatus.BAD_REQUEST, "이메일 주소를 확인해 주세요"),
	WEAK_PASSWORD(HttpStatus.BAD_REQUEST, "비밀번호는 8자 이상이에요"),
	EMAIL_TAKEN(HttpStatus.CONFLICT, "이미 가입된 이메일이에요"),
	INVALID_CREDENTIALS(HttpStatus.UNAUTHORIZED, "이메일 또는 비밀번호가 맞지 않아요"),
	INVALID_TOKEN(HttpStatus.UNAUTHORIZED, "다시 로그인해 주세요"),
	UNAUTHORIZED(HttpStatus.UNAUTHORIZED, "로그인이 필요해요"),
	ACCOUNT_WITHDRAWN(HttpStatus.FORBIDDEN, "탈퇴한 계정이에요"),
	UNSUPPORTED_PROVIDER(HttpStatus.NOT_FOUND, "지원하지 않는 로그인 방식이에요"),
	SOCIAL_NOT_CONFIGURED(HttpStatus.SERVICE_UNAVAILABLE, "아직 준비 중인 로그인 방식이에요"),
	BAD_REQUEST(HttpStatus.BAD_REQUEST, "요청을 확인해 주세요");

	public final HttpStatus status;
	public final String message;

	ErrorCode(HttpStatus status, String message) {
		this.status = status;
		this.message = message;
	}
}
