import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/pixel_widgets.dart';
import '../onboarding/onboarding_parts.dart' show DotGridPainter, RibbonPanel, pixelInputDecoration;

/// 이메일 로그인 · 회원가입. 성공하면 닫히고, 아래의 [AuthGate]가 온보딩이나 홈을 보여준다.
class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  bool _signUp = false;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text;
    final pw = _password.text;
    final err = AuthRules.emailError(email) ??
        (_signUp ? AuthRules.passwordError(pw) : (pw.isEmpty ? '비밀번호를 입력해 주세요' : null)) ??
        (_signUp && pw != _confirm.text ? '비밀번호가 서로 달라요' : null);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _error = null);
    final auth = AuthScope.of(context);
    final nav = Navigator.of(context);
    try {
      if (_signUp) {
        await auth.signUpWithEmail(email, pw);
      } else {
        await auth.signInWithEmail(email, pw);
      }
      nav.pop();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Widget _field(String label, TextEditingController c, {bool secret = false, String hint = ''}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.brownMuted)),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.parchment,
            border: Border.all(color: AppColors.ink, width: 3),
          ),
          child: Semantics(
            label: label,
            child: TextField(
              controller: c,
              obscureText: secret,
              keyboardType: secret ? TextInputType.visiblePassword : TextInputType.emailAddress,
              autocorrect: false,
              enableSuggestions: !secret,
              cursorColor: AppColors.brownText,
              style: const TextStyle(fontSize: 13, color: AppColors.brownText),
              decoration: pixelInputDecoration(hint),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = AuthScope.of(context).busy;
    return Scaffold(
      backgroundColor: AppColors.introSky,
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: DotGridPainter())),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    button: true,
                    label: '뒤로',
                    excludeSemantics: true,
                    onTap: () => Navigator.of(context).pop(),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('◀ 뒤로', style: TextStyle(fontSize: 12, color: AppColors.purpleSoft)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 로그인 / 회원가입 탭
                Row(
                  children: [
                    for (final (signUp, label) in const [(false, '로그인'), (true, '회원가입')]) ...[
                      if (signUp) const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _signUp = signUp;
                            _error = null;
                          }),
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _signUp == signUp ? AppColors.introFloor : AppColors.nightDeep,
                              border: Border.all(
                                  color: _signUp == signUp ? AppColors.purple : AppColors.nightLine, width: 3),
                            ),
                            child: Text(label,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _signUp == signUp ? AppColors.text : AppColors.textMuted)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                RibbonPanel(
                  title: _signUp ? '이메일로 가입' : '이메일로 로그인',
                  gap: 12,
                  children: [
                    _field('이메일', _email, hint: 'you@example.com'),
                    _field('비밀번호', _password,
                        secret: true, hint: _signUp ? '${AuthRules.minPasswordLength}자 이상' : ''),
                    if (_signUp) _field('비밀번호 확인', _confirm, secret: true),
                    if (_error != null)
                      Text(_error!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.red)),
                    PixelButton(
                      label: busy ? '잠시만요…' : (_signUp ? '가입하고 시작하기' : '로그인'),
                      onPressed: busy ? null : _submit,
                      height: 46,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
