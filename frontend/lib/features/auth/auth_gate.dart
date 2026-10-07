import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../onboarding/onboarding_screen.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';

/// 첫 화면 결정: 로그인 전 → 로그인, 온보딩 전 → 온보딩(인트로부터), 그 밖 → 홈.
/// 로그아웃하면 이 화면으로 돌아온다 ([MainShellState] 설정 창).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AuthScope.of(context).session;
    if (session == null) return const LoginScreen();
    return session.onboardingDone ? const MainShell() : const OnboardingScreen();
  }
}
