package kr.habitmonster.common;

import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class ApiExceptionHandler {

	public record ErrorBody(String code, String message) {
	}

	public static ResponseEntity<ErrorBody> body(ErrorCode code, String message) {
		return ResponseEntity.status(code.status).body(new ErrorBody(code.name(), message));
	}

	@ExceptionHandler(ApiException.class)
	ResponseEntity<ErrorBody> api(ApiException e) {
		return body(e.code(), e.getMessage());
	}

	@ExceptionHandler({ HttpMessageNotReadableException.class, MethodArgumentNotValidException.class })
	ResponseEntity<ErrorBody> badRequest(Exception e) {
		return body(ErrorCode.BAD_REQUEST, ErrorCode.BAD_REQUEST.message);
	}
}
