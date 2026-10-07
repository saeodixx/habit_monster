package kr.habitmonster.auth.social;

/**
 * 검증된 소셜 사용자.
 *
 * @param subject 제공자의 사용자 ID (카카오 회원번호, 구글 · 애플 sub) → {@code auth_credential.provider_subject}
 * @param email 제공자가 준 이메일 (없을 수 있음, 표시용)
 */
public record SocialIdentity(String subject, String email) {
}
