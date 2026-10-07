package kr.habitmonster.common;

/** 서비스에서 던지면 {@link ApiExceptionHandler}가 {@code {code, message}} 응답으로 바꾼다. */
public class ApiException extends RuntimeException {

	private final ErrorCode code;

	public ApiException(ErrorCode code) {
		this(code, code.message);
	}

	public ApiException(ErrorCode code, String message) {
		super(message);
		this.code = code;
	}

	public ErrorCode code() {
		return code;
	}
}
