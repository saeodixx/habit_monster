import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// 배경음악 곡. 파일은 `assets/audio/bgm/<이름>.mp3`.
enum BgmTrack { intro, home, chat, explore, shop }

/// 배경음악. 화면이 "지금 이 곡"을 요청하면 이전 곡을 줄이고 새 곡을 키운다(크로스페이드).
abstract class Bgm extends ChangeNotifier {
  /// 켜져 있는지 (상단 바 스피커 버튼).
  bool get enabled;
  void setEnabled(bool on);

  /// 이 곡을 반복 재생한다 (이미 그 곡이면 그대로).
  void play(BgmTrack track);

  /// 첫 터치 때 다시 시도 (웹 브라우저는 사용자가 누르기 전엔 소리를 막는다).
  void unlock();
}

/// 소리 없는 버전 (테스트 · BgmScope 밖).
class SilentBgm extends Bgm {
  bool _on = true;
  BgmTrack? lastRequested;

  @override
  bool get enabled => _on;

  @override
  void setEnabled(bool on) {
    _on = on;
    notifyListeners();
  }

  @override
  void play(BgmTrack track) => lastRequested = track;

  @override
  void unlock() {}
}

/// 실제 재생 (audioplayers).
class AudioBgm extends Bgm {
  static const double _volume = 0.45;
  static const int _fadeSteps = 8;
  static const Duration _fadeStep = Duration(milliseconds: 40); // 페이드 약 0.3초

  final AudioPlayer _player = AudioPlayer(playerId: 'bgm');
  BgmTrack? _want;
  BgmTrack? _playing;
  bool _on = true;
  bool _busy = false;
  double _vol = 0;

  @override
  bool get enabled => _on;

  @override
  void setEnabled(bool on) {
    _on = on;
    notifyListeners();
    _sync();
  }

  @override
  void play(BgmTrack track) {
    _want = track;
    _sync();
  }

  @override
  void unlock() {
    if (_playing != _want) _sync();
  }

  /// 원하는 곡과 실제 재생 곡을 맞춘다. 페이드 중에 요청이 바뀌면 끝난 뒤 다시 맞춘다.
  Future<void> _sync() async {
    if (_busy) return;
    _busy = true;
    try {
      while (true) {
        final target = _on ? _want : null;
        if (target == _playing) break;
        if (_playing != null) {
          await _fadeTo(0);
          await _player.stop();
          _playing = null;
        }
        if (target != null) {
          await _player.setReleaseMode(ReleaseMode.loop);
          await _player.play(AssetSource('audio/bgm/${target.name}.mp3'), volume: 0);
          _playing = target;
          await _fadeTo(_volume);
        }
      }
    } catch (_) {
      // 웹 자동재생 차단 등: 다음 터치(unlock) 때 다시 시도
      _playing = null;
    } finally {
      _busy = false;
    }
  }

  Future<void> _fadeTo(double to) async {
    final from = _vol;
    for (var i = 1; i <= _fadeSteps; i++) {
      _vol = from + (to - from) * i / _fadeSteps;
      await _player.setVolume(_vol);
      await Future<void>.delayed(_fadeStep);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

/// 위젯 트리에서 `BgmScope.of(context)`로 배경음악을 꺼내 쓴다. 없으면 소리 없는 버전.
class BgmScope extends InheritedNotifier<Bgm> {
  const BgmScope({super.key, required Bgm super.notifier, required super.child});

  static final Bgm _silent = SilentBgm();

  /// 스피커 버튼처럼 켜짐/꺼짐이 바뀌면 다시 그려야 할 때.
  static Bgm of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BgmScope>()?.notifier ?? _silent;

  /// 곡만 바꿀 때 (다시 그리기 구독 없음).
  static Bgm read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<BgmScope>()?.notifier ?? _silent;
}
