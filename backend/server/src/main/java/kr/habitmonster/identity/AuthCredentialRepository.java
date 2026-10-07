package kr.habitmonster.identity;

import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AuthCredentialRepository extends JpaRepository<AuthCredential, Long> {

	@EntityGraph(attributePaths = "user")
	Optional<AuthCredential> findByProviderAndProviderSubject(AuthProvider provider, String providerSubject);

	/** 사용자의 첫 로그인 수단 (응답의 provider 표시용 — 계정 연결 기능이 없어 보통 하나). */
	Optional<AuthCredential> findFirstByUser_IdOrderByIdAsc(Long userId);
}
