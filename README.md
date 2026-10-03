# 습관 몬스터 (habit_monster)

습관을 지키면 성실도가 쌓이고, 골드로 몬스터를 키우는 픽셀 게임형 습관 앱.

```
habit_monster/
├─ frontend/          Flutter 앱 (iOS · Android)
│  ├─ assets/
│  │  ├─ images/monsters/     잿불 늑대 · 찌릿 쥐 · 번쩍 병아리 · 새싹냥 · 그믐 꼬마
│  │  ├─ images/characters/   대림대 박사 스프라이트 시트(6×6) · 상점 주인
│  │  ├─ images/items/        물약 하급/중급/상급 · 성실볼
│  │  ├─ images/backgrounds/  홈 초원 배경
│  │  └─ fonts/               갈무리11 (OFL 라이선스 동봉)
│  ├─ lib/
│  │  ├─ core/        테마 · 색 · 이미지 경로 · 경제 수치 · 공용 위젯 · 게임 상태
│  │  ├─ data/        모델(습관/몬스터/아이템/목표) · 고정 데이터(카테고리·도감·상점)
│  │  └─ features/    onboarding · shell(상단 바+탭) · home · chat · stats · dex · goals
│  └─ test/
├─ backend/           서버 (스택 미정 · API 초안만 있음)
└─ docs/
   ├─ design/habit-monster-prototype.html   디자인 프로토타입 (브라우저로 열기)
   └─ economy-v1.md                          진화 경제 수치 설계
```

## 처음 실행하기

1. Flutter 설치 확인: `flutter --version` (3.19 이상 권장)
2. 플랫폼 폴더 만들기 (android/ios 등은 아직 없어요. `lib/`와 `pubspec.yaml`은 그대로 유지됩니다)
   ```
   cd frontend
   flutter create . --project-name habit_monster --org com.daelim.habitmonster --platforms android,ios
   ```
3. 패키지 받고 실행
   ```
   flutter pub get
   flutter run
   ```
4. 테스트: `flutter test`

## 지금 만들어진 것

- 대림대 박사 인트로 (스프라이트 36프레임 애니메이션 + 대사 타이핑)
- 상단 바 (날짜 · DAY/연속 · 탐색 횟수 · 골드 · 성실볼) + 하단 탭 5개
- 홈: 초원 배경 위를 몬스터가 돌아다님, 상점 (상점 주인 대사 + 구매)
- 경제 수치 · 카테고리 · 몬스터 도감 · 아이템 데이터, 성실도/레벨 계산 + 테스트

## 다음에 만들 것

온보딩 1~3단계 → 챗봇 습관 체크 → 탐색 → 몬스터 교감(쓰다듬기/간식/놀아주기/말 걸기) → 가방 → 도감 → 목표 → 통계 → 저장/백엔드 연동.
각 탭의 할 일 목록은 앱 안의 '준비 중' 화면에도 적혀 있어요.
