package kr.habitmonster.identity;

import java.time.Instant;
import java.time.LocalDate;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** {@code identity.users} */
@Entity
@Table(schema = "identity", name = "users")
public class User {

	public enum OnboardingStep { INTRO, CATEGORY, HABIT, GOAL, DONE }

	public enum Status { ACTIVE, WITHDRAWN }

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;

	@Column(length = 30)
	private String nickname;

	@Enumerated(EnumType.STRING)
	@Column(name = "onboarding_step", nullable = false)
	private OnboardingStep onboardingStep = OnboardingStep.INTRO;

	@Enumerated(EnumType.STRING)
	@Column(nullable = false)
	private Status status = Status.ACTIVE;

	@Column(name = "last_active_date")
	private LocalDate lastActiveDate;

	@Column(name = "frozen_at")
	private Instant frozenAt;

	@Column(name = "created_at", nullable = false)
	private Instant createdAt;

	@Column(name = "updated_at", nullable = false)
	private Instant updatedAt;

	@Column(name = "withdrawn_at")
	private Instant withdrawnAt;

	protected User() {
	}

	public User(Instant now) {
		this.createdAt = now;
		this.updatedAt = now;
	}

	public Long getId() {
		return id;
	}

	public String getNickname() {
		return nickname;
	}

	public OnboardingStep getOnboardingStep() {
		return onboardingStep;
	}

	public boolean isOnboardingDone() {
		return onboardingStep == OnboardingStep.DONE;
	}

	public boolean isWithdrawn() {
		return status == Status.WITHDRAWN;
	}

	public void changeOnboardingStep(OnboardingStep step, Instant now) {
		this.onboardingStep = step;
		this.updatedAt = now;
	}
}
