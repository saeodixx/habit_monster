/// 이미지 경로 모음. 새 이미지는 여기에 등록하고 pubspec.yaml의 폴더 안에 넣으면 된다.
class AppAssets {
  AppAssets._();

  static const String _monsters = 'assets/images/monsters';
  static const String _characters = 'assets/images/characters';
  static const String _items = 'assets/images/items';
  static const String _bg = 'assets/images/backgrounds';
  static const String _brand = 'assets/images/brand';

  // 몬스터
  static const String wolf = '$_monsters/wolf.png';
  static const String spark = '$_monsters/spark.png';
  static const String chick = '$_monsters/chick.png';
  static const String sprout = '$_monsters/sprout.png';
  static const String moon = '$_monsters/moon.png';

  // 캐릭터
  /// 대림대 박사 스프라이트 시트: 6열 × 6행 = 36프레임, 프레임 208×380px.
  static const String professorSheet = '$_characters/professor_sheet.png';
  static const int professorCols = 6;
  static const int professorRows = 6;
  static const double professorFrameW = 208;
  static const double professorFrameH = 380;

  static const String shopkeeper = '$_characters/shopkeeper.png';

  // 아이템
  static const String potionSmall = '$_items/potion_small.png';
  static const String potionMedium = '$_items/potion_medium.png';
  static const String potionLarge = '$_items/potion_large.png';
  static const String seongsilBall = '$_items/seongsil_ball.png';

  // 브랜드 (로그인 화면 로고 = 앱 아이콘)
  static const String logo = '$_brand/logo.png';

  // 배경
  static const String homeField = '$_bg/home_field.png';
}
