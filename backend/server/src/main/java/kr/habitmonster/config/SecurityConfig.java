package kr.habitmonster.config;

import java.nio.charset.StandardCharsets;

import jakarta.servlet.http.HttpServletResponse;

import kr.habitmonster.common.ErrorCode;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.SecurityFilterChain;

/** {@code /auth/**}만 열고, 나머지는 {@code Authorization: Bearer <accessToken>} 필요. 세션 · CSRF 없음 (앱 전용 API). */
@Configuration
public class SecurityConfig {

	@Bean
	SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
		AuthenticationEntryPoint unauthorized = (req, res, e) -> {
			ErrorCode code = req.getHeader("Authorization") == null ? ErrorCode.UNAUTHORIZED : ErrorCode.INVALID_TOKEN;
			res.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
			res.setContentType(MediaType.APPLICATION_JSON_VALUE);
			res.setCharacterEncoding(StandardCharsets.UTF_8.name());
			res.getWriter().write("{\"code\":\"" + code.name() + "\",\"message\":\"" + code.message + "\"}");
		};
		return http
			.csrf(c -> c.disable())
			.httpBasic(b -> b.disable())
			.formLogin(f -> f.disable())
			.sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
			.authorizeHttpRequests(a -> a
				.requestMatchers("/auth/**", "/error").permitAll()
				.anyRequest().authenticated())
			.oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()).authenticationEntryPoint(unauthorized))
			.exceptionHandling(e -> e.authenticationEntryPoint(unauthorized))
			.build();
	}
}
